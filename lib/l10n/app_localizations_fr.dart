// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Paramètres';

  @override
  String get addSound => 'Ajouter un son';

  @override
  String get loop => 'Répéter';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get deleteMode => 'Mode suppression';

  @override
  String get cancelDeleteMode => 'Annuler le mode suppression';

  @override
  String get searchSounds => 'Rechercher des sons...';

  @override
  String get noSoundPlaying => 'Aucun son en cours';

  @override
  String nowPlaying(String title) {
    return 'En cours : $title';
  }

  @override
  String get filter => 'Filtrer';

  @override
  String get search => 'Rechercher';

  @override
  String soundsCount(int count) {
    return '$count sons';
  }

  @override
  String get noSoundsFound => 'Aucun son trouvé';

  @override
  String get tryChangingSearch => 'Essayez de modifier votre recherche ou catégorie';

  @override
  String get restoringSound => 'Restauration des sons...';

  @override
  String get pleaseWait => 'Veuillez patienter un moment';

  @override
  String get resetSounds => 'Réinitialiser les sons';

  @override
  String get resetSoundsDescription =>
      'Cela supprimera tous les sons actuels et rechargera les sons originaux avec leurs catégories.';

  @override
  String get resetToDefault => 'Réinitialiser aux sons par défaut';

  @override
  String get resetConfirmTitle => 'Réinitialiser les sons';

  @override
  String get resetConfirmMessage =>
      'Cela supprimera tous les sons actuels et rechargera les sons originaux avec leurs catégories.\n\nVoulez-vous continuer ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get manageCategories => 'Gérer les catégories';

  @override
  String get manageCategoriesDescription =>
      'Supprimez les catégories dont vous n\'avez plus besoin. Tous les sons de cette catégorie la perdront.';

  @override
  String get deleteCategory => 'Supprimer la catégorie';

  @override
  String deleteCategoryConfirm(String category) {
    return 'Êtes-vous sûr de vouloir supprimer \"$category\" ?\n\nTous les sons de cette catégorie la perdront.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get noCustomCategories => 'Aucune catégorie personnalisée pour l\'instant';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionnez votre langue préférée';

  @override
  String get shufflePlay => 'Lecture aléatoire';

  @override
  String get shufflePlayDescription => 'Lire des sons aléatoires en continu';

  @override
  String get everything => 'Tous';

  @override
  String get favorite => 'favori';
}
