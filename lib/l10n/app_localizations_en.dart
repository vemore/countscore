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
  String get newWithSamePlayers => 'New with same players';

  @override
  String get playAgain => 'Play again';

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
  String get allGames => 'All games';

  @override
  String get filterGames => 'Filter games';

  @override
  String get applyFilter => 'Apply';

  @override
  String get resetFilter => 'Reset';

  @override
  String get selectGameType => 'Select a game type';

  @override
  String get gameType => 'Game type';

  @override
  String get loadingGameTypes => 'Loading game types...';

  @override
  String get lowestScoreWins => 'Lowest score wins';

  @override
  String get highestScoreWins => 'Highest score wins';

  @override
  String get players => 'Players';

  @override
  String get add => 'Add';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get clear => 'Clear';

  @override
  String get remove => 'Remove';

  @override
  String get game => 'Game';

  @override
  String get editGame => 'Edit game';

  @override
  String get editGameDialogTitle => 'Edit game';

  @override
  String get removePlayer => 'Remove player';

  @override
  String get addPlayerToGame => 'Add player';

  @override
  String get warningRemovePlayer =>
      'Warning! Removing this player will delete all their scores from this game. This action is irreversible.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Do you really want to remove $playerName from this game?';
  }

  @override
  String get playerRemoved => 'Player removed from game';

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
  String boardRoundButton(int round) {
    return 'Round $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · round $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · round $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'total after: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Next\n$player';
  }

  @override
  String get keypadValidateRound => 'Validate round';

  @override
  String get keypadToggleSign => 'Change sign';

  @override
  String get keypadBackspace => 'Delete a digit';

  @override
  String get keypadShortcutTitle => 'Keypad shortcut';

  @override
  String get keypadShortcutKind => 'Key type';

  @override
  String get keypadShortcutKindValue => 'Enter a value';

  @override
  String get keypadShortcutKindMultiply => 'Multiply the score (positive only)';

  @override
  String get keypadShortcutKindAdd => 'Add to the score';

  @override
  String get keypadShortcutAmount => 'Number';

  @override
  String get keypadShortcutLabel => 'Key label (optional)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'A whole number between $min and $max, other than 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'A whole number between $min and $max';
  }

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
  String get byGameType => 'By game type';

  @override
  String get rate => 'Rate';

  @override
  String version(String version) {
    return 'Version $version';
  }

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
  String get featureGroupSharing => 'Group sharing';

  @override
  String get featureGameAnalysis => 'AI game analysis';

  @override
  String get rateApp => 'Rate CountScore';

  @override
  String get search => 'Search';

  @override
  String get newPlayerName => 'New player name';

  @override
  String get noPlayersFound => 'No players found';

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
  String get firstPlayerOver => 'First player to reach';

  @override
  String get firstPlayerUnder => 'First player under';

  @override
  String get lastPlayerOver => 'Last player standing (others over)';

  @override
  String get lastPlayerUnder => 'Last player standing (others under)';

  @override
  String get threshold => 'Threshold';

  @override
  String get conditionType => 'Condition Type';

  @override
  String get continuePlay => 'Continue Playing';

  @override
  String gameEndWinner(String name) {
    return '$name wins';
  }

  @override
  String gameEndTie(String names) {
    return 'Tie: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '$count round',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'lowest score wins';

  @override
  String get gameEndHighestWins => 'highest score wins';

  @override
  String get gameEndAnalysis => 'Analysis';

  @override
  String get gameEndResults => 'Results';

  @override
  String get rankingEliminationNote =>
      'Ranked by elimination order: whoever goes out later ranks ahead, whatever the totals.';

  @override
  String get endGame => 'End Game';

  @override
  String get reopenGame => 'Reopen game';

  @override
  String get gameFinished => 'Finished';

  @override
  String get undo => 'Undo';

  @override
  String get gameReopened => 'Game reopened';

  @override
  String get comment => 'Comment';

  @override
  String get enterComment => 'Enter a comment';

  @override
  String get analyzeGame => 'Analyze game';

  @override
  String get analysisTitle => 'Game analysis';

  @override
  String get analysisStyle => 'Analysis style';

  @override
  String get analysisStyleProfessor => 'The professor';

  @override
  String get analysisStyleCommentator => 'The sports commentator';

  @override
  String get analysisStyleDocumentary => 'The wildlife documentary';

  @override
  String get analysisStyleNoir => 'The detective';

  @override
  String get analysisStyleBard => 'The bard';

  @override
  String get analysisStyleCoach => 'The coach';

  @override
  String get analysisStyleConsultant => 'The consultant';

  @override
  String get analysisStyleAstrologer => 'The astrologer';

  @override
  String get analysisStyleRealityTv => 'The reality show';

  @override
  String get generatingAnalysis => 'Generating analysis…';

  @override
  String get generateAnalysis => 'Generate analysis';

  @override
  String get regenerateAnalysis => 'Regenerate analysis';

  @override
  String get deleteAnalysis => 'Delete analysis';

  @override
  String get confirmRegenerateAnalysis =>
      'Regenerate? Current analysis will be replaced.';

  @override
  String get confirmDeleteAnalysis => 'Delete the analysis for this game?';

  @override
  String get analysisError => 'Failed to generate analysis';

  @override
  String get analysisErrorUnavailable =>
      'The analysis server is temporarily unavailable. Try again later.';

  @override
  String get analysisErrorGroupBudget =>
      'Your group has used up its analysis budget for this month. It renews at the start of next month.';

  @override
  String get analysisStyleGroupDefault =>
      'No style picked: this shared game is analysed in the group\'s style and language.';

  @override
  String analysisErrorStatus(int status) {
    return 'Failed to generate analysis (HTTP $status)';
  }

  @override
  String get retry => 'Retry';

  @override
  String analysisGeneratedAt(String date) {
    return 'Generated on $date';
  }

  @override
  String get serverSection => 'Server';

  @override
  String get backendUrlLabel => 'Server URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Connected features need a CountScore server. Install one from the backend/ folder and enter its address here. With no server, no data ever leaves this device.';

  @override
  String get backendNotConfigured => 'No server configured';

  @override
  String get backendUrlInvalid =>
      'Invalid address. Enter a full URL, for example https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// is only accepted on a local network. Use https:// for a public server.';

  @override
  String get testConnection => 'Test connection';

  @override
  String get connectionOk => 'The server is responding';

  @override
  String get connectionFailed => 'The server is not responding';

  @override
  String get serverUrlSaved => 'Server saved';

  @override
  String get analysisRequiresBackend =>
      'This analysis needs a server. Configure one in the settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get serverUrlCleared => 'Server cleared';

  @override
  String get groupSection => 'Group';

  @override
  String get groupDescription =>
      'Share games with the other devices in your group. Shared games, their players, scores, comments and analyses are sent to your server; other games stay on this device.';

  @override
  String get groupNeedsServer => 'Set up a server above first.';

  @override
  String get groupCreate => 'Create a group';

  @override
  String get groupJoin => 'Join a group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNicknameLabel => 'Your nickname';

  @override
  String get groupNicknameHint => 'The others in the group will see it';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Your nickname: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Change your nickname';

  @override
  String get shareTokenLabel => 'Invite code';

  @override
  String get shareTokenHint => 'Paste the code a group member sent you';

  @override
  String groupCurrent(String name) {
    return 'Group: $name';
  }

  @override
  String get shareTokenExplain =>
      'Send this code to the devices that should join the group. Anyone who has it can join.';

  @override
  String get shareTokenCopy => 'Copy code';

  @override
  String get shareTokenCopied => 'Code copied';

  @override
  String get shareTokenRotate => 'New code';

  @override
  String get shareTokenRotateConfirm =>
      'The old code will no longer let anyone join. Devices already in the group are not affected.';

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupLeaveConfirm =>
      'This device leaves the group. Shared games stay on this device but will no longer sync.';

  @override
  String get groupLeft => 'Left the group';

  @override
  String get groupJoined => 'Joined the group';

  @override
  String get clearServerLeavesGroup =>
      'Clearing the server leaves the group. Shared games stay on this device.';

  @override
  String get syncNow => 'Sync now';

  @override
  String syncStatusIdle(String time) {
    return 'Synced at $time';
  }

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusOffline =>
      'Server unreachable — changes will be sent later';

  @override
  String get syncStatusUnauthorized =>
      'The server no longer accepts this device. Leave the group, then join it again.';

  @override
  String get syncStatusError => 'Server error during sync';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting',
      one: '1 change waiting',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes refused by the server',
      one: '1 change refused by the server',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'Unknown or replaced invite code';

  @override
  String get groupErrorRateLimited =>
      'Too many attempts. Try again in a minute.';

  @override
  String get groupErrorUnreachable => 'Server unreachable';

  @override
  String get groupErrorServer => 'Server error';

  @override
  String get shareWithGroup => 'Share with the group';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Devices in $name will see and edit this game';
  }

  @override
  String shareGameConfirm(String name) {
    return 'The game, its players, scores and comments will be sent to $name. Sharing cannot be undone.';
  }

  @override
  String get gameSharedDone => 'Game shared with the group';

  @override
  String get gameSharedBadge => 'Shared game';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'These names cannot be shared: $names. Use letters, digits, spaces, hyphens, apostrophes or periods (32 characters at most).';
  }

  @override
  String roundRenumbered(int number) {
    return 'That round had already been entered on another device, so it became round $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" was deleted on another device';
  }

  @override
  String get groupDevices => 'Devices';

  @override
  String get groupDevicesExplain =>
      'A lost or sold phone can be removed from the group here.';

  @override
  String get groupDeviceThisOne => 'This device';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Last seen $date';
  }

  @override
  String get groupDeviceRevoke => 'Remove';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Remove “$label” from the group? It will no longer sync. The invite code changes too: members keep their access, but you will need to share the new code to invite anyone.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '“$label” was removed. The invite code has changed.';
  }

  @override
  String get reportCommentary => 'Report this commentary';

  @override
  String get reportCommentarySubject => 'CountScore — AI commentary report';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'What is wrong with this AI-generated commentary?\n\n\n---\nReference: $reference\nCommentary:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'No email app found. Write to $email to report this commentary.';
  }

  @override
  String get gameRulesTitle => 'Game rules';

  @override
  String get gameRulesInApp => 'In CountScore';

  @override
  String get gameRulesSection => 'The rules';

  @override
  String get gameRulesNoElimination => 'No elimination during play';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'A player is eliminated above $threshold points';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'A player is eliminated below $threshold points';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'The game ends as soon as a player reaches $threshold points';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'The game ends as soon as a player drops below $threshold points';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'The game ends when every player but one is above $threshold points';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'The game ends when every player but one is below $threshold points';
  }

  @override
  String get gameRulesNoEnd =>
      'No automatic end: you decide when the game is over';

  @override
  String get gameRulesEmptyTitle => 'No rules yet';

  @override
  String get gameRulesEmptyHint =>
      'Write down how your table counts the points — everyone will have the same version.';

  @override
  String get gameRulesWrite => 'Write the rules';

  @override
  String get gameRulesEditTitle => 'Edit the rules';

  @override
  String get gameRulesEditorHint =>
      'Your table\'s rules. Markdown is supported.';

  @override
  String get gameRulesFromGroup => 'Your group\'s rules';

  @override
  String get gameRulesRestoreDefault => 'Restore the original rules';

  @override
  String get gameRulesSaved => 'Rules saved';

  @override
  String get gameRulesRestored => 'Original rules restored';

  @override
  String get gameRulesDisclaimer =>
      'Summary written for CountScore from the rules as they are commonly played. Game names belong to their respective owners and are used descriptively only.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Uno';

  @override
  String get gameTypeNameUnoSortKey => 'Uno';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameScrabbleSortKey => 'Scrabble';

  @override
  String get gameTypeNameOther => 'Other';

  @override
  String get gameTypeNameOtherSortKey => 'Other';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNameSkyjoSortKey => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'President';

  @override
  String get gameTypeNamePresidentSortKey => 'President';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameBeloteSortKey => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarot';

  @override
  String get gameTypeNameTarotSortKey => 'Tarot';

  @override
  String get gameTypeNameBridge => 'Bridge';

  @override
  String get gameTypeNameBridgeSortKey => 'Bridge';

  @override
  String get gameTypeNameRami => 'Rummy';

  @override
  String get gameTypeNameRamiSortKey => 'Rummy';

  @override
  String get gameTypeNameCoinche => 'Coinche';

  @override
  String get gameTypeNameCoincheSortKey => 'Coinche';

  @override
  String get gameTypeNameYahtzee => 'Yahtzee';

  @override
  String get gameTypeNameYahtzeeSortKey => 'Yahtzee';

  @override
  String get gameTypeNamePhase10 => 'Phase 10';

  @override
  String get gameTypeNamePhase10SortKey => 'Phase 10';

  @override
  String get gameTypeNameFlip7 => 'Flip 7';

  @override
  String get gameTypeNameFlip7SortKey => 'Flip 7';

  @override
  String get gameTypeNameMilleBornes => 'Mille Bornes';

  @override
  String get gameTypeNameMilleBornesSortKey => 'Mille Bornes';

  @override
  String get gameTypeNameRummikub => 'Rummikub';

  @override
  String get gameTypeNameRummikubSortKey => 'Rummikub';

  @override
  String get gameTypeNameSixNimmt => 'Take 6';

  @override
  String get gameTypeNameSixNimmtSortKey => 'Take 6';

  @override
  String get gameTypeNameQwirkle => 'Qwirkle';

  @override
  String get gameTypeNameQwirkleSortKey => 'Qwirkle';

  @override
  String get gameTypeNameFarkle => 'Farkle';

  @override
  String get gameTypeNameFarkleSortKey => 'Farkle';

  @override
  String get gameTypeNameCanasta => 'Canasta';

  @override
  String get gameTypeNameCanastaSortKey => 'Canasta';

  @override
  String get gameTypeNameWizard => 'Wizard';

  @override
  String get gameTypeNameWizardSortKey => 'Wizard';

  @override
  String get gameTypeNameTriomino => 'Triomino';

  @override
  String get gameTypeNameTriominoSortKey => 'Triomino';

  @override
  String get groupDeviceOwner => 'Owner';

  @override
  String get groupDeviceMakeOwner => 'Make owner';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Hand the group over to “$label”? This device will no longer be able to remove devices or change the invite code.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '“$label” now owns the group.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Only the group\'s owner can remove a device or change the invite code.';

  @override
  String get groupErrorNotOwner => 'Only the group\'s owner can do this';

  @override
  String get whoStarts => 'Who starts?';

  @override
  String get whoStartsAgain => 'Draw again';

  @override
  String get diceRoller => 'Roll dice';

  @override
  String get diceCount => 'Number of dice';

  @override
  String get diceRollAgain => 'Roll again';

  @override
  String diceTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get resumeGame => 'Resume';

  @override
  String get recentGames => 'Recent';

  @override
  String get gameInProgress => 'In progress';

  @override
  String roundNumber(int number) {
    return 'round $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name leads · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Won by $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '#$rank',
      one: '#$rank',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'One row per player';

  @override
  String get boardViewLanes => 'One column per player';

  @override
  String get boardSeatOrder => 'Seat order';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'Player';

  @override
  String get boardTotal => 'Total';

  @override
  String get boardLeader => 'Leading';

  @override
  String get groupSettingsTitle => 'Comments and usage';

  @override
  String get groupSettingsDescription =>
      'The style and language of the comments the server writes for the group\'s games. Any member can change them.';

  @override
  String get groupCommentStyle => 'Comment style';

  @override
  String get groupCommentStyleNarrative => 'Narrative';

  @override
  String get groupCommentStyleHumorous => 'Humorous';

  @override
  String get groupCommentStyleAnalytical => 'Analytical';

  @override
  String get groupCommentLanguage => 'Comment language';

  @override
  String get groupSettingsSaved => 'Group settings saved';

  @override
  String get groupUsageTitle => 'LLM usage this month';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used spent of $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Resets on $date';
  }

  @override
  String get statsBestWinRate => 'Best win rate';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins wins out of $games',
      one: '$wins win out of $games',
      zero: 'No wins out of $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Player';

  @override
  String get statsColumnGames => 'Games';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games · not ranked yet',
      one: '$count game · not ranked yet',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ranked from $count finished games. Tap a player to see their card.',
      one: 'Ranked from $count finished game. Tap a player to see their card.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'games',
      one: 'game',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wins',
      one: 'win',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'average place';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Place, last $count games',
      one: 'Place, last game',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'improving';

  @override
  String get statsTrendDeclining => 'slipping';

  @override
  String get statsTrendSteady => 'steady';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1st',
      '2': '2nd',
      '3': '3rd',
      'other': '${rank}th',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Streak: $count wins',
      one: 'Streak: $count win',
      zero: 'No winning streak',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Best: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'On $gameType';
  }

  @override
  String get statsAverageTotal => 'Average final total';

  @override
  String get statsBestTotal => 'Best final total';

  @override
  String get statsMostBeaten => 'Most beaten opponent';

  @override
  String get statsOpenPlayerCard => 'open the player card';

  @override
  String get shareResult => 'Share the result';

  @override
  String get shareAnalysis => 'Share the analysis';

  @override
  String shareResultSubject(String gameName) {
    return 'Result: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Game of $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points',
      one: '$points point',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Scores kept with $appName: $url';
  }

  @override
  String get shareFailed => 'Sharing could not be opened';

  @override
  String get newGameNameLabel => 'Name';

  @override
  String get newGameGameLabel => 'Game';

  @override
  String newGameAllGames(int count) {
    return 'All games ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Players · seat order';

  @override
  String get newGameDragToReorder => 'drag to reorder';

  @override
  String get newGameDealer => 'deals';

  @override
  String get newGameAddPlayer => 'Add a player';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start · $count players',
      one: 'Start · 1 player',
      zero: 'Start',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Who\'s playing?';

  @override
  String get whoIsPlayingSearchHint => 'Name, or a new player';

  @override
  String get whoIsPlayingFrequent => 'Often plays with you';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Same players as “$gameName”';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Create “$name”';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count players',
      one: 'Add 1 player',
      zero: 'Done',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Game $number';
  }

  @override
  String get pwaUpdateReady => 'A new version of CountScore is ready';

  @override
  String get pwaUpdateReload => 'Reload';

  @override
  String get thresholdIsRequired =>
      'A threshold is required for this condition';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'The threshold cannot be above $maxString';
  }

  @override
  String get deletionImpossible => 'Deletion impossible';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games use this type: it cannot be deleted.',
      one: '1 game uses this type: it cannot be deleted.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Do you really want to delete the game type \"$name\"?';
  }

  @override
  String get winDirectionChangeTitle => 'Reverse who wins?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count finished games of this type will have their standings reversed: their winners become the last.',
      one: '1 finished game of this type will have its standings reversed: its winner becomes the last.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'The game-over condition rewards the opposite of the chosen winner. A house rule may want exactly that.';

  @override
  String get rulesOutOfDateTitle => 'Update the rules?';

  @override
  String get rulesOutOfDateMessage =>
      'This type\'s rules still describe the old condition.';

  @override
  String get later => 'Later';

  @override
  String get currentIcon => 'Current icon';

  @override
  String get currentColor => 'Current colour';

  @override
  String get groupDeviceClaimOwner => 'Claim ownership';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '“$label” owns the group but has not been seen for a long time. Take ownership over on this device?';
  }

  @override
  String get groupDeviceOwnerClaimed => 'This device now owns the group.';

  @override
  String get groupErrorOwnerActive =>
      'The group\'s owner has been seen recently: ownership cannot be claimed.';

  @override
  String get groupCreatedOwnerExplain =>
      'Group created. This device owns it; the role can be handed over to another one in Devices.';

  @override
  String get boardEliminated => 'Eliminated';

  @override
  String get soundsSection => 'Sounds';

  @override
  String get gameSounds => 'Game sounds';

  @override
  String get gameSoundsDescription =>
      'A sound when a player is eliminated, when the game is won and when the timer ends';

  @override
  String get turnTimer => 'Turn timer';

  @override
  String get turnTimerLess => 'Less time';

  @override
  String get turnTimerMore => 'More time';

  @override
  String get turnTimerStart => 'Start';

  @override
  String get turnTimerPause => 'Pause';

  @override
  String get turnTimerReset => 'Reset';

  @override
  String get turnTimerTimeUp => 'Time\'s up!';

  @override
  String get configShareOpen => 'Share by QR code';

  @override
  String get configShareTitle => 'Share this configuration';

  @override
  String get configShareExplainServer =>
      'Scan this code with another phone to set it up with the same server.';

  @override
  String configShareExplainGroup(String name) {
    return 'Scan this code with another phone to set it up with the same server and join the group $name. It holds the group\'s invite code: show it only to the people you want in the group.';
  }

  @override
  String get configShareWebAppLabel => 'Web app address';

  @override
  String get configShareWebAppHelper =>
      'Where your server serves the CountScore web app, such as https://countscore.example.com/countscore. The code opens this page.';

  @override
  String get configShareWebAppNeeded =>
      'Enter the web app address to show the code.';

  @override
  String get configShareQrLabel => 'QR code of the configuration link';

  @override
  String get configShareCopyLink => 'Copy link';

  @override
  String get configShareLinkCopied => 'Link copied';

  @override
  String get configShareTooLong =>
      'This link is too long to fit in a QR code. Use \"Copy link\" instead.';

  @override
  String get replaceConfigTitle => 'Replace the configuration?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Now: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'New: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'invite code $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'This device will leave the group $name. Its games stay on this device.';
  }

  @override
  String get replaceConfigConfirm => 'Replace';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes on this device have not reached the group yet. If you leave now, the group will never receive them.',
      one: '1 change on this device has not reached the group yet. If you leave now, the group will never receive it.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Leave anyway';

  @override
  String get replaceConfigDone => 'Configuration replaced';

  @override
  String get replaceConfigUnchanged =>
      'This device already uses this configuration';

  @override
  String get joinLinkHandOverMessage =>
      'This link can open in the CountScore Android app. If the app is not installed, the Play Store opens instead.';

  @override
  String get joinLinkOpenInApp => 'Open in the app';

  @override
  String get joinLinkContinueHere => 'Continue in the browser';
}
