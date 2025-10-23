import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SoundboardPage(),
    );
  }
}

class SoundboardPage extends StatefulWidget {
  const SoundboardPage({super.key});
  @override
  State<SoundboardPage> createState() => _SoundboardPageState();
}

class _SoundboardPageState extends State<SoundboardPage> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentSound;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isSeeking = false;

  final List<Map<String, String>> sounds = [
    {'name': 'bruh.mp3', 'title': 'Bruh'},
    {'name': 'danika_house.mp3', 'title': 'Danika'},
    {'name': 'hamburger.mp3', 'title': 'Hamburger'},
    {'name': 'huh.mp3', 'title': 'Huh'},
    {'name': 'let_him_cook.mp3', 'title': 'Let Him Cook'},
  ];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _player.onDurationChanged.listen((d) {
      print('🎵 Duration changed: ${d.inSeconds} seconds');
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted && !_isSeeking) {
        setState(() {
          // Lerp medzi starou a novou pozíciou (hladký prechod)
          _position = Duration(
            milliseconds: (_position.inMilliseconds * 0.7 + p.inMilliseconds * 0.3).round(),
          );
        });
      }
    });

    _player.onPlayerStateChanged.listen((state) {
      print('🎵 Player state: $state');
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
            _isPlaying = false;
          }
        });
      }
    });

    _player.onPlayerComplete.listen((_) {
      print('🎵 Playback completed');
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _playSound(String name) async {
    try {
      print('▶️ Attempting to play: $name');

      if (mounted) {
        setState(() {
          _isLoading = true;
          _currentSound = name;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
      }

      await _player.stop();
      await _player.setSource(AssetSource(name));

      final duration = await _player.getDuration();
      if (duration != null) {
        setState(() => _duration = duration);
      }

      await _player.resume();

      print('✅ Successfully started playing: $name');

    } catch (e) {
      print('❌ Error playing sound $name: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_currentSound != null) {
          await _player.resume();
        } else if (sounds.isNotEmpty) {
          await _playSound(sounds.first['name']!);
        }
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  Future<void> _seekAudio(double value) async {
    if (_duration == Duration.zero) return;

    final newPosition = Duration(milliseconds: (value * _duration.inMilliseconds).round());

    setState(() {
      _position = newPosition;
      _isSeeking = true;
    });
  }

  Future<void> _seekAudioComplete(double value) async {
    if (_duration == Duration.zero) return;

    final newPosition = Duration(milliseconds: (value * _duration.inMilliseconds).round());

    try {
      await _player.seek(newPosition);
      print('🔍 Seeked to: ${newPosition.inSeconds} seconds');
    } catch (e) {
      print('Error seeking: $e');
    }

    setState(() {
      _isSeeking = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_duration.inMilliseconds > 0)
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundboard 🎵'),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Progress Bar Section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and loading indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentSound == null
                            ? "🎵 Vyber sound"
                            : "🎶 ${_currentSound!.replaceAll('.mp3', '')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isPlaying && !_isLoading)
                      const Icon(Icons.equalizer, color: Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                // INTERAKTÍVNY SLIDER PRE POSÚVANIE
                _buildInteractiveSlider(progress),

                // Time labels
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Debug information
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPlaying ? Icons.play_arrow : Icons.pause,
                            size: 16,
                            color: _isPlaying ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stav: ${_isPlaying ? 'Prehráva sa' : 'Pozastavené'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (_isSeeking) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.touch_app, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Posúvam...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pozícia: ${_position.inSeconds}.${_position.inMilliseconds % 1000}ms | '
                            'Dĺžka: ${_duration.inSeconds}s | '
                            'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sound Buttons Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  final isCurrentSound = _currentSound == sound['name'];

                  return _buildSoundButton(
                    title: sound['title']!,
                    isActive: isCurrentSound && _isPlaying,
                    onTap: () => _playSound(sound['name']!),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePlayPause,
        backgroundColor: _isPlaying ? Colors.orange : Colors.blue,
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInteractiveSlider(double progress) {
    return Column(
      children: [
        // Slider s lepšou vizualizáciou
        Slider(
          value: progress,
          min: 0.0,
          max: 1.0,
          onChanged: (_duration > Duration.zero) ? _seekAudio : null,
          onChangeStart: (_duration > Duration.zero)
              ? (value) => setState(() => _isSeeking = true)
              : null,
          onChangeEnd: (_duration > Duration.zero) ? _seekAudioComplete : null,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300],
          thumbColor: Colors.blueAccent,
        ),

        // Rýchle tlačidlá pre skok
        if (_duration > Duration.zero) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeekButton('⏪ -10s', -10),
              _buildSeekButton('⏩ +10s', 10),
              _buildSeekButton('🎯 Začiatok', 0, isStart: true),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSeekButton(String label, int seconds, {bool isStart = false}) {
    return ElevatedButton.icon(
      onPressed: () {
        if (isStart) {
          _seekAudioComplete(0.0);
        } else {
          final newPosition = _position + Duration(seconds: seconds);
          final newProgress = newPosition.inMilliseconds / _duration.inMilliseconds;
          _seekAudioComplete(newProgress.clamp(0.0, 1.0));
        }
      },
      icon: Icon(
        seconds < 0 ? Icons.replay_10 : (isStart ? Icons.skip_previous : Icons.forward_10),
        size: 16,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildSoundButton({
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Card(
      elevation: isActive ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [Colors.orange[400]!, Colors.orange[600]!]
                  : [Colors.blue[400]!, Colors.blue[600]!],
            ),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.audiotrack,
                    color: Colors.white,
                    size: 32,
                  ),
                  if (isActive)
                    const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}