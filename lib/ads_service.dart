import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kRemoveAdsProductId = 'remove_ads';
const String _kAdsRemovedPrefKey = 'ads_removed';

/// Single source of truth for "has the user bought Remove Ads" across the app.
/// Every screen that shows a banner ad checks [adsRemoved] before loading one
/// and listens to it so a purchase made on another screen hides ads immediately.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  final ValueNotifier<bool> adsRemoved = ValueNotifier(false);
  ValueListenable<bool> get purchaseInProgress => _purchaseInProgress;
  final ValueNotifier<bool> _purchaseInProgress = ValueNotifier(false);

  ProductDetails? removeAdsProduct;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _purchaseTimeoutTimer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    adsRemoved.value = prefs.getBool(_kAdsRemovedPrefKey) ?? false;

    final available = await _iap.isAvailable();
    debugPrint('[AdsService] Billing isAvailable: $available');
    if (!available) return;

    _purchaseSubscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) {
        debugPrint('[AdsService] purchaseStream error: $e');
        _purchaseInProgress.value = false;
      },
    );

    final response = await _iap.queryProductDetails({kRemoveAdsProductId});
    debugPrint('[AdsService] queryProductDetails found: ${response.productDetails.map((p) => p.id).toList()}');
    debugPrint('[AdsService] queryProductDetails notFoundIDs: ${response.notFoundIDs}');
    if (response.error != null) {
      debugPrint('[AdsService] queryProductDetails error: ${response.error!.code} ${response.error!.message}');
    }
    if (response.productDetails.isNotEmpty) {
      removeAdsProduct = response.productDetails.first;
    }

    // Recognize a purchase made before a reinstall / on another device
    // without requiring the user to tap "Restore purchases" themselves.
    if (!adsRemoved.value) {
      unawaited(_iap.restorePurchases());
    }
  }

  Future<void> buyRemoveAds() async {
    final product = removeAdsProduct;
    if (product == null) return;
    _purchaseInProgress.value = true;

    // Some platforms never deliver a purchaseStream update when the user
    // backs out of the native purchase sheet, which would otherwise leave
    // the Buy button stuck showing "Processing..." forever.
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 30), () {
      _purchaseInProgress.value = false;
    });

    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != kRemoveAdsProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _setAdsRemoved(true);
          _purchaseTimeoutTimer?.cancel();
          _purchaseInProgress.value = false;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _purchaseTimeoutTimer?.cancel();
          _purchaseInProgress.value = false;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _setAdsRemoved(bool value) async {
    adsRemoved.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdsRemovedPrefKey, value);
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseTimeoutTimer?.cancel();
  }
}
