import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_button.dart';
import 'settings_page.dart';
import 'add_soud_page.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'sound_data.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';
import 'language_picker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SplashApp());
  // await _initializeConsent();
  // await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// Future<void> _initializeConsent() async {
//   final completer = Completer<void>();
//
//   final params = ConsentRequestParameters();
//   ConsentInformation.instance.requestConsentInfoUpdate(
//     params,
//     () async {
//       if (await ConsentInformation.instance.isConsentFormAvailable()) {
//         ConsentForm.loadAndShowConsentFormIfRequired((formError) {
//           if (formError != null) {
//             debugPrint('Consent form error: ${formError.message}');
//           }
//           if (!completer.isCompleted) completer.complete();
//         });
//       } else {
//         if (!completer.isCompleted) completer.complete();
//       }
//     },
//     (error) {
//       debugPrint('Consent info error: ${error.message}');
//       if (!completer.isCompleted) completer.complete();
//     },
//   );
//
//   return completer.future.timeout(
//     const Duration(seconds: 5),
//     onTimeout: () => debugPrint('Consent timeout - continuing without consent'),
//   );
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void toggleThemeStatic(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.toggleTheme();
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  bool? _isFirstLaunch; // null = still loading prefs
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final isDark = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _isFirstLaunch = languageCode == null;
      _locale = Locale(languageCode ?? 'en');
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _saveLocale(locale);
  }

  void _onLanguageSelected(Locale locale) {
    setLocale(locale);
    setState(() {
      _isFirstLaunch = false;
    });
  }

  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {
      _themeMode = newMode;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('dark_mode', newMode == ThemeMode.dark),
    );
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(backgroundColor: Colors.blueGrey[900]),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B2428),
        appBarTheme: AppBarTheme(backgroundColor: Colors.blueGrey[900]),
        cardColor: const Color(0xFF263238),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('sk'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ru'),
      ],
      home: _isFirstLaunch == null
          ? const SizedBox()
          : _isFirstLaunch == true
              ? LanguagePickerPage(onLanguageSelected: _onLanguageSelected)
              : const SoundboardPage(),
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
  Timer? _shuffleTimer; // Timer pre shuffle play
  String? _currentSound;
  bool _isLooping = false;
  bool _isShufflePlay = false; // Shuffle play mode
  double _playbackRate = 1.0;
  int _totalDurationMs = 0; // Celkové trvanie aktuálneho zvuku v ms
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isDeleteMode = false;
  bool _isResetting = false; // Loading state pre reset
  bool _simpleMode = false;
  bool _hideCategories = false;
  bool _hidePlayback = false;
  bool _hapticFeedback = true;
  bool _showLoop = true;
  bool _showSpeed = true;
  bool _showShuffle = true;
  bool _showAdd = true;
  bool _showDelete = true;
  bool _showDarkMode = true;
  final Set<String> _selectedCategories = {'everything'};
  List<String> _categories = ['everything'];
  List<String> _customCategories = []; // kategórie uložené nezávisle od zvukov
  Map<String, int> _categoryColors = {}; // farby kategórií (category name → color value)

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
          final loadedList = List<Map<String, dynamic>>.from(soundsList is List ? soundsList : []);
          // Migrate sounds missing 'id' field (backward compatibility)
          final int migrationBase = DateTime.now().millisecondsSinceEpoch;
          for (int i = 0; i < loadedList.length; i++) {
            if (loadedList[i]['id'] == null) {
              loadedList[i]['id'] = 'migrated_${migrationBase + i}';
            }
          }
          final savedCategories = data['categories'];
          final savedCategoryColors = data['categoryColors'];
          final prefs = await SharedPreferences.getInstance();
          final hasCustomOrder = prefs.getBool('custom_sound_order') ?? false;
          if (!hasCustomOrder) {
            loadedList.sort((a, b) => (a['title'] ?? '').toString().toLowerCase()
                .compareTo((b['title'] ?? '').toString().toLowerCase()));
          }
          setState(() {
            sounds
              ..clear()
              ..addAll(loadedList);
            if (savedCategories != null) {
              _customCategories = List<String>.from(savedCategories);
            }
            if (savedCategoryColors != null) {
              _categoryColors = Map<String, int>.from(savedCategoryColors);
            }
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

  Future<void> deleteSound(String soundId) async {
    try {
      final soundIndex = sounds.indexWhere((s) => s['id'] == soundId);
      if (soundIndex == -1) return;
      final soundName = sounds[soundIndex]['name'] as String;

      // Ak sa práve prehráva tento zvuk, zastav ho
      if (_currentSound == soundId) {
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
      sounds.removeWhere((s) => s['id'] == soundId);

      // Update JSON
      await saveSoundsToStorage();

      // Aktualizuj zoznam kategórií
      _rebuildCategoriesList();
      _updateFilteredSounds(); // ✅ Aktualizuj cache
    } catch (e) {
      debugPrint('Error deleting sound: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('errorDeletingSound')} $e')),
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
        'categories': _customCategories,
        'categoryColors': _categoryColors,
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
      int idBase = DateTime.now().millisecondsSinceEpoch;
      int idCounter = 0;
      sounds
        ..clear()
        ..addAll(defaultSounds.map((sound) {
          // Deep copy každého zvuku, aby sme nemodifikovali originálne defaultSounds
          return {
            'id': 'def_${idBase + idCounter++}',
            'name': sound['name'],
            'title': sound['title'],
            'categories': List<String>.from(sound['categories'] ?? []),
            'fav': sound['fav'] ?? false,
            'color': sound['color'],
            'startMs': sound['startMs'] ?? 0,
            'endMs': sound['endMs'],
            'volume': (sound['volume'] as num?)?.toDouble() ?? 1.0,
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
      // Kategória filter - zobraz ak je 'everything' alebo zvuk má aspoň jednu zvolenú kategóriu
      if (!_selectedCategories.contains('everything')) {
        final categories = List<String>.from(sound['categories'] ?? []);
        if (!categories.any((c) => _selectedCategories.contains(c))) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = sound['title']?.toString().toLowerCase() ?? '';
        if (!title.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    final movedSound = _cachedFilteredSounds[oldIndex];
    final targetSound = _cachedFilteredSounds[newIndex];
    final oldSoundsIndex = sounds.indexOf(movedSound);
    final newSoundsIndex = sounds.indexOf(targetSound);
    setState(() {
      final item = sounds.removeAt(oldSoundsIndex);
      sounds.insert(newSoundsIndex, item);
    });
    _updateFilteredSounds();
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('custom_sound_order', true));
    saveSoundsToStorage();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _simpleMode = prefs.getBool('simple_mode') ?? false;
      _hideCategories = prefs.getBool('hide_categories') ?? false;
      _hidePlayback = prefs.getBool('hide_playback') ?? false;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _showLoop = prefs.getBool('show_loop') ?? true;
      _showSpeed = prefs.getBool('show_speed') ?? true;
      _showShuffle = prefs.getBool('show_shuffle') ?? true;
      _showAdd = prefs.getBool('show_add') ?? true;
      _showDelete = prefs.getBool('show_delete') ?? true;
      _showDarkMode = prefs.getBool('show_darkmode') ?? true;
    });
    await _checkAndLoadSounds();
    _rebuildCategoriesList();
    _updateFilteredSounds(); // ✅ Inicializuj cache

    _player.onPlayerComplete.listen((event) {
      if (mounted && !_isLooping) {
        _handlePlaybackComplete();
      }
    });
  }

  // Funkcia na dynamické vytvorenie zoznamu kategórií podľa skutočne používaných
  void _rebuildCategoriesList() {
    final usedCategories = <String>{'everything'}; // Len 'everything' je vždy prítomné

    // Pridaj explicitne vytvorené kategórie
    for (var cat in _customCategories) {
      usedCategories.add(cat);
    }

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

      // Odstráň zo selected kategórie ktoré už neexistujú
      _selectedCategories.removeWhere((c) => c != 'everything' && !usedCategories.contains(c));
      if (_selectedCategories.isEmpty) _selectedCategories.add('everything');
    });
  }


  Future<void> _checkAndLoadSounds() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${dir.path}/sounds.json');

      if (await jsonFile.exists()) {
        await loadSoundsFromStorage();
        debugPrint('Loaded ${sounds.length} sounds from storage');

        // Empty list is valid (user deleted all sounds intentionally)
      } else {
        debugPrint('JSON does not exist - initializing default sounds');
        await _initializeSounds();
      }
    } catch (e) {
      debugPrint('Error checking and loading sounds: $e');
    }
  }

  Future<void> _playSound(String soundId) async {
    try {
      await _player.stop();
      if (!mounted) return;
      await _player.setPlaybackRate(_playbackRate);
      await _player.setReleaseMode(ReleaseMode.release);

      // Look up sound by ID
      final soundData = sounds.firstWhere(
        (s) => s['id'] == soundId,
        orElse: () => <String, dynamic>{},
      );
      if (soundData.isEmpty) return;
      final String name = soundData['name'] as String;
      final int startMs = soundData['startMs'] ?? 0;
      final int? endMs = soundData['endMs'] as int?;
      final double volume = (soundData['volume'] as num?)?.toDouble() ?? 1.0;
      await _player.setVolume(volume);

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$name';

      if (await File(filePath).exists()) {
        await _player.play(DeviceFileSource(filePath));
        debugPrint('Playing from permanent storage: $filePath');
      } else if (name.startsWith('/')) {
        await _player.play(DeviceFileSource(name));
        debugPrint('Playing from local path: $name');
      } else {
        debugPrint('File does not exist: $filePath');
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${l10n.get('fileNotExist')}')),
          );
        }
        return;
      }

      setState(() {
        _currentSound = soundId;
      });
      _progressNotifier.value = 0.0;

      if (startMs > 0) {
        await _player.seek(Duration(milliseconds: startMs));
      }

      final duration = await _player.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        _totalDurationMs = duration.inMilliseconds;
        _startFakeProgress(duration.inMilliseconds, startMs: startMs, endMs: endMs);
      } else {
        _player.onDurationChanged.first.then((d) {
          final length = d.inMilliseconds;
          if (length > 0) {
            _totalDurationMs = length;
            _startFakeProgress(length, startMs: startMs, endMs: endMs);
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('errorPlayingSound')} $e')),
        );
      }
    }
  }

  // startFrom = 0.0..1.0 within trim window (nie celý súbor)
  void _startFakeProgress(int totalMs, {double startFrom = 0.0, int startMs = 0, int? endMs}) {
    _progressTimer?.cancel();

    final int effectiveEndMs = (endMs ?? totalMs).clamp(0, totalMs);
    final int clampedStartMs = startMs.clamp(0, totalMs);
    final int trimWindowMs = effectiveEndMs - clampedStartMs;

    if (trimWindowMs <= 0) {
      _handlePlaybackComplete();
      return;
    }

    // Progress 0.0..1.0 = od startMs po endMs (trim okno)
    final int adjustedWindowMs = (trimWindowMs / _playbackRate).toInt();
    final int alreadyElapsedMs = (startFrom * adjustedWindowMs).toInt();

    final start = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(start).inMilliseconds + alreadyElapsedMs;
      final p = (elapsed / adjustedWindowMs).clamp(0.0, 1.0);

      _progressNotifier.value = p;

      if (p >= 1.0) {
        timer.cancel();
        _handlePlaybackComplete();
      }
    });
  }

  void _handlePlaybackComplete() {
    if (_isLooping && _currentSound != null && mounted) {
      _playSound(_currentSound!);
    } else {
      _player.stop();
      if (mounted) {
        setState(() {
          _progressNotifier.value = 0.0;
          _currentSound = null;
        });
        if (_isShufflePlay) {
          _shuffleTimer = Timer(const Duration(milliseconds: 500), () {
            if (_isShufflePlay && mounted) _playRandomSound();
          });
        }
      }
    }
  }

  // position = 0.0..1.0 v rámci trim okna
  void _seekTo(double position) {
    if (_currentSound == null || _totalDurationMs == 0) return;

    final soundData = sounds.firstWhere(
      (s) => s['id'] == _currentSound,
      orElse: () => <String, dynamic>{},
    );
    final int startMs = soundData['startMs'] ?? 0;
    final int? endMs = soundData['endMs'] as int?;
    final int effectiveEndMs = endMs ?? _totalDurationMs;

    // Mapuj position (0.0..1.0 trim okna) na skutočné ms
    final int seekMs = (startMs + position * (effectiveEndMs - startMs)).toInt().clamp(startMs, effectiveEndMs);
    _player.seek(Duration(milliseconds: seekMs));
    _startFakeProgress(_totalDurationMs, startFrom: position, startMs: startMs, endMs: endMs);
  }




  Future<void> _toggleLoop() async {
    setState(() => _isLooping = !_isLooping);
  }



  Future<void> _changeSpeed(double speed) async {
    final currentProgress = _progressNotifier.value;
    setState(() => _playbackRate = speed);
    await _player.setPlaybackRate(speed);

    if (_currentSound != null && _totalDurationMs > 0) {
      final soundData = sounds.firstWhere(
        (s) => s['id'] == _currentSound,
        orElse: () => <String, dynamic>{},
      );
      _startFakeProgress(
        _totalDurationMs,
        startFrom: currentProgress,
        startMs: soundData['startMs'] ?? 0,
        endMs: soundData['endMs'] as int?,
      );
    }
  }

  void _stopSound() {
    _progressTimer?.cancel();
    _progressNotifier.value = 0.0; // ✅ Resetuj progress mimo setState
    _totalDurationMs = 0;
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
  void _updateSound(String soundId, String newTitle, List<String> newCategories,
      Color newColor, int newStartMs, int? newEndMs, double newVolume) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['id'] == soundId);
      if (soundIndex != -1) {
        sounds[soundIndex]['title'] = newTitle;
        sounds[soundIndex]['categories'] = newCategories;
        sounds[soundIndex]['color'] =
        '#${newColor.toARGB32().toRadixString(16).padLeft(8, '0')}';
        sounds[soundIndex]['fav'] = newCategories.contains('favorite');
        sounds[soundIndex]['startMs'] = newStartMs;
        sounds[soundIndex]['endMs'] = newEndMs;
        sounds[soundIndex]['volume'] = newVolume;
      }
      // Ensure any category assigned via sound button dialog is persisted
      for (final cat in newCategories) {
        if (cat != 'everything' && cat != 'favorite' && !_customCategories.contains(cat)) {
          _customCategories.add(cat);
        }
      }
    });
    saveSoundsToStorage();
    _rebuildCategoriesList();
    _updateFilteredSounds();
  }

  Future<void> _deleteAllSounds() async {
    setState(() {
      sounds.clear();
      _currentSound = null;
    });
    _player.stop();
    _updateFilteredSounds();
    await saveSoundsToStorage();
  }

  Future<void> _exportSounds() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final archive = Archive();

      // Pridaj sounds.json
      final jsonFile = File('${dir.path}/sounds.json');
      if (await jsonFile.exists()) {
        final jsonBytes = await jsonFile.readAsBytes();
        archive.addFile(ArchiveFile('sounds.json', jsonBytes.length, jsonBytes));
      }

      // Pridaj všetky audio súbory
      for (final sound in sounds) {
        final name = sound['name'] as String?;
        if (name == null) continue;
        final audioFile = File('${dir.path}/$name');
        if (await audioFile.exists()) {
          final bytes = await audioFile.readAsBytes();
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }

      final zipBytes = ZipEncoder().encode(archive)!;
      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/soundboard_backup.zip');
      await zipFile.writeAsBytes(zipBytes);

      await Share.shareXFiles(
        [XFile(zipFile.path)],
        subject: 'Soundboard backup',
      );
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }

  Future<void> _importSounds(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) return;

      final zipBytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final dir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        if (file.isFile) {
          final outFile = File('${dir.path}/${file.name}');
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      await loadSoundsFromStorage();
      _rebuildCategoriesList();
      _updateFilteredSounds();
      setState(() {});
    } catch (e) {
      debugPrint('Import error: $e');
    }
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
      setState(() {
        _categoryColors = {};
      });
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
  Future<void> _deleteCategory(String category, bool deleteSounds) async {
    if (deleteSounds) {
      // Zisti ktoré zvuky sa majú vymazať
      final toDelete = sounds.where((s) {
        final cats = List<String>.from(s['categories'] ?? []);
        return cats.contains(category);
      }).toList();

      // Zastav prehrávanie ak sa prehráva niektorý z mazaných zvukov
      if (_currentSound != null) {
        final isPlayingDeleted = toDelete.any((s) => s['id'] == _currentSound);
        if (isPlayingDeleted) _stopSound();
      }

      // Vymaž fyzické súbory
      final dir = await getApplicationDocumentsDirectory();
      for (final sound in toDelete) {
        final file = File('${dir.path}/${sound['name']}');
        if (await file.exists()) await file.delete();
      }

      // Odstráň zo zoznamu
      setState(() {
        sounds.removeWhere((s) {
          final cats = List<String>.from(s['categories'] ?? []);
          return cats.contains(category);
        });
      });
    } else {
      // Len odstráň kategóriu zo zvukov, nemaž buttony
      setState(() {
        for (var sound in sounds) {
          final categories = List<String>.from(sound['categories'] ?? []);
          categories.remove(category);
          sound['categories'] = categories;
        }
      });
    }

    _customCategories.remove(category);
    await saveSoundsToStorage();
    _rebuildCategoriesList();
    _updateFilteredSounds();
    if (mounted) setState(() {}); // zaruč rebuild gridu
  }

  // Funkcia na pridanie kategórie
  void _addCategory(String name) {
    if (!_customCategories.contains(name)) {
      setState(() {
        _customCategories.add(name);
      });
      _rebuildCategoriesList();
      saveSoundsToStorage();
    }
  }

  // Funkcia na nastavenie farby kategórie — prebarví všetky buttony v danej kategórii
  void _setCategoryColor(String category, Color color) {
    setState(() {
      _categoryColors[category] = color.toARGB32();
      for (var sound in sounds) {
        final cats = List<String>.from(sound['categories'] ?? []);
        if (cats.contains(category)) {
          sound['color'] = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
        }
      }
    });
    saveSoundsToStorage();
  }

  // Funkcia na premenovanie kategórie
  void _renameCategory(String oldName, String newName) {
    setState(() {
      final catIndex = _customCategories.indexOf(oldName);
      if (catIndex != -1) _customCategories[catIndex] = newName;

      for (var sound in sounds) {
        final categories = List<String>.from(sound['categories'] ?? []);
        final index = categories.indexOf(oldName);
        if (index != -1) {
          categories[index] = newName;
          sound['categories'] = categories;
        }
      }
    });

    saveSoundsToStorage();
    _rebuildCategoriesList();
    _updateFilteredSounds();
  }

  // Funkcia na prepnutie obľúbených
  void _toggleFavorite(String soundId) {
    setState(() {
      final soundIndex = sounds.indexWhere((s) => s['id'] == soundId);
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

  void _toggleShufflePlay() {
    setState(() {
      _isShufflePlay = !_isShufflePlay;

      if (_isShufflePlay) {
        // Start shuffle play - play a random sound immediately
        _playRandomSound();
      } else {
        // Stop shuffle play - cancel timer and stop current sound
        _shuffleTimer?.cancel();
        _shuffleTimer = null;
        _stopSound();
      }
    });
  }

  void _playRandomSound() {
    if (_cachedFilteredSounds.isEmpty) return;

    // Get a random sound from filtered sounds
    final random = DateTime.now().millisecondsSinceEpoch % _cachedFilteredSounds.length;
    final randomSound = _cachedFilteredSounds[random];
    _playSound(randomSound['id']);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _debounceTimer?.cancel(); // ✅ Dispose debounce timer
    _shuffleTimer?.cancel(); // ✅ Dispose shuffle timer
    _player.dispose();
    _progressNotifier.dispose(); // ✅ Dispose ValueNotifier
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ⚡ Cache screen width - používaj sizeOf namiesto .of aby sa nerebuildovalo pri klávesnici!
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    final visibleLeadingCount = [_showLoop, _showSpeed, _showShuffle, _showAdd].where((b) => b).length;
    final iconButtonDensity = isTablet ? VisualDensity.comfortable : VisualDensity.compact;
    final iconButtonWidth = isTablet ? 56.0 : 46.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _isSearchOpen
          ? AppBar(
              backgroundColor: Colors.blueGrey[900],
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearchOpen = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _updateFilteredSounds();
                },
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: l10n.get('searchSounds'),
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _searchQuery = value);
                      _updateFilteredSounds();
                    }
                  });
                },
              ),
            )
          : AppBar(
        backgroundColor: Colors.blueGrey[900],
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: iconButtonDensity,
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearchOpen = true),
              tooltip: l10n.get('searchSounds'),
            ),
            if (_showLoop)
              IconButton(
                visualDensity: iconButtonDensity,
                icon: Icon(
                  _isLooping ? Icons.loop : Icons.loop_outlined,
                  color: _isLooping ? Colors.lightBlueAccent : Colors.white,
                ),
                onPressed: _toggleLoop,
                tooltip: l10n.get('loop'),
              ),
            if (_showSpeed)
              PopupMenuButton<double>(
                icon: const Icon(Icons.speed, color: Colors.white),
                tooltip: l10n.get('playbackSpeed'),
                color: Colors.blueGrey[800],
                onSelected: _changeSpeed,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0.5,
                    child: Text(l10n.get('speed05'), style: const TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 1.0,
                    child: Text(l10n.get('speed10'), style: const TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 2.0,
                    child: Text(l10n.get('speed20'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            if (_showShuffle)
              IconButton(
                visualDensity: iconButtonDensity,
                icon: Icon(
                  _isShufflePlay ? Icons.shuffle : Icons.shuffle_outlined,
                  color: _isShufflePlay ? Colors.greenAccent : Colors.white,
                ),
                onPressed: _toggleShufflePlay,
                tooltip: l10n.get('shufflePlay'),
              ),
            if (_showAdd)
              IconButton(
                visualDensity: iconButtonDensity,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: l10n.get('addSound'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSoundPage(
                        categories: _categories,
                        onSoundAdded: (filePath, title, categories, color, volume) async {
                          final savedFileName = await saveFileToPermanentStorage(filePath);
                          setState(() {
                            sounds.add({
                              'id': 'user_${DateTime.now().millisecondsSinceEpoch}_${sounds.length}',
                              'name': savedFileName,
                              'title': title.isNotEmpty ? title : savedFileName,
                              'categories': categories,
                              'fav': false,
                              'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
                              'volume': volume,
                            });
                          });
                          await saveSoundsToStorage();
                          _rebuildCategoriesList();
                          _updateFilteredSounds();
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        leadingWidth: (visibleLeadingCount + 1) * iconButtonWidth,
        title: const SizedBox.shrink(),
        actions: [
          if (_showDelete)
            IconButton(
              visualDensity: iconButtonDensity,
              icon: Icon(
                _isDeleteMode ? Icons.close : Icons.delete,
                color: _isDeleteMode ? Colors.redAccent : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isDeleteMode = !_isDeleteMode;
                });
              },
              tooltip: _isDeleteMode ? l10n.get('cancelDeleteMode') : l10n.get('deleteMode'),
            ),
          if (_showDarkMode)
            IconButton(
              visualDensity: iconButtonDensity,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => MyApp.toggleThemeStatic(context),
            ),
          IconButton(
            visualDensity: iconButtonDensity,
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: l10n.get('settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    categories: _categories,
                    onResetSounds: _resetSounds,
                    onDeleteAllSounds: _deleteAllSounds,
                    onExportSounds: _exportSounds,
                    onImportSounds: _importSounds,
                    hapticFeedback: _hapticFeedback,
                    onToggleHapticFeedback: (value) {
                      setState(() => _hapticFeedback = value);
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.setBool('haptic_feedback', value),
                      );
                    },
                    onDeleteCategory: (cat, del) => _deleteCategory(cat, del),
                    onRenameCategory: _renameCategory,
                    onAddCategory: _addCategory,
                    categoryColors: _categoryColors,
                    onSetCategoryColor: _setCategoryColor,
                    simpleMode: _simpleMode,
                    onToggleSimpleMode: (value) {
                      setState(() => _simpleMode = value);
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.setBool('simple_mode', value),
                      );
                    },
                    hideCategories: _hideCategories,
                    onToggleHideCategories: (value) {
                      setState(() => _hideCategories = value);
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.setBool('hide_categories', value),
                      );
                    },
                    hidePlayback: _hidePlayback,
                    onToggleHidePlayback: (value) {
                      setState(() => _hidePlayback = value);
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.setBool('hide_playback', value),
                      );
                    },
                    showLoop: _showLoop,
                    showSpeed: _showSpeed,
                    showShuffle: _showShuffle,
                    showAdd: _showAdd,
                    showDelete: _showDelete,
                    showDarkMode: _showDarkMode,
                    onToggleToolbarButton: (key, value) {
                      setState(() {
                        switch (key) {
                          case 'loop': _showLoop = value;
                          case 'speed': _showSpeed = value;
                          case 'shuffle': _showShuffle = value;
                          case 'add': _showAdd = value;
                          case 'delete': _showDelete = value;
                          case 'darkmode': _showDarkMode = value;
                        }
                      });
                      SharedPreferences.getInstance().then(
                        (prefs) => prefs.setBool('show_$key', value),
                      );
                    },
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
              // 🏷️ Category filter chips
              if (!(_simpleMode && _hideCategories)) SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategories.contains(category);
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final l10n = AppLocalizations.of(context);
                    final displayLabel = category == 'everything'
                        ? l10n.get('everything')
                        : category == 'favorite'
                            ? l10n.get('favorite')
                            : category;
                    return FilterChip(
                      label: Text(
                        displayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? (isDark ? Colors.black87 : Colors.white)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: isDark ? Colors.white : Colors.blueGrey[600],
                      backgroundColor: isDark ? Colors.blueGrey[700] : Colors.grey[200],
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategories.clear();
                          _selectedCategories.add(category);
                        });
                        _updateFilteredSounds();
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ⏳ Progress bar
              if (!(_simpleMode && _hidePlayback)) Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentSound == null
                                ? l10n.get('noSoundPlaying')
                                : () {
                                    // Nájdi sound v zozname a zobraz title namiesto file name
                                    final sound = sounds.firstWhere(
                                      (s) => s['id'] == _currentSound,
                                      orElse: () => {'title': _currentSound},
                                    );
                                    return "${l10n.get('nowPlaying')} ${sound['title']}";
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
                        GestureDetector(
                          onTap: () {
                            if (_playbackRate == 1.0) {
                              _changeSpeed(2.0);
                            } else if (_playbackRate == 2.0) {
                              _changeSpeed(0.5);
                            } else {
                              _changeSpeed(1.0);
                            }
                          },
                          child: Text(
                            '${_playbackRate}x',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _progressNotifier,
                        builder: (context, progress, child) {
                          return SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: Colors.blueAccent,
                              inactiveTrackColor: Colors.grey.shade300,
                              thumbColor: Colors.blueAccent,
                              overlayColor: Colors.blueAccent.withAlpha(40),
                            ),
                            child: Slider(
                              value: progress,
                              onChanged: _currentSound != null
                                  ? (value) {
                                      _seekTo(value);
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Filter info
              const SizedBox(height: 8),

              // 🟩 Grid tlačidiel
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _cachedFilteredSounds.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.audiotrack,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('noSoundsFound'),
                          style:
                          const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.get('tryChangingSearch'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ReorderableGridView.builder(
                    onReorder: _isDeleteMode ? (_, __) {} : _onReorder,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _cachedFilteredSounds.length,
                    itemBuilder: (context, index) {
                      final sound = _cachedFilteredSounds[index];
                      return SoundButton(
                        key: ValueKey(sound['id']),
                        soundName: sound['name'],
                        displayName: sound['title'],
                        buttonColor: _isDeleteMode
                            ? Colors.redAccent
                            : _parseColor(sound['color'] ?? '#42A5F5'),
                        savedColor: _parseColor(sound['color'] ?? '#42A5F5'),
                        isDeleteMode: _isDeleteMode,
                        categories: List<String>.from(
                            sound['categories'] ?? []),
                        isFavorite: sound['fav'] ?? false,
                        allCategories: _categories,
                        isPlaying: _currentSound == sound['id'],
                        startMs: sound['startMs'] ?? 0,
                        endMs: sound['endMs'] as int?,
                        volume: (sound['volume'] as num?)?.toDouble() ?? 1.0,
                        onPressed: () async {
                          if (_hapticFeedback) HapticFeedback.lightImpact();
                          if (_isDeleteMode) {
                            await deleteSound(sound['id']);
                            setState(() {});
                          } else {
                            if (_currentSound == sound['id']) {
                              _stopSound();
                            } else {
                              _playSound(sound['id']);
                            }
                          }
                        },
                        onUpdate: (newTitle, newCategories, newColor, newStartMs, newEndMs, newVolume) {
                          _updateSound(sound['id'], newTitle, newCategories, newColor, newStartMs, newEndMs, newVolume);
                        },
                        onToggleFavorite: () =>
                            _toggleFavorite(sound['id']),
                        simpleMode: _simpleMode,
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
                          l10n.get('restoringSound'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.get('pleaseWait'),
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
