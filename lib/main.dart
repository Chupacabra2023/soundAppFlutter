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
  bool _isDeleteMode = false;
  String _selectedCategory = 'Všetko';
  final List<String> _categories = [
    'Všetko',
    'Meme',
    'Hudba',
    'Zvuky',
    'Favourite'
  ];

  // tu máš zoznam zvukov
  // ✅ PRÁZDNY ZOZNAM – defaulty sa načítajú až v _initializeSounds()
  final List<Map<String, dynamic>> sounds = [];

  Future<void> _clearAllSavedSounds() async {
    final dir = await getApplicationDocumentsDirectory();

    // 🧾 zmažeme JSON
    final jsonFile = File('${dir.path}/sounds.json');
    if (await jsonFile.exists()) {
      await jsonFile.delete();
      print('🗑️ sounds.json deleted');
    }

    // 🧼 zmažeme všetky zvukové súbory
    final files = dir.listSync();
    for (var file in files) {
      if (file is File &&
          (file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))) {
        await file.delete();
        print('🗑️ Deleted: ${file.path}');
      }
    }
  }

  Future<String> saveFileToPermanentStorage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = sourcePath
        .split('/')
        .last;
    final newFile = File('${dir.path}/$fileName');

    if (sourcePath.startsWith('assets/')) {
      final byteData = await rootBundle.load(sourcePath);
      await newFile.writeAsBytes(byteData.buffer.asUint8List());
    } else {
      await File(sourcePath).copy(newFile.path);
    }

    return fileName;
  }

  Future<void> loadSoundsFromStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sounds.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final data = jsonDecode(content);
        setState(() {
          sounds
            ..clear()
            ..addAll(List<Map<String, dynamic>>.from(data));
        });
        print('📥 Načítané ${sounds.length} zvukov z JSON-u');
      }
    } else {
      print('⚠️ sounds.json neexistuje');
    }
  }

  Future<void> deleteSound(String soundName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$soundName';
    final file = File(filePath);

    // 🗑️ zmaž fyzický súbor ak existuje
    if (await file.exists()) {
      await file.delete();
      print('🗑️ Súbor zmazaný: $filePath');
    }

    // 🧼 odstráň položku zo zoznamu
    sounds.removeWhere((s) => s['name'] == soundName);

    // 💾 aktualizuj JSON
    await saveSoundsToStorage();
  }


  Future<void> saveSoundsToStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sounds.json');
    await file.writeAsString(jsonEncode(sounds));
    print('📄 JSON uložený v: ${file.path}');
  }

