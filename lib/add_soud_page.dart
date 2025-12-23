import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'sound_data.dart';
import 'app_localizations.dart';

class AddSoundPage extends StatefulWidget {
  final List<String> categories;
  final Function(String filePath, String title, List<String> categories, Color color) onSoundAdded;

  const AddSoundPage({
    super.key,
    required this.categories,
    required this.onSoundAdded,
  });

  @override
  State<AddSoundPage> createState() => _AddSoundPageState();
}

class _AddSoundPageState extends State<AddSoundPage> {
  // 🐛 DEBUG: Počítadlo rebuildov
  static int _rebuildCount = 0;

  final _record = AudioRecorder();
  final _player = AudioPlayer();
  String? _filePath;
  bool _isRecording = false;
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedCategories = [];

  Color _selectedColor = const Color(0xFF7BAFD4);

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ✅ FocusNode pre sledovanie focusu na TextField
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded successfully on Add Sound page');
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load on Add Sound page: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _record.dispose();
    _player.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose(); // ✅ Dispose FocusNode
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final path = '${Directory.systemTemp.path}/temp_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _record.start(const RecordConfig(), path: path);
        setState(() {
          _filePath = path;
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _record.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error stopping recording: $e')),
        );
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  Future<void> _playSound() async {
    if (_filePath != null) {
      try {
        await _player.play(DeviceFileSource(_filePath!));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error playing sound: $e')),
          );
        }
      }
    }
  }

  void _addNewCategory() async {
    final l10n = AppLocalizations.of(context);
    final TextEditingController newCatController = TextEditingController();

    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[900],
          title: Text(l10n.get('addNewSound'), style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: newCatController,
            maxLength: 15,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.get('categoryName'),
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
              ),
              onPressed: () {
                final value = newCatController.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: Text(l10n.get('add'), style: const TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      setState(() {
        if (!widget.categories.contains(newCategory)) {
          widget.categories.add(newCategory);
        }
        _selectedCategories.add(newCategory);
      });
    }
  }

  void _saveSound() async {
    if (_filePath == null ||
        _nameController.text.trim().isEmpty ||
        _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please fill all fields')),
      );
      return;
    }

    try {
      final extension = _filePath!.split('.').last;
      final cleanName = _nameController.text.trim()
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');

      if (cleanName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Invalid file name')),
        );
        return;
      }

      final finalPath = '${Directory.systemTemp.path}/$cleanName.$extension';

      final targetFile = File(finalPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await File(_filePath!).rename(finalPath);

      widget.onSoundAdded(
        finalPath,
        cleanName,
        List.from(_selectedCategories),
        _selectedColor,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error saving sound: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🐛 DEBUG: Počítadlo rebuildov
    _rebuildCount++;
    debugPrint('➕ ADD SOUND PAGE REBUILD #$_rebuildCount');

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // ⚡ Zastaví rebuildy pri klavesnici!
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(
          l10n.get('addNewSound'),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🎤 Record / play / pick file
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording
                                ? Colors.redAccent
                                : Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? l10n.get('stopRecording') : l10n.get('record')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _playSound,
                        icon: const Icon(Icons.play_arrow),
                        color: Colors.blueGrey[800],
                        tooltip: l10n.get('play'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        color: Colors.blueGrey[800],
                        tooltip: l10n.get('pickFile'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 📝 Name input
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode, // ✅ Pridaj FocusNode
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: l10n.get('soundName'),
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueGrey[700]!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📂 Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.get('categories'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _addNewCategory,
                        icon: const Icon(Icons.add),
                        color: Colors.blueGrey[800],
                        tooltip: l10n.get('addCategory'),
                      ),
                    ],
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.categories
                        .where((category) => category.toLowerCase() != 'everything')
                        .map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        selected: isSelected,
                        selectedColor: Colors.blueGrey[700],
                        backgroundColor: Colors.grey[200],
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 🎨 Color picker
                  Text(
                    l10n.get('buttonColor'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kColorPalette.map((color) {
                      final isSelected =
                          _selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueGrey[900]!
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 💾 Save button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saveSound,
                    icon: const Icon(Icons.save),
                    label: Text(l10n.get('saveSound')),
                  ),
                ],
              ),
            ),
          ),

          // Banner Ad - fixne na spodku
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}