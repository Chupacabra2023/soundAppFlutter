import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:id3tag/id3tag.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'sound_data.dart';
import 'app_localizations.dart';

class _FileEntry {
  final String path;
  final TextEditingController nameController;

  _FileEntry({required this.path, required String name})
      : nameController = TextEditingController(text: name);

  void dispose() => nameController.dispose();
}

class AddSoundPage extends StatefulWidget {
  final List<String> categories;
  final Function(String filePath, String title, List<String> categories, Color color, double volume) onSoundAdded;

  const AddSoundPage({
    super.key,
    required this.categories,
    required this.onSoundAdded,
  });

  @override
  State<AddSoundPage> createState() => _AddSoundPageState();
}

class _AddSoundPageState extends State<AddSoundPage> {
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  Timer? _trimTimer;
  String? _recordedPath;

  final List<_FileEntry> _selectedFiles = [];
  final List<String> _selectedCategories = [];
  Color _selectedColor = const Color(0xFF7BAFD4);

  double _volume = 1.0;

  // Trim state (only for single file / recording)
  int _trimStartMs = 0;
  int _trimEndMs = 0;
  int _fileDurationMs = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerAd());
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3948591512361475/7085908168',
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isBannerAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _trimTimer?.cancel();
    _bannerAd?.dispose();
    _record.dispose();
    _player.dispose();
    for (final f in _selectedFiles) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDuration(String filePath) async {
    final probePlayer = AudioPlayer();
    try {
      await probePlayer.setSource(DeviceFileSource(filePath));
      final duration = await probePlayer.getDuration();
      final ms = duration?.inMilliseconds ?? 0;
      if (ms > 0) {
        setState(() {
          _fileDurationMs = ms;
          _trimStartMs = 0;
          _trimEndMs = ms;
        });
      }
    } catch (_) {
    } finally {
      await probePlayer.dispose();
    }
  }

  String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final tenths = (ms % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  String _cleanName(String fileName) {
    final withoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    return withoutExt
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final path = '${Directory.systemTemp.path}/temp_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _record.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordedPath = path;
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
        // Replace files list with just the recording
        for (final f in _selectedFiles) f.dispose();
        _selectedFiles.clear();
        _selectedFiles.add(_FileEntry(
          path: _recordedPath!,
          name: 'recording_${DateTime.now().millisecondsSinceEpoch}',
        ));
        _fileDurationMs = 0;
      });
      await _fetchDuration(_recordedPath!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error stopping recording: $e')),
        );
        setState(() => _isRecording = false);
      }
    }
  }

  Future<String> _readId3Title(String path) async {
    try {
      final parser = ID3TagReader(File(path));
      final tag = await parser.readTag();
      final title = tag.title?.trim() ?? '';
      return title.isNotEmpty ? title : _cleanName(path.split('/').last.split('\\').last);
    } catch (_) {
      return _cleanName(path.split('/').last.split('\\').last);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      for (final f in _selectedFiles) f.dispose();
      setState(() {
        _selectedFiles.clear();
        _fileDurationMs = 0;
        _trimStartMs = 0;
        _trimEndMs = 0;
      });

      for (final file in result.files) {
        if (file.path != null) {
          final name = await _readId3Title(file.path!);
          setState(() {
            _selectedFiles.add(_FileEntry(path: file.path!, name: name));
          });
        }
      }

      if (_selectedFiles.isNotEmpty) {
        await _fetchDuration(_selectedFiles.first.path);
      }
    }
  }

  Future<void> _playSound() async {
    if (_selectedFiles.length == 1) {
      try {
        _trimTimer?.cancel();
        await _player.stop();
        await _player.setVolume(_volume);
        await _player.play(DeviceFileSource(_selectedFiles.first.path));

        final hasTrim = _fileDurationMs > 0 &&
            (_trimStartMs > 0 || _trimEndMs < _fileDurationMs);

        if (hasTrim) {
          await _player.seek(Duration(milliseconds: _trimStartMs));
          final playDurationMs = _trimEndMs - _trimStartMs;
          _trimTimer = Timer(Duration(milliseconds: playDurationMs), () {
            _player.stop();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error playing sound: $e')),
          );
        }
      }
    }
  }

  Future<void> _stopSound() async {
    _trimTimer?.cancel();
    await _player.stop();
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
            maxLength: 40,
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
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

  Future<void> _saveSound() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No files selected')),
      );
      return;
    }

    for (final entry in _selectedFiles) {
      final name = entry.nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ All files need a name')),
        );
        return;
      }
    }

    if (_selectedCategories.isEmpty) {
      final l10n = AppLocalizations.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.get('noCategoryTitle')),
          content: Text(l10n.get('noCategoryMessage')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.get('addAnyway')),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      final hasTrim = _fileDurationMs > 0 &&
          (_trimStartMs > 0 || _trimEndMs < _fileDurationMs);

      for (final entry in _selectedFiles) {
        final extension = entry.path.split('.').last;
        final displayName = entry.nameController.text.trim();
        final safeFileName = displayName
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
            .replaceAll(' ', '_');

        if (safeFileName.isEmpty) continue;

        final finalPath = '${Directory.systemTemp.path}/$safeFileName.$extension';
        final targetFile = File(finalPath);
        if (await targetFile.exists()) await targetFile.delete();

        if (hasTrim) {
          final startSec = _trimStartMs / 1000.0;
          final endSec = _trimEndMs / 1000.0;
          final session = await FFmpegKit.execute(
            '-i "${entry.path}" -ss $startSec -to $endSec -c:a libmp3lame -q:a 2 "$finalPath" -y',
          );
          final returnCode = await session.getReturnCode();
          if (!ReturnCode.isSuccess(returnCode)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Error trimming audio')),
              );
            }
            return;
          }
        } else {
          await File(entry.path).copy(finalPath);
        }

        widget.onSoundAdded(
          finalPath,
          displayName,
          List.from(_selectedCategories),
          _selectedColor,
          _volume,
        );
      }

      if (mounted) Navigator.pop(context);
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.blueGrey[800];
    final isSingle = _selectedFiles.length == 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(
          l10n.get('addNewSound'),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: l10n.get('saveSound'),
            onPressed: _selectedFiles.isNotEmpty ? _saveSound : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
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
                        onPressed: isSingle
                            ? (_isPlaying ? _stopSound : _playSound)
                            : null,
                        icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                        color: isSingle ? iconColor : Colors.grey[400],
                        tooltip: _isPlaying ? l10n.get('stop') : l10n.get('play'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        color: iconColor,
                        tooltip: l10n.get('pickFile'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ✂️ Trim slider
                  if (_fileDurationMs > 0) ...[
                    Text(
                      l10n.get('trimSound'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    RangeSlider(
                      values: RangeValues(
                        _trimStartMs.toDouble().clamp(0, _fileDurationMs.toDouble()),
                        _trimEndMs.toDouble().clamp(0, _fileDurationMs.toDouble()),
                      ),
                      min: 0,
                      max: _fileDurationMs.toDouble(),
                      activeColor: Colors.blueGrey[800],
                      inactiveColor: Colors.grey[300],
                      onChanged: (RangeValues values) {
                        setState(() {
                          _trimStartMs = values.start.toInt();
                          _trimEndMs = values.end.toInt();
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatMs(_trimStartMs), style: const TextStyle(fontSize: 12)),
                          Text(_formatMs(_fileDurationMs), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text(_formatMs(_trimEndMs), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 🔊 Volume
                  Text(
                    '🔊 ${l10n.get('volume')}: ${(_volume * 100).round()}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: Colors.blueGrey[800],
                    inactiveColor: Colors.grey[300],
                    onChanged: (value) {
                      setState(() => _volume = value);
                      _player.setVolume(value);
                    },
                  ),

                  const SizedBox(height: 8),

                  // 📝 File name fields
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._selectedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: file.nameController,
                                maxLength: 30,
                                decoration: InputDecoration(
                                  labelText: _selectedFiles.length == 1
                                      ? l10n.get('soundName')
                                      : '${l10n.get('soundName')} ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blueGrey[700]!),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            if (_selectedFiles.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _selectedFiles[index].dispose();
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 8),

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
                        color: iconColor,
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
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.blueGrey[600],
                        backgroundColor: isDark ? Colors.blueGrey[700] : Colors.grey[200],
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
                  GridView.count(
                    crossAxisCount: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: kColorPalette.map((color) {
                      final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                ],
              ),
            ),
          ),

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
