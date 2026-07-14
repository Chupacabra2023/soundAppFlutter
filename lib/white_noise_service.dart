import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_route_service.dart';

/// off: never play.
/// always: loop continuously while the app is in the foreground.
/// wiredOnly: loop only while a wired audio output (jack/USB DAC) is connected.
enum WhiteNoiseMode { off, always, wiredOnly }

const String _kWhiteNoiseModePrefKey = 'white_noise_mode';

/// Some wired sound cards/DACs power down their DAC between plays and produce
/// an audible pop/click when they wake up for the next sound. Keeping the
/// output continuously fed with real silent PCM samples (via a native
/// AudioTrack, see MainActivity.kt) prevents the DAC from ever going idle,
/// eliminating the click without anything audible. Lowering a player's
/// volume instead isn't enough: volume is a software gain on top of the
/// samples, so a "quiet" stream can still be silence-detected and let the
/// DAC idle anyway. See user report: connecting via cable clicks at the
/// start of every sound; Bluetooth is unaffected.
///
/// Nothing here touches the audio engine or the wired-route listener unless
/// the user actually turns this on in Settings — off (the default) stays a
/// no-op so it can't add startup/runtime cost for people who never use it.
class WhiteNoiseService {
  WhiteNoiseService._();
  static final WhiteNoiseService instance = WhiteNoiseService._();

  static const MethodChannel _channel = MethodChannel('sk.marcelsotak.soundboard/silent_keepalive');

  final ValueNotifier<WhiteNoiseMode> mode = ValueNotifier(WhiteNoiseMode.off);

  StreamSubscription<bool>? _wiredSub;
  bool _wiredConnected = false;
  bool _running = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWhiteNoiseModePrefKey);
    mode.value = WhiteNoiseMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => WhiteNoiseMode.off,
    );
    if (mode.value != WhiteNoiseMode.off) {
      _listenWiredRoute();
    }
    await _applyState();
  }

  Future<void> setMode(WhiteNoiseMode newMode) async {
    final wasOff = mode.value == WhiteNoiseMode.off;
    mode.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWhiteNoiseModePrefKey, newMode.name);

    if (newMode == WhiteNoiseMode.off) {
      await _wiredSub?.cancel();
      _wiredSub = null;
    } else if (wasOff) {
      _listenWiredRoute();
    }
    await _applyState();
  }

  void _listenWiredRoute() {
    _wiredSub ??= AudioRouteService.instance.wiredAudioConnected.listen((connected) {
      _wiredConnected = connected;
      _applyState();
    });
  }

  Future<void> _applyState() async {
    final shouldRun = switch (mode.value) {
      WhiteNoiseMode.off => false,
      WhiteNoiseMode.always => true,
      WhiteNoiseMode.wiredOnly => _wiredConnected,
    };
    if (shouldRun == _running) return;
    _running = shouldRun;
    try {
      await _channel.invokeMethod(shouldRun ? 'start' : 'stop');
    } on MissingPluginException {
      // Not implemented on this platform (e.g. desktop) — no-op.
    } on PlatformException {
      // Native side failed to start/stop the keep-alive — ignore, nothing
      // audible is at stake and the app's sounds still play normally.
    }
  }

  void dispose() {
    _wiredSub?.cancel();
    _wiredSub = null;
    if (_running) {
      _running = false;
      unawaited(_channel.invokeMethod('stop').catchError((_) => null));
    }
  }
}
