import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Trieda na správu prehrávača a streamovanie stavu (progress, buffer, total)
class AudioPlayerManager {
  final player = AudioPlayer();

  /// Spojený stream progressu, bufferu a celkového času
  Stream<DurationState> get durationState => Rx.combineLatest3<Duration, Duration, Duration?, DurationState>(
    player.positionStream,
    player.bufferedPositionStream,
    player.durationStream,
        (position, bufferedPosition, totalDuration) => DurationState(
      progress: position,
      buffered: bufferedPosition,
      total: totalDuration ?? Duration.zero,
    ),
  );

  /// Inicializácia (môžeš načítať ľubovoľný zvukový súbor)
  Future<void> init() async {
    await player.setAsset('assets/bruh.mp3'); // napríklad tvoj zvuk
  }

  void dispose() {
    player.dispose();
  }
}

/// Pomocná dátová trieda pre stav prehrávania
class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });

  final Duration progress;
  final Duration buffered;
  final Duration total;
}
