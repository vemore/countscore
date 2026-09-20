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
  String get newWithSamePlayers => 'Neu mit denselben Spielern';

  @override
  String get playAgain => 'Nochmal spielen';

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
  String get allGames => 'Alle Spiele';

  @override
  String get filterGames => 'Spiele filtern';

  @override
  String get applyFilter => 'Anwenden';

  @override
  String get resetFilter => 'Zurücksetzen';

  @override
  String get selectGameType => 'Wählen Sie einen Spieltyp';

  @override
  String get gameType => 'Spieltyp';

  @override
  String get loadingGameTypes => 'Lade Spieltypen...';

  @override
  String get lowestScoreWins => 'Niedrigste Punktzahl gewinnt';

  @override
  String get highestScoreWins => 'Höchste Punktzahl gewinnt';

  @override
  String get players => 'Spieler';

  @override
  String get add => 'Hinzufügen';

  @override
  String get pleaseEnterName => 'Bitte geben Sie einen Namen ein';

  @override
  String get clear => 'Leeren';

  @override
  String get remove => 'Entfernen';

  @override
  String get game => 'Spiel';

  @override
  String get editGame => 'Spiel bearbeiten';

  @override
  String get editGameDialogTitle => 'Spiel bearbeiten';

  @override
  String get removePlayer => 'Spieler entfernen';

  @override
  String get addPlayerToGame => 'Spieler hinzufügen';

  @override
  String get warningRemovePlayer =>
      'Warnung! Das Entfernen dieses Spielers löscht alle seine Punkte aus diesem Spiel. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Möchten Sie $playerName wirklich aus diesem Spiel entfernen?';
  }

  @override
  String get playerRemoved => 'Spieler aus dem Spiel entfernt';

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
  String boardRoundButton(int round) {
    return 'Runde $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · Runde $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · Runde $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'danach gesamt: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Weiter\n$player';
  }

  @override
  String get keypadValidateRound => 'Runde bestätigen';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => 'Vorzeichen wechseln';

  @override
  String get keypadBackspace => 'Ziffer löschen';

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
  String get byGameType => 'Nach Spieltyp';

  @override
  String get rate => 'Rate';

  @override
  String version(String version) {
    return 'Version $version';
  }

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
  String get featureGroupSharing => 'Gruppenfreigabe';

  @override
  String get featureGameAnalysis => 'KI-Spielanalyse';

  @override
  String get rateApp => 'CountScore bewerten';

  @override
  String get credits => 'Danksagungen';

  @override
  String get appIconCredit => 'App-Symbol';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get search => 'Suchen';

  @override
  String get newPlayerName => 'Name des neuen Spielers';

  @override
  String get noPlayersFound => 'Keine Spieler gefunden';

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
  String get firstPlayerOver => 'Erster Spieler erreicht';

  @override
  String get firstPlayerUnder => 'Erster Spieler unter';

  @override
  String get lastPlayerOver => 'Letzter Spieler im Spiel (andere darüber)';

  @override
  String get lastPlayerUnder => 'Letzter Spieler im Spiel (andere darunter)';

  @override
  String get threshold => 'Schwellenwert';

  @override
  String get conditionType => 'Bedingungstyp';

  @override
  String get continuePlay => 'Weiterspielen';

  @override
  String gameEndWinner(String name) {
    return '$name gewinnt';
  }

  @override
  String gameEndTie(String names) {
    return 'Unentschieden: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '$count Runde',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'niedrigste Punktzahl gewinnt';

  @override
  String get gameEndHighestWins => 'höchste Punktzahl gewinnt';

  @override
  String get gameEndAnalysis => 'Analyse';

  @override
  String get gameEndResults => 'Ergebnis';

  @override
  String get endGame => 'Spiel beenden';

  @override
  String get reopenGame => 'Spiel fortsetzen';

  @override
  String get gameFinished => 'Beendet';

  @override
  String get undo => 'Rückgängig';

  @override
  String get gameReopened => 'Partie wieder geöffnet';

  @override
  String get comment => 'Kommentar';

  @override
  String get enterComment => 'Kommentar eingeben';

  @override
  String get analyzeGame => 'Partie analysieren';

  @override
  String get analysisTitle => 'Partieanalyse';

  @override
  String get analysisStyle => 'Analysestil';

  @override
  String get analysisStyleProfessor => 'Der Professor';

  @override
  String get analysisStyleCommentator => 'Der Sportkommentator';

  @override
  String get analysisStyleDocumentary => 'Die Tierdokumentation';

  @override
  String get analysisStyleNoir => 'Der Detektiv';

  @override
  String get analysisStyleBard => 'Der Barde';

  @override
  String get analysisStyleCoach => 'Der Coach';

  @override
  String get analysisStyleConsultant => 'Der Berater';

  @override
  String get analysisStyleAstrologer => 'Der Astrologe';

  @override
  String get analysisStyleRealityTv => 'Die Realityshow';

  @override
  String get generatingAnalysis => 'Analyse wird erstellt…';

  @override
  String get generateAnalysis => 'Analyse erstellen';

  @override
  String get regenerateAnalysis => 'Analyse neu erstellen';

  @override
  String get deleteAnalysis => 'Analyse löschen';

  @override
  String get confirmRegenerateAnalysis =>
      'Neu erstellen? Die aktuelle Analyse wird ersetzt.';

  @override
  String get confirmDeleteAnalysis => 'Analyse für diese Partie löschen?';

  @override
  String get analysisError => 'Analyse konnte nicht erstellt werden';

  @override
  String get analysisErrorUnavailable =>
      'Der Analyseserver ist vorübergehend nicht verfügbar. Versuchen Sie es später erneut.';

  @override
  String get analysisErrorGroupBudget =>
      'Ihre Gruppe hat ihr Analysebudget für diesen Monat aufgebraucht. Es erneuert sich zu Beginn des nächsten Monats.';

  @override
  String get analysisStyleGroupDefault =>
      'Kein Stil gewählt: Dieses geteilte Spiel wird im Stil und in der Sprache der Gruppe analysiert.';

  @override
  String analysisErrorStatus(int status) {
    return 'Analyse konnte nicht erstellt werden (HTTP $status)';
  }

  @override
  String get retry => 'Erneut versuchen';

  @override
  String analysisGeneratedAt(String date) {
    return 'Erstellt am $date';
  }

  @override
  String get serverSection => 'Server';

  @override
  String get backendUrlLabel => 'Server-URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Für die Online-Funktionen wird ein CountScore-Server benötigt. Richte einen aus dem Ordner backend/ ein und trage hier seine Adresse ein. Ohne Server verlassen keine Daten dieses Gerät.';

  @override
  String get backendNotConfigured => 'Kein Server konfiguriert';

  @override
  String get backendUrlInvalid =>
      'Ungültige Adresse. Gib eine vollständige URL ein, zum Beispiel https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// wird nur im lokalen Netzwerk akzeptiert. Für einen öffentlichen Server https:// verwenden.';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get connectionOk => 'Der Server antwortet';

  @override
  String get connectionFailed => 'Der Server antwortet nicht';

  @override
  String get serverUrlSaved => 'Server gespeichert';

  @override
  String get analysisRequiresBackend =>
      'Diese Analyse benötigt einen Server. Richte einen in den Einstellungen ein.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get serverUrlCleared => 'Server gelöscht';

  @override
  String get groupSection => 'Gruppe';

  @override
  String get groupDescription =>
      'Teile Spiele mit den anderen Geräten deiner Gruppe. Geteilte Spiele mit ihren Spielern, Punkten, Kommentaren und Analysen werden an deinen Server gesendet; alle anderen Spiele bleiben auf diesem Gerät.';

  @override
  String get groupNeedsServer => 'Richte zuerst oben einen Server ein.';

  @override
  String get groupCreate => 'Gruppe erstellen';

  @override
  String get groupJoin => 'Gruppe beitreten';

  @override
  String get groupNameLabel => 'Gruppenname';

  @override
  String get deviceLabelLabel => 'Name dieses Geräts';

  @override
  String get deviceLabelDefault => 'Mein Gerät';

  @override
  String get shareTokenLabel => 'Einladungscode';

  @override
  String get shareTokenHint =>
      'Füge den Code ein, den dir ein Gruppenmitglied geschickt hat';

  @override
  String groupCurrent(String name) {
    return 'Gruppe: $name';
  }

  @override
  String get shareTokenExplain =>
      'Sende diesen Code an die Geräte, die der Gruppe beitreten sollen. Wer ihn hat, kann beitreten.';

  @override
  String get shareTokenCopy => 'Code kopieren';

  @override
  String get shareTokenCopied => 'Code kopiert';

  @override
  String get shareTokenRotate => 'Neuer Code';

  @override
  String get shareTokenRotateConfirm =>
      'Mit dem alten Code kann niemand mehr beitreten. Geräte, die bereits in der Gruppe sind, sind nicht betroffen.';

  @override
  String get groupLeave => 'Gruppe verlassen';

  @override
  String get groupLeaveConfirm =>
      'Dieses Gerät verlässt die Gruppe. Geteilte Spiele bleiben auf diesem Gerät, werden aber nicht mehr synchronisiert.';

  @override
  String get groupLeft => 'Gruppe verlassen';

  @override
  String get groupJoined => 'Gruppe beigetreten';

  @override
  String get clearServerLeavesGroup =>
      'Wenn du den Server löschst, verlässt du die Gruppe. Geteilte Spiele bleiben auf diesem Gerät.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String syncStatusIdle(String time) {
    return 'Synchronisiert um $time';
  }

  @override
  String get syncStatusSyncing => 'Synchronisiere…';

  @override
  String get syncStatusOffline =>
      'Server nicht erreichbar – Änderungen werden später gesendet';

  @override
  String get syncStatusUnauthorized =>
      'Der Server akzeptiert dieses Gerät nicht mehr. Verlasse die Gruppe und tritt ihr erneut bei.';

  @override
  String get syncStatusError => 'Serverfehler bei der Synchronisierung';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen ausstehend',
      one: '1 Änderung ausstehend',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen vom Server abgelehnt',
      one: '1 Änderung vom Server abgelehnt',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Unbekannter oder ersetzter Einladungscode';

  @override
  String get groupErrorRateLimited =>
      'Zu viele Versuche. Versuche es in einer Minute erneut.';

  @override
  String get groupErrorUnreachable => 'Server nicht erreichbar';

  @override
  String get groupErrorServer => 'Serverfehler';

  @override
  String get shareWithGroup => 'Mit der Gruppe teilen';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Die Geräte in $name sehen und bearbeiten dieses Spiel';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Das Spiel mit seinen Spielern, Punkten und Kommentaren wird an $name gesendet. Das Teilen kann nicht rückgängig gemacht werden.';
  }

  @override
  String get gameSharedDone => 'Spiel mit der Gruppe geteilt';

  @override
  String get gameSharedBadge => 'Geteiltes Spiel';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Diese Namen können nicht geteilt werden: $names. Verwende Buchstaben, Ziffern, Leerzeichen, Bindestriche, Apostrophe oder Punkte (höchstens 32 Zeichen).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Diese Runde wurde bereits auf einem anderen Gerät eingetragen und ist jetzt Runde $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '„$name“ wurde auf einem anderen Gerät gelöscht';
  }

  @override
  String get groupDevices => 'Geräte';

  @override
  String get groupDevicesExplain =>
      'Ein verlorenes oder verkauftes Handy kann hier aus der Gruppe entfernt werden.';

  @override
  String get groupDeviceThisOne => 'Dieses Gerät';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Zuletzt gesehen: $date';
  }

  @override
  String get groupDeviceRevoke => 'Entfernen';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '„$label“ aus der Gruppe entfernen? Es wird nicht mehr synchronisiert. Der Einladungscode ändert sich ebenfalls: Mitglieder behalten ihren Zugang, aber zum Einladen muss der neue Code geteilt werden.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '„$label“ wurde entfernt. Der Einladungscode hat sich geändert.';
  }

  @override
  String get reportCommentary => 'Diesen Kommentar melden';

  @override
  String get reportCommentarySubject =>
      'CountScore — Meldung eines KI-Kommentars';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Was ist an diesem KI-generierten Kommentar problematisch?\n\n\n---\nReferenz: $reference\nKommentar:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Keine E-Mail-App gefunden. Schreibe an $email, um diesen Kommentar zu melden.';
  }

  @override
  String get gameRulesTitle => 'Spielregeln';

  @override
  String get gameRulesInApp => 'In CountScore';

  @override
  String get gameRulesSection => 'Die Regeln';

  @override
  String get gameRulesNoElimination => 'Kein Ausscheiden während des Spiels';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Ein Spieler scheidet über $threshold Punkten aus';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Ein Spieler scheidet unter $threshold Punkten aus';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Das Spiel endet, sobald ein Spieler $threshold Punkte erreicht';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Das Spiel endet, sobald ein Spieler unter $threshold Punkte fällt';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Das Spiel endet, wenn alle bis auf einen Spieler über $threshold Punkten liegen';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Das Spiel endet, wenn alle bis auf einen Spieler unter $threshold Punkten liegen';
  }

  @override
  String get gameRulesNoEnd =>
      'Kein automatisches Ende: Sie entscheiden, wann das Spiel vorbei ist';

  @override
  String get gameRulesEmptyTitle => 'Noch keine Regeln';

  @override
  String get gameRulesEmptyHint =>
      'Halten Sie fest, wie an Ihrem Tisch gezählt wird — dann haben alle dieselbe Fassung.';

  @override
  String get gameRulesWrite => 'Regeln schreiben';

  @override
  String get gameRulesEditTitle => 'Regeln bearbeiten';

  @override
  String get gameRulesEditorHint =>
      'Die Regeln Ihres Tisches. Markdown wird unterstützt.';

  @override
  String get gameRulesFromGroup => 'Regeln Ihrer Gruppe';

  @override
  String get gameRulesRestoreDefault => 'Ursprüngliche Regeln wiederherstellen';

  @override
  String get gameRulesSaved => 'Regeln gespeichert';

  @override
  String get gameRulesRestored => 'Ursprüngliche Regeln wiederhergestellt';

  @override
  String get gameRulesDisclaimer =>
      'Zusammenfassung für CountScore, nach den üblicherweise gespielten Regeln. Spielnamen gehören ihren jeweiligen Eigentümern und werden nur beschreibend verwendet.';

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
  String get gameTypeNameOther => 'Andere';

  @override
  String get gameTypeNameOtherSortKey => 'Andere';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNameSkyjoSortKey => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'Präsident';

  @override
  String get gameTypeNamePresidentSortKey => 'Präsident';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameBeloteSortKey => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarock';

  @override
  String get gameTypeNameTarotSortKey => 'Tarock';

  @override
  String get gameTypeNameBridge => 'Bridge';

  @override
  String get gameTypeNameBridgeSortKey => 'Bridge';

  @override
  String get gameTypeNameRami => 'Rommé';

  @override
  String get gameTypeNameRamiSortKey => 'Rommé';

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
  String get gameTypeNameSixNimmt => '6 nimmt!';

  @override
  String get gameTypeNameSixNimmtSortKey => '6 nimmt!';

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
  String get groupDeviceOwner => 'Eigentümer';

  @override
  String get groupDeviceMakeOwner => 'Zum Eigentümer machen';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Die Gruppe an „$label“ übergeben? Dieses Gerät kann dann keine Geräte mehr entfernen und den Einladungscode nicht mehr ändern.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '„$label“ ist jetzt Eigentümer der Gruppe.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Nur der Eigentümer der Gruppe kann ein Gerät entfernen oder den Einladungscode ändern.';

  @override
  String get groupErrorNotOwner => 'Nur der Eigentümer der Gruppe kann das tun';

  @override
  String get whoStarts => 'Wer fängt an?';

  @override
  String get whoStartsAgain => 'Neu auslosen';

  @override
  String get diceRoller => 'Würfeln';

  @override
  String get diceCount => 'Anzahl der Würfel';

  @override
  String get diceRollAgain => 'Nochmal würfeln';

  @override
  String diceTotal(int total) {
    return 'Summe: $total';
  }

  @override
  String get resumeGame => 'Fortsetzen';

  @override
  String get recentGames => 'Zuletzt';

  @override
  String get gameInProgress => 'Läuft';

  @override
  String roundNumber(int number) {
    return 'Runde $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name führt · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Gewonnen von $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '$rank.',
      one: '$rank.',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'Eine Zeile pro Spieler';

  @override
  String get boardViewLanes => 'Eine Spalte pro Spieler';

  @override
  String get boardSeatOrder => 'Spielreihenfolge';

  @override
  String boardRoundShort(int number) {
    return 'Rd.$number';
  }

  @override
  String get boardPlayer => 'Spieler';

  @override
  String get boardTotal => 'Summe';

  @override
  String get boardLeader => 'In Führung';

  @override
  String get groupSettingsTitle => 'Kommentare und Verbrauch';

  @override
  String get groupSettingsDescription =>
      'Stil und Sprache der Kommentare, die der Server zu den Partien der Gruppe schreibt. Jedes Mitglied kann sie ändern.';

  @override
  String get groupCommentStyle => 'Kommentarstil';

  @override
  String get groupCommentStyleNarrative => 'Erzählend';

  @override
  String get groupCommentStyleHumorous => 'Humorvoll';

  @override
  String get groupCommentStyleAnalytical => 'Analytisch';

  @override
  String get groupCommentLanguage => 'Kommentarsprache';

  @override
  String get groupSettingsSaved => 'Gruppeneinstellungen gespeichert';

  @override
  String get groupUsageTitle => 'LLM-Verbrauch diesen Monat';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used von $budget verbraucht';
  }

  @override
  String groupUsageResets(String date) {
    return 'Wird am $date zurückgesetzt';
  }

  @override
  String get statsBestWinRate => 'Beste Siegquote';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins Siege in $games',
      one: '$wins Sieg in $games',
      zero: 'Kein Sieg in $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Spieler';

  @override
  String get statsColumnGames => 'Partien';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Partien · noch nicht gewertet',
      one: '$count Partie · noch nicht gewertet',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Gewertet ab $count beendeten Partien. Tippe auf einen Spieler, um seine Karte zu sehen.',
      one:
          'Gewertet ab $count beendeten Partie. Tippe auf einen Spieler, um seine Karte zu sehen.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Partien',
      one: 'Partie',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Siege',
      one: 'Sieg',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'Ø Platz';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Platz, letzte $count Partien',
      one: 'Platz, letzte Partie',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'im Aufwind';

  @override
  String get statsTrendDeclining => 'rückläufig';

  @override
  String get statsTrendSteady => 'konstant';

  @override
  String statsRankOrdinal(String rank) {
    return '$rank.';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serie: $count Siege',
      one: 'Serie: $count Sieg',
      zero: 'Keine Siegesserie',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Rekord: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Bei $gameType';
  }

  @override
  String get statsAverageTotal => 'Durchschnittliches Endergebnis';

  @override
  String get statsBestTotal => 'Bestes Endergebnis';

  @override
  String get statsMostBeaten => 'Am häufigsten geschlagen';

  @override
  String get statsOpenPlayerCard => 'Spielerkarte öffnen';

  @override
  String get shareResult => 'Ergebnis teilen';

  @override
  String get shareAnalysis => 'Analyse teilen';

  @override
  String shareResultSubject(String gameName) {
    return 'Ergebnis: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Partie vom $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points Punkte',
      one: '$points Punkt',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Punkte gezählt mit $appName: $url';
  }

  @override
  String get shareFailed => 'Teilen konnte nicht geöffnet werden';

  @override
  String get newGameNameLabel => 'Name';

  @override
  String get newGameGameLabel => 'Spiel';

  @override
  String newGameAllGames(int count) {
    return 'Alle Spiele ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Spieler · Sitzordnung';

  @override
  String get newGameDragToReorder => 'zum Umordnen ziehen';

  @override
  String get newGameDealer => 'gibt';

  @override
  String get newGameAddPlayer => 'Spieler hinzufügen';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Starten · $count Spieler',
      one: 'Starten · 1 Spieler',
      zero: 'Starten',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Wer spielt mit?';

  @override
  String get whoIsPlayingSearchHint => 'Name oder neuer Spieler';

  @override
  String get whoIsPlayingFrequent => 'Spielt oft mit dir';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Dieselben Spieler wie „$gameName“';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '„$name“ anlegen';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler hinzufügen',
      one: '1 Spieler hinzufügen',
      zero: 'Fertig',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Spiel $number';
  }

  @override
  String get pwaUpdateReady => 'Eine neue Version von CountScore ist bereit';

  @override
  String get pwaUpdateReload => 'Neu laden';

  @override
  String get groupDeviceClaimOwner => 'Eigentum übernehmen';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '„$label“ ist Eigentümer der Gruppe, war aber lange nicht mehr zu sehen. Das Eigentum auf dieses Gerät übernehmen?';
  }

  @override
  String get groupDeviceOwnerClaimed =>
      'Dieses Gerät ist jetzt Eigentümer der Gruppe.';

  @override
  String get groupErrorOwnerActive =>
      'Der Eigentümer der Gruppe war kürzlich aktiv: Das Eigentum kann nicht übernommen werden.';

  @override
  String get groupCreatedOwnerExplain =>
      'Gruppe erstellt. Dieses Gerät ist ihr Eigentümer; diese Rolle kann unter „Geräte“ an ein anderes übergeben werden.';
}
