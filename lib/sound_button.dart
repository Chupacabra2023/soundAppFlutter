import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'sound_data.dart';
import 'app_localizations.dart';

const _kButtonBorderRadius = BorderRadius.all(Radius.circular(12));
const _kBottomBorderRadius = BorderRadius.vertical(bottom: Radius.circular(12));
const _kButtonShadow = [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))];
const _kIconConstraints = BoxConstraints(minWidth: 24, minHeight: 24);
const _kIconPadding = EdgeInsets.zero;
const _kBottomPadding = EdgeInsets.symmetric(horizontal: 4);

String _formatMs(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final tenths = (ms % 1000) ~/ 100;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$tenths';
}

class SoundButton extends StatefulWidget {
  final String soundName;
  final String displayName;
  final List<String> categories;
  final bool isFavorite;
  final List<String> allCategories;
  final VoidCallback onPressed;
  final Function(String, List<String>, Color, int, int?, double, int, int) onUpdate;
  final VoidCallback onToggleFavorite;
  final Color buttonColor;
  final Color savedColor;
  final bool isDeleteMode;
  final bool isPlaying;
  final int startMs;
  final int? endMs;
  final double volume;
  final int fadeInMs;
  final int fadeOutMs;
  final bool simpleMode;

  const SoundButton({
    super.key,
    required this.buttonColor,
    required this.savedColor,
    required this.soundName,
    required this.displayName,
    required this.categories,
    required this.isFavorite,
    required this.allCategories,
    required this.onPressed,
    required this.onUpdate,
    required this.onToggleFavorite,
    this.isDeleteMode = false,
    this.isPlaying = false,
    this.startMs = 0,
    this.endMs,
    this.volume = 1.0,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.simpleMode = false,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  late String _currentDisplayName;

  @override
  void initState() {
    super.initState();
    _currentDisplayName = widget.displayName;
  }

  void _openSettings() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        alignment: Alignment.bottomCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: _SoundSettingsSheet(
          displayName: _currentDisplayName,
          soundName: widget.soundName,
          categories: widget.categories,
          allCategories: widget.allCategories,
          savedColor: widget.savedColor,
          startMs: widget.startMs,
          endMs: widget.endMs,
          volume: widget.volume,
          fadeInMs: widget.fadeInMs,
          fadeOutMs: widget.fadeOutMs,
          onConfirm: (name, cats, color, start, end, vol, fi, fo) {
            setState(() => _currentDisplayName = name);
            widget.onUpdate(name, cats, color, start, end, vol, fi, fo);
          },
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
          borderRadius: _kButtonBorderRadius,
          boxShadow: _kButtonShadow,
          border: widget.isDeleteMode
              ? Border.all(color: Colors.redAccent, width: 2.5)
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              flex: widget.simpleMode ? 100 : 75,
              child: Center(
                child: widget.isPlaying
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop, size: 40, color: Colors.white),
                          SizedBox(height: 2),
                          Text(
                            'STOP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _currentDisplayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            if (!widget.simpleMode)
              Expanded(
                flex: 25,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF546E7A),
                    borderRadius: _kBottomBorderRadius,
                  ),
                  padding: _kBottomPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 16),
                        onPressed: _openSettings,
                        padding: _kIconPadding,
                        constraints: _kIconConstraints,
                      ),
                      IconButton(
                        icon: Icon(
                          widget.isFavorite ? Icons.star : Icons.star_border,
                          color: widget.isFavorite ? Colors.yellow : Colors.white,
                          size: 16,
                        ),
                        onPressed: widget.onToggleFavorite,
                        padding: _kIconPadding,
                        constraints: _kIconConstraints,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog content as a proper StatefulWidget — fixes InheritedWidget lifecycle
// ---------------------------------------------------------------------------

class _SoundSettingsSheet extends StatefulWidget {
  final String displayName;
  final String soundName;
  final List<String> categories;
  final List<String> allCategories;
  final Color savedColor;
  final int startMs;
  final int? endMs;
  final double volume;
  final int fadeInMs;
  final int fadeOutMs;
  final void Function(String, List<String>, Color, int, int?, double, int, int) onConfirm;

  const _SoundSettingsSheet({
    required this.displayName,
    required this.soundName,
    required this.categories,
    required this.allCategories,
    required this.savedColor,
    required this.startMs,
    this.endMs,
    required this.volume,
    required this.fadeInMs,
    required this.fadeOutMs,
    required this.onConfirm,
  });

  @override
  State<_SoundSettingsSheet> createState() => _SoundSettingsSheetState();
}

class _SoundSettingsSheetState extends State<_SoundSettingsSheet> {
  late String _displayName;
  late List<String> _selectedCategories;
  late List<String> _availableCategories;
  late Color _selectedColor;
  late double _volume;
  late int _startMs;
  int? _endMs;
  late int _fadeInMs;
  late int _fadeOutMs;
  int _totalDurationMs = 0;
  bool _isDurationLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  late final TextEditingController _nameController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _fadeInController;
  late final TextEditingController _fadeOutController;

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName;
    _selectedCategories = List.from(widget.categories);
    _availableCategories = List.from(widget.allCategories);
    _selectedColor = widget.savedColor;
    _volume = widget.volume;
    _startMs = widget.startMs;
    _endMs = widget.endMs;
    _fadeInMs = widget.fadeInMs;
    _fadeOutMs = widget.fadeOutMs;

    _nameController = TextEditingController(text: _displayName);
    _startController = TextEditingController(
      text: (widget.startMs / 1000).toStringAsFixed(1),
    );
    _endController = TextEditingController();
    _fadeInController = TextEditingController(
      text: widget.fadeInMs > 0 ? (widget.fadeInMs / 1000).toStringAsFixed(1) : '1.0',
    );
    _fadeOutController = TextEditingController(
      text: widget.fadeOutMs > 0 ? (widget.fadeOutMs / 1000).toStringAsFixed(1) : '1.0',
    );

    _fetchDuration();
    _loadBannerAd();
  }

  Future<void> _fetchDuration() async {
    final probePlayer = AudioPlayer();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${widget.soundName}';
      if (!await File(filePath).exists()) {
        if (mounted) setState(() => _isDurationLoading = false);
        return;
      }
      await probePlayer.setSource(DeviceFileSource(filePath));
      final duration = await probePlayer.getDuration();
      if (!mounted) return;
      setState(() {
        if (duration != null && duration.inMilliseconds > 0) {
          _totalDurationMs = duration.inMilliseconds;
          _endMs ??= _totalDurationMs;
          _endController.text = (_endMs! / 1000).toStringAsFixed(1);
        }
        _isDurationLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isDurationLoading = false);
    } finally {
      await probePlayer.dispose();
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3948591512361475/4467483687',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  void _confirm() {
    final finalName = _nameController.text.trim().isEmpty
        ? _displayName
        : _nameController.text.trim();
    final int? finalEndMs =
        (_totalDurationMs > 0 && _endMs == _totalDurationMs) ? null : _endMs;
    widget.onConfirm(
      finalName,
      _selectedCategories,
      _selectedColor,
      _startMs,
      finalEndMs,
      _volume,
      _fadeInMs,
      _fadeOutMs,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    _displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _confirm,
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // Name field
                    TextField(
                      controller: _nameController,
                      maxLength: 50,
                      onChanged: (value) {
                        // update header live
                        setState(() => _displayName =
                            value.trim().isEmpty ? widget.displayName : value);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.get('soundName'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categories
                    Text(l10n.get('categories'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ..._availableCategories
                            .where((c) => c.toLowerCase() != 'everything')
                            .map((category) {
                          final isSelected =
                              _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: Colors.blueGrey[700],
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                            backgroundColor: isDark
                                ? Colors.blueGrey[700]
                                : Colors.grey[200],
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(l10n.get('add')),
                          onPressed: () async {
                            final controller = TextEditingController();
                            final newCategory = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.get('newCategory')),
                                content: TextField(
                                  controller: controller,
                                  maxLength: 15,
                                  decoration: InputDecoration(
                                    hintText: l10n.get('enterCategoryName'),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(l10n.get('cancel')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final v = controller.text.trim();
                                      if (v.isNotEmpty) Navigator.pop(ctx, v);
                                    },
                                    child: Text(l10n.get('add')),
                                  ),
                                ],
                              ),
                            );
                            if (newCategory != null &&
                                newCategory.isNotEmpty &&
                                !_availableCategories.contains(newCategory)) {
                              setState(() {
                                _availableCategories.add(newCategory);
                                _selectedCategories.add(newCategory);
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Color picker
                    Text(l10n.get('buttonColor'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      children: kColorPalette.map((color) {
                        final isSelected =
                            _selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Trim
                    Text(l10n.get('trimSound'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_isDurationLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            l10n.get('trimLoading'),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    else if (_totalDurationMs > 0)
                      Column(
                        children: [
                          RangeSlider(
                            values: RangeValues(
                              _startMs
                                  .toDouble()
                                  .clamp(0, _totalDurationMs.toDouble()),
                              (_endMs ?? _totalDurationMs)
                                  .toDouble()
                                  .clamp(0, _totalDurationMs.toDouble()),
                            ),
                            min: 0,
                            max: _totalDurationMs.toDouble(),
                            activeColor: Colors.blueGrey[700],
                            inactiveColor: Colors.grey[300],
                            onChanged: (values) {
                              setState(() {
                                _startMs = values.start.toInt();
                                _endMs = values.end.toInt();
                                _startController.text =
                                    (_startMs / 1000).toStringAsFixed(1);
                                _endController.text =
                                    (_endMs! / 1000).toStringAsFixed(1);
                              });
                            },
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 72,
                                  child: TextField(
                                    controller: _startController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Start (s)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final secs = double.tryParse(val);
                                      if (secs != null) {
                                        setState(() => _startMs = (secs * 1000)
                                            .toInt()
                                            .clamp(
                                                0,
                                                (_endMs ??
                                                        _totalDurationMs) -
                                                    100));
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      _formatMs(_totalDurationMs),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: TextField(
                                    controller: _endController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'End (s)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final secs = double.tryParse(val);
                                      if (secs != null) {
                                        setState(() => _endMs = (secs * 1000)
                                            .toInt()
                                            .clamp(_startMs + 100,
                                                _totalDurationMs));
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Volume
                    Text(
                      '🔊 ${l10n.get('volume')}: ${(_volume * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: Colors.blueGrey[700],
                      inactiveColor: Colors.grey[300],
                      onChanged: (value) => setState(() => _volume = value),
                    ),

                    const SizedBox(height: 20),

                    // Fade In / Fade Out
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: _fadeInMs > 0,
                                    activeColor: Colors.blueGrey[700],
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked) {
                                          final secs = double.tryParse(_fadeInController.text) ?? 1.0;
                                          _fadeInMs = (secs * 1000).toInt().clamp(100, 10000);
                                        } else {
                                          _fadeInMs = 0;
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Fade In', style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _fadeInController,
                                enabled: _fadeInMs > 0,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  suffixText: 's',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final secs = double.tryParse(val);
                                  if (secs != null && secs > 0) {
                                    setState(() => _fadeInMs = (secs * 1000).toInt().clamp(100, 10000));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: _fadeOutMs > 0,
                                    activeColor: Colors.blueGrey[700],
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked) {
                                          final secs = double.tryParse(_fadeOutController.text) ?? 1.0;
                                          _fadeOutMs = (secs * 1000).toInt().clamp(100, 10000);
                                        } else {
                                          _fadeOutMs = 0;
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Fade Out', style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _fadeOutController,
                                enabled: _fadeOutMs > 0,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  suffixText: 's',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final secs = double.tryParse(val);
                                  if (secs != null && secs > 0) {
                                    setState(() => _fadeOutMs = (secs * 1000).toInt().clamp(100, 10000));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Banner ad
                    if (_isBannerLoaded && _bannerAd != null)
                      Container(
                        alignment: Alignment.center,
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      )
                    else
                      const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
