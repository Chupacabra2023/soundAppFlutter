import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onResetSounds;
  final Function(String category) onDeleteCategory;

  const SettingsPage({
    super.key,
    required this.categories,
    required this.onResetSounds,
    required this.onDeleteCategory,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<String> _localCategories;

  @override
  void initState() {
    super.initState();
    // Vytvor lokálnu kópiu kategórií pre okamžitú UI aktualizáciu
    _localCategories = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aktualizuj lokálne kategórie keď sa zmenia v parent (napr. po reset)
    if (widget.categories != oldWidget.categories) {
      setState(() {
        _localCategories = List.from(widget.categories);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔄 Reset Sounds Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      const Text(
                        'Reset Sounds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will delete all current sounds and reload the original sounds with their categories.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Reset sounds'),
                            content: const Text(
                              'This will delete all current sounds and reload the original sounds with their categories.\n\nDo you want to continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey[800],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          widget.onResetSounds();
                          // Zatvor Settings page, aby sa po resete zobrazili aktuálne kategórie
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to default sounds'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 📂 Manage Categories Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      const Text(
                        'Manage Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Delete categories that you no longer need. All sounds with this category will lose it.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Category list
                  ..._localCategories
                      .where((cat) => cat.toLowerCase() != 'everything')
                      .map((category) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[100],
                      child: ListTile(
                        leading: Icon(
                          Icons.label,
                          color: Colors.blueGrey[700],
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete category',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Delete category'),
                                content: Text(
                                  'Are you sure you want to delete "$category"?\n\nAll sounds with this category will lose it.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                // Odstráň z lokálneho zoznamu pre okamžitú UI aktualizáciu
                                _localCategories.remove(category);
                              });
                              // Zavolaj callback pre update v main.dart
                              widget.onDeleteCategory(category);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),

                  if (_localCategories
                      .where((cat) => cat.toLowerCase() != 'everything')
                      .isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No custom categories yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
