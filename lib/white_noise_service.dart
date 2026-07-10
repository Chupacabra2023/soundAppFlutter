import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_route_service.dart';

/// off: never play.
/// always: loop continuously while the app is in the foreground.
/// wiredOnly: loop only while a wired audio output (jack/USB DAC) is connected.
enum WhiteNoiseMode { off, always, wiredOnly }

const String _kWhiteNoiseModePrefKey = 'white_noise_mode';

/// Some wired sound cards/DACs power down their DAC between plays and produce
/// an audible pop/click when they wake up for the next sound. Keeping a
/// continuous, near-silent noise stream open prevents the DAC from ever
/// going idle, eliminating the click. See user report: connecting via cable
/// clicks at the start of every sound; Bluetooth is unaffected.
///
/// Nothing here touches the audio engine or the wired-route listener unless
/// the user actually turns this on in Settings — off (the default) stays a
/// no-op so it can't add startup/runtime cost for people who never use it.
class WhiteNoiseService {
  WhiteNoiseService._();
  static final WhiteNoiseService instance = WhiteNoiseService._();

  final ValueNotifier<WhiteNoiseMode> mode = ValueNotifier(WhiteNoiseMode.off);

  AudioPlayer? _player;
  StreamSubscription<bool>? _wiredSub;
  bool _wiredConnected = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWhiteNoiseModePrefKey);
    mode.value = WhiteNoiseMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => WhiteNoiseMode.off,
    );
    if (mode.value != WhiteNoiseMode.off) {
      await _activate();
    }
  }

  Future<void> setMode(WhiteNoiseMode newMode) async {
    final wasOff = mode.value == WhiteNoiseMode.off;
    mode.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWhiteNoiseModePrefKey, newMode.name);

    if (newMode == WhiteNoiseMode.off) {
      await _deactivate();
    } else {
      if (wasOff) await _activate();
      _applyState();
    }
  }

  Future<void> _activate() async {
    if (_player != null) return;
    final player = AudioPlayer(playerId: 'white_noise');
    _player = player;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0.06);
    await player.setSource(AssetSource('white_noise.wav'));

    _wiredSub = AudioRouteService.instance.wiredAudioConnected.listen((connected) {
      _wiredConnected = connected;
      _applyState();
    });

    _applyState();
  }

  Future<void> _deactivate() async {
    await _wiredSub?.cancel();
    _wiredSub = null;
    final player = _player;
    _player = null;
    await player?.stop();
    await player?.dispose();
  }

  void _applyState() {
    final player = _player;
    if (player == null) return;
    final shouldPlay = switch (mode.value) {
      WhiteNoiseMode.off => false,
      WhiteNoiseMode.always => true,
      WhiteNoiseMode.wiredOnly => _wiredConnected,
    };
    if (shouldPlay) {
      player.resume();
    } else {
      player.pause();
    }
  }

  void dispose() {
    _wiredSub?.cancel();
    _player?.dispose();
  }
}
