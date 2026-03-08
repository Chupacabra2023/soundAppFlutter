// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Einstellungen';

  @override
  String get addSound => 'Sound hinzufügen';

  @override
  String get loop => 'Wiederholen';

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get deleteMode => 'Löschmodus';

  @override
  String get cancelDeleteMode => 'Löschmodus beenden';

  @override
  String get searchSounds => 'Sounds suchen...';

  @override
  String get noSoundPlaying => 'Kein Sound wird abgespielt';

  @override
  String nowPlaying(String title) {
    return 'Läuft: $title';
  }

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Suchen';

  @override
  String soundsCount(int count) {
    return '$count Sounds';
  }

  @override
  String get noSoundsFound => 'Keine Sounds gefunden';

  @override
  String get tryChangingSearch => 'Versuche, deine Suche oder Kategorie zu ändern';

  @override
  String get restoringSound => 'Sounds werden wiederhergestellt...';

  @override
  String get pleaseWait => 'Bitte einen Moment warten';

  @override
  String get resetSounds => 'Sounds zurücksetzen';

  @override
  String get resetSoundsDescription =>
      'Dies löscht alle aktuellen Sounds und lädt die Original-Sounds mit ihren Kategorien neu.';

  @override
  String get resetToDefault => 'Auf Standard-Sounds zurücksetzen';

  @override
  String get resetConfirmTitle => 'Sounds zurücksetzen';

  @override
  String get resetConfirmMessage =>
      'Dies löscht alle aktuellen Sounds und lädt die Original-Sounds mit ihren Kategorien neu.\n\nMöchtest du fortfahren?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get manageCategories => 'Kategorien verwalten';

  @override
  String get manageCategoriesDescription =>
      'Lösche Kategorien, die du nicht mehr benötigst. Alle Sounds mit dieser Kategorie verlieren sie.';

  @override
  String get deleteCategory => 'Kategorie löschen';

  @override
  String deleteCategoryConfirm(String category) {
    return 'Bist du sicher, dass du "$category" löschen möchtest?\n\nAlle Sounds mit dieser Kategorie verlieren sie.';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get noCustomCategories => 'Noch keine eigenen Kategorien';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Wähle deine bevorzugte Sprache';

  @override
  String get shufflePlay => 'Zufallswiedergabe';

  @override
  String get shufflePlayDescription => 'Zufällige Sounds kontinuierlich abspielen';

  @override
  String get everything => 'alles';

  @override
  String get favorite => 'favorit';
}
