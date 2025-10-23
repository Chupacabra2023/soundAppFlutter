import 'package:flutter/material.dart';

class SoundButton extends StatefulWidget {
  final String soundName;
  final String displayName;
  final List<String> categories;
  final bool isFavorite;
  final List<String> allCategories;
  final VoidCallback onPressed;
  final Function(String, List<String>, Color) onUpdate;
  final VoidCallback onToggleFavorite;
  final Color buttonColor;

  const SoundButton({
    super.key,
    required this.buttonColor,
    required this.soundName,
    required this.displayName,
    required this.categories,
    required this.isFavorite,
    required this.allCategories,
    required this.onPressed,
    required this.onUpdate,
    required this.onToggleFavorite,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  late String _currentDisplayName;
  late List<String> _selectedCategories;
  late Color _selectedColor;

  // 🎨 zoznam preddefinovaných farieb
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

  @override
  void initState() {
    super.initState();
    _currentDisplayName = widget.displayName;
    _selectedCategories = List.from(widget.categories);
    _selectedColor = widget.buttonColor;
  }

  void _openSettings() {
    final nameController = TextEditingController(text: _currentDisplayName);

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  onChanged: (value) => _currentDisplayName = value,
                  decoration: const InputDecoration(labelText: 'Názov'),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kategórie', style: Theme.of(context).textTheme.titleMedium),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ...widget.allCategories
                        .where((c) => c != 'Všetko')
                        .map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),

                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Pridať'),
                      onPressed: () async {
                        final controller = TextEditingController();
                        final newCategory = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Nová kategória'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'Zadaj názov kategórie',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Zrušiť'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final value = controller.text.trim();
                                    if (value.isNotEmpty) {
                                      Navigator.pop(context, value);
                                    }
                                  },
                                  child: const Text('Pridať'),
                                ),
                              ],
                            );
                          },
                        );

                        if (newCategory != null && newCategory.isNotEmpty) {
                          setModalState(() {
                            if (!widget.allCategories.contains(newCategory)) {
                              widget.allCategories.add(newCategory);
                            }
                            _selectedCategories.add(newCategory);
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Farba tlačidla', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),

                // 🎨 výber farby
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
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

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade100,


                        ),
                        onPressed: () {
                          // 🧠 pošleme všetko späť rodičovi
                          widget.onUpdate(
                            _currentDisplayName,
                            _selectedCategories,
                            _selectedColor,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Uložiť'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: widget.buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.4),
              child: Text(
                _currentDisplayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                onPressed: _openSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                icon: Icon(
                  widget.isFavorite ? Icons.star : Icons.star_border,
                  color: widget.isFavorite ? Colors.yellow : Colors.white,
                  size: 20,
                ),
                onPressed: widget.onToggleFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
