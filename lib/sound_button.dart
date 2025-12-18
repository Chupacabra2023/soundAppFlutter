import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'sound_data.dart';

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
  late String _currentDisplayName;
  late List<String> _selectedCategories;
  late Color _selectedColor;
  late List<String> _availableCategories;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentDisplayName = widget.displayName;
    _selectedCategories = List.from(widget.categories);
    _selectedColor = widget.buttonColor;
    _availableCategories = List.from(widget.allCategories);
  }

  @override
  void didUpdateWidget(SoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aktualizuj dostupné kategórie keď sa zmenia v parent widgete
    if (widget.allCategories != oldWidget.allCategories) {
      setState(() {
        _availableCategories = List.from(widget.allCategories);
        // Odstráň vymazané kategórie zo selected categories
        _selectedCategories.removeWhere((cat) => !widget.allCategories.contains(cat));
      });
    }
  }

  void _loadBannerAd({VoidCallback? onLoaded}) {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // TEST AD
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _openSettings() {
    final nameController = TextEditingController(text: _currentDisplayName);
    // Lokálne kópie pre modal - zmeny sa prejavia až po Save
    String tempDisplayName = _currentDisplayName;
    List<String> tempSelectedCategories = List.from(_selectedCategories);
    Color tempSelectedColor = _selectedColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setModalState) {
              // Načítaj reklamu len raz
              if (_bannerAd == null && !_isBannerAdLoaded) {
                _loadBannerAd(onLoaded: () {
                  setModalState(() {});
                });
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
                          onChanged: (value) {
                            // Len ulož do lokálnej premennej, NEupdatuj _currentDisplayName
                            tempDisplayName = value;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Sound name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ..._availableCategories
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
                              label: const Text('Add'),
                              onPressed: () async {
                                final controller = TextEditingController();
                                final newCategory = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('New category'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter category name',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final value =
                                            controller.text.trim();
                                            if (value.isNotEmpty) {
                                              Navigator.pop(context, value);
                                            }
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (newCategory != null &&
                                    newCategory.isNotEmpty &&
                                    !_availableCategories.contains(newCategory)) {
                                  setModalState(() {

                                    _availableCategories.add(newCategory);

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
                          'Button color',
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
                            // ✅ Teraz nastav skutočné state premenné
                            setState(() {
                              _currentDisplayName = tempDisplayName;
                              _selectedCategories = tempSelectedCategories;
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
                          child: const Text('Save'),
                        ),

                        // Banner Ad
                        if (_isBannerAdLoaded && _bannerAd != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            alignment: Alignment.center,
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
                          fontSize: 16,
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
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: Colors.white, size: 16),
                      onPressed: _openSettings,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isFavorite ? Icons.star : Icons.star_border,
                        color: widget.isFavorite ? Colors.yellow : Colors.white,
                        size: 16,
                      ),
                      onPressed: widget.onToggleFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
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


