import 'package:flutter/material.dart';

class SoundSettingsPage extends StatefulWidget {
  final String initialName;
  final String initialCategory;
  final List<String> categories;

  const SoundSettingsPage({
    super.key,
    required this.initialName,
    required this.initialCategory,
    required this.categories,
  });

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  late TextEditingController _nameController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveAndExit() {
    Navigator.pop(context, {
      'name': _nameController.text,
      'category': _selectedCategory,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavenia zvuku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndExit,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Názov:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Zadaj nový názov zvuku',
              ),
            ),
            const SizedBox(height: 20),

            const Text(
                'Kategória:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const Spacer(),

            // 🟢 Uložiť
            // 🟡 Zrušiť
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.pop(context); // 👈 len zavrie modal bez výsledku
                },
                icon: const Icon(Icons.close),
                label: const Text('Zrušiť'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

