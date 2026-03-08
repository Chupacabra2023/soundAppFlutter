// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Soundboard Studio';

  @override
  String get settings => 'Настройки';

  @override
  String get addSound => 'Добавить звук';

  @override
  String get loop => 'Повтор';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get deleteMode => 'Режим удаления';

  @override
  String get cancelDeleteMode => 'Отменить режим удаления';

  @override
  String get searchSounds => 'Поиск звуков...';

  @override
  String get noSoundPlaying => 'Ничего не воспроизводится';

  @override
  String nowPlaying(String title) {
    return 'Играет: $title';
  }

  @override
  String get filter => 'Фильтр';

  @override
  String get search => 'Поиск';

  @override
  String soundsCount(int count) {
    return '$count звуков';
  }

  @override
  String get noSoundsFound => 'Звуки не найдены';

  @override
  String get tryChangingSearch => 'Попробуйте изменить поиск или категорию';

  @override
  String get restoringSound => 'Восстановление звуков...';

  @override
  String get pleaseWait => 'Пожалуйста, подождите';

  @override
  String get resetSounds => 'Сбросить звуки';

  @override
  String get resetSoundsDescription =>
      'Это удалит все текущие звуки и перезагрузит оригинальные звуки с их категориями.';

  @override
  String get resetToDefault => 'Сбросить до стандартных звуков';

  @override
  String get resetConfirmTitle => 'Сбросить звуки';

  @override
  String get resetConfirmMessage =>
      'Это удалит все текущие звуки и перезагрузит оригинальные звуки с их категориями.\n\nВы хотите продолжить?';

  @override
  String get cancel => 'Отмена';

  @override
  String get reset => 'Сбросить';

  @override
  String get manageCategories => 'Управление категориями';

  @override
  String get manageCategoriesDescription =>
      'Удалите категории, которые вам больше не нужны. Все звуки с этой категорией её потеряют.';

  @override
  String get deleteCategory => 'Удалить категорию';

  @override
  String deleteCategoryConfirm(String category) {
    return 'Вы уверены, что хотите удалить "$category"?\n\nВсе звуки с этой категорией её потеряют.';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get noCustomCategories => 'Пока нет пользовательских категорий';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите предпочитаемый язык';

  @override
  String get shufflePlay => 'Случайное воспроизведение';

  @override
  String get shufflePlayDescription => 'Воспроизводить случайные звуки непрерывно';

  @override
  String get everything => 'всё';

  @override
  String get favorite => 'избранное';
}
