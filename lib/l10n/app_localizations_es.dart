// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Configuración';

  @override
  String get addSound => 'Agregar sonido';

  @override
  String get loop => 'Repetir';

  @override
  String get playbackSpeed => 'Velocidad de reproducción';

  @override
  String get deleteMode => 'Modo de eliminación';

  @override
  String get cancelDeleteMode => 'Cancelar modo de eliminación';

  @override
  String get searchSounds => 'Buscar sonidos...';

  @override
  String get noSoundPlaying => 'No hay sonido reproduciéndose';

  @override
  String nowPlaying(String title) {
    return 'Reproduciendo: $title';
  }

  @override
  String get filter => 'Filtro';

  @override
  String get search => 'Buscar';

  @override
  String soundsCount(int count) {
    return '$count sonidos';
  }

  @override
  String get noSoundsFound => 'No se encontraron sonidos';

  @override
  String get tryChangingSearch => 'Intenta cambiar tu búsqueda o categoría';

  @override
  String get restoringSound => 'Restaurando sonidos...';

  @override
  String get pleaseWait => 'Por favor espera un momento';

  @override
  String get resetSounds => 'Restablecer sonidos';

  @override
  String get resetSoundsDescription =>
      'Esto eliminará todos los sonidos actuales y recargará los sonidos originales con sus categorías.';

  @override
  String get resetToDefault => 'Restablecer a sonidos predeterminados';

  @override
  String get resetConfirmTitle => 'Restablecer sonidos';

  @override
  String get resetConfirmMessage =>
      'Esto eliminará todos los sonidos actuales y recargará los sonidos originales con sus categorías.\n\n¿Deseas continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get reset => 'Restablecer';

  @override
  String get manageCategories => 'Gestionar categorías';

  @override
  String get manageCategoriesDescription =>
      'Elimina las categorías que ya no necesites. Todos los sonidos con esta categoría la perderán.';

  @override
  String get deleteCategory => 'Eliminar categoría';

  @override
  String deleteCategoryConfirm(String category) {
    return '¿Estás seguro de que deseas eliminar \"$category\"?\n\nTodos los sonidos con esta categoría la perderán.';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get noCustomCategories => 'Aún no hay categorías personalizadas';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecciona tu idioma preferido';

  @override
  String get shufflePlay => 'Reproducción aleatoria';

  @override
  String get shufflePlayDescription =>
      'Reproducir sonidos aleatorios continuamente';

  @override
  String get everything => 'todo';

  @override
  String get favorite => 'favorito';
}
