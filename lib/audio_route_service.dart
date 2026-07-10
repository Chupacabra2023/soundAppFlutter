import 'dart:async';
import 'package:flutter/services.dart';

/// Reports whether a wired audio output (3.5mm jack, USB-C DAC/dongle, line-out)
/// is currently connected, via a native Android AudioDeviceCallback bridged
/// through an EventChannel. Used to auto-enable the anti-standby white noise
/// only while a wired speaker is plugged in.
class AudioRouteService {
  AudioRouteService._();
  static final AudioRouteService instance = AudioRouteService._();

  static const EventChannel _channel = EventChannel('sk.marcelsotak.soundboard/audio_route');

  Stream<bool>? _stream;

  Stream<bool> get wiredAudioConnected {
    return _stream ??= _channel
        .receiveBroadcastStream()
        .map((event) => event as bool)
        .handleError((_) {})
        .asBroadcastStream();
  }
}
