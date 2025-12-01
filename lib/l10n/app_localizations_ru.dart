// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Главная';

  @override
  String get playersListTitle => 'Список игроков';

  @override
  String get gameTypesTitle => 'Типы игр';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String get newGame => 'Новая игра';

  @override
  String get noGames => 'Нет игр';

  @override
  String get noGamesOfThisType => 'Нет игр этого типа';

  @override
  String get createFirstGame => 'Создайте свою первую игру';

  @override
  String get createdOn => 'Создано';

  @override
  String get newWithSamePlayers => 'Новая с теми же игроками';

  @override
  String get newGameSuffix => '(новая)';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmDeletion => 'Подтвердите удаление';

  @override
  String confirmDeleteGame(String name) {
    return 'Вы действительно хотите удалить игру \"$name\"?';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get renameGame => 'Переименовать игру';

  @override
  String get gameName => 'Название игры';

  @override
  String get save => 'Сохранить';

  @override
  String get filterByGameType => 'Фильтр по типу игры';

  @override
  String get allGames => 'Все игры';

  @override
  String get filterGames => 'Фильтр игр';

  @override
  String get applyFilter => 'Применить';

  @override
  String get resetFilter => 'Сбросить';

  @override
  String get selectGameType => 'Выберите тип игры';

  @override
  String get gameType => 'Тип игры';

  @override
  String get loadingGameTypes => 'Загрузка типов игр...';

  @override
  String get winRule => 'Правило победы';

  @override
  String get lowestScoreWins => 'Выигрывает меньший счёт';

  @override
  String get highestScoreWins => 'Выигрывает больший счёт';

  @override
  String get lowestScoreExample => 'Напр: Гольф, Червы';

  @override
  String get highestScoreExample => 'Напр: Рамми, Бридж';

  @override
  String get players => 'Игроки';

  @override
  String get add => 'Добавить';

  @override
  String get pleaseEnterName => 'Пожалуйста, введите имя';

  @override
  String get atLeast2PlayersRequired => 'Требуется минимум 2 игрока';

  @override
  String playerNumber(int index) {
    return 'Игрок $index';
  }

  @override
  String get selectPlayer => 'Выберите игрока...';

  @override
  String get clear => 'Очистить';

  @override
  String get remove => 'Удалить';

  @override
  String get createGame => 'Создать игру';

  @override
  String get game => 'Игра';

  @override
  String get editGame => 'Редактировать игру';

  @override
  String get editGameDialogTitle => 'Редактировать игру';

  @override
  String get gameSettings => 'Настройки игры';

  @override
  String get removePlayer => 'Удалить игрока';

  @override
  String get addPlayerToGame => 'Добавить игрока';

  @override
  String get warningRemovePlayer =>
      'Внимание! Удаление этого игрока удалит все его очки из этой игры. Это действие необратимо.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Вы действительно хотите удалить $playerName из этой игры?';
  }

  @override
  String get playerRemoved => 'Игрок удален из игры';

  @override
  String get deleteLastRound => 'Удалить последний раунд';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get confirmDeleteLastRound => 'Удалить последний раунд?';

  @override
  String get noPlayersInGame => 'В этой игре нет игроков';

  @override
  String get round => 'Раунд';

  @override
  String get addRound => 'Добавить раунд';

  @override
  String get score => 'Счёт';

  @override
  String get enterScore => 'Введите счёт';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get system => 'Системная';

  @override
  String get screen => 'Экран';

  @override
  String get keepScreenAwake => 'Не выключать экран';

  @override
  String get keepScreenAwakeDescription =>
      'Предотвращает выключение экрана во время игры';

  @override
  String get backup => 'Резервная копия';

  @override
  String get exportDatabase => 'Экспорт базы данных';

  @override
  String get exportDatabaseDescription => 'Сохраните все ваши игры в файл';

  @override
  String get databaseExportedTo => 'База данных экспортирована в:';

  @override
  String get errorDuringExport => 'Ошибка при экспорте:';

  @override
  String get importDatabase => 'Импорт базы данных';

  @override
  String get importDatabaseDescription =>
      'Восстановите ваши игры из файла резервной копии';

  @override
  String get confirmation => 'Подтверждение';

  @override
  String get importWarning =>
      'Импорт заменит все ваши текущие данные. Автоматическая резервная копия будет создана перед импортом.\n\nПродолжить?';

  @override
  String get import => 'Импортировать';

  @override
  String get databaseImportedSuccessfully =>
      'База данных успешно импортирована';

  @override
  String get importSuccessful => 'Импорт выполнен';

  @override
  String get importSuccessMessage =>
      'База данных была успешно импортирована.\n\nПриложение сейчас закроется. Пожалуйста, откройте его снова, чтобы увидеть новые данные.';

  @override
  String get ok => 'ОК';

  @override
  String get errorDuringImport => 'Ошибка при импорте:';

  @override
  String get noPlayers => 'Нет игроков';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count игроков: $names',
      few: '$count игрока: $names',
      one: '1 игрок: $names',
      zero: 'Нет игроков',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Игроки появятся здесь, когда\nвы создадите игры';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count игр',
      few: '$count игры',
      one: '1 игра',
      zero: '0 игр',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count побед',
      few: '$count победы',
      one: '1 победа',
      zero: '0 побед',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Изменить цвет';

  @override
  String get renamePlayer => 'Переименовать игрока';

  @override
  String get newName => 'Новое имя';

  @override
  String playerRenamedTo(String name) {
    return 'Игрок переименован в \"$name\"';
  }

  @override
  String get deletePlayer => 'Удалить игрока';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Вы действительно хотите удалить \"$name\"?\n\nЭтот игрок будет удалён из всех $count игр(ы).';
  }

  @override
  String playerDeleted(String name) {
    return 'Игрок \"$name\" удалён';
  }

  @override
  String get chooseColor => 'Выберите цвет';

  @override
  String get noGameTypes => 'Нет типов игр';

  @override
  String get predefined => 'По умолчанию';

  @override
  String get edit => 'Редактировать';

  @override
  String get newType => 'Новый тип';

  @override
  String get editType => 'Редактировать тип';

  @override
  String get newGameType => 'Новый тип игры';

  @override
  String get gameTypeName => 'Название типа игры';

  @override
  String get icon => 'Значок:';

  @override
  String get color => 'Цвет:';

  @override
  String get chooseIcon => 'Выберите значок';

  @override
  String get nameIsRequired => 'Необходимо ввести название';

  @override
  String get create => 'Создать';

  @override
  String get ranking => 'Рейтинг';

  @override
  String get noCurrentGame => 'Нет текущей игры';

  @override
  String get noScoresRecorded => 'Нет записанных результатов';

  @override
  String get playerStatistics => 'Статистика игрока';

  @override
  String get noStatisticsAvailable => 'Статистика недоступна';

  @override
  String get gamesPlayed => 'Сыграно игр';

  @override
  String get wins => 'Победы';

  @override
  String get winRate => 'Процент побед';

  @override
  String get overallStatistics => 'Общая статистика';

  @override
  String get byGameType => 'По типу игры';

  @override
  String get rate => 'Процент';

  @override
  String get version => 'Версия 1.0.0';

  @override
  String get appDescription =>
      'Приложение для управления счётом ваших игровых сессий от Vincent Moreau';

  @override
  String get features => 'Возможности';

  @override
  String get featureDifferentGameTypes => 'Разные типы игр';

  @override
  String get featurePlayerManagement => 'Управление игроками';

  @override
  String get featureDetailedStatistics => 'Подробная статистика';

  @override
  String get featureCustomization => 'Настройка';

  @override
  String get featureDarkLightTheme => 'Тёмная/светлая тема';

  @override
  String get credits => 'Авторы';

  @override
  String get appIconCredit => 'Значок приложения';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Выберите игрока';

  @override
  String get search => 'Поиск';

  @override
  String get searchOrCreate => 'Искать / Создать';

  @override
  String get createNewPlayer => 'Создать нового игрока';

  @override
  String get newPlayerName => 'Имя нового игрока';

  @override
  String get noPlayersFound => 'Игроки не найдены';

  @override
  String get allPlayersSelected => 'Все игроки выбраны';

  @override
  String get close => 'Закрыть';

  @override
  String get playerEliminationCondition => 'Player Elimination Condition';

  @override
  String get gameOverCondition => 'Game Over Condition';

  @override
  String get none => 'None';

  @override
  String get overThreshold => 'Over threshold';

  @override
  String get underThreshold => 'Under threshold';

  @override
  String get firstPlayerOver => 'First player over';

  @override
  String get firstPlayerUnder => 'First player under';

  @override
  String get lastPlayerOver => 'Last player over';

  @override
  String get lastPlayerUnder => 'Last player under';

  @override
  String get threshold => 'Threshold';

  @override
  String get conditionType => 'Condition Type';

  @override
  String get gameOverTitle => 'Game Over!';

  @override
  String get gameOverMessage => 'Game over condition reached. End game now?';

  @override
  String get continuePlay => 'Continue Playing';

  @override
  String get endGame => 'End Game';
}
