import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'sound_data.dart';
import 'app_localizations.dart';

// ⚡ Globálne konštanty pre performance
const _kButtonBorderRadius = BorderRadius.all(Radius.circular(12));
const _kBottomBorderRadius = BorderRadius.vertical(bottom: Radius.circular(12));
const _kButtonShadow = [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))];
const _kIconConstraints = BoxConstraints(minWidth: 24, minHeight: 24);
const _kIconPadding = EdgeInsets.zero;
const _kBottomPadding = EdgeInsets.symmetric(horizontal: 4);

class SoundButton extends StatefulWidget {
  final String soundName;
  final String displayName;
  final List<String> categories;
  final bool isFavorite;
  final List<String> allCategories;
  final VoidCallback onPressed;
  final Function(String, List<String>, Color, int, int?, double) onUpdate;
  final VoidCallback onToggleFavorite;
  final Color buttonColor;   // display farba (môže byť červená v delete móde)
  final Color savedColor;    // skutočná uložená farba (vždy správna)
  final bool isDeleteMode;
  final bool isPlaying;
  final int startMs;
  final int? endMs;
  final double volume;
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

  Future<int?> _fetchDurationMs() async {
    final probePlayer = AudioPlayer();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${widget.soundName}';
      if (!await File(filePath).exists()) return null;
      await probePlayer.setSource(DeviceFileSource(filePath));
      final duration = await probePlayer.getDuration();
      return duration?.inMilliseconds;
    } catch (e) {
      return null;
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

  void _openSettings() {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: _currentDisplayName);
    List<String> tempSelectedCategories = List.from(widget.categories);
    List<String> tempAvailableCategories = List.from(widget.allCategories);
    String tempDisplayName = _currentDisplayName;
    Color tempSelectedColor = widget.savedColor;

    // Volume state
    double tempVolume = widget.volume;

    // Trim state
    int tempStartMs = widget.startMs;
    int? tempEndMs = widget.endMs;
    int dialogTotalDurationMs = 0;
    bool isDurationLoading = true;
    StateSetter? dialogSetState;

    // BannerAd? dialogBannerAd;
    // bool isBannerLoaded = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (buildContext) {
        return Dialog(
          alignment: Alignment.bottomCenter,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                dialogSetState = setModalState;

                // Fetch duration once on first build
                if (isDurationLoading && dialogTotalDurationMs == 0) {
                  _fetchDurationMs().then((durationMs) {
                    if (durationMs != null && durationMs > 0 && dialogSetState != null) {
                      dialogSetState!(() {
                        dialogTotalDurationMs = durationMs;
                        isDurationLoading = false;
                        tempEndMs ??= durationMs;
                      });
                    } else {
                      dialogSetState!(() {
                        isDurationLoading = false;
                      });
                    }
                  });
                }

                // // Načítaj reklamu len raz pri prvom builde
                // if (dialogBannerAd == null) {
                //   dialogBannerAd = BannerAd(
                //     adUnitId: 'ca-app-pub-3948591512361475/4467483687',
                //     size: AdSize.banner,
                //     request: const AdRequest(),
                //     listener: BannerAdListener(
                //       onAdLoaded: (ad) {
                //         setModalState(() {
                //           isBannerLoaded = true;
                //         });
                //       },
                //       onAdFailedToLoad: (ad, error) {
                //         ad.dispose();
                //       },
                //     ),
                //   );
                //   dialogBannerAd!.load();
                // }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              _currentDisplayName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.white),
                            onPressed: () {
                              final finalName = tempDisplayName.trim().isEmpty
                                  ? _currentDisplayName
                                  : tempDisplayName.trim();

                              setState(() {
                                _currentDisplayName = finalName;
                                nameController.text = finalName;
                              });

                              final int? finalEndMs = (dialogTotalDurationMs > 0 && tempEndMs == dialogTotalDurationMs)
                                  ? null
                                  : tempEndMs;

                              widget.onUpdate(
                                finalName,
                                tempSelectedCategories,
                                tempSelectedColor,
                                tempStartMs,
                                finalEndMs,
                                tempVolume,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          maxLength: 50,
                          onChanged: (value) {
                            // Len ulož do lokálnej premennej, NEupdatuj _currentDisplayName
                            tempDisplayName = value;
                          },
                          decoration: InputDecoration(
                            labelText: l10n.get('soundName'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          l10n.get('categories'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...tempAvailableCategories
                                .where((c) => c.toLowerCase() != 'everything')
                                .map((category) {
                              final isSelected =
                              tempSelectedCategories.contains(category);
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                selectedColor: Colors.blueGrey[700],
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                ),
                                backgroundColor: isDark ? Colors.blueGrey[700] : Colors.grey[200],
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      tempSelectedCategories.add(category);
                                    } else {
                                      tempSelectedCategories.remove(category);
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
                                  builder: (context) {
                                    return AlertDialog(
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
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(l10n.get('cancel')),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final value =
                                            controller.text.trim();
                                            if (value.isNotEmpty) {
                                              Navigator.pop(context, value);
                                            }
                                          },
                                          child: Text(l10n.get('add')),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (newCategory != null &&
                                    newCategory.isNotEmpty &&
                                    !tempAvailableCategories.contains(newCategory)) {
                                  setModalState(() {

                                    tempAvailableCategories.add(newCategory);

                                    if (!tempSelectedCategories.contains(newCategory)) {
                                      tempSelectedCategories.add(newCategory);
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Text(
                          l10n.get('buttonColor'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        GridView.count(
                          crossAxisCount: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          children: kColorPalette.map((color) {
                            final isSelected = tempSelectedColor.toARGB32() == color.toARGB32();
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  tempSelectedColor = color;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.transparent,
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

                        const SizedBox(height: 20),
                        Text(
                          l10n.get('trimSound'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (isDurationLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                l10n.get('trimLoading'),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                          )
                        else if (dialogTotalDurationMs > 0)
                          Column(
                            children: [
                              RangeSlider(
                                values: RangeValues(
                                  tempStartMs.toDouble().clamp(0, dialogTotalDurationMs.toDouble()),
                                  (tempEndMs ?? dialogTotalDurationMs).toDouble().clamp(0, dialogTotalDurationMs.toDouble()),
                                ),
                                min: 0,
                                max: dialogTotalDurationMs.toDouble(),
                                activeColor: Colors.blueGrey[700],
                                inactiveColor: Colors.grey[300],
                                onChanged: (RangeValues values) {
                                  setModalState(() {
                                    tempStartMs = values.start.toInt();
                                    tempEndMs = values.end.toInt();
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatMs(tempStartMs), style: const TextStyle(fontSize: 12)),
                                    Text(_formatMs(dialogTotalDurationMs), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text(_formatMs(tempEndMs ?? dialogTotalDurationMs), style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),
                        Text(
                          '🔊 ${l10n.get('volume')}: ${(tempVolume * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: tempVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          activeColor: Colors.blueGrey[700],
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            setModalState(() {
                              tempVolume = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                        // if (isBannerLoaded && dialogBannerAd != null)
                        //   Container(
                        //     alignment: Alignment.center,
                        //     width: dialogBannerAd!.size.width.toDouble(),
                        //     height: dialogBannerAd!.size.height.toDouble(),
                        //     child: AdWidget(ad: dialogBannerAd!),
                        //   )
                        // else
                        //   Container(
                        //     alignment: Alignment.center,
                        //     height: 50,
                        //     child: const CircularProgressIndicator(),
                        //   ),
                      ],
                    ),
                  ),
                ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Uvoľni reklamu keď sa dialóg zatvorí
      // dialogBannerAd?.dispose();
    });
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
                          Icon(
                            Icons.stop,
                            size: 40, // Zmenšené z 48 na 40 kvôli overflow
                            color: Colors.white,
                          ),
                          SizedBox(height: 2), // Zmenšené z 4 na 2
                          Text(
                            'STOP',
                            style: TextStyle(
                              fontSize: 12, // Zmenšené z 14 na 12
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
              flex: 25, // Zväčšené z 20 na 25 (o trochu väčší spodný panel)
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF546E7A), // Colors.blueGrey.shade800 ako const
                  borderRadius: _kBottomBorderRadius,
                ),
                padding: _kBottomPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: Colors.white, size: 16),
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

  @override
  void dispose() {
    super.dispose();
  }
}


