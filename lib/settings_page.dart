import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'app_localizations.dart';
import 'main.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'sound_data.dart';

class SettingsPage extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onResetSounds;
  final VoidCallback onDeleteAllSounds;
  final Future<void> Function() onExportSounds;
  final Future<void> Function(BuildContext) onImportSounds;
  final bool hapticFeedback;
  final Function(bool) onToggleHapticFeedback;
  final Function(String category, bool deleteSounds) onDeleteCategory;
  final Function(String oldName, String newName) onRenameCategory;
  final Function(String category) onAddCategory;
  final Map<String, int> categoryColors;
  final Function(String category, Color color) onSetCategoryColor;
  final bool simpleMode;
  final Function(bool) onToggleSimpleMode;
  final bool hideCategories;
  final Function(bool) onToggleHideCategories;
  final bool hidePlayback;
  final Function(bool) onToggleHidePlayback;
  final bool showSearch;
  final bool showLoop;
  final bool showSpeed;
  final bool showShuffle;
  final bool showAdd;
  final bool showDelete;
  final bool showDarkMode;
  final bool showMasterVolume;
  final bool hideVolume;
  final Function(bool) onToggleHideVolume;
  final Function(String key, bool value) onToggleToolbarButton;

  const SettingsPage({
    super.key,
    required this.categories,
    required this.onResetSounds,
    required this.onDeleteAllSounds,
    required this.onExportSounds,
    required this.onImportSounds,
    required this.hapticFeedback,
    required this.onToggleHapticFeedback,
    required this.onDeleteCategory,
    required this.onRenameCategory,
    required this.onAddCategory,
    required this.categoryColors,
    required this.onSetCategoryColor,
    required this.simpleMode,
    required this.onToggleSimpleMode,
    required this.hideCategories,
    required this.onToggleHideCategories,
    required this.hidePlayback,
    required this.onToggleHidePlayback,
    required this.showSearch,
    required this.showLoop,
    required this.showSpeed,
    required this.showShuffle,
    required this.showAdd,
    required this.showDelete,
    required this.showDarkMode,
    required this.showMasterVolume,
    required this.hideVolume,
    required this.onToggleHideVolume,
    required this.onToggleToolbarButton,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<String> _localCategories;
  late Map<String, int> _localCategoryColors;
  late bool _simpleMode;
  bool _simpleModeExpanded = false;
  late bool _hapticFeedback;
  late bool _hideCategories;
  late bool _hidePlayback;
  late bool _showSearch;
  late bool _showLoop;
  late bool _showSpeed;
  late bool _showShuffle;
  late bool _showAdd;
  late bool _showDelete;
  late bool _showDarkMode;
  late bool _showMasterVolume;
  late bool _hideVolume;
  bool _isExporting = false;
  bool _isImporting = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
    _localCategoryColors = Map.from(widget.categoryColors);
    _simpleMode = widget.simpleMode;
    _hapticFeedback = widget.hapticFeedback;
    _hideCategories = widget.hideCategories;
    _hidePlayback = widget.hidePlayback;
    _showSearch = widget.showSearch;
    _showLoop = widget.showLoop;
    _showSpeed = widget.showSpeed;
    _showShuffle = widget.showShuffle;
    _showAdd = widget.showAdd;
    _showDelete = widget.showDelete;
    _showDarkMode = widget.showDarkMode;
    _showMasterVolume = widget.showMasterVolume;
    _hideVolume = widget.hideVolume;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerAd());
  }

  Future<void> _loadBannerAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (adSize == null || !mounted) return;
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3948591512361475/7117189914',
      size: adSize,
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
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _toolbarToggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey[600]),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch(
            value: value,
            activeThumbColor: Colors.blueGrey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, String category) {
    final currentColorValue = _localCategoryColors[category];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kColorPalette.map((color) {
                  final isSelected = currentColorValue == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _localCategoryColors[category] = color.toARGB32();
                      });
                      widget.onSetCategoryColor(category, color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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

  Widget _buildSubToggle({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Icon(icon, size: 20, color: Colors.blueGrey[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Switch(
            value: value,
            activeThumbColor: Colors.blueGrey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
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
      body: Column(
        children: [
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // 🎛️ Simple Mode Section
          Card(
            elevation: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.get('simpleMode'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.get('simpleModeDesc'),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _simpleMode,
                        activeThumbColor: Colors.blueGrey[800],
                        onChanged: (value) {
                          setState(() => _simpleMode = value);
                          widget.onToggleSimpleMode(value);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _simpleModeExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blueGrey[600],
                        ),
                        onPressed: () => setState(() => _simpleModeExpanded = !_simpleModeExpanded),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _simpleModeExpanded
                      ? Column(
                          children: [
                            const Divider(height: 1),
                            _buildSubToggle(
                              icon: Icons.label_off_outlined,
                              title: l10n.get('hideCategories'),
                              value: _hideCategories,
                              onChanged: (v) {
                                setState(() => _hideCategories = v);
                                widget.onToggleHideCategories(v);
                              },
                            ),
                            _buildSubToggle(
                              icon: Icons.speaker_notes_off_outlined,
                              title: l10n.get('hidePlayback'),
                              value: _hidePlayback,
                              onChanged: (v) {
                                setState(() => _hidePlayback = v);
                                widget.onToggleHidePlayback(v);
                              },
                            ),
                            _buildSubToggle(
                              icon: Icons.volume_off_outlined,
                              title: 'Skryť volume slider',
                              value: _hideVolume,
                              onChanged: (v) {
                                setState(() => _hideVolume = v);
                                widget.onToggleHideVolume(v);
                              },
                            ),
                            const SizedBox(height: 4),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                            title: Text(
                              l10n.get('resetConfirmTitle'),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            content: Text(
                              l10n.get('resetConfirmMessage'),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.get('cancel'),
                                    style: const TextStyle(color: Colors.black54)),
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
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.get('resetToDefault')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text(
                              l10n.get('deleteAllConfirmTitle'),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            content: Text(
                              l10n.get('deleteAllConfirmMessage'),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.get('cancel'),
                                    style: const TextStyle(color: Colors.black54)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.get('deleteAll')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          widget.onDeleteAllSounds();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: Text(l10n.get('deleteAllSounds')),
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
                      Expanded(
                        child: Text(
                          l10n.get('manageCategories'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.blueGrey[700]),
                        tooltip: l10n.get('addCategory'),
                        onPressed: () async {
                          final controller = TextEditingController();
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              title: Text(l10n.get('newCategory')),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                maxLength: 40,
                                decoration: InputDecoration(
                                  labelText: l10n.get('enterCategoryName'),
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

                          if (newName != null && newName.isNotEmpty &&
                              !_localCategories.contains(newName)) {
                            setState(() {
                              _localCategories.add(newName);
                            });
                            widget.onAddCategory(newName);
                          }
                        },
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
                            GestureDetector(
                              onTap: () => _showColorPicker(context, category),
                              child: Container(
                                width: 26,
                                height: 26,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _localCategoryColors.containsKey(category)
                                      ? Color(_localCategoryColors[category]!)
                                      : kColorPalette.first,
                                  shape: BoxShape.circle,
                                ),
                              ),
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
          const SizedBox(height: 16),

          // 🎛️ Toolbar Buttons Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.get('toolbarButtons'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.get('toolbarButtonsDesc'),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _toolbarToggleRow(Icons.search, l10n.get('searchSounds'), _showSearch, (v) {
                    setState(() => _showSearch = v);
                    widget.onToggleToolbarButton('search', v);
                  }),
                  _toolbarToggleRow(Icons.loop, l10n.get('loop'), _showLoop, (v) {
                    setState(() => _showLoop = v);
                    widget.onToggleToolbarButton('loop', v);
                  }),
                  _toolbarToggleRow(Icons.speed, l10n.get('playbackSpeed'), _showSpeed, (v) {
                    setState(() => _showSpeed = v);
                    widget.onToggleToolbarButton('speed', v);
                  }),
                  _toolbarToggleRow(Icons.shuffle, l10n.get('shufflePlay'), _showShuffle, (v) {
                    setState(() => _showShuffle = v);
                    widget.onToggleToolbarButton('shuffle', v);
                  }),
                  _toolbarToggleRow(Icons.add, l10n.get('addSound'), _showAdd, (v) {
                    setState(() => _showAdd = v);
                    widget.onToggleToolbarButton('add', v);
                  }),
                  _toolbarToggleRow(Icons.delete, l10n.get('deleteMode'), _showDelete, (v) {
                    setState(() => _showDelete = v);
                    widget.onToggleToolbarButton('delete', v);
                  }),
                  _toolbarToggleRow(Icons.dark_mode, l10n.get('darkMode'), _showDarkMode, (v) {
                    setState(() => _showDarkMode = v);
                    widget.onToggleToolbarButton('darkmode', v);
                  }),
                  _toolbarToggleRow(Icons.volume_up, 'Master volume slider', _showMasterVolume, (v) {
                    setState(() => _showMasterVolume = v);
                    widget.onToggleToolbarButton('master_volume', v);
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 💾 Export / Import Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup, color: Colors.blueGrey[800]),
                      const SizedBox(width: 12),
                      Text(
                        l10n.get('backupRestore'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('backupRestoreDesc'),
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
                      onPressed: _isExporting || _isImporting ? null : () async {
                        setState(() => _isExporting = true);
                        try {
                          await widget.onExportSounds();
                        } finally {
                          if (mounted) setState(() => _isExporting = false);
                        }
                      },
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload),
                      label: Text(l10n.get('exportSounds')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isImporting || _isExporting ? null : () async {
                        setState(() => _isImporting = true);
                        try {
                          await widget.onImportSounds(context);
                        } finally {
                          if (mounted) setState(() => _isImporting = false);
                        }
                      },
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download),
                      label: Text(l10n.get('importSounds')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 📳 Haptic Feedback Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.vibration, color: Colors.blueGrey[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.get('hapticFeedback'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Switch(
                    value: _hapticFeedback,
                    activeThumbColor: Colors.blueGrey[800],
                    onChanged: (value) {
                      setState(() => _hapticFeedback = value);
                      widget.onToggleHapticFeedback(value);
                    },
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

          const SizedBox(height: 16),

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
                        // ConsentForm.showPrivacyOptionsForm((formError) {});
                      },
                      icon: const Icon(Icons.settings),
                      label: Text(l10n.get('managePrivacy')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ☕ Support / Ko-fi Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.pinkAccent[200]),
                      const SizedBox(width: 12),
                      Text(
                        l10n.get('supportTitle'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.get('supportDesc'),
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
                        const intent = AndroidIntent(
                          action: 'action_view',
                          data: 'https://ko-fi.com/marcelso',
                        );
                        await intent.launch();
                      },
                      icon: const Icon(Icons.coffee),
                      label: Text(l10n.get('donateButton')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
          ),
        ],
      ),
    );
  }
}
