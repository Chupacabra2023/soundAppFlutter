import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

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
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  String? _filePath;
  bool _isRecording = false;
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedCategories = [];

  // 🎨 Paleta farieb
  final List<Color> _colorOptions = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.indigoAccent,
    Colors.brown,
    Colors.grey,
  ];

  Color _selectedColor = Colors.blueAccent; // 🟡 default

  Future<void> _startRecording() async {
    if (await _record.hasPermission()) {
      final path = '${Directory.systemTemp.path}/temp_sound.m4a';
      await _record.start(const RecordConfig(), path: path);
      setState(() {
        _filePath = path;
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    await _record.stop();
    setState(() {
      _isRecording = false;
    });
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
      await _player.play(DeviceFileSource(_filePath!));
    }
  }

  void _addNewCategory() async {
    final TextEditingController newCatController = TextEditingController();

    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pridať novú kategóriu'),
          content: TextField(
            controller: newCatController,
            decoration: const InputDecoration(hintText: 'Názov kategórie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušiť'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = newCatController.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: const Text('Pridať'),
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

  void _saveSound() {
    if (_filePath == null ||
        _nameController.text.trim().isEmpty ||
        _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Vyplň všetky polia')),
      );
      return;
    }

    final extension = _filePath!.split('.').last;
    final cleanName = _nameController.text.trim().replaceAll(' ', '_');
    final finalPath = '${Directory.systemTemp.path}/$cleanName.$extension';
    File(_filePath!).renameSync(finalPath);

    widget.onSoundAdded(
      finalPath,
      cleanName,
      List.from(_selectedCategories),
      _selectedColor, // 🟡 tu posielame farbu
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Zvuk uložený')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pridať nový zvuk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop' : 'Nahrať'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _playSound,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Prehrať'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Nahrať zo súboru'),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Názov zvuku',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategórie:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addNewCategory,
                  icon: const Icon(Icons.add),
                  tooltip: 'Pridať kategóriu',
                ),
              ],
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade200,
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
            const Text(
              'Farba tlačidla:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
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
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSound,
              icon: const Icon(Icons.save),
              label: const Text('Uložiť zvuk'),
            ),
          ],
        ),
      ),
    );
  }
}
