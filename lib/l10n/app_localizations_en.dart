// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Settings';

  @override
  String get addSound => 'Add Sound';

  @override
  String get loop => 'Loop';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get deleteMode => 'Delete mode';

  @override
  String get cancelDeleteMode => 'Cancel delete mode';

  @override
  String get searchSounds => 'Search sounds...';

  @override
  String get noSoundPlaying => 'No sound playing';

  @override
  String nowPlaying(String title) {
    return 'Now playing: $title';
  }

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String soundsCount(int count) {
    return '$count sounds';
  }

  @override
  String get noSoundsFound => 'No sounds found';

  @override
  String get tryChangingSearch => 'Try changing your search or category';

  @override
  String get restoringSound => 'Restoring sounds...';

  @override
  String get pleaseWait => 'Please wait a moment';

  @override
  String get resetSounds => 'Reset Sounds';

  @override
  String get resetSoundsDescription =>
      'This will delete all current sounds and reload the original sounds with their categories.';

  @override
  String get resetToDefault => 'Reset to default sounds';

  @override
  String get resetConfirmTitle => 'Reset sounds';

  @override
  String get resetConfirmMessage =>
      'This will delete all current sounds and reload the original sounds with their categories.\n\nDo you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get manageCategoriesDescription =>
      'Delete categories that you no longer need. All sounds with this category will lose it.';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String deleteCategoryConfirm(String category) {
    return 'Are you sure you want to delete \"$category\"?\n\nAll sounds with this category will lose it.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get noCustomCategories => 'No custom categories yet';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get shufflePlay => 'Shuffle Play';

  @override
  String get shufflePlayDescription => 'Play random sounds continuously';

  @override
  String get everything => 'everything';

  @override
  String get favorite => 'favorite';
}
