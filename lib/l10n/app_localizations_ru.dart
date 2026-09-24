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
  String get newWithSamePlayers => 'Новая с теми же игроками';

  @override
  String get playAgain => 'Играть снова';

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
  String get lowestScoreWins => 'Выигрывает меньший счёт';

  @override
  String get highestScoreWins => 'Выигрывает больший счёт';

  @override
  String get players => 'Игроки';

  @override
  String get add => 'Добавить';

  @override
  String get pleaseEnterName => 'Пожалуйста, введите имя';

  @override
  String get clear => 'Очистить';

  @override
  String get remove => 'Удалить';

  @override
  String get game => 'Игра';

  @override
  String get editGame => 'Редактировать игру';

  @override
  String get editGameDialogTitle => 'Редактировать игру';

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
  String boardRoundButton(int round) {
    return 'Раунд $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · раунд $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · раунд $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'итого после: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Далее\n$player';
  }

  @override
  String get keypadValidateRound => 'Подтвердить раунд';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => 'Сменить знак';

  @override
  String get keypadBackspace => 'Стереть цифру';

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
  String get byGameType => 'По типу игры';

  @override
  String get rate => 'Процент';

  @override
  String version(String version) {
    return 'Версия $version';
  }

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
  String get featureGroupSharing => 'Совместный доступ в группах';

  @override
  String get featureGameAnalysis => 'Анализ партий с ИИ';

  @override
  String get rateApp => 'Оценить CountScore';

  @override
  String get search => 'Поиск';

  @override
  String get newPlayerName => 'Имя нового игрока';

  @override
  String get noPlayersFound => 'Игроки не найдены';

  @override
  String get close => 'Закрыть';

  @override
  String get playerEliminationCondition => 'Условие выбывания игрока';

  @override
  String get gameOverCondition => 'Условие окончания игры';

  @override
  String get none => 'Нет';

  @override
  String get overThreshold => 'Выше порога';

  @override
  String get underThreshold => 'Ниже порога';

  @override
  String get firstPlayerOver => 'Первый игрок достигает';

  @override
  String get firstPlayerUnder => 'Первый игрок ниже';

  @override
  String get lastPlayerOver => 'Последний игрок в игре (остальные выше)';

  @override
  String get lastPlayerUnder => 'Последний игрок в игре (остальные ниже)';

  @override
  String get threshold => 'Порог';

  @override
  String get conditionType => 'Тип условия';

  @override
  String get continuePlay => 'Продолжить игру';

  @override
  String gameEndWinner(String name) {
    return 'Побеждает $name';
  }

  @override
  String gameEndTie(String names) {
    return 'Ничья: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раунда',
      many: '$count раундов',
      few: '$count раунда',
      one: '$count раунд',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'побеждает наименьший счёт';

  @override
  String get gameEndHighestWins => 'побеждает наибольший счёт';

  @override
  String get gameEndAnalysis => 'Анализ';

  @override
  String get gameEndResults => 'Итоги';

  @override
  String get rankingEliminationNote =>
      'Места — по порядку выбывания: кто выбыл позже, тот идёт впереди остальных, независимо от счёта.';

  @override
  String get endGame => 'Завершить игру';

  @override
  String get reopenGame => 'Возобновить игру';

  @override
  String get gameFinished => 'Завершена';

  @override
  String get undo => 'Отменить';

  @override
  String get gameReopened => 'Игра возобновлена';

  @override
  String get comment => 'Комментарий';

  @override
  String get enterComment => 'Введите комментарий';

  @override
  String get analyzeGame => 'Анализировать игру';

  @override
  String get analysisTitle => 'Анализ игры';

  @override
  String get analysisStyle => 'Стиль анализа';

  @override
  String get analysisStyleProfessor => 'Профессор';

  @override
  String get analysisStyleCommentator => 'Спортивный комментатор';

  @override
  String get analysisStyleDocumentary => 'Фильм о дикой природе';

  @override
  String get analysisStyleNoir => 'Детектив';

  @override
  String get analysisStyleBard => 'Бард';

  @override
  String get analysisStyleCoach => 'Тренер';

  @override
  String get analysisStyleConsultant => 'Консультант';

  @override
  String get analysisStyleAstrologer => 'Астролог';

  @override
  String get analysisStyleRealityTv => 'Реалити-шоу';

  @override
  String get generatingAnalysis => 'Создание анализа…';

  @override
  String get generateAnalysis => 'Создать анализ';

  @override
  String get regenerateAnalysis => 'Пересоздать анализ';

  @override
  String get deleteAnalysis => 'Удалить анализ';

  @override
  String get confirmRegenerateAnalysis =>
      'Пересоздать? Текущий анализ будет заменён.';

  @override
  String get confirmDeleteAnalysis => 'Удалить анализ этой игры?';

  @override
  String get analysisError => 'Не удалось создать анализ';

  @override
  String get analysisErrorUnavailable =>
      'Сервер анализа временно недоступен. Повторите попытку позже.';

  @override
  String get analysisErrorGroupBudget =>
      'Ваша группа исчерпала бюджет анализов на этот месяц. Он обновится в начале следующего месяца.';

  @override
  String get analysisStyleGroupDefault =>
      'Стиль не выбран: эта общая партия будет проанализирована в стиле и на языке группы.';

  @override
  String analysisErrorStatus(int status) {
    return 'Не удалось создать анализ (HTTP $status)';
  }

  @override
  String get retry => 'Повторить';

  @override
  String analysisGeneratedAt(String date) {
    return 'Создано $date';
  }

  @override
  String get serverSection => 'Сервер';

  @override
  String get backendUrlLabel => 'Адрес сервера';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Сетевые функции требуют сервера CountScore. Установите его из папки backend/ и укажите здесь его адрес. Без сервера никакие данные не покидают это устройство.';

  @override
  String get backendNotConfigured => 'Сервер не настроен';

  @override
  String get backendUrlInvalid =>
      'Неверный адрес. Введите полный URL, например https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// допускается только в локальной сети. Для публичного сервера используйте https://.';

  @override
  String get testConnection => 'Проверить соединение';

  @override
  String get connectionOk => 'Сервер отвечает';

  @override
  String get connectionFailed => 'Сервер не отвечает';

  @override
  String get serverUrlSaved => 'Сервер сохранён';

  @override
  String get analysisRequiresBackend =>
      'Для этого анализа нужен сервер. Настройте его в настройках.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get serverUrlCleared => 'Сервер удалён';

  @override
  String get groupSection => 'Группа';

  @override
  String get groupDescription =>
      'Делитесь партиями с другими устройствами группы. Общие партии, их игроки, очки, комментарии и анализы отправляются на ваш сервер; остальные партии остаются на этом устройстве.';

  @override
  String get groupNeedsServer => 'Сначала укажите сервер выше.';

  @override
  String get groupCreate => 'Создать группу';

  @override
  String get groupJoin => 'Присоединиться к группе';

  @override
  String get groupNameLabel => 'Название группы';

  @override
  String get groupNicknameLabel => 'Ваш псевдоним';

  @override
  String get groupNicknameHint => 'Его увидят другие участники группы';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Ваш псевдоним: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Изменить псевдоним';

  @override
  String get shareTokenLabel => 'Код приглашения';

  @override
  String get shareTokenHint => 'Вставьте код, присланный участником группы';

  @override
  String groupCurrent(String name) {
    return 'Группа: $name';
  }

  @override
  String get shareTokenExplain =>
      'Отправьте этот код устройствам, которые должны присоединиться. Любой, у кого он есть, может войти в группу.';

  @override
  String get shareTokenCopy => 'Скопировать код';

  @override
  String get shareTokenCopied => 'Код скопирован';

  @override
  String get shareTokenRotate => 'Новый код';

  @override
  String get shareTokenRotateConfirm =>
      'По старому коду больше нельзя будет присоединиться. Устройства, уже состоящие в группе, это не затронет.';

  @override
  String get groupLeave => 'Покинуть группу';

  @override
  String get groupLeaveConfirm =>
      'Это устройство покинет группу. Общие партии останутся на нём, но больше не будут синхронизироваться.';

  @override
  String get groupLeft => 'Вы покинули группу';

  @override
  String get groupJoined => 'Вы в группе';

  @override
  String get clearServerLeavesGroup =>
      'Если удалить сервер, устройство покинет группу. Общие партии останутся на нём.';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String syncStatusIdle(String time) {
    return 'Синхронизировано в $time';
  }

  @override
  String get syncStatusSyncing => 'Синхронизация…';

  @override
  String get syncStatusOffline =>
      'Сервер недоступен — изменения будут отправлены позже';

  @override
  String get syncStatusUnauthorized =>
      'Сервер больше не принимает это устройство. Покиньте группу и присоединитесь снова.';

  @override
  String get syncStatusError => 'Ошибка сервера при синхронизации';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения ожидают',
      many: '$count изменений ожидают',
      few: '$count изменения ожидают',
      one: '$count изменение ожидает',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения отклонены сервером',
      many: '$count изменений отклонено сервером',
      few: '$count изменения отклонены сервером',
      one: '$count изменение отклонено сервером',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Неизвестный или заменённый код приглашения';

  @override
  String get groupErrorRateLimited =>
      'Слишком много попыток. Повторите через минуту.';

  @override
  String get groupErrorUnreachable => 'Сервер недоступен';

  @override
  String get groupErrorServer => 'Ошибка сервера';

  @override
  String get shareWithGroup => 'Поделиться с группой';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Устройства группы $name увидят и смогут изменять эту партию';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Партия, её игроки, очки и комментарии будут отправлены в группу $name. Отменить это нельзя.';
  }

  @override
  String get gameSharedDone => 'Партия отправлена в группу';

  @override
  String get gameSharedBadge => 'Общая партия';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Эти имена нельзя передать: $names. Используйте буквы, цифры, пробелы, дефисы, апострофы или точки (не более 32 символов).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Этот раунд уже ввели на другом устройстве, поэтому он стал раундом $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'Партия «$name» удалена на другом устройстве';
  }

  @override
  String get groupDevices => 'Устройства';

  @override
  String get groupDevicesExplain =>
      'Здесь можно исключить из группы потерянный или проданный телефон.';

  @override
  String get groupDeviceThisOne => 'Это устройство';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Последняя активность: $date';
  }

  @override
  String get groupDeviceRevoke => 'Исключить';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Исключить «$label» из группы? Устройство больше не будет синхронизироваться. Код приглашения тоже изменится: участники сохранят доступ, но для приглашения нужно будет отправить новый код.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '«$label» исключено. Код приглашения изменён.';
  }

  @override
  String get reportCommentary => 'Пожаловаться на комментарий';

  @override
  String get reportCommentarySubject => 'CountScore — жалоба на комментарий ИИ';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Что не так с этим комментарием, созданным ИИ?\n\n\n---\nСсылка: $reference\nКомментарий:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Почтовое приложение не найдено. Напишите на $email, чтобы пожаловаться на этот комментарий.';
  }

  @override
  String get gameRulesTitle => 'Правила игры';

  @override
  String get gameRulesInApp => 'В CountScore';

  @override
  String get gameRulesSection => 'Правила';

  @override
  String get gameRulesNoElimination => 'Игроки не выбывают по ходу партии';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Игрок выбывает, набрав больше $threshold очков';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Игрок выбывает, опустившись ниже $threshold очков';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Партия заканчивается, как только игрок наберёт $threshold очков';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Партия заканчивается, как только игрок опускается ниже $threshold очков';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Партия заканчивается, когда все игроки, кроме одного, наберут больше $threshold очков';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Партия заканчивается, когда все игроки, кроме одного, опустятся ниже $threshold очков';
  }

  @override
  String get gameRulesNoEnd =>
      'Автоматического завершения нет: вы сами решаете, когда партия окончена';

  @override
  String get gameRulesEmptyTitle => 'Правил пока нет';

  @override
  String get gameRulesEmptyHint =>
      'Запишите, как считают очки за вашим столом, — и у всех будет одна версия.';

  @override
  String get gameRulesWrite => 'Записать правила';

  @override
  String get gameRulesEditTitle => 'Изменить правила';

  @override
  String get gameRulesEditorHint =>
      'Правила вашего стола. Поддерживается Markdown.';

  @override
  String get gameRulesFromGroup => 'Правила вашей группы';

  @override
  String get gameRulesRestoreDefault => 'Восстановить исходные правила';

  @override
  String get gameRulesSaved => 'Правила сохранены';

  @override
  String get gameRulesRestored => 'Исходные правила восстановлены';

  @override
  String get gameRulesDisclaimer =>
      'Пересказ подготовлен для CountScore по правилам в их наиболее распространённом виде. Названия игр принадлежат их правообладателям и упоминаются только описательно.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Уно';

  @override
  String get gameTypeNameUnoSortKey => 'Уно';

  @override
  String get gameTypeNameScrabble => 'Скрэббл';

  @override
  String get gameTypeNameScrabbleSortKey => 'Скрэббл';

  @override
  String get gameTypeNameOther => 'Другое';

  @override
  String get gameTypeNameOtherSortKey => 'Другое';

  @override
  String get gameTypeNameSkyjo => 'Скайджо';

  @override
  String get gameTypeNameSkyjoSortKey => 'Скайджо';

  @override
  String get gameTypeNamePresident => 'Президент';

  @override
  String get gameTypeNamePresidentSortKey => 'Президент';

  @override
  String get gameTypeNameBelote => 'Белот';

  @override
  String get gameTypeNameBeloteSortKey => 'Белот';

  @override
  String get gameTypeNameTarot => 'Таро';

  @override
  String get gameTypeNameTarotSortKey => 'Таро';

  @override
  String get gameTypeNameBridge => 'Бридж';

  @override
  String get gameTypeNameBridgeSortKey => 'Бридж';

  @override
  String get gameTypeNameRami => 'Рамми';

  @override
  String get gameTypeNameRamiSortKey => 'Рамми';

  @override
  String get gameTypeNameCoinche => 'Куанш';

  @override
  String get gameTypeNameCoincheSortKey => 'Куанш';

  @override
  String get gameTypeNameYahtzee => 'Яцзы';

  @override
  String get gameTypeNameYahtzeeSortKey => 'Яцзы';

  @override
  String get gameTypeNamePhase10 => 'Фаза 10';

  @override
  String get gameTypeNamePhase10SortKey => 'Фаза 10';

  @override
  String get gameTypeNameFlip7 => 'Флип 7';

  @override
  String get gameTypeNameFlip7SortKey => 'Флип 7';

  @override
  String get gameTypeNameMilleBornes => 'Милль Борн';

  @override
  String get gameTypeNameMilleBornesSortKey => 'Милль Борн';

  @override
  String get gameTypeNameRummikub => 'Руммикуб';

  @override
  String get gameTypeNameRummikubSortKey => 'Руммикуб';

  @override
  String get gameTypeNameSixNimmt => 'Шесть берёт';

  @override
  String get gameTypeNameSixNimmtSortKey => 'Шесть берёт';

  @override
  String get gameTypeNameQwirkle => 'Квиркл';

  @override
  String get gameTypeNameQwirkleSortKey => 'Квиркл';

  @override
  String get gameTypeNameFarkle => 'Фаркл';

  @override
  String get gameTypeNameFarkleSortKey => 'Фаркл';

  @override
  String get gameTypeNameCanasta => 'Канаста';

  @override
  String get gameTypeNameCanastaSortKey => 'Канаста';

  @override
  String get gameTypeNameWizard => 'Визард';

  @override
  String get gameTypeNameWizardSortKey => 'Визард';

  @override
  String get gameTypeNameTriomino => 'Триомино';

  @override
  String get gameTypeNameTriominoSortKey => 'Триомино';

  @override
  String get groupDeviceOwner => 'Владелец';

  @override
  String get groupDeviceMakeOwner => 'Сделать владельцем';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Передать группу устройству «$label»? Это устройство больше не сможет исключать устройства и менять код приглашения.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '«$label» теперь владелец группы.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Только владелец группы может исключить устройство или сменить код приглашения.';

  @override
  String get groupErrorNotOwner => 'Это может сделать только владелец группы';

  @override
  String get whoStarts => 'Кто начинает?';

  @override
  String get whoStartsAgain => 'Выбрать заново';

  @override
  String get diceRoller => 'Бросить кубики';

  @override
  String get diceCount => 'Количество кубиков';

  @override
  String get diceRollAgain => 'Бросить ещё раз';

  @override
  String diceTotal(int total) {
    return 'Сумма: $total';
  }

  @override
  String get resumeGame => 'Продолжить';

  @override
  String get recentGames => 'Недавние';

  @override
  String get gameInProgress => 'Идёт';

  @override
  String roundNumber(int number) {
    return 'раунд $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name лидирует · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Победитель: $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '$rank-й',
      many: '$rank-й',
      few: '$rank-й',
      one: '$rank-й',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'Строка на игрока';

  @override
  String get boardViewLanes => 'Столбец на игрока';

  @override
  String get boardSeatOrder => 'Порядок хода';

  @override
  String boardRoundShort(int number) {
    return 'Р$number';
  }

  @override
  String get boardPlayer => 'Игрок';

  @override
  String get boardTotal => 'Итого';

  @override
  String get boardLeader => 'Лидирует';

  @override
  String get groupSettingsTitle => 'Комментарии и расход';

  @override
  String get groupSettingsDescription =>
      'Стиль и язык комментариев, которые сервер пишет к партиям группы. Их может изменить любой участник.';

  @override
  String get groupCommentStyle => 'Стиль комментариев';

  @override
  String get groupCommentStyleNarrative => 'Повествовательный';

  @override
  String get groupCommentStyleHumorous => 'Юмористический';

  @override
  String get groupCommentStyleAnalytical => 'Аналитический';

  @override
  String get groupCommentLanguage => 'Язык комментариев';

  @override
  String get groupSettingsSaved => 'Настройки группы сохранены';

  @override
  String get groupUsageTitle => 'Расход LLM в этом месяце';

  @override
  String groupUsageAmount(String used, String budget) {
    return 'Потрачено $used из $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Обнулится $date';
  }

  @override
  String get statsBestWinRate => 'Лучший процент побед';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins победы из $games',
      many: '$wins побед из $games',
      few: '$wins победы из $games',
      one: '$wins победа из $games',
      zero: 'Ни одной победы из $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Игрок';

  @override
  String get statsColumnGames => 'Партии';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count партии · пока вне рейтинга',
      many: '$count партий · пока вне рейтинга',
      few: '$count партии · пока вне рейтинга',
      one: '$count партия · пока вне рейтинга',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'В рейтинге с $count завершённых партий. Нажмите на игрока, чтобы открыть его карточку.',
      many:
          'В рейтинге с $count завершённых партий. Нажмите на игрока, чтобы открыть его карточку.',
      few:
          'В рейтинге с $count завершённых партий. Нажмите на игрока, чтобы открыть его карточку.',
      one:
          'В рейтинге с $count завершённой партии. Нажмите на игрока, чтобы открыть его карточку.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'партии',
      many: 'партий',
      few: 'партии',
      one: 'партия',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'победы',
      many: 'побед',
      few: 'победы',
      one: 'победа',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'среднее место';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Место, последние $count партии',
      many: 'Место, последние $count партий',
      few: 'Место, последние $count партии',
      one: 'Место, последняя $count партия',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'растёт';

  @override
  String get statsTrendDeclining => 'снижается';

  @override
  String get statsTrendSteady => 'стабильно';

  @override
  String statsRankOrdinal(String rank) {
    return '$rank-е';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серия: $count победы',
      many: 'Серия: $count побед',
      few: 'Серия: $count победы',
      one: 'Серия: $count победа',
      zero: 'Серии побед нет',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Рекорд: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'В игре $gameType';
  }

  @override
  String get statsAverageTotal => 'Средний итоговый счёт';

  @override
  String get statsBestTotal => 'Лучший итоговый счёт';

  @override
  String get statsMostBeaten => 'Чаще всего обыгран';

  @override
  String get statsOpenPlayerCard => 'открыть карточку игрока';

  @override
  String get shareResult => 'Поделиться результатом';

  @override
  String get shareAnalysis => 'Поделиться анализом';

  @override
  String shareResultSubject(String gameName) {
    return 'Результат: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Партия от $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points очка',
      many: '$points очков',
      few: '$points очка',
      one: '$points очко',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Счёт вёлся в $appName: $url';
  }

  @override
  String get shareFailed => 'Не удалось открыть меню «Поделиться»';

  @override
  String get newGameNameLabel => 'Название';

  @override
  String get newGameGameLabel => 'Игра';

  @override
  String newGameAllGames(int count) {
    return 'Все игры ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Игроки · порядок хода';

  @override
  String get newGameDragToReorder => 'перетащите, чтобы изменить порядок';

  @override
  String get newGameDealer => 'сдаёт';

  @override
  String get newGameAddPlayer => 'Добавить игрока';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Начать · $count игрока',
      many: 'Начать · $count игроков',
      few: 'Начать · $count игрока',
      one: 'Начать · $count игрок',
      zero: 'Начать',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Кто играет?';

  @override
  String get whoIsPlayingSearchHint => 'Имя или новый игрок';

  @override
  String get whoIsPlayingFrequent => 'Часто играет с вами';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Те же игроки, что в «$gameName»';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Создать «$name»';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавить $count игрока',
      many: 'Добавить $count игроков',
      few: 'Добавить $count игроков',
      one: 'Добавить $count игрока',
      zero: 'Готово',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Игра $number';
  }

  @override
  String get pwaUpdateReady => 'Новая версия CountScore готова';

  @override
  String get pwaUpdateReload => 'Перезагрузить';

  @override
  String get thresholdIsRequired => 'Для этого условия необходим порог';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Порог не может быть больше $maxString';
  }

  @override
  String get deletionImpossible => 'Удаление невозможно';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Этот тип используется в $count играх: удалить его нельзя.',
      many: 'Этот тип используется в $count играх: удалить его нельзя.',
      few: 'Этот тип используется в $count играх: удалить его нельзя.',
      one: 'Этот тип используется в 1 игре: удалить его нельзя.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Вы действительно хотите удалить тип игры «$name»?';
  }

  @override
  String get winDirectionChangeTitle => 'Обратить направление победы?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Порядок в $count завершённых играх этого типа будет обращён: победители станут последними.',
      many:
          'Порядок в $count завершённых играх этого типа будет обращён: победители станут последними.',
      few:
          'Порядок в $count завершённых играх этого типа будет обращён: победители станут последними.',
      one: 'Порядок в 1 завершённой игре этого типа будет обращён: победитель станет последним.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'Условие завершения игры поощряет направление, обратное выбранному победителю. Домашнее правило может этого и требовать.';

  @override
  String get rulesOutOfDateTitle => 'Обновить правила?';

  @override
  String get rulesOutOfDateMessage =>
      'Правила этого типа по-прежнему описывают старое условие.';

  @override
  String get later => 'Позже';

  @override
  String get currentIcon => 'Текущий значок';

  @override
  String get currentColor => 'Текущий цвет';

  @override
  String get groupDeviceClaimOwner => 'Стать владельцем';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '«$label» — владелец группы, но давно не выходил на связь. Сделать владельцем это устройство?';
  }

  @override
  String get groupDeviceOwnerClaimed =>
      'Теперь это устройство — владелец группы.';

  @override
  String get groupErrorOwnerActive =>
      'Владелец группы недавно выходил на связь: стать владельцем нельзя.';

  @override
  String get groupCreatedOwnerExplain =>
      'Группа создана. Это устройство — её владелец; роль можно передать другому в разделе «Устройства».';
}
