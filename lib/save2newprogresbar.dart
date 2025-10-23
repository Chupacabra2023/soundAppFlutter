import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_button.dart';
import 'add_soud_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';


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
  double _progress = 0.0;
  Timer? _progressTimer;
  String? _currentSound;
  bool _isLooping = false;
  double _playbackRate = 1.0;
  String _searchQuery = '';
  int progressBarOffset = 280;
  String _selectedCategory = 'Všetko';
  final List<String> _categories = ['Všetko', 'Meme', 'Hudba', 'Zvuky'];

  // tu máš zoznam zvukov
  final List<Map<String, dynamic>> sounds = [
    {'name': 'bruh.mp3', 'title': 'Bruh', 'categories': ['Meme'], 'fav': false},
    {'name': 'danika_house.mp3', 'title': 'Danika', 'categories': ['Hudba'], 'fav': false},
    {'name': 'hamburger.mp3', 'title': 'Hamburger', 'categories': ['Meme', 'Zvuky'], 'fav': false},
    {'name': 'huh.mp3', 'title': 'Huh', 'categories': ['Zvuky'], 'fav': false},
    {'name': 'let_him_cook.mp3', 'title': 'Let Him Cook', 'categories': ['Meme'], 'fav': false},
  ];

  Future<void> _clearAllSavedSounds() async {
    final dir = await getApplicationDocumentsDirectory();

    // 🧾 zmažeme JSON
    final jsonFile = File('${dir.path}/sounds.json');
    if (await jsonFile.exists()) {
      await jsonFile.delete();
      print('🗑️ sounds.json deleted');
    }

    // 🧼 zmažeme všetky mp3 súbory
    final files = dir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.mp3')) {
        await file.delete();
        print('🗑️ Deleted: ${file.path}');
      }
    }
  }



  Future<String> copyAssetToPermanentStorage(String assetPath) async {
    // načítame súbor z assets
    final byteData = await rootBundle.load('assets/$assetPath');

    // zistíme cieľový priečinok
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$assetPath');

    // ak súbor ešte neexistuje, vytvoríme ho
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }

    return file.path;
  }
  Future<void> loadSoundsFromStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sounds.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      setState(() {
        sounds.clear();
        sounds.addAll(List<Map<String, dynamic>>.from(data));
      });
    }
  }

  Future<void> saveSoundsToStorage(List<Map<String, dynamic>> sounds) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sounds.json');
    await file.writeAsString(jsonEncode(sounds));
    print('📄 JSON uložený v: ${file.path}');

  }

  Future<void> _initializeSounds() async {
    for (var sound in sounds) {
      await copyAssetToPermanentStorage(sound['name']);
    }
  }

  //ULOZISKO
  List<Map<String, dynamic>> get filteredSounds {
    var result = sounds;

    if (_selectedCategory != 'Všetko') {
      result = result.where((s) => s['categories'].contains(_selectedCategory)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((s) =>
          s['title'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _clearAllSavedSounds();
    // 🔹 najprv inicializujeme default zvuky
    _initializeSounds().then((_) {
      // 🔸 potom načítame uložené zvuky
      loadSoundsFromStorage();
    });

    // 🎧 keď dohrá zvuk
    _player.onPlayerComplete.listen((event) {
      if (_isLooping && _currentSound != null) {
        // ak je loop zapnutý, prehrá znova
        _playSound(_currentSound!);
      } else {
        setState(() {
          _progress = 1.0;
          _currentSound = null;
        });
      }
    });
  }


  Future<void> _playSound(String name) async {
    await _player.stop();

    await _player.setPlaybackRate(_playbackRate);
    await _player.setReleaseMode(ReleaseMode.release);

    // 🗂 permanentný priečinok aplikácie
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$name';

    if (await File(filePath).exists()) {
      // ✅ prehráme uložený súbor
      await _player.play(DeviceFileSource(filePath));
      print('🎧 Playing from permanent storage: $filePath');
    } else if (name.startsWith('/')) {
      // ✅ prehráme súbor, ktorý má priamo absolútnu cestu
      await _player.play(DeviceFileSource(name));
      print('🎧 Playing from local path: $name');
    } else {
      // ❌ súbor neexistuje
      print('⚠️ Súbor neexistuje: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Súbor neexistuje v úložisku')),
      );
      return;
    }

    setState(() {
      _currentSound = name;
      _progress = 0.0;
    });

    final duration = await _player.getDuration();
    if (duration != null && duration.inMilliseconds > 0) {
      _startFakeProgress(duration.inMilliseconds + progressBarOffset);
    } else {
      _player.onDurationChanged.first.then((d) {
        final length = d.inMilliseconds;
        if (length > 0) _startFakeProgress(length + progressBarOffset);
      });
    }
  }


  void _startFakeProgress(int milliseconds) {
    _progressTimer?.cancel();

    // ⏳ upravíme čas podľa playback speed
    int adjustedMilliseconds = (milliseconds / _playbackRate).toInt();

    final start = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final p = (elapsed / adjustedMilliseconds).clamp(0.0, 1.0);

      setState(() => _progress = p);

      if (p >= 1.0) {
        timer.cancel();
        // ak je loop, spustíme znova
        if (_isLooping && _currentSound != null) {
          _playSound(_currentSound!);
        }
      }
    });
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });

    // NEreštartuj progress bar, iba ak nie je nič pustené
    if (_currentSound == null) {
      final duration = _player.getDuration();
      if (duration != null) {
        duration.then((d) {
          if (d != null && d.inMilliseconds > 0) {
            _startFakeProgress(d.inMilliseconds + progressBarOffset);
          }
        });
      }
    }
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackRate = speed;
    });

    _player.setPlaybackRate(speed);

    // reset progress baru
    if (_currentSound != null) {
      _progressTimer?.cancel();
      final duration = _player.getDuration();
      if (duration != null) {
        duration.then((d) {
          if (d != null && d.inMilliseconds > 0) {
            _startFakeProgress(d.inMilliseconds + progressBarOffset);
          }
        });
      }
    }
  }

  // Funkcia na aktualizáciu zvuku
  void _updateSound(String oldName, String newTitle, List<String> newCategories) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['name'] == oldName);
      if (soundIndex != -1) {
        sounds[soundIndex]['title'] = newTitle;
        sounds[soundIndex]['categories'] = newCategories;
      }
    });
  }

  // Funkcia na prepnutie obľúbených
  void _toggleFavorite(String soundName) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['name'] == soundName);
      if (soundIndex != -1) {
        sounds[soundIndex]['fav'] = !sounds[soundIndex]['fav'];
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundboard 🎵'),
        actions: [
          IconButton(
            icon: Icon(
              _isLooping ? Icons.loop : Icons.loop_outlined,
              color: _isLooping ? Colors.blue : null,
            ),
            onPressed: _toggleLoop,
            tooltip: 'Loop',
          ),

          // 🟡 výber kategórie
          DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
            items: _categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),

          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Playback Speed',
            onSelected: _changeSpeed,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x Speed')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x Normal')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x Speed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search sounds...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // ⏳ Progress bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentSound == null
                            ? "No sound playing"
                            : "🎶 Now playing: $_currentSound",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_currentSound != null) ...[
                      if (_isLooping)
                        const Icon(Icons.loop, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_playbackRate}x',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),

          // 🟩 Grid tlačidiel
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: filteredSounds.length,
                  itemBuilder: (context, index) {
                    final sound = filteredSounds[index];
                    return SoundButton(
                      soundName: sound['name'],
                      displayName: sound['title'],
                      categories: List<String>.from(sound['categories']),
                      isFavorite: sound['fav'],
                      allCategories: _categories,
                      onPressed: () => _playSound(sound['name']),
                      onUpdate: (newTitle, newCategories) {
                        _updateSound(sound['name'], newTitle, newCategories);
                      },
                      onToggleFavorite: () => _toggleFavorite(sound['name']),
                    );
                  },
                )

            ),

          ),


        ],

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSoundPage(
                categories: _categories,
                onSoundAdded: (filePath, title, categories) {
                  setState(() {
                    sounds.add({
                      'name': filePath,      // alebo len názov súboru
                      'title': title,
                      'categories': categories,
                      'fav': false,
                    });
                    saveSoundsToStorage(sounds);

                    // ak je nová kategória, pridáme ju do zoznamu
                    for (var c in categories) { // 'categories' sú tie nové z AddSoundPage
                      if (!_categories.contains(c)) {
                        _categories.add(c);
                      }
                    }
                  });
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

    );

  }

}