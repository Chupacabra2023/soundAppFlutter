import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-intrusive "rate this app" prompt.
///
/// Shown [_kDaysBeforePrompt] days after first launch, as a small
/// dismissible bottom banner (not a blocking dialog). If the user dismisses
/// it (X), it comes back after [_kDaysBetweenReminders] days. If the user
/// rates the app, it never shows again.
class RateAppService {
  RateAppService._();
  static final RateAppService instance = RateAppService._();

  static const int _kDaysBeforePrompt = 3;
  static const int _kDaysBetweenReminders = 10;
  static const String _kFirstLaunchKey = 'rate_first_launch_ms';
  static const String _kRatedKey = 'rate_app_rated';
  static const String _kLastDismissedKey = 'rate_banner_last_dismissed_ms';

  /// Whether the bottom "rate us" banner should be shown right now.
  Future<bool> shouldShowBanner() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_kRatedKey) ?? false) return false;

    final firstLaunchMs = prefs.getInt(_kFirstLaunchKey);
    if (firstLaunchMs == null) {
      await prefs.setInt(_kFirstLaunchKey, DateTime.now().millisecondsSinceEpoch);
      return false;
    }

    final lastDismissedMs = prefs.getInt(_kLastDismissedKey);
    if (lastDismissedMs != null) {
      final lastDismissed = DateTime.fromMillisecondsSinceEpoch(lastDismissedMs);
      final daysSinceDismiss = DateTime.now().difference(lastDismissed).inDays;
      return daysSinceDismiss >= _kDaysBetweenReminders;
    }

    final firstLaunch = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
    final daysSince = DateTime.now().difference(firstLaunch).inDays;
    return daysSince >= _kDaysBeforePrompt;
  }

  /// User dismissed the banner (tapped the X) — ask again in
  /// [_kDaysBetweenReminders] days.
  Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastDismissedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// User tapped a star — trigger the platform's native in-app rating
  /// popup, where they pick the actual star count and submit it without
  /// leaving the app. Never shows the banner again after this.
  Future<void> rate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRatedKey, true);

    final inAppReview = InAppReview.instance;
    final available = await inAppReview.isAvailable();
    debugPrint('[RateAppService] isAvailable: $available');
    if (available) {
      debugPrint('[RateAppService] calling requestReview()');
      await inAppReview.requestReview();
      debugPrint('[RateAppService] requestReview() returned');
      return;
    }

    // Native popup unavailable (e.g. old Play Store) — fall back to opening
    // the store listing directly. App Store ID isn't set up yet (app isn't
    // published on iOS), so only do this on platforms where that's not required.
    if (Platform.isAndroid) {
      debugPrint('[RateAppService] falling back to openStoreListing()');
      await inAppReview.openStoreListing();
    }
  }
}
