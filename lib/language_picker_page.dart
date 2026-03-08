import 'package:flutter/material.dart';

class LanguagePickerPage extends StatelessWidget {
  final Function(Locale) onLanguageSelected;

  const LanguagePickerPage({super.key, required this.onLanguageSelected});

  static const _languages = [
    ('🇬🇧', 'en'),
    ('🇸🇰', 'sk'),
    ('🇪🇸', 'es'),
    ('🇫🇷', 'fr'),
    ('🇩🇪', 'de'),
    ('🇷🇺', 'ru'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238), // blueGrey[900]
      body: Center(
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: _languages.map((lang) {
            final flag = lang.$1;
            final code = lang.$2;
            return GestureDetector(
              onTap: () => onLanguageSelected(Locale(code)),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF37474F), // blueGrey[800]
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
