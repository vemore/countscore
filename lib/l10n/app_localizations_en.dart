// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Home';

  @override
  String get playersListTitle => 'Players List';

  @override
  String get gameTypesTitle => 'Game Types';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get newGame => 'New Game';

  @override
  String get noGames => 'No games';

  @override
  String get noGamesOfThisType => 'No games of this type';

  @override
  String get createFirstGame => 'Create your first game';

  @override
  String get createdOn => 'Created on';

  @override
  String get newWithSamePlayers => 'New with same players';

  @override
  String get newGameSuffix => '(new)';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String confirmDeleteGame(String name) {
    return 'Do you really want to delete the game \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get renameGame => 'Rename game';

  @override
  String get gameName => 'Game name';

  @override
  String get save => 'Save';

  @override
  String get filterByGameType => 'Filter by game type';

  @override
  String get allGames => 'All games';

  @override
  String get gameType => 'Game type';

  @override
  String get loadingGameTypes => 'Loading game types...';

  @override
  String get winRule => 'Win rule';

  @override
  String get lowestScoreWins => 'Lowest score wins';

  @override
  String get highestScoreWins => 'Highest score wins';

  @override
  String get lowestScoreExample => 'Ex: Golf, Hearts';

  @override
  String get highestScoreExample => 'Ex: Rummy, Bridge';

  @override
  String get players => 'Players';

  @override
  String get add => 'Add';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get atLeast2PlayersRequired => 'At least 2 players are required';

  @override
  String playerNumber(int index) {
    return 'Player $index';
  }

  @override
  String get selectPlayer => 'Select a player...';

  @override
  String get clear => 'Clear';

  @override
  String get remove => 'Remove';

  @override
  String get createGame => 'Create game';

  @override
  String get game => 'Game';

  @override
  String get deleteLastRound => 'Delete last round';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDeleteLastRound => 'Delete the last round?';

  @override
  String get noPlayersInGame => 'No players in this game';

  @override
  String get round => 'Round';

  @override
  String get addRound => 'Add round';

  @override
  String get score => 'Score';

  @override
  String get enterScore => 'Enter score';

  @override
  String get appearance => 'Appearance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get screen => 'Screen';

  @override
  String get keepScreenAwake => 'Keep screen awake';

  @override
  String get keepScreenAwakeDescription =>
      'Prevents the screen from sleeping during a game';

  @override
  String get backup => 'Backup';

  @override
  String get exportDatabase => 'Export database';

  @override
  String get exportDatabaseDescription => 'Save all your games to a file';

  @override
  String get databaseExportedTo => 'Database exported to:';

  @override
  String get errorDuringExport => 'Error during export:';

  @override
  String get importDatabase => 'Import database';

  @override
  String get importDatabaseDescription =>
      'Restore your games from a backup file';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get importWarning =>
      'Importing will replace all your current data. An automatic backup will be created before import.\n\nDo you want to continue?';

  @override
  String get import => 'Import';

  @override
  String get databaseImportedSuccessfully => 'Database imported successfully';

  @override
  String get importSuccessful => 'Import successful';

  @override
  String get importSuccessMessage =>
      'The database has been imported successfully.\n\nThe application will now close. Please reopen it to see the new data.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Error during import:';

  @override
  String get noPlayers => 'No players';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players: $names',
      one: '1 player: $names',
      zero: 'No players',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Players will appear here once\nyou have created games';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
      zero: '0 games',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '1 win',
      zero: '0 wins',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Change color';

  @override
  String get renamePlayer => 'Rename player';

  @override
  String get newName => 'New name';

  @override
  String playerRenamedTo(String name) {
    return 'Player renamed to \"$name\"';
  }

  @override
  String get deletePlayer => 'Delete player';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Do you really want to delete \"$name\"?\n\nThis player will be removed from all $count game(s).';
  }

  @override
  String playerDeleted(String name) {
    return 'Player \"$name\" deleted';
  }

  @override
  String get chooseColor => 'Choose a color';

  @override
  String get noGameTypes => 'No game types';

  @override
  String get predefined => 'Default';

  @override
  String get edit => 'Edit';

  @override
  String get newType => 'New type';

  @override
  String get editType => 'Edit type';

  @override
  String get newGameType => 'New game type';

  @override
  String get gameTypeName => 'Game type name';

  @override
  String get icon => 'Icon:';

  @override
  String get color => 'Color:';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get create => 'Create';

  @override
  String get ranking => 'Ranking';

  @override
  String get noCurrentGame => 'No current game';

  @override
  String get noScoresRecorded => 'No scores recorded';

  @override
  String get playerStatistics => 'Player Statistics';

  @override
  String get noStatisticsAvailable => 'No statistics available';

  @override
  String get gamesPlayed => 'Games played';

  @override
  String get wins => 'Wins';

  @override
  String get winRate => 'Win rate';

  @override
  String get overallStatistics => 'Overall Statistics';

  @override
  String get byGameType => 'By game type';

  @override
  String get rate => 'Rate';

  @override
  String get version => 'Version 1.0.1';

  @override
  String get appDescription =>
      'Score management application for your game sessions by Vincent Moreau';

  @override
  String get features => 'Features';

  @override
  String get featureDifferentGameTypes => 'Different game types';

  @override
  String get featurePlayerManagement => 'Player management';

  @override
  String get featureDetailedStatistics => 'Detailed statistics';

  @override
  String get featureCustomization => 'Customization';

  @override
  String get featureDarkLightTheme => 'Dark/light theme';

  @override
  String get credits => 'Credits';

  @override
  String get appIconCredit => 'App icon';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Select a player';

  @override
  String get search => 'Search';

  @override
  String get createNewPlayer => 'Create new player';

  @override
  String get newPlayerName => 'New player name';

  @override
  String get noPlayersFound => 'No players found';

  @override
  String get allPlayersSelected => 'All players have been selected';

  @override
  String get close => 'Close';

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
