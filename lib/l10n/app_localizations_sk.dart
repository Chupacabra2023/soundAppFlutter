// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Nastavenia';

  @override
  String get addSound => 'Pridať zvuk';

  @override
  String get loop => 'Opakovať';

  @override
  String get playbackSpeed => 'Rýchlosť prehrávania';

  @override
  String get deleteMode => 'Režim mazania';

  @override
  String get cancelDeleteMode => 'Zrušiť režim mazania';

  @override
  String get searchSounds => 'Hľadať zvuky...';

  @override
  String get noSoundPlaying => 'Žiadny zvuk sa neprehráva';

  @override
  String nowPlaying(String title) {
    return 'Práve hrá: $title';
  }

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Hľadať';

  @override
  String soundsCount(int count) {
    return '$count zvukov';
  }

  @override
  String get noSoundsFound => 'Nenašli sa žiadne zvuky';

  @override
  String get tryChangingSearch => 'Skúste zmeniť vyhľadávanie alebo kategóriu';

  @override
  String get restoringSound => 'Obnovujem zvuky...';

  @override
  String get pleaseWait => 'Prosím počkajte chvíľu';

  @override
  String get resetSounds => 'Resetovať zvuky';

  @override
  String get resetSoundsDescription =>
      'Toto vymaže všetky aktuálne zvuky a obnoví pôvodné zvuky s ich kategóriami.';

  @override
  String get resetToDefault => 'Resetovať na predvolené zvuky';

  @override
  String get resetConfirmTitle => 'Resetovať zvuky';

  @override
  String get resetConfirmMessage =>
      'Toto vymaže všetky aktuálne zvuky a obnoví pôvodné zvuky s ich kategóriami.\n\nChcete pokračovať?';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get reset => 'Resetovať';

  @override
  String get manageCategories => 'Spravovať kategórie';

  @override
  String get manageCategoriesDescription =>
      'Vymažte kategórie, ktoré už nepotrebujete. Všetky zvuky s touto kategóriou ju stratia.';

  @override
  String get deleteCategory => 'Vymazať kategóriu';

  @override
  String deleteCategoryConfirm(String category) {
    return 'Naozaj chcete vymazať \"$category\"?\n\nVšetky zvuky s touto kategóriou ju stratia.';
  }

  @override
  String get delete => 'Vymazať';

  @override
  String get noCustomCategories => 'Zatiaľ žiadne vlastné kategórie';

  @override
  String get language => 'Jazyk';

  @override
  String get selectLanguage => 'Vyberte si preferovaný jazyk';

  @override
  String get shufflePlay => 'Náhodné prehrávanie';

  @override
  String get shufflePlayDescription => 'Prehrávať náhodné zvuky nepretržite';

  @override
  String get everything => 'všetko';

  @override
  String get favorite => 'obľúbené';
}
