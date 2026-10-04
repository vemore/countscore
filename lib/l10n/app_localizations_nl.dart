// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Home';

  @override
  String get playersListTitle => 'Spelerlijst';

  @override
  String get gameTypesTitle => 'Speltypen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get aboutTitle => 'Over';

  @override
  String get newGame => 'Nieuw spel';

  @override
  String get noGames => 'Geen spellen';

  @override
  String get noGamesOfThisType => 'Geen spellen van dit type';

  @override
  String get createFirstGame => 'Maak je eerste spel';

  @override
  String get newWithSamePlayers => 'Nieuw met dezelfde spelers';

  @override
  String get playAgain => 'Speel opnieuw';

  @override
  String get rename => 'Hernoemen';

  @override
  String get delete => 'Verwijderen';

  @override
  String get confirmDeletion => 'Verwijdering bevestigen';

  @override
  String confirmDeleteGame(String name) {
    return 'Wil je het spel \"$name\" echt verwijderen?';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String get renameGame => 'Spel hernoemen';

  @override
  String get gameName => 'Spelnaam';

  @override
  String get save => 'Opslaan';

  @override
  String get allGames => 'Alle spellen';

  @override
  String get filterGames => 'Spellen filteren';

  @override
  String get applyFilter => 'Toepassen';

  @override
  String get resetFilter => 'Opnieuw instellen';

  @override
  String get selectGameType => 'Selecteer een speltype';

  @override
  String get gameType => 'Speltype';

  @override
  String get loadingGameTypes => 'Speltypen laden...';

  @override
  String get lowestScoreWins => 'Laagste score wint';

  @override
  String get highestScoreWins => 'Hoogste score wint';

  @override
  String get players => 'Spelers';

  @override
  String get add => 'Toevoegen';

  @override
  String get pleaseEnterName => 'Voer alstublieft een naam in';

  @override
  String get clear => 'Wissen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get game => 'Spel';

  @override
  String get editGame => 'Spel bewerken';

  @override
  String get editGameDialogTitle => 'Spel bewerken';

  @override
  String get removePlayer => 'Speler verwijderen';

  @override
  String get addPlayerToGame => 'Speler toevoegen';

  @override
  String get warningRemovePlayer =>
      'Waarschuwing! Het verwijderen van deze speler verwijdert al hun scores uit dit spel. Deze actie kan niet ongedaan gemaakt worden.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Wil je $playerName echt uit dit spel verwijderen?';
  }

  @override
  String get playerRemoved => 'Speler uit spel verwijderd';

  @override
  String get deleteLastRound => 'Laatste ronde verwijderen';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get confirmDeleteLastRound => 'Laatste ronde verwijderen?';

  @override
  String get noPlayersInGame => 'Geen spelers in dit spel';

  @override
  String get round => 'Ronde';

  @override
  String boardRoundButton(int round) {
    return 'Ronde $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · ronde $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · ronde $round · $position/$count';
  }

  @override
  String keypadTotalAfter(String total) {
    return 'totaal na: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Volgende\n$player';
  }

  @override
  String get keypadValidateRound => 'Ronde valideren';

  @override
  String get keypadToggleSign => 'Teken wijzigen';

  @override
  String get keypadBackspace => 'Cijfer verwijderen';

  @override
  String get keypadShortcutTitle => 'Sneltoets toetsenblok';

  @override
  String get keypadShortcutKind => 'Soort toets';

  @override
  String get keypadShortcutKindValue => 'Een waarde invoeren';

  @override
  String get keypadShortcutKindMultiply =>
      'Score vermenigvuldigen (alleen positief)';

  @override
  String get keypadShortcutKindAdd => 'Bij score optellen';

  @override
  String get keypadShortcutAmount => 'Getal';

  @override
  String get keypadShortcutLabel => 'Toetslabel (optioneel)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'Een geheel getal tussen $min en $max, ongelijk aan 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'Een geheel getal tussen $min en $max';
  }

  @override
  String get appearance => 'Uiterlijk';

  @override
  String get light => 'Licht';

  @override
  String get dark => 'Donker';

  @override
  String get system => 'Systeem';

  @override
  String get screen => 'Scherm';

  @override
  String get keepScreenAwake => 'Scherm actief houden';

  @override
  String get keepScreenAwakeDescription =>
      'Voorkomt dat het scherm in slaapstand gaat tijdens een spel';

  @override
  String get backup => 'Back-up';

  @override
  String get exportDatabase => 'Database exporteren';

  @override
  String get exportDatabaseDescription => 'Sla al je spellen op in een bestand';

  @override
  String get databaseExportedTo => 'Database geëxporteerd naar:';

  @override
  String get errorDuringExport => 'Fout bij export:';

  @override
  String get importDatabase => 'Database importeren';

  @override
  String get importDatabaseDescription =>
      'Herstel je spellen vanuit een back-upbestand';

  @override
  String get confirmation => 'Bevestiging';

  @override
  String get importWarning =>
      'Importeren zal al je huidige gegevens vervangen. Er wordt automatisch een back-up gemaakt vóór het importeren.\n\nWil je doorgaan?';

  @override
  String get import => 'Importeren';

  @override
  String get databaseImportedSuccessfully => 'Database succesvol geïmporteerd';

  @override
  String get importSuccessful => 'Import geslaagd';

  @override
  String get importSuccessMessage =>
      'De database is succesvol geïmporteerd.\n\nDe toepassing sluit nu af. Opnieuw openen om de nieuwe gegevens te zien.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Fout bij import:';

  @override
  String get noPlayers => 'Geen spelers';

  @override
  String get playersAppearMessage =>
      'Spelers verschijnen hier zodra\nje spellen hebt gemaakt';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spellen',
      one: '1 spel',
      zero: '0 spellen',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count winsten',
      one: '1 winst',
      zero: '0 winsten',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Kleur wijzigen';

  @override
  String get renamePlayer => 'Speler hernoemen';

  @override
  String get newName => 'Nieuwe naam';

  @override
  String playerRenamedTo(String name) {
    return 'Speler hernoemd naar \"$name\"';
  }

  @override
  String get deletePlayer => 'Speler verwijderen';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Wil je \"$name\" echt verwijderen?\n\nDeze speler wordt verwijderd uit alle $count spel(len).';
  }

  @override
  String playerDeleted(String name) {
    return 'Speler \"$name\" verwijderd';
  }

  @override
  String get chooseColor => 'Kies een kleur';

  @override
  String get noGameTypes => 'Geen speltypen';

  @override
  String get edit => 'Bewerken';

  @override
  String get newType => 'Nieuw type';

  @override
  String get editType => 'Type bewerken';

  @override
  String get newGameType => 'Nieuw speltype';

  @override
  String get gameTypeName => 'Naam van speltype';

  @override
  String get icon => 'Pictogram:';

  @override
  String get color => 'Kleur:';

  @override
  String get chooseIcon => 'Kies een pictogram';

  @override
  String get nameIsRequired => 'Naam is vereist';

  @override
  String get create => 'Maken';

  @override
  String get ranking => 'Rangschikking';

  @override
  String get noCurrentGame => 'Geen huidig spel';

  @override
  String get noScoresRecorded => 'Geen scores geregistreerd';

  @override
  String get playerStatistics => 'Spelersstatistieken';

  @override
  String get noStatisticsAvailable => 'Geen statistieken beschikbaar';

  @override
  String get gamesPlayed => 'Gespeelde spellen';

  @override
  String get wins => 'Winsten';

  @override
  String get winRate => 'Winpercentage';

  @override
  String get byGameType => 'Op speltype';

  @override
  String get rate => 'Percentage';

  @override
  String version(String version) {
    return 'Versie $version';
  }

  @override
  String get appDescription =>
      'Scoresturingtoepassing voor je spelletjes door Vincent Moreau';

  @override
  String get features => 'Functies';

  @override
  String get featureDifferentGameTypes => 'Verschillende speltypen';

  @override
  String get featurePlayerManagement => 'Spelersbeheer';

  @override
  String get featureDetailedStatistics => 'Gedetailleerde statistieken';

  @override
  String get featureCustomization => 'Aanpassing';

  @override
  String get featureDarkLightTheme => 'Donker/licht thema';

  @override
  String get featureGroupSharing => 'Groepsdeling';

  @override
  String get featureGameAnalysis => 'AI-spelanalyse';

  @override
  String get rateApp => 'Beoordeel CountScore';

  @override
  String get search => 'Zoeken';

  @override
  String get newPlayerName => 'Naam nieuwe speler';

  @override
  String get noPlayersFound => 'Geen spelers gevonden';

  @override
  String get close => 'Sluiten';

  @override
  String get playerEliminationCondition => 'Speilerelimineringsvoorwaarde';

  @override
  String get gameOverCondition => 'Voorwaarde spelbeëindiging';

  @override
  String get none => 'Geen';

  @override
  String get overThreshold => 'Boven drempel';

  @override
  String get underThreshold => 'Onder drempel';

  @override
  String get firstPlayerOver => 'Eerste speler aan';

  @override
  String get firstPlayerUnder => 'Eerste speler onder';

  @override
  String get lastPlayerOver => 'Laatste speler staande (anderen boven)';

  @override
  String get lastPlayerUnder => 'Laatste speler staande (anderen onder)';

  @override
  String get threshold => 'Drempel';

  @override
  String get conditionType => 'Soort voorwaarde';

  @override
  String get continuePlay => 'Speel verder';

  @override
  String gameEndWinner(String name) {
    return '$name wint';
  }

  @override
  String gameEndTie(String names) {
    return 'Gelijkspel: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondes',
      one: '$count ronde',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'laagste score wint';

  @override
  String get gameEndHighestWins => 'hoogste score wint';

  @override
  String get gameEndAnalysis => 'Analyse';

  @override
  String get gameEndResults => 'Resultaten';

  @override
  String get rankingEliminationNote =>
      'Gerangschikt op elimineringsvolorde: wie later uitvalt staat hoger, ongeacht de totalen.';

  @override
  String get endGame => 'Spel beëindigen';

  @override
  String get reopenGame => 'Spel heropenen';

  @override
  String get gameFinished => 'Afgelopen';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get gameReopened => 'Spel heropend';

  @override
  String get comment => 'Opmerking';

  @override
  String get enterComment => 'Voer een opmerking in';

  @override
  String get analyzeGame => 'Spel analyseren';

  @override
  String get analysisTitle => 'Spelanalyse';

  @override
  String get analysisStyle => 'Analysestijl';

  @override
  String get analysisStyleProfessor => 'De professor';

  @override
  String get analysisStyleCommentator => 'De sportcommentator';

  @override
  String get analysisStyleDocumentary => 'De wildlife-documentaire';

  @override
  String get analysisStyleNoir => 'De detective';

  @override
  String get analysisStyleBard => 'De bard';

  @override
  String get analysisStyleCoach => 'De coach';

  @override
  String get analysisStyleConsultant => 'De consultant';

  @override
  String get analysisStyleAstrologer => 'De astroloog';

  @override
  String get analysisStyleRealityTv => 'De realityshow';

  @override
  String get generatingAnalysis => 'Analyse wordt gegenereerd…';

  @override
  String get generateAnalysis => 'Analyse genereren';

  @override
  String get regenerateAnalysis => 'Analyse opnieuw genereren';

  @override
  String get deleteAnalysis => 'Analyse verwijderen';

  @override
  String get confirmRegenerateAnalysis =>
      'Opnieuw genereren? Huidige analyse wordt vervangen.';

  @override
  String get confirmDeleteAnalysis => 'Analyse voor dit spel verwijderen?';

  @override
  String get analysisError => 'Analyse genereren is mislukt';

  @override
  String get analysisErrorUnavailable =>
      'De analyseserver is tijdelijk niet beschikbaar. Probeer het later opnieuw.';

  @override
  String get analysisErrorGroupBudget =>
      'Je groep heeft haar analysebudget voor deze maand opgebruikt. Het wordt vernieuwd aan het begin van volgende maand.';

  @override
  String get analysisStyleGroupDefault =>
      'Geen stijl geselecteerd: dit gedeelde spel wordt in de stijl en taal van de groep geanalyseerd.';

  @override
  String analysisErrorStatus(int status) {
    return 'Analyse genereren is mislukt (HTTP $status)';
  }

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String analysisGeneratedAt(String date) {
    return 'Gegenereerd op $date';
  }

  @override
  String get serverSection => 'Server';

  @override
  String get backendUrlLabel => 'Server-URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Verbonden functies vereisen een CountScore-server. Installeer er een vanuit de backend/-map en voer het adres hier in. Zonder server verlaat geen gegevens dit apparaat.';

  @override
  String get backendNotConfigured => 'Geen server geconfigureerd';

  @override
  String get backendUrlInvalid =>
      'Ongeldig adres. Voer een volledige URL in, bijvoorbeeld https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// wordt alleen op een lokaal netwerk geaccepteerd. Gebruik https:// voor een openbare server.';

  @override
  String get testConnection => 'Verbinding testen';

  @override
  String get connectionOk => 'De server reageert';

  @override
  String get connectionFailed => 'De server reageert niet';

  @override
  String get serverUrlSaved => 'Server opgeslagen';

  @override
  String get analysisRequiresBackend =>
      'Deze analyse vereist een server. Configureer er een in de instellingen.';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get serverUrlCleared => 'Server gewist';

  @override
  String get groupSection => 'Groep';

  @override
  String get groupDescription =>
      'Deel spellen met andere apparaten in je groep. Gedeelde spellen, hun spelers, scores, opmerkingen en analyses worden naar je server gestuurd; andere spellen blijven op dit apparaat.';

  @override
  String get groupNeedsServer => 'Stel eerst een server hierboven in.';

  @override
  String get groupCreate => 'Een groep maken';

  @override
  String get groupJoin => 'Een groep toetreden';

  @override
  String get groupNameLabel => 'Groepsnaam';

  @override
  String get groupNicknameLabel => 'Je bijnaam';

  @override
  String get groupNicknameHint => 'De anderen in de groep zien het';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Je bijnaam: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Je bijnaam wijzigen';

  @override
  String get shareTokenLabel => 'Uitnodigingscode';

  @override
  String get shareTokenHint =>
      'Plak de code die een groeplid je heeft gestuurd';

  @override
  String groupCurrent(String name) {
    return 'Groep: $name';
  }

  @override
  String get shareTokenExplain =>
      'Stuur deze code naar de apparaten die de groep moeten toetreden. Iedereen die hem heeft kan toetreden.';

  @override
  String get shareTokenCopy => 'Code kopiëren';

  @override
  String get shareTokenCopied => 'Code gekopieerd';

  @override
  String get shareTokenRotate => 'Nieuwe code';

  @override
  String get shareTokenRotateConfirm =>
      'De oude code laat niemand meer toetreden. Apparaten die al lid zijn worden niet beïnvloed.';

  @override
  String get groupLeave => 'Groep verlaten';

  @override
  String get groupLeaveConfirm =>
      'Dit apparaat verlaat de groep. Gedeelde spellen blijven op dit apparaat maar worden niet meer gesynchroniseerd.';

  @override
  String get groupLeft => 'Groep verlaten';

  @override
  String get groupJoined => 'Groep toegetreden';

  @override
  String get clearServerLeavesGroup =>
      'Server wissen verlaat de groep. Gedeelde spellen blijven op dit apparaat.';

  @override
  String get syncNow => 'Nu synchroniseren';

  @override
  String syncStatusIdle(String time) {
    return 'Gesynchroniseerd op $time';
  }

  @override
  String get syncStatusSyncing => 'Synchroniseren…';

  @override
  String get syncStatusOffline =>
      'Server onbereikbaar — wijzigingen worden later verzonden';

  @override
  String get syncStatusUnauthorized =>
      'De server accepteert dit apparaat niet meer. Verlaat de groep en sluit je er opnieuw bij aan.';

  @override
  String get syncStatusError => 'Serverfout tijdens synchronisatie';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wijzigingen in afwachting',
      one: '1 wijziging in afwachting',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wijzigingen geweigerd door de server',
      one: '1 wijziging geweigerd door de server',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Onbekende of vervangen uitnodigingscode';

  @override
  String get groupErrorRateLimited =>
      'Te veel pogingen. Probeer over een minuut opnieuw.';

  @override
  String get groupErrorUnreachable => 'Server onbereikbaar';

  @override
  String get groupErrorServer => 'Serverfout';

  @override
  String get shareWithGroup => 'Met de groep delen';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Apparaten in $name zien en bewerken dit spel';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Het spel, zijn spelers, scores en opmerkingen worden naar $name verzonden. Delen kan niet ongedaan gemaakt worden.';
  }

  @override
  String get gameSharedDone => 'Spel met de groep gedeeld';

  @override
  String get gameSharedBadge => 'Gedeeld spel';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Deze namen kunnen niet worden gedeeld: $names. Gebruik letters, cijfers, spaties, koppeltekens, apostrofs of punten (maximaal 32 tekens).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Deze ronde was al op een ander apparaat ingevoerd, dus het werd ronde $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'Spel \"$name\" is op een ander apparaat verwijderd';
  }

  @override
  String get groupDevices => 'Apparaten';

  @override
  String get groupDevicesExplain =>
      'Een verloren of verkocht telefoon kan hier uit de groep worden verwijderd.';

  @override
  String get groupDeviceThisOne => 'Dit apparaat';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Laatst gezien $date';
  }

  @override
  String get groupDeviceRevoke => 'Verwijderen';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Verwijder \"$label\" uit de groep? Het zal niet meer synchroniseren. De uitnodigingscode verandert ook: leden houden hun toegang, maar je moet de nieuwe code delen om iemand uit te nodigen.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" is verwijderd. De uitnodigingscode is veranderd.';
  }

  @override
  String get reportCommentary => 'Deze commentaar melden';

  @override
  String get reportCommentarySubject => 'CountScore — AI-commentaarrapporten';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Wat is er mis met deze AI-gegenereerde commentaar?\n\n\n---\nReferentie: $reference\nCommentaar:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Geen e-mailapp gevonden. Schrijf naar $email om deze commentaar te melden.';
  }

  @override
  String get gameRulesTitle => 'Spelregels';

  @override
  String get gameRulesInApp => 'In CountScore';

  @override
  String get gameRulesSection => 'De regels';

  @override
  String get gameRulesNoElimination => 'Geen eliminatie tijdens het spel';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Een speler wordt boven $threshold punten geëlimineerd';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Een speler wordt onder $threshold punten geëlimineerd';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Het spel eindigt zodra een speler $threshold punten bereikt';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Het spel eindigt zodra een speler onder $threshold punten zakt';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Het spel eindigt wanneer alle spelers behalve één boven $threshold punten liggen';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Het spel eindigt wanneer alle spelers behalve één onder $threshold punten liggen';
  }

  @override
  String get gameRulesNoEnd =>
      'Geen automatische beëindiging: je beslist wanneer het spel voorbij is';

  @override
  String get gameRulesEmptyTitle => 'Nog geen regels';

  @override
  String get gameRulesEmptyHint =>
      'Noteer hoe je groep de punten telt — iedereen heeft dezelfde versie.';

  @override
  String get gameRulesWrite => 'Schrijf de regels';

  @override
  String get gameRulesEditTitle => 'Regels bewerken';

  @override
  String get gameRulesEditorHint =>
      'De regels van je groep. Markdown wordt ondersteund.';

  @override
  String get gameRulesFromGroup => 'Regels van je groep';

  @override
  String get gameRulesRestoreDefault => 'Originele regels herstellen';

  @override
  String get gameRulesSaved => 'Regels opgeslagen';

  @override
  String get gameRulesRestored => 'Originele regels hersteld';

  @override
  String get gameRulesDisclaimer =>
      'Samenvatting geschreven voor CountScore van de regels zoals deze gewoonlijk worden gespeeld. Spelnamen behoren toe aan hun respectieve eigenaren en worden alleen beschrijvend gebruikt.';

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
  String get gameTypeNameOther => 'Ander';

  @override
  String get gameTypeNameOtherSortKey => 'Ander';

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
  String get gameTypeNameRami => 'Rummikub';

  @override
  String get gameTypeNameRamiSortKey => 'Rummikub';

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
  String get groupDeviceOwner => 'Eigenaar';

  @override
  String get groupDeviceMakeOwner => 'Eigenaar maken';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'De groep aan \"$label\" geven? Dit apparaat kan geen apparaten verwijderen of de uitnodigingscode wijzigen.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" is nu eigenaar van de groep.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Alleen de eigenaar van de groep kan een apparaat verwijderen of de uitnodigingscode wijzigen.';

  @override
  String get groupErrorNotOwner =>
      'Alleen de eigenaar van de groep kan dit doen';

  @override
  String get whoStarts => 'Wie begint?';

  @override
  String get whoStartsAgain => 'Opnieuw gooien';

  @override
  String get diceRoller => 'Dobbelsteen gooien';

  @override
  String get diceCount => 'Aantal dobbelstenen';

  @override
  String get diceRollAgain => 'Opnieuw gooien';

  @override
  String diceTotal(int total) {
    return 'Totaal: $total';
  }

  @override
  String get resumeGame => 'Hervatten';

  @override
  String get recentGames => 'Recent';

  @override
  String get gameInProgress => 'In voortgang';

  @override
  String roundNumber(int number) {
    return 'ronde $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name leidt · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Gewonnen door $name';
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
  String get boardViewRows => 'Één rij per speler';

  @override
  String get boardViewLanes => 'Één kolom per speler';

  @override
  String get boardSeatOrder => 'Zitorde';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'Speler';

  @override
  String get boardTotal => 'Totaal';

  @override
  String get boardLeader => 'Leidt';

  @override
  String get groupSettingsTitle => 'Opmerkingen en gebruik';

  @override
  String get groupSettingsDescription =>
      'De stijl en taal van de opmerkingen die de server voor de spellen van de groep schrijft. Elk lid kan ze wijzigen.';

  @override
  String get groupCommentStyle => 'Opmerking stijl';

  @override
  String get groupCommentStyleNarrative => 'Verhaal';

  @override
  String get groupCommentStyleHumorous => 'Humoristisch';

  @override
  String get groupCommentStyleAnalytical => 'Analytisch';

  @override
  String get groupCommentLanguage => 'Opmerking taal';

  @override
  String get groupSettingsSaved => 'Groepsinstellingen opgeslagen';

  @override
  String get groupUsageTitle => 'LLM-gebruik deze maand';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used besteed van $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Opnieuw ingesteld op $date';
  }

  @override
  String get statsBestWinRate => 'Beste winpercentage';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins winsten van $games',
      one: '$wins winst van $games',
      zero: 'Geen winsten van $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Speler';

  @override
  String get statsColumnGames => 'Spellen';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spellen · nog niet geclassificeerd',
      one: '$count spel · nog niet geclassificeerd',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Geclassificeerd van $count afgelopen spellen. Tik op een speler om hun kaart te zien.',
      one:
          'Geclassificeerd van $count afgelopen spel. Tik op een speler om hun kaart te zien.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'spellen',
      one: 'spel',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'winsten',
      one: 'winst',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'gemiddelde plaats';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plaats, vorige $count spellen',
      one: 'Plaats, vorige spel',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'verbetert';

  @override
  String get statsTrendDeclining => 'verslechtert';

  @override
  String get statsTrendSteady => 'stabiel';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1e',
      '2': '2e',
      '3': '3e',
      'other': '${rank}de',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Strijd: $count winsten',
      one: 'Strijd: $count winst',
      zero: 'Geen winststrijd',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'Beste: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Op $gameType';
  }

  @override
  String get statsAverageTotal => 'Gemiddeld slottotaal';

  @override
  String get statsBestTotal => 'Beste slottotaal';

  @override
  String get statsMostBeaten => 'Meest verslagen tegenstander';

  @override
  String get statsOpenPlayerCard => 'spelerskaart openen';

  @override
  String get shareResult => 'Het resultaat delen';

  @override
  String get shareAnalysis => 'Analyse delen';

  @override
  String shareResultSubject(String gameName) {
    return 'Resultaat: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Spel van $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points punten',
      one: '$points punt',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Scores bijgehouden met $appName: $url';
  }

  @override
  String get shareFailed => 'Delen kon niet worden geopend';

  @override
  String get newGameNameLabel => 'Naam';

  @override
  String get newGameGameLabel => 'Spel';

  @override
  String newGameAllGames(int count) {
    return 'Alle spellen ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Spelers · zitorde';

  @override
  String get newGameDragToReorder => 'slepen om te herordenen';

  @override
  String get newGameDealer => 'deelt';

  @override
  String get newGameAddPlayer => 'Voeg een speler toe';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start · $count spelers',
      one: 'Start · 1 speler',
      zero: 'Start',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Wie speelt mee?';

  @override
  String get whoIsPlayingSearchHint => 'Naam, of een nieuwe speler';

  @override
  String get whoIsPlayingFrequent => 'Speelt vaak met je';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Dezelfde spelers als \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Maak \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spelers toevoegen',
      one: '1 speler toevoegen',
      zero: 'Klaar',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Spel $number';
  }

  @override
  String get pwaUpdateReady =>
      'Een nieuwe versie van CountScore is beschikbaar';

  @override
  String get pwaUpdateReload => 'Opnieuw laden';

  @override
  String get thresholdIsRequired =>
      'Een drempel is vereist voor deze voorwaarde';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'De drempel kan niet hoger zijn dan $maxString';
  }

  @override
  String get deletionImpossible => 'Verwijdering onmogelijk';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count spellen gebruiken dit type: het kan niet worden verwijderd.',
      one: '1 spel gebruikt dit type: het kan niet worden verwijderd.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Wil je het speltype \"$name\" echt verwijderen?';
  }

  @override
  String get winDirectionChangeTitle => 'Omgekeerde winstand?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count afgelopen spellen van dit type zullen hun stand omgekeerd hebben: hun winnaars worden de laatsten.',
      one: '1 afgelopen spel van dit type zal zijn stand omgekeerd hebben: de winnaar wordt de laatste.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'De spielbeëindigingsvoorwaarde beloont de tegenovergestelde van de gekozen winnaar. Een huisregel kan precies dat willen.';

  @override
  String get rulesOutOfDateTitle => 'Regels bijwerken?';

  @override
  String get rulesOutOfDateMessage =>
      'De regels van dit type beschrijven nog steeds de oude voorwaarde.';

  @override
  String get later => 'Later';

  @override
  String get currentIcon => 'Huidig pictogram';

  @override
  String get currentColor => 'Huidge kleur';

  @override
  String get groupDeviceClaimOwner => 'Eigenaarschap claimen';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" is eigenaar van de groep maar is al lange tijd niet gezien. Neem eigenaarschap op dit apparaat over?';
  }

  @override
  String get groupDeviceOwnerClaimed =>
      'Dit apparaat is nu eigenaar van de groep.';

  @override
  String get groupErrorOwnerActive =>
      'De eigenaar van de groep is onlangs gezien: eigenaarschap kan niet worden geclaimd.';

  @override
  String get groupCreatedOwnerExplain =>
      'Groep gemaakt. Dit apparaat is eigenaar; de rol kan op een ander apparaat worden overgedragen in Apparaten.';

  @override
  String get boardEliminated => 'Geëlimineerd';

  @override
  String get soundsSection => 'Geluiden';

  @override
  String get gameSounds => 'Spelgeluiden';

  @override
  String get gameSoundsDescription =>
      'Een geluid wanneer een speler wordt geëlimineerd, wanneer het spel is gewonnen en wanneer de timer eindigt';

  @override
  String get turnTimer => 'Beurt timer';

  @override
  String get turnTimerLess => 'Minder tijd';

  @override
  String get turnTimerMore => 'Meer tijd';

  @override
  String get turnTimerStart => 'Start';

  @override
  String get turnTimerPause => 'Pauzeren';

  @override
  String get turnTimerReset => 'Herstellen';

  @override
  String get turnTimerTimeUp => 'Tijd voorbij!';

  @override
  String get configShareOpen => 'Delen via QR-code';

  @override
  String get configShareTitle => 'Deze configuratie delen';

  @override
  String get configShareExplainServer =>
      'Scan deze code met een ander telefoon om het in te stellen met dezelfde server.';

  @override
  String configShareExplainGroup(String name) {
    return 'Scan deze code met een ander telefoon om het in te stellen met dezelfde server en de groep $name toe te treden. Het bevat de uitnodigingscode van de groep: toon het alleen aan de mensen die je in de groep wilt.';
  }

  @override
  String get configShareWebAppLabel => 'Webapp-adres';

  @override
  String get configShareWebAppHelper =>
      'Waar je server de CountScore-webapp serveert, zoals https://countscore.example.com/countscore. De code opent deze pagina.';

  @override
  String get configShareWebAppNeeded =>
      'Voer het webapp-adres in om de code te tonen.';

  @override
  String get configShareQrLabel => 'QR-code van de configuratiekoppeling';

  @override
  String get configShareCopyLink => 'Link kopiëren';

  @override
  String get configShareLinkCopied => 'Link gekopieerd';

  @override
  String get configShareTooLong =>
      'Deze link is te lang voor een QR-code. Gebruik in plaats daarvan \"Link kopiëren\".';

  @override
  String get replaceConfigTitle => 'Configuratie vervangen?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Nu: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Nieuw: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'uitnodigingscode $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'Dit apparaat verlaat de groep $name. De spellen blijven op dit apparaat.';
  }

  @override
  String get replaceConfigConfirm => 'Vervangen';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count wijzigingen op dit apparaat zijn nog niet bij de groep aangekomen. Als je nu vertrekt, ontvangt de groep deze nooit.',
      one: '1 wijziging op dit apparaat is nog niet bij de groep aangekomen. Als je nu vertrekt, ontvangt de groep deze nooit.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Toch vertrekken';

  @override
  String get replaceConfigDone => 'Configuratie vervangen';

  @override
  String get replaceConfigUnchanged =>
      'Dit apparaat gebruikt al deze configuratie';

  @override
  String get joinLinkHandOverMessage =>
      'Deze link kan openen in de CountScore Android-app. Als de app niet is geïnstalleerd, wordt de Play Store geopend.';

  @override
  String get joinLinkOpenInApp => 'Open in de app';

  @override
  String get joinLinkContinueHere => 'Doorgaan in de browser';
}