// ✅ Inicializácia default zvukov len ak JSON neexistuje alebo je prázdny
  Future<void> _initializeSounds() async {
    final defaultSounds = [
      {
        'name': 'bruh.mp3',
        'title': 'Bruh',
        'categories': ['Meme'],
        'fav': false,
        'color': '#42A5F5'
      },
      {
        'name': 'danika_house.mp3',
        'title': 'Danika',
        'categories': ['Hudba'],
        'fav': false,
        'color': '#66BB6A'
      },
      {
        'name': 'hamburger.mp3',
        'title': 'Hamburger',
        'categories': ['Meme', 'Zvuky'],
        'fav': false,
        'color': '#FFA726'
      },
      {
        'name': 'huh.mp3',
        'title': 'Huh',
        'categories': ['Zvuky'],
        'fav': false,
        'color': '#AB47BC'
      },
      {
        'name': 'let_him_cook.mp3',
        'title': 'Let Him Cook',
        'categories': ['Meme'],
        'fav': false,
        'color': '#EC407A'
      },
    ];

    sounds.clear();
    sounds.addAll(defaultSounds);

    for (var sound in defaultSounds) {
      await saveFileToPermanentStorage('assets/${sound['name']}');
    }

    await saveSoundsToStorage();
    print('✅ Default zvuky inicializované');
  }

  List<Map<String, dynamic>> get filteredSounds {
    return sounds.where((sound) {
      // Kategória filter
      if (_selectedCategory != 'Všetko') {
        final categories = List<String>.from(sound['categories'] ?? []);
        if (!categories.contains(_selectedCategory)) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = sound['title']?.toString().toLowerCase() ?? '';
        if (!title.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList(growable: false); // ✅ Fixed-size list pre lepšiu performance
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // await _clearAllSavedSounds();     // 🧹 najprv vymažeme
    await _checkAndLoadSounds(); // 📥 potom načítame zvuky

    _player.onPlayerComplete.listen((event) {
    });
  }


  Future<void> _checkAndLoadSounds() async {
    final dir = await getApplicationDocumentsDirectory();
    final jsonFile = File('${dir.path}/sounds.json');

    if (await jsonFile.exists()) {
      await loadSoundsFromStorage();
      print('📥 Načítané ${sounds.length} zvukov z úložiska');

      // Ak je JSON prázdny, inicializuj default
      if (sounds.isEmpty) {
        print('📂 JSON je prázdny — inicializujem default zvuky');
        await _initializeSounds();
      }
    } else {
      print('🚀 JSON neexistuje — inicializujem default zvuky');
      await _initializeSounds();
    }
  }

  Future<void> _playSound(String name) async {
    await _player.stop();
    if (!mounted) return;
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
      _startFakeProgress(duration.inMilliseconds);
    } else {
      _player.onDurationChanged.first.then((d) {
        final length = d.inMilliseconds;
        if (length > 0) _startFakeProgress(length);
      });
    }
  }

  void _startFakeProgress(int milliseconds) {
    _progressTimer?.cancel();

    int adjustedMilliseconds = (milliseconds / _playbackRate).toInt();
    final start = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // ✅ BEZPEČNOSTNÁ KONTROLA
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final p = (elapsed / adjustedMilliseconds).clamp(0.0, 1.0);

      setState(() => _progress = p);

      if (p >= 1.0) {
        timer.cancel();
        if (_isLooping && _currentSound != null && mounted) {
          _playSound(_currentSound!);
        } else if (mounted) {
          setState(() {
            _progress = 0.0;
            _currentSound = null;
          });
        }
      }
    });
  }




  Future<void> _toggleLoop() async {
    setState(() => _isLooping = !_isLooping);
  }



  Future<void> _changeSpeed(double speed) async {
    setState(() => _playbackRate = speed);
    await _player.setPlaybackRate(speed);

    if (_currentSound != null) {
      // ⏸️ stopni aktuálny zvuk
      await _player.stop();
      _progressTimer?.cancel();

      // ▶️ prehráme od začiatku s novou rýchlosťou
      await _playSound(_currentSound!);
    }
  }

  void _stopSound() {
    _progressTimer?.cancel();
    _player.stop().then((_) {
      if (mounted) {
        setState(() {
          _currentSound = null;
          _progress = 0.0;
          _isLooping = false;
        });
      }
    });
  }
  // Funkcia na aktualizáciu zvuku
  void _updateSound(String oldName, String newTitle, List<String> newCategories,
      Color newColor) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['name'] == oldName);
      if (soundIndex != -1) {
        sounds[soundIndex]['title'] = newTitle;
        sounds[soundIndex]['categories'] = newCategories;
        sounds[soundIndex]['color'] =
        '#${newColor.toARGB32().toRadixString(16).padLeft(8, '0')}';
      }
    });
    saveSoundsToStorage();
  }

  // Funkcia na prepnutie obľúbených
  void _toggleFavorite(String soundName) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['name'] == soundName);
      if (soundIndex != -1) {
        final sound = sounds[soundIndex];
        final isFav = sound['fav'] ?? false;
        sound['fav'] = !isFav;

        // 🟡 Pridáme alebo odstránime kategóriu "Favourite"
        final categories = List<String>.from(sound['categories'] ?? []);
        if (sound['fav']) {
          if (!categories.contains('Favourite')) {
            categories.add('Favourite');
          }
        } else {
          categories.remove('Favourite');
        }
        sound['categories'] = categories;
      }
    });

    saveSoundsToStorage();
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    // ak má iba 6 znakov, pridaj alpha kanál
    if (hex.length == 6) {
      hex = 'ff$hex';
    }
    return Color(int.parse(hex, radix: 16));
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
              _isDeleteMode ? Icons.close : Icons.delete,
              color: _isDeleteMode ? Colors.red : null,
            ),
            tooltip: _isDeleteMode ? 'Zrušiť mazanie' : 'Mód mazania',
            onPressed: () {
              setState(() {
                _isDeleteMode = !_isDeleteMode;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isLooping ? Icons.loop : Icons.loop_outlined,
              color: _isLooping ? Colors.blue : null,
            ),
            onPressed: _toggleLoop,
            tooltip: 'Loop',
          ),
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
            itemBuilder: (context) =>
            [
              const PopupMenuItem(value: 0.5, child: Text('0.5x Speed')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x Normal')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x Speed')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                                : "🎶 Now playing: ${_currentSound!.split('/')
                                .last}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentSound != null) ...[
                          if (_isLooping)
                            const Icon(Icons.loop, color: Colors.blue,
                                size: 16),
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

              // Filter info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      'Filter: $_selectedCategory',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Search: "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${filteredSounds.length} sounds',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 🟩 Grid tlačidiel
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: filteredSounds.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.audiotrack, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No sounds found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try changing your search or category',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
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
                        key: ValueKey(sound['name']),
                        soundName: sound['name'],
                        displayName: sound['title'],
                        buttonColor: _isDeleteMode
                            ? Colors.redAccent
                            : _parseColor(sound['color'] ?? '#42A5F5'),
                        categories: List<String>.from(sound['categories'] ?? [
                        ]),
                        isFavorite: sound['fav'] ?? false,
                        allCategories: _categories,
                        onPressed: () async {
                          if (_isDeleteMode) {
                            await deleteSound(sound['name']);
                            setState(() {});
                          } else {
                            _playSound(sound['name']);
                          }
                        },
                        onUpdate: (newTitle, newCategories, newColor) {
                          _updateSound(
                              sound['name'], newTitle, newCategories, newColor);
                        },
                        onToggleFavorite: () => _toggleFavorite(sound['name']),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Stack(
        children: [
          // 🟦 STOP tlačidlo v strede
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              onPressed: _stopSound,
              child: const Icon(Icons.stop),
            ),
          ),

          // ➕ ADD tlačidlo vpravo (pôvodné)
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSoundPage(
                      categories: _categories,
                      onSoundAdded: (filePath, title, categories, color) async {
                        final savedFileName = await saveFileToPermanentStorage(filePath);
                        setState(() {
                          sounds.add({
                            'name': savedFileName,
                            'title': title.isNotEmpty ? title : savedFileName,
                            'categories': categories,
                            'fav': false,
                            'color': '#${color
                                .toARGB32()
                                .toRadixString(16)
                                .padLeft(8, '0')}',
                          });
                        });
                        await saveSoundsToStorage();

                        for (var c in categories) {
                          if (!_categories.contains(c)) {
                            setState(() {
                              _categories.add(c);
                            });
                          }
                        }
                      },
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
