import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_button.dart';
import 'add_soud_page.dart';
import 'settings_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'sound_data.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

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
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);
  Timer? _progressTimer;
  Timer? _debounceTimer; // Debounce timer pre search
  String? _currentSound;
  bool _isLooping = false;
  double _playbackRate = 1.0;
  String _searchQuery = '';
  bool _isDeleteMode = false;
  bool _isResetting = false; // Loading state pre reset
  String _selectedCategory = 'everything';
  List<String> _categories = ['everything'];

  // Sound list - empty by default, defaults will be loaded in _initializeSounds()
  final List<Map<String, dynamic>> sounds = [];

  // Cached filtered sounds pre lepšiu performance
  List<Map<String, dynamic>> _cachedFilteredSounds = [];

  Future<String> saveFileToPermanentStorage(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = sourcePath.split('/').last;
      final newFile = File('${dir.path}/$fileName');

      if (sourcePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(sourcePath);
        await newFile.writeAsBytes(byteData.buffer.asUint8List());
      } else {
        await File(sourcePath).copy(newFile.path);
      }

      return fileName;
    } catch (e) {
      debugPrint('Error saving file to permanent storage: $e');
      rethrow;
    }
  }

  Future<void> loadSoundsFromStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sounds.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);

          // Skontroluj verziu dát
          final savedVersion = data['version'] ?? 1;

          if (savedVersion != DATA_VERSION) {
            debugPrint('Data version mismatch! Saved: $savedVersion, Current: $DATA_VERSION');
            debugPrint('Resetting to default sounds with new version...');
            // Verzia sa zmenila - načítaj nové defaulty
            await _initializeSounds();
            return;
          }

          // Verzia sedí - načítaj uložené zvuky
          final soundsList = data['sounds'] ?? data; // Backward compatibility
          setState(() {
            sounds
              ..clear()
              ..addAll(List<Map<String, dynamic>>.from(soundsList is List ? soundsList : []));
          });
          debugPrint('Loaded ${sounds.length} sounds from JSON (version: $savedVersion)');
        }
      } else {
        debugPrint('sounds.json does not exist');
      }
    } catch (e) {
      debugPrint('Error loading sounds from storage: $e - will try to initialize defaults');
      await _initializeSounds();
    }
  }

  Future<void> deleteSound(String soundName) async {
    try {
      // Ak sa práve prehráva tento zvuk, zastav ho
      if (_currentSound == soundName) {
        _stopSound();
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$soundName';
      final file = File(filePath);

      // Delete physical file if exists
      if (await file.exists()) {
        await file.delete();
        debugPrint('File deleted: $filePath');
      }

      // Remove from list
      sounds.removeWhere((s) => s['name'] == soundName);

      // Update JSON
      await saveSoundsToStorage();

      // Aktualizuj zoznam kategórií
      _rebuildCategoriesList();
      _updateFilteredSounds(); // ✅ Aktualizuj cache
    } catch (e) {
      debugPrint('Error deleting sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting sound: $e')),
        );
      }
    }
  }


  Future<void> saveSoundsToStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sounds.json');

      // Ulož zvuky aj s verziou dát
      final data = {
        'version': DATA_VERSION,
        'sounds': sounds,
      };

      await file.writeAsString(jsonEncode(data));
      debugPrint('JSON saved at: ${file.path} (version: $DATA_VERSION)');
    } catch (e) {
      debugPrint('Error saving sounds to storage: $e');
    }
  }

  // Initialize default sounds only if JSON doesn't exist or is empty
  Future<void> _initializeSounds() async {
    try {
      sounds
        ..clear()
        ..addAll(defaultSounds.map((sound) {
          // Deep copy každého zvuku, aby sme nemodifikovali originálne defaultSounds
          return {
            'name': sound['name'],
            'title': sound['title'],
            'categories': List<String>.from(sound['categories'] ?? []),
            'fav': sound['fav'] ?? false,
            'color': sound['color'],
          };
        }));

      for (var sound in defaultSounds) {
        await saveFileToPermanentStorage('assets/${sound['name']}');
      }

      await saveSoundsToStorage();
      debugPrint('Default sounds initialized');
    } catch (e) {
      debugPrint('Error initializing sounds: $e');
    }
  }

  // ✅ Optimalizovaná funkcia - aktualizuje cache namiesto toho aby počítala zakaždým
  void _updateFilteredSounds() {
    _cachedFilteredSounds = sounds.where((sound) {
      // Kategória filter
      if (_selectedCategory != 'everything') {
        final categories = List<String>.from(sound['categories'] ?? []);
        if (!categories.contains(_selectedCategory)) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = sound['title']?.toString().toLowerCase() ?? '';
        if (!title.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkAndLoadSounds();
    _rebuildCategoriesList();
    _updateFilteredSounds(); // ✅ Inicializuj cache

    _player.onPlayerComplete.listen((event) {
      if (mounted && !_isLooping) {
        setState(() {
          _progressNotifier.value = 0.0; // ✅ Použij ValueNotifier
          _currentSound = null;
        });
      }
    });
  }

  // Funkcia na dynamické vytvorenie zoznamu kategórií podľa skutočne používaných
  void _rebuildCategoriesList() {
    final usedCategories = <String>{'everything'}; // Len 'everything' je vždy prítomné

    // Prejdi všetky zvuky a zozbieraj ich kategórie
    for (var sound in sounds) {
      final categories = List<String>.from(sound['categories'] ?? []);
      for (var category in categories) {
        if (category.toLowerCase() != 'everything') {
          usedCategories.add(category);
        }
      }
    }

    setState(() {
      _categories = usedCategories.toList()..sort();
      // Presun 'everything' na začiatok
      _categories.remove('everything');
      _categories.insert(0, 'everything');

      // Ak aktuálne vybraná kategória už neexistuje, prepni na 'everything'
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'everything';
      }
    });
  }


  Future<void> _checkAndLoadSounds() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${dir.path}/sounds.json');

      if (await jsonFile.exists()) {
        await loadSoundsFromStorage();
        debugPrint('Loaded ${sounds.length} sounds from storage');

        // If JSON is empty, initialize defaults
        if (sounds.isEmpty) {
          debugPrint('JSON is empty - initializing default sounds');
          await _initializeSounds();
        }
      } else {
        debugPrint('JSON does not exist - initializing default sounds');
        await _initializeSounds();
      }
    } catch (e) {
      debugPrint('Error checking and loading sounds: $e');
    }
  }

  Future<void> _playSound(String name) async {
    try {
      await _player.stop();
      if (!mounted) return;
      await _player.setPlaybackRate(_playbackRate);
      await _player.setReleaseMode(ReleaseMode.release);

      // Get application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$name';

      if (await File(filePath).exists()) {
        // Play saved file
        await _player.play(DeviceFileSource(filePath));
        debugPrint('Playing from permanent storage: $filePath');
      } else if (name.startsWith('/')) {
        // Play file with absolute path
        await _player.play(DeviceFileSource(name));
        debugPrint('Playing from local path: $name');
      } else {
        // File doesn't exist
        debugPrint('File does not exist: $filePath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ File does not exist in storage')),
          );
        }
        return;
      }

      setState(() {
        _currentSound = name;
      });
      _progressNotifier.value = 0.0; // ✅ Použij ValueNotifier mimo setState

      final duration = await _player.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        _startFakeProgress(duration.inMilliseconds);
      } else {
        _player.onDurationChanged.first.then((d) {
          final length = d.inMilliseconds;
          if (length > 0) _startFakeProgress(length);
        });
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing sound: $e')),
        );
      }
    }
  }

  void _startFakeProgress(int milliseconds) {
    _progressTimer?.cancel();

    int adjustedMilliseconds = (milliseconds / _playbackRate).toInt();
    final start = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // Safety check - cancel if widget is disposed
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final p = (elapsed / adjustedMilliseconds).clamp(0.0, 1.0);

      _progressNotifier.value = p; // ✅ Len aktualizuj notifier - ŽIADNE setState!

      if (p >= 1.0) {
        timer.cancel();
        if (_isLooping && _currentSound != null && mounted) {
          _playSound(_currentSound!);
        } else if (mounted) {
          setState(() {
            _progressNotifier.value = 0.0;
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
    _progressNotifier.value = 0.0; // ✅ Resetuj progress mimo setState
    _player.stop().then((_) {
      if (mounted) {
        setState(() {
          _currentSound = null;
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

        // Automaticky synchronizuj hviezdu (fav) s kategóriou "favorite"
        sounds[soundIndex]['fav'] = newCategories.contains('favorite');
      }
    });
    saveSoundsToStorage();

    // Aktualizuj zoznam kategórií podľa skutočne používaných
    _rebuildCategoriesList();
    _updateFilteredSounds(); // ✅ Aktualizuj cache
  }

  // Funkcia na reset zvukov
  Future<void> _resetSounds() async {
    setState(() {
      _isResetting = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();

      // Vymaž všetky audio súbory
      for (var sound in sounds) {
        final filePath = '${dir.path}/${sound['name']}';
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Vymaž JSON
      final jsonFile = File('${dir.path}/sounds.json');
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      // Načítaj defaultné zvuky s kategóriami
      await _initializeSounds();
      _rebuildCategoriesList();
      _updateFilteredSounds();

      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  // Funkcia na odstránenie kategórie
  void _deleteCategory(String category) {
    setState(() {
      // Odstráň kategóriu zo všetkých zvukov
      for (var sound in sounds) {
        final categories = List<String>.from(sound['categories'] ?? []);
        categories.remove(category);
        sound['categories'] = categories;
      }
    });

    saveSoundsToStorage();
    _rebuildCategoriesList();
    _updateFilteredSounds();
  }

  // Funkcia na prepnutie obľúbených
  void _toggleFavorite(String soundName) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['name'] == soundName);
      if (soundIndex != -1) {
        final sound = sounds[soundIndex];
        final isFav = sound['fav'] ?? false;
        sound['fav'] = !isFav;

        // 🟡 Pridáme alebo odstránime kategóriu "Favorite"
        final categories = List<String>.from(sound['categories'] ?? []);
        if (sound['fav']) {
          if (!categories.contains('favorite')) {
            categories.add('favorite');
          }
        } else {
          categories.remove('favorite');
        }
        sound['categories'] = categories;
      }
    });

    saveSoundsToStorage();

    // Aktualizuj zoznam kategórií (favorite sa môže pridať/odobrať)
    _rebuildCategoriesList();
    _updateFilteredSounds(); // ✅ Aktualizuj cache
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    // ak má iba 6 znakov, pridaj alpha kanál
    if (hex.length == 6) {
      hex = 'ff$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Responzívny výpočet počtu stĺpcov podľa šírky obrazovky
  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 3;       // Mobil portrait (malá obrazovka)
    if (width < 900) return 4;       // Mobil landscape / malý tablet
    if (width < 1200) return 5;      // Tablet
    if (width < 1600) return 6;      // Veľký tablet
    return 7;                        // Desktop / veľmi veľká obrazovka
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _debounceTimer?.cancel(); // ✅ Dispose debounce timer
    _player.dispose();
    _progressNotifier.dispose(); // ✅ Dispose ValueNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Cache screen width mimo GridView buildu
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 30),
            DropdownButton<String>(
              value: _selectedCategory,
              underline: const SizedBox(),
              dropdownColor: Colors.blueGrey[800],
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _updateFilteredSounds(); // ✅ Aktualizuj cache
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          // ➕ PRIDAŤ HORE
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Pridať zvuk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSoundPage(
                    categories: _categories,
                    onSoundAdded:
                        (filePath, title, categories, color) async {
                      final savedFileName =
                      await saveFileToPermanentStorage(filePath);
                      setState(() {
                        sounds.add({
                          'name': savedFileName,
                          'title': title.isNotEmpty ? title : savedFileName,
                          'categories': categories,
                          'fav': false,
                          'color':
                          '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
                        });
                      });
                      await saveSoundsToStorage();

                      // Aktualizuj zoznam kategórií
                      _rebuildCategoriesList();
                      _updateFilteredSounds(); // ✅ Aktualizuj cache
                    },
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: Icon(
              _isLooping ? Icons.loop : Icons.loop_outlined,
              color: _isLooping ? Colors.lightBlueAccent : Colors.white,
            ),
            onPressed: _toggleLoop,
            tooltip: 'Loop',
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed, color: Colors.white),
            tooltip: 'Playback Speed',
            color: Colors.blueGrey[800],
            onSelected: _changeSpeed,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 0.5,
                child: Text('0.5x Speed', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 1.0,
                child: Text('1.0x Normal', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 2.0,
                child: Text('2.0x Speed', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isDeleteMode ? Icons.close : Icons.delete,
              color: _isDeleteMode ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isDeleteMode = !_isDeleteMode;
              });
            },
            tooltip: _isDeleteMode ? 'Cancel delete mode' : 'Delete mode',
          ),
          // ⚙️ Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    categories: _categories,
                    onResetSounds: _resetSounds,
                    onDeleteCategory: _deleteCategory,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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
                    // ⚡ Debouncing - zruš predchádzajúci timer
                    _debounceTimer?.cancel();

                    // Vytvor nový timer s 300ms oneskorením
                    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _searchQuery = value;
                          _updateFilteredSounds(); // ✅ Aktualizuj cache
                        });
                      }
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
                                : () {
                                    // Nájdi sound v zozname a zobraz title namiesto file name
                                    final sound = sounds.firstWhere(
                                      (s) => s['name'] == _currentSound,
                                      orElse: () => {'title': _currentSound!.split('/').last},
                                    );
                                    return "Now playing: ${sound['title']}";
                                  }(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentSound != null && _isLooping)
                          const Icon(Icons.loop,
                              color: Colors.blue, size: 16),
                        if (_currentSound != null)
                          const SizedBox(width: 4),
                        Text(
                          '${_playbackRate}x',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _progressNotifier,
                        builder: (context, progress, child) {
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.blueAccent,
                          );
                        },
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
                      '${_cachedFilteredSounds.length} sounds',
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
                  child: _cachedFilteredSounds.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.audiotrack,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No sounds found',
                          style:
                          TextStyle(fontSize: 18, color: Colors.grey),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    addAutomaticKeepAlives: false, // ⚡ Dispose widgety mimo obrazovky
                    addRepaintBoundaries: true, // ⚡ Automatické repaint boundaries
                    cacheExtent: 100, // ⚡ Redukuj počet off-screen widgetov
                    itemCount: _cachedFilteredSounds.length,
                    itemBuilder: (context, index) {
                      final sound = _cachedFilteredSounds[index];
                      // ⚡ addRepaintBoundaries: true robí to isté automaticky
                      return SoundButton(
                        key: ValueKey(sound['name']),
                        soundName: sound['name'],
                        displayName: sound['title'],
                        buttonColor: _isDeleteMode
                            ? Colors.redAccent
                            : _parseColor(
                          sound['color'] ?? '#42A5F5',
                        ),
                        categories: List<String>.from(
                            sound['categories'] ?? []),
                        isFavorite: sound['fav'] ?? false,
                        allCategories: _categories,
                        isPlaying: _currentSound == sound['name'], // Skontroluj či sa tento zvuk prehráva
                        onPressed: () async {
                          if (_isDeleteMode) {
                            await deleteSound(sound['name']);
                            setState(() {});
                          } else {
                            // Ak sa tento zvuk už prehráva, zastav ho
                            if (_currentSound == sound['name']) {
                              _stopSound();
                            } else {
                              // Inak prehraj zvuk
                              _playSound(sound['name']);
                            }
                          }
                        },
                        onUpdate:
                            (newTitle, newCategories, newColor) {
                          _updateSound(sound['name'], newTitle,
                              newCategories, newColor);
                        },
                        onToggleFavorite: () =>
                            _toggleFavorite(sound['name']),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isResetting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Restoring sounds...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait a moment',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
