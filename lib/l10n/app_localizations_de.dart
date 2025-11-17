// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get playersListTitle => 'Spielerliste';

  @override
  String get gameTypesTitle => 'Spieltypen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get aboutTitle => 'Über';

  @override
  String get newGame => 'Neues Spiel';

  @override
  String get noGames => 'Keine Spiele';

  @override
  String get noGamesOfThisType => 'Keine Spiele dieses Typs';

  @override
  String get createFirstGame => 'Erstellen Sie Ihr erstes Spiel';

  @override
  String get createdOn => 'Erstellt am';

  @override
  String get newWithSamePlayers => 'Neu mit denselben Spielern';

  @override
  String get newGameSuffix => '(neu)';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirmDeletion => 'Löschen bestätigen';

  @override
  String confirmDeleteGame(String name) {
    return 'Möchten Sie das Spiel \"$name\" wirklich löschen?';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get renameGame => 'Spiel umbenennen';

  @override
  String get gameName => 'Spielname';

  @override
  String get save => 'Speichern';

  @override
  String get filterByGameType => 'Nach Spieltyp filtern';

  @override
  String get allGames => 'Alle Spiele';

  @override
  String get gameType => 'Spieltyp';

  @override
  String get loadingGameTypes => 'Lade Spieltypen...';

  @override
  String get winRule => 'Siegesregel';

  @override
  String get lowestScoreWins => 'Niedrigste Punktzahl gewinnt';

  @override
  String get highestScoreWins => 'Höchste Punktzahl gewinnt';

  @override
  String get lowestScoreExample => 'Z.B.: Golf, Herz';

  @override
  String get highestScoreExample => 'Z.B.: Rommé, Bridge';

  @override
  String get players => 'Spieler';

  @override
  String get add => 'Hinzufügen';

  @override
  String get pleaseEnterName => 'Bitte geben Sie einen Namen ein';

  @override
  String get atLeast2PlayersRequired => 'Mindestens 2 Spieler erforderlich';

  @override
  String playerNumber(int index) {
    return 'Spieler $index';
  }

  @override
  String get selectPlayer => 'Spieler auswählen...';

  @override
  String get clear => 'Leeren';

  @override
  String get remove => 'Entfernen';

  @override
  String get createGame => 'Spiel erstellen';

  @override
  String get game => 'Spiel';

  @override
  String get deleteLastRound => 'Letzte Runde löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get confirmDeleteLastRound => 'Letzte Runde löschen?';

  @override
  String get noPlayersInGame => 'Keine Spieler in diesem Spiel';

  @override
  String get round => 'Runde';

  @override
  String get addRound => 'Runde hinzufügen';

  @override
  String get score => 'Punktzahl';

  @override
  String get enterScore => 'Punktzahl eingeben';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get screen => 'Bildschirm';

  @override
  String get keepScreenAwake => 'Bildschirm aktiv halten';

  @override
  String get keepScreenAwakeDescription =>
      'Verhindert, dass der Bildschirm während eines Spiels ausgeht';

  @override
  String get backup => 'Sicherung';

  @override
  String get exportDatabase => 'Datenbank exportieren';

  @override
  String get exportDatabaseDescription =>
      'Speichern Sie alle Ihre Spiele in einer Datei';

  @override
  String get databaseExportedTo => 'Datenbank exportiert nach:';

  @override
  String get errorDuringExport => 'Fehler beim Exportieren:';

  @override
  String get importDatabase => 'Datenbank importieren';

  @override
  String get importDatabaseDescription =>
      'Stellen Sie Ihre Spiele aus einer Sicherungsdatei wieder her';

  @override
  String get confirmation => 'Bestätigung';

  @override
  String get importWarning =>
      'Der Import wird alle Ihre aktuellen Daten ersetzen. Vor dem Import wird automatisch eine Sicherung erstellt.\n\nMöchten Sie fortfahren?';

  @override
  String get import => 'Importieren';

  @override
  String get databaseImportedSuccessfully => 'Datenbank erfolgreich importiert';

  @override
  String get importSuccessful => 'Import erfolgreich';

  @override
  String get importSuccessMessage =>
      'Die Datenbank wurde erfolgreich importiert.\n\nDie Anwendung wird jetzt geschlossen. Bitte öffnen Sie sie erneut, um die neuen Daten zu sehen.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Fehler beim Importieren:';

  @override
  String get noPlayers => 'Keine Spieler';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler: $names',
      one: '1 Spieler: $names',
      zero: 'Keine Spieler',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Spieler erscheinen hier, sobald\nSie Spiele erstellt haben';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele',
      one: '1 Spiel',
      zero: '0 Spiele',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Siege',
      one: '1 Sieg',
      zero: '0 Siege',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Farbe ändern';

  @override
  String get renamePlayer => 'Spieler umbenennen';

  @override
  String get newName => 'Neuer Name';

  @override
  String playerRenamedTo(String name) {
    return 'Spieler umbenannt in \"$name\"';
  }

  @override
  String get deletePlayer => 'Spieler löschen';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Möchten Sie \"$name\" wirklich löschen?\n\nDieser Spieler wird aus allen $count Spiel(en) entfernt.';
  }

  @override
  String playerDeleted(String name) {
    return 'Spieler \"$name\" gelöscht';
  }

  @override
  String get chooseColor => 'Farbe wählen';

  @override
  String get noGameTypes => 'Keine Spieltypen';

  @override
  String get predefined => 'Standard';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get newType => 'Neuer Typ';

  @override
  String get editType => 'Typ bearbeiten';

  @override
  String get newGameType => 'Neuer Spieltyp';

  @override
  String get gameTypeName => 'Name des Spieltyps';

  @override
  String get icon => 'Symbol:';

  @override
  String get color => 'Farbe:';

  @override
  String get chooseIcon => 'Symbol wählen';

  @override
  String get nameIsRequired => 'Name ist erforderlich';

  @override
  String get create => 'Erstellen';

  @override
  String get ranking => 'Rangliste';

  @override
  String get noCurrentGame => 'Kein aktuelles Spiel';

  @override
  String get noScoresRecorded => 'Keine Punktzahlen erfasst';

  @override
  String get playerStatistics => 'Spielerstatistik';

  @override
  String get noStatisticsAvailable => 'Keine Statistiken verfügbar';

  @override
  String get gamesPlayed => 'Gespielte Spiele';

  @override
  String get wins => 'Siege';

  @override
  String get winRate => 'Siegesrate';

  @override
  String get overallStatistics => 'Gesamtstatistik';

  @override
  String get byGameType => 'Nach Spieltyp';

  @override
  String get rate => 'Rate';

  @override
  String get version => 'Version 1.0.1';

  @override
  String get appDescription =>
      'Punkteverwaltungsanwendung für Ihre Spielsitzungen von Vincent Moreau';

  @override
  String get features => 'Funktionen';

  @override
  String get featureDifferentGameTypes => 'Verschiedene Spieltypen';

  @override
  String get featurePlayerManagement => 'Spielerverwaltung';

  @override
  String get featureDetailedStatistics => 'Detaillierte Statistiken';

  @override
  String get featureCustomization => 'Anpassung';

  @override
  String get featureDarkLightTheme => 'Dunkles/helles Design';

  @override
  String get credits => 'Danksagungen';

  @override
  String get appIconCredit => 'App-Symbol';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Spieler auswählen';

  @override
  String get search => 'Suchen';

  @override
  String get createNewPlayer => 'Neuen Spieler erstellen';

  @override
  String get newPlayerName => 'Name des neuen Spielers';

  @override
  String get noPlayersFound => 'Keine Spieler gefunden';

  @override
  String get allPlayersSelected => 'Alle Spieler wurden ausgewählt';

  @override
  String get close => 'Schließen';

  @override
  String get playerEliminationCondition => 'Spielerausschlussbedingung';

  @override
  String get gameOverCondition => 'Spielende-Bedingung';

  @override
  String get none => 'Keine';

  @override
  String get overThreshold => 'Über Schwellenwert';

  @override
  String get underThreshold => 'Unter Schwellenwert';

  @override
  String get firstPlayerOver => 'Erster Spieler über';

  @override
  String get firstPlayerUnder => 'Erster Spieler unter';

  @override
  String get lastPlayerOver => 'Letzter Spieler über';

  @override
  String get lastPlayerUnder => 'Letzter Spieler unter';

  @override
  String get threshold => 'Schwellenwert';

  @override
  String get conditionType => 'Bedingungstyp';

  @override
  String get gameOverTitle => 'Spiel beendet!';

  @override
  String get gameOverMessage => 'Spielende-Bedingung erreicht. Jetzt beenden?';

  @override
  String get continuePlay => 'Weiterspielen';

  @override
  String get endGame => 'Spiel beenden';
}
