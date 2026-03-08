import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'main.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SettingsPage extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onResetSounds;
  final Function(String category, bool deleteSounds) onDeleteCategory;
  final Function(String oldName, String newName) onRenameCategory;

  const SettingsPage({
    super.key,
    required this.categories,
    required this.onResetSounds,
    required this.onDeleteCategory,
    required this.onRenameCategory,
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
    final l10n = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(
          l10n.get('settings'),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => MyApp.toggleThemeStatic(context),
          ),
        ],
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
                      Text(
                        l10n.get('resetSounds'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('resetSoundsDescription'),
                    style: const TextStyle(color: Colors.grey),
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
                            title: Text(l10n.get('resetConfirmTitle')),
                            content: Text(
                              l10n.get('resetConfirmMessage'),
                            ),
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
                                child: Text(l10n.get('reset')),
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
                      label: Text(l10n.get('resetToDefault')),
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
                      Text(
                        l10n.get('manageCategories'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('manageCategoriesDescription'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Category list
                  ..._localCategories
                      .where((cat) => cat.toLowerCase() != 'everything')
                      .map((category) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.label,
                          color: Colors.blueGrey[700],
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                              tooltip: l10n.get('editCategory'),
                              onPressed: () async {
                                final controller = TextEditingController(text: category);
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Theme.of(context).cardColor,
                                    title: Text(l10n.get('editCategory')),
                                    content: TextField(
                                      controller: controller,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.get('newCategoryName'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(l10n.get('cancel')),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                                        child: Text(l10n.get('save')),
                                      ),
                                    ],
                                  ),
                                );

                                if (newName != null && newName.isNotEmpty && newName != category) {
                                  setState(() {
                                    final index = _localCategories.indexOf(category);
                                    if (index != -1) {
                                      _localCategories[index] = newName;
                                    }
                                  });
                                  widget.onRenameCategory(category, newName);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: l10n.get('deleteCategory'),
                              onPressed: () async {
                                bool deleteSounds = false;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setDialogState) => AlertDialog(
                                      backgroundColor: Theme.of(context).cardColor,
                                      title: Text(l10n.get('deleteCategory')),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l10n.get('deleteCategoryConfirm').replaceAll('{category}', category)),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: deleteSounds,
                                                activeColor: Colors.redAccent,
                                                onChanged: (v) => setDialogState(() => deleteSounds = v ?? false),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => setDialogState(() => deleteSounds = !deleteSounds),
                                                  child: Text(
                                                    l10n.get('deleteSoundsAlso'),
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(l10n.get('cancel')),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(l10n.get('delete')),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (confirm == true) {
                                  setState(() {
                                    _localCategories.remove(category);
                                  });
                                  widget.onDeleteCategory(category, deleteSounds);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  if (_localCategories
                      .where((cat) => cat.toLowerCase() != 'everything')
                      .isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.get('noCustomCategories'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

// 🔒 Privacy Settings Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      Text(
                        l10n.get('privacySettings'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('privacySettingsDesc'),
                    style: const TextStyle(color: Colors.grey),
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
                      onPressed: () {
                        ConsentForm.showPrivacyOptionsForm((formError) {});
                      },
                      icon: const Icon(Icons.settings),
                      label: Text(l10n.get('managePrivacy')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🌍 Language Selection Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      Text(
                        l10n.get('language'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('selectLanguage'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: currentLocale.languageCode,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('English'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'sk',
                        child: Row(
                          children: [
                            Text('🇸🇰', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('Slovenčina'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'es',
                        child: Row(
                          children: [
                            Text('🇪🇸', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('Español'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Row(
                          children: [
                            Text('🇫🇷', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('Français'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'de',
                        child: Row(
                          children: [
                            Text('🇩🇪', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('Deutsch'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ru',
                        child: Row(
                          children: [
                            Text('🇷🇺', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text('Русский'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        MyApp.setLocale(context, Locale(value));
                      }
                    },
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
