import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';


class AudioPlayerManager {
  final player = AudioPlayer();


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


  Future<void> init() async {
    await player.setAsset('assets/bruh.mp3');
  }

  void dispose() {
    player.dispose();
  }
}


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
