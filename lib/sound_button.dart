import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  final Function(String, List<String>, Color) onUpdate;
  final VoidCallback onToggleFavorite;
  final Color buttonColor;
  final bool isPlaying; // Nový parameter - či sa tento zvuk práve prehráva

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
    this.isPlaying = false, // Default: nie je playing
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  // ⚡ Optimalizácia - len displayName a color v state, ostatné lazy load
  late String _currentDisplayName;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _currentDisplayName = widget.displayName;
    _selectedColor = widget.buttonColor;
  }

  void _openSettings() {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: _currentDisplayName);
    // ⚡ Vytvor kategórie až TU, nie v initState!
    List<String> tempSelectedCategories = List.from(widget.categories);
    List<String> tempAvailableCategories = List.from(widget.allCategories);
    // Lokálne kópie pre modal - zmeny sa prejavia až po Save
    String tempDisplayName = _currentDisplayName;
    Color tempSelectedColor = _selectedColor;

    // Lazy-loaded reklama - načíta sa až teraz
    BannerAd? dialogBannerAd;
    bool isBannerLoaded = false;

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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                // Načítaj reklamu len raz pri prvom builde
                if (dialogBannerAd == null) {
                  dialogBannerAd = BannerAd(
                    adUnitId: 'ca-app-pub-3948591512361475/4467483687',
                    size: AdSize.banner,
                    request: const AdRequest(),
                    listener: BannerAdListener(
                      onAdLoaded: (ad) {
                        setModalState(() {
                          isBannerLoaded = true;
                        });
                      },
                      onAdFailedToLoad: (ad, error) {
                        ad.dispose();
                      },
                    ),
                  );
                  dialogBannerAd!.load();
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: nameController,
                          maxLength: 30,
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
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                selectedColor: Colors.blueGrey[700],
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                                backgroundColor: Colors.grey[200],
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

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kColorPalette.map((color) {
                            final isSelected =
                                tempSelectedColor.toARGB32() == color.toARGB32();
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  tempSelectedColor = color;
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

                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            // ✅ Teraz nastav skutočné state premenné (len displayName a color)
                            setState(() {
                              _currentDisplayName = tempDisplayName;
                              _selectedColor = tempSelectedColor;
                            });

                            // Pošli update do parent widgetu
                            widget.onUpdate(
                              tempDisplayName,
                              tempSelectedCategories,
                              tempSelectedColor,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(l10n.get('save')),
                        ),

                        // Banner Ad pod Save button - lazy loaded
                        const SizedBox(height: 16),
                        if (isBannerLoaded && dialogBannerAd != null)
                          Container(
                            alignment: Alignment.center,
                            width: dialogBannerAd!.size.width.toDouble(),
                            height: dialogBannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: dialogBannerAd!),
                          )
                        else
                          Container(
                            alignment: Alignment.center,
                            height: 50,
                            child: const CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Uvoľni reklamu keď sa dialóg zatvorí
      dialogBannerAd?.dispose();
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
        ),
        child: Column(
          children: [

            Expanded(
              flex: 75, // Zmenšené z 80, aby bol spodný panel väčší
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


