// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Home';

  @override
  String get playersListTitle => 'Lista Giocatori';

  @override
  String get gameTypesTitle => 'Tipi di Gioco';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get aboutTitle => 'Info';

  @override
  String get newGame => 'Nuova Partita';

  @override
  String get noGames => 'Nessuna partita';

  @override
  String get noGamesOfThisType => 'Nessuna partita di questo tipo';

  @override
  String get createFirstGame => 'Crea la tua prima partita';

  @override
  String get newWithSamePlayers => 'Nuova con gli stessi giocatori';

  @override
  String get playAgain => 'Gioca di nuovo';

  @override
  String get rename => 'Rinomina';

  @override
  String get delete => 'Elimina';

  @override
  String get confirmDeletion => 'Conferma eliminazione';

  @override
  String confirmDeleteGame(String name) {
    return 'Vuoi davvero eliminare la partita \"$name\"?';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get renameGame => 'Rinomina partita';

  @override
  String get gameName => 'Nome partita';

  @override
  String get save => 'Salva';

  @override
  String get allGames => 'Tutte le partite';

  @override
  String get filterGames => 'Filtra partite';

  @override
  String get applyFilter => 'Applica';

  @override
  String get resetFilter => 'Reimposta';

  @override
  String get selectGameType => 'Seleziona un tipo di gioco';

  @override
  String get gameType => 'Tipo di gioco';

  @override
  String get loadingGameTypes => 'Caricamento tipi di gioco...';

  @override
  String get lowestScoreWins => 'Vince il punteggio più basso';

  @override
  String get highestScoreWins => 'Vince il punteggio più alto';

  @override
  String get players => 'Giocatori';

  @override
  String get add => 'Aggiungi';

  @override
  String get pleaseEnterName => 'Per favore, inserisci un nome';

  @override
  String get clear => 'Cancella';

  @override
  String get remove => 'Rimuovi';

  @override
  String get game => 'Partita';

  @override
  String get editGame => 'Modifica partita';

  @override
  String get editGameDialogTitle => 'Modifica partita';

  @override
  String get removePlayer => 'Rimuovi giocatore';

  @override
  String get addPlayerToGame => 'Aggiungi giocatore';

  @override
  String get warningRemovePlayer =>
      'Attenzione! La rimozione di questo giocatore eliminerà tutti i suoi punteggi da questa partita. Questa azione è irreversibile.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Vuoi davvero rimuovere $playerName da questa partita?';
  }

  @override
  String get playerRemoved => 'Giocatore rimosso dalla partita';

  @override
  String get deleteLastRound => 'Elimina ultimo round';

  @override
  String get confirm => 'Conferma';

  @override
  String get confirmDeleteLastRound => 'Eliminare l\'ultimo round?';

  @override
  String get noPlayersInGame => 'Nessun giocatore in questa partita';

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
  String keypadTotalAfter(String total) {
    return 'totale dopo: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Successivo\n$player';
  }

  @override
  String get keypadValidateRound => 'Convalida round';

  @override
  String get keypadToggleSign => 'Cambia segno';

  @override
  String get keypadBackspace => 'Elimina una cifra';

  @override
  String get keypadShortcutTitle => 'Scorciatoia tastierino';

  @override
  String get keypadShortcutKind => 'Tipo di tasto';

  @override
  String get keypadShortcutKindValue => 'Inserisci un valore';

  @override
  String get keypadShortcutKindMultiply =>
      'Moltiplica il punteggio (solo positivo)';

  @override
  String get keypadShortcutKindAdd => 'Aggiungi al punteggio';

  @override
  String get keypadShortcutAmount => 'Numero';

  @override
  String get keypadShortcutLabel => 'Etichetta tasto (opzionale)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'Un numero intero tra $min e $max, diverso da 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'Un numero intero tra $min e $max';
  }

  @override
  String get appearance => 'Aspetto';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get system => 'Sistema';

  @override
  String get screen => 'Schermo';

  @override
  String get keepScreenAwake => 'Mantieni schermo attivo';

  @override
  String get keepScreenAwakeDescription =>
      'Evita che lo schermo si spenga durante una partita';

  @override
  String get backup => 'Backup';

  @override
  String get exportDatabase => 'Esporta database';

  @override
  String get exportDatabaseDescription =>
      'Salva tutte le tue partite in un file';

  @override
  String get databaseExportedTo => 'Database esportato in:';

  @override
  String get errorDuringExport => 'Errore durante l\'esportazione:';

  @override
  String get importDatabase => 'Importa database';

  @override
  String get importDatabaseDescription =>
      'Ripristina le tue partite da un file di backup';

  @override
  String get confirmation => 'Conferma';

  @override
  String get importWarning =>
      'L\'importazione sostituirà tutti i tuoi dati attuali. Un backup automatico verrà creato prima dell\'importazione.\n\nVuoi continuare?';

  @override
  String get import => 'Importa';

  @override
  String get databaseImportedSuccessfully => 'Database importato con successo';

  @override
  String get importSuccessful => 'Importazione riuscita';

  @override
  String get importSuccessMessage =>
      'Il database è stato importato con successo.\n\nL\'applicazione ora si chiuderà. Per favore, riaprila per vedere i nuovi dati.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Errore durante l\'importazione:';

  @override
  String get noPlayers => 'Nessun giocatore';

  @override
  String get playersAppearMessage =>
      'I giocatori appariranno qui una volta\nche avrai creato partite';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite',
      one: '1 partita',
      zero: '0 partite',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vittorie',
      one: '1 vittoria',
      zero: '0 vittorie',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Cambia colore';

  @override
  String get renamePlayer => 'Rinomina giocatore';

  @override
  String get newName => 'Nuovo nome';

  @override
  String playerRenamedTo(String name) {
    return 'Giocatore rinominato a \"$name\"';
  }

  @override
  String get deletePlayer => 'Elimina giocatore';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Vuoi davvero eliminare \"$name\"?\n\nQuesto giocatore verrà rimosso da tutte le $count partita/e.';
  }

  @override
  String playerDeleted(String name) {
    return 'Giocatore \"$name\" eliminato';
  }

  @override
  String get chooseColor => 'Scegli un colore';

  @override
  String get noGameTypes => 'Nessun tipo di gioco';

  @override
  String get edit => 'Modifica';

  @override
  String get newType => 'Nuovo tipo';

  @override
  String get editType => 'Modifica tipo';

  @override
  String get newGameType => 'Nuovo tipo di gioco';

  @override
  String get gameTypeName => 'Nome tipo di gioco';

  @override
  String get icon => 'Icona:';

  @override
  String get color => 'Colore:';

  @override
  String get chooseIcon => 'Scegli un\'icona';

  @override
  String get nameIsRequired => 'Il nome è obbligatorio';

  @override
  String get create => 'Crea';

  @override
  String get ranking => 'Classifica';

  @override
  String get noCurrentGame => 'Nessuna partita in corso';

  @override
  String get noScoresRecorded => 'Nessun punteggio registrato';

  @override
  String get playerStatistics => 'Statistiche Giocatore';

  @override
  String get noStatisticsAvailable => 'Nessuna statistica disponibile';

  @override
  String get gamesPlayed => 'Partite giocate';

  @override
  String get wins => 'Vittorie';

  @override
  String get winRate => 'Percentuale vittorie';

  @override
  String get byGameType => 'Per tipo di gioco';

  @override
  String get rate => 'Valuta';

  @override
  String version(String version) {
    return 'Versione $version';
  }

  @override
  String get appDescription =>
      'Applicazione di gestione punteggi per le tue sessioni di gioco di Vincent Moreau';

  @override
  String get features => 'Caratteristiche';

  @override
  String get featureDifferentGameTypes => 'Diversi tipi di gioco';

  @override
  String get featurePlayerManagement => 'Gestione giocatori';

  @override
  String get featureDetailedStatistics => 'Statistiche dettagliate';

  @override
  String get featureCustomization => 'Personalizzazione';

  @override
  String get featureDarkLightTheme => 'Tema scuro/chiaro';

  @override
  String get featureGroupSharing => 'Condivisione di gruppo';

  @override
  String get featureGameAnalysis => 'Analisi del gioco con IA';

  @override
  String get rateApp => 'Valuta CountScore';

  @override
  String get search => 'Cerca';

  @override
  String get newPlayerName => 'Nome nuovo giocatore';

  @override
  String get noPlayersFound => 'Nessun giocatore trovato';

  @override
  String get close => 'Chiudi';

  @override
  String get playerEliminationCondition =>
      'Condizione di Eliminazione Giocatore';

  @override
  String get gameOverCondition => 'Condizione di Fine Partita';

  @override
  String get none => 'Nessuno';

  @override
  String get overThreshold => 'Sopra la soglia';

  @override
  String get underThreshold => 'Sotto la soglia';

  @override
  String get firstPlayerOver => 'Primo a raggiungere';

  @override
  String get firstPlayerUnder => 'Primo sotto';

  @override
  String get lastPlayerOver => 'Ultimo giocatore in piedi (altri sopra)';

  @override
  String get lastPlayerUnder => 'Ultimo giocatore in piedi (altri sotto)';

  @override
  String get threshold => 'Soglia';

  @override
  String get conditionType => 'Tipo di Condizione';

  @override
  String get continuePlay => 'Continua a Giocare';

  @override
  String gameEndWinner(String name) {
    return '$name vince';
  }

  @override
  String gameEndTie(String names) {
    return 'Pareggio: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count round',
      one: '$count round',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'il punteggio più basso vince';

  @override
  String get gameEndHighestWins => 'il punteggio più alto vince';

  @override
  String get gameEndAnalysis => 'Analisi';

  @override
  String get gameEndResults => 'Risultati';

  @override
  String get rankingEliminationNote =>
      'Classificato per ordine di eliminazione: chi esce più tardi ha un ranking migliore, indipendentemente dai totali.';

  @override
  String get endGame => 'Termina Partita';

  @override
  String get reopenGame => 'Riapri partita';

  @override
  String get gameFinished => 'Terminata';

  @override
  String get undo => 'Annulla';

  @override
  String get gameReopened => 'Partita riaperta';

  @override
  String get comment => 'Commento';

  @override
  String get enterComment => 'Inserisci un commento';

  @override
  String get analyzeGame => 'Analizza partita';

  @override
  String get analysisTitle => 'Analisi partita';

  @override
  String get analysisStyle => 'Stile di analisi';

  @override
  String get analysisStyleProfessor => 'Il professore';

  @override
  String get analysisStyleCommentator => 'Il commentatore sportivo';

  @override
  String get analysisStyleDocumentary => 'Il documentario naturalistico';

  @override
  String get analysisStyleNoir => 'Il detective';

  @override
  String get analysisStyleBard => 'Il bardo';

  @override
  String get analysisStyleCoach => 'L\'allenatore';

  @override
  String get analysisStyleConsultant => 'Il consulente';

  @override
  String get analysisStyleAstrologer => 'L\'astrologo';

  @override
  String get analysisStyleRealityTv => 'Lo spettacolo reality';

  @override
  String get generatingAnalysis => 'Generazione analisi…';

  @override
  String get generateAnalysis => 'Genera analisi';

  @override
  String get regenerateAnalysis => 'Rigenera analisi';

  @override
  String get deleteAnalysis => 'Elimina analisi';

  @override
  String get confirmRegenerateAnalysis =>
      'Rigenerare? L\'analisi attuale sarà sostituita.';

  @override
  String get confirmDeleteAnalysis =>
      'Eliminare l\'analisi per questa partita?';

  @override
  String get analysisError => 'Errore nella generazione dell\'analisi';

  @override
  String get analysisErrorUnavailable =>
      'Il server di analisi è temporaneamente non disponibile. Riprova più tardi.';

  @override
  String get analysisErrorGroupBudget =>
      'Il tuo gruppo ha esaurito il budget di analisi per questo mese. Si rinnova all\'inizio del mese prossimo.';

  @override
  String get analysisStyleGroupDefault =>
      'Nessuno stile scelto: questa partita condivisa viene analizzata nello stile e nella lingua del gruppo.';

  @override
  String analysisErrorStatus(int status) {
    return 'Errore nella generazione dell\'analisi (HTTP $status)';
  }

  @override
  String get retry => 'Riprova';

  @override
  String analysisGeneratedAt(String date) {
    return 'Generato il $date';
  }

  @override
  String get serverSection => 'Server';

  @override
  String get backendUrlLabel => 'URL Server';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Le funzioni connesse hanno bisogno di un server CountScore. Installa uno dalla cartella backend/ e inserisci il suo indirizzo qui. Senza un server, nessun dato lascia questo dispositivo.';

  @override
  String get backendNotConfigured => 'Nessun server configurato';

  @override
  String get backendUrlInvalid =>
      'Indirizzo non valido. Inserisci un URL completo, ad esempio https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// è accettato solo su una rete locale. Usa https:// per un server pubblico.';

  @override
  String get testConnection => 'Testa connessione';

  @override
  String get connectionOk => 'Il server sta rispondendo';

  @override
  String get connectionFailed => 'Il server non sta rispondendo';

  @override
  String get serverUrlSaved => 'Server salvato';

  @override
  String get analysisRequiresBackend =>
      'Questa analisi ha bisogno di un server. Configurane uno nelle impostazioni.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get serverUrlCleared => 'Server cancellato';

  @override
  String get groupSection => 'Gruppo';

  @override
  String get groupDescription =>
      'Condividi partite con gli altri dispositivi del tuo gruppo. Le partite condivise, i loro giocatori, punteggi, commenti e analisi vengono inviati al tuo server; le altre partite rimangono su questo dispositivo.';

  @override
  String get groupNeedsServer => 'Configura prima un server.';

  @override
  String get groupCreate => 'Crea un gruppo';

  @override
  String get groupJoin => 'Unisciti a un gruppo';

  @override
  String get groupNameLabel => 'Nome del gruppo';

  @override
  String get groupNicknameLabel => 'Il tuo nickname';

  @override
  String get groupNicknameHint => 'Gli altri nel gruppo lo vedranno';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Il tuo nickname: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Cambia il tuo nickname';

  @override
  String get shareTokenLabel => 'Codice invito';

  @override
  String get shareTokenHint =>
      'Incolla il codice che un membro del gruppo ti ha inviato';

  @override
  String groupCurrent(String name) {
    return 'Gruppo: $name';
  }

  @override
  String get shareTokenExplain =>
      'Invia questo codice ai dispositivi che dovrebbero unirsi al gruppo. Chiunque lo abbia può unirsi.';

  @override
  String get shareTokenCopy => 'Copia codice';

  @override
  String get shareTokenCopied => 'Codice copiato';

  @override
  String get shareTokenRotate => 'Nuovo codice';

  @override
  String get shareTokenRotateConfirm =>
      'Il codice vecchio non permetterà più a nessuno di unirsi. I dispositivi già nel gruppo non sono interessati.';

  @override
  String get groupLeave => 'Lascia il gruppo';

  @override
  String get groupLeaveConfirm =>
      'Questo dispositivo lascia il gruppo. Le partite condivise rimangono su questo dispositivo ma non si sincronizzeranno più.';

  @override
  String get groupLeft => 'Hai lasciato il gruppo';

  @override
  String get groupJoined => 'Sei entrato nel gruppo';

  @override
  String get clearServerLeavesGroup =>
      'Cancellare il server fa abbandonare il gruppo. Le partite condivise rimangono su questo dispositivo.';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String syncStatusIdle(String time) {
    return 'Sincronizzato a $time';
  }

  @override
  String get syncStatusSyncing => 'Sincronizzazione…';

  @override
  String get syncStatusOffline =>
      'Server non raggiungibile — le modifiche verranno inviate in seguito';

  @override
  String get syncStatusUnauthorized =>
      'Il server non accetta più questo dispositivo. Lascia il gruppo e rientravi di nuovo.';

  @override
  String get syncStatusError => 'Errore del server durante la sincronizzazione';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche in sospeso',
      one: '1 modifica in sospeso',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche rifiutate dal server',
      one: '1 modifica rifiutata dal server',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'Codice invito sconosciuto o sostituito';

  @override
  String get groupErrorRateLimited =>
      'Troppi tentativi. Riprova tra un minuto.';

  @override
  String get groupErrorUnreachable => 'Server non raggiungibile';

  @override
  String get groupErrorServer => 'Errore del server';

  @override
  String get shareWithGroup => 'Condividi con il gruppo';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'I dispositivi in $name vedranno e modificheranno questa partita';
  }

  @override
  String shareGameConfirm(String name) {
    return 'La partita, i suoi giocatori, punteggi e commenti verranno inviati a $name. La condivisione non può essere annullata.';
  }

  @override
  String get gameSharedDone => 'Partita condivisa con il gruppo';

  @override
  String get gameSharedBadge => 'Partita condivisa';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Questi nomi non possono essere condivisi: $names. Usa lettere, cifre, spazi, trattini, apostrofi o punti (32 caratteri al massimo).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Questo round era già stato inserito su un altro dispositivo, quindi è diventato il round $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" è stata eliminata su un altro dispositivo';
  }

  @override
  String get groupDevices => 'Dispositivi';

  @override
  String get groupDevicesExplain =>
      'Un telefono perso o venduto può essere rimosso dal gruppo qui.';

  @override
  String get groupDeviceThisOne => 'Questo dispositivo';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Visto l\'ultima volta $date';
  }

  @override
  String get groupDeviceRevoke => 'Rimuovi';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Rimuovere \"$label\" dal gruppo? Non si sincronizzerà più. Il codice invito cambia anche: i membri mantengono l\'accesso, ma dovrai condividere il nuovo codice per invitare qualcuno.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" è stata rimossa. Il codice invito è cambiato.';
  }

  @override
  String get reportCommentary => 'Segnala questo commento';

  @override
  String get reportCommentarySubject => 'CountScore — segnalazione commento IA';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Cos\'è che non va in questo commento generato dall\'IA?\n\n\n---\nRiferimento: $reference\nCommento:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Nessuna app email trovata. Scrivi a $email per segnalare questo commento.';
  }

  @override
  String get gameRulesTitle => 'Regole del gioco';

  @override
  String get gameRulesInApp => 'In CountScore';

  @override
  String get gameRulesSection => 'Le regole';

  @override
  String get gameRulesNoElimination => 'Nessuna eliminazione durante il gioco';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Un giocatore viene eliminato sopra $threshold punti';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Un giocatore viene eliminato sotto $threshold punti';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'La partita finisce non appena un giocatore raggiunge $threshold punti';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'La partita finisce non appena un giocatore scende sotto $threshold punti';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'La partita finisce quando tutti i giocatori tranne uno sono sopra $threshold punti';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'La partita finisce quando tutti i giocatori tranne uno sono sotto $threshold punti';
  }

  @override
  String get gameRulesNoEnd =>
      'Nessuna fine automatica: decidi tu quando la partita è finita';

  @override
  String get gameRulesEmptyTitle => 'Nessuna regola ancora';

  @override
  String get gameRulesEmptyHint =>
      'Scrivi come il tuo tavolo conta i punti — tutti avranno la stessa versione.';

  @override
  String get gameRulesWrite => 'Scrivi le regole';

  @override
  String get gameRulesEditTitle => 'Modifica le regole';

  @override
  String get gameRulesEditorHint =>
      'Le regole del tuo tavolo. Markdown è supportato.';

  @override
  String get gameRulesFromGroup => 'Le regole del tuo gruppo';

  @override
  String get gameRulesRestoreDefault => 'Ripristina le regole originali';

  @override
  String get gameRulesSaved => 'Regole salvate';

  @override
  String get gameRulesRestored => 'Regole originali ripristinate';

  @override
  String get gameRulesDisclaimer =>
      'Riepilogo scritto per CountScore dalle regole come comunemente giocate. I nomi dei giochi appartengono ai rispettivi proprietari e sono usati solo in senso descrittivo.';

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
  String get gameTypeNameOther => 'Altro';

  @override
  String get gameTypeNameOtherSortKey => 'Altro';

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
  String get groupDeviceOwner => 'Proprietario';

  @override
  String get groupDeviceMakeOwner => 'Rendi proprietario';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Passare il gruppo a \"$label\"? Questo dispositivo non sarà più in grado di rimuovere dispositivi o cambiare il codice di invito.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" ora è proprietario del gruppo.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Solo il proprietario del gruppo può rimuovere un dispositivo o cambiare il codice di invito.';

  @override
  String get groupErrorNotOwner => 'Solo il proprietario del gruppo può farlo';

  @override
  String get whoStarts => 'Chi inizia?';

  @override
  String get whoStartsAgain => 'Estrai di nuovo';

  @override
  String get diceRoller => 'Lancia i dadi';

  @override
  String get diceCount => 'Numero di dadi';

  @override
  String get diceRollAgain => 'Lancia di nuovo';

  @override
  String diceTotal(int total) {
    return 'Totale: $total';
  }

  @override
  String get resumeGame => 'Riprendi';

  @override
  String get recentGames => 'Recenti';

  @override
  String get gameInProgress => 'In corso';

  @override
  String roundNumber(int number) {
    return 'round $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name in testa · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Vinta da $name';
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
  String get boardViewRows => 'Una riga per giocatore';

  @override
  String get boardViewLanes => 'Una colonna per giocatore';

  @override
  String get boardSeatOrder => 'Ordine dei posti';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'Giocatore';

  @override
  String get boardTotal => 'Totale';

  @override
  String get boardLeader => 'In testa';

  @override
  String get groupSettingsTitle => 'Commenti e utilizzo';

  @override
  String get groupSettingsDescription =>
      'Lo stile e la lingua dei commenti che il server scrive per le partite del gruppo. Qualsiasi membro può cambiarli.';

  @override
  String get groupCommentStyle => 'Stile commento';

  @override
  String get groupCommentStyleNarrative => 'Narrativo';

  @override
  String get groupCommentStyleHumorous => 'Umoristico';

  @override
  String get groupCommentStyleAnalytical => 'Analitico';

  @override
  String get groupCommentLanguage => 'Lingua commento';

  @override
  String get groupSettingsSaved => 'Impostazioni del gruppo salvate';

  @override
  String get groupUsageTitle => 'Utilizzo IA questo mese';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used speso su $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Si reimposta il $date';
  }

  @override
  String get statsBestWinRate => 'Miglior percentuale di vittorie';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins vittorie su $games',
      one: '$wins vittoria su $games',
      zero: 'Nessuna vittoria su $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Giocatore';

  @override
  String get statsColumnGames => 'Partite';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite · non ancora classificate',
      one: '$count partita · non ancora classificata',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Classificato da $count partite terminate. Tocca un giocatore per vedere la sua carta.',
      one:
          'Classificato da $count partita terminata. Tocca un giocatore per vedere la sua carta.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'partite',
      one: 'partita',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vittorie',
      one: 'vittoria',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'posizionamento medio';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Posizione, ultime $count partite',
      one: 'Posizione, ultima partita',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'in miglioramento';

  @override
  String get statsTrendDeclining => 'in calo';

  @override
  String get statsTrendSteady => 'stabile';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1º',
      '2': '2º',
      '3': '3º',
      'other': '$rankº',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serie: $count vittorie',
      one: 'Serie: $count vittoria',
      zero: 'Nessuna serie di vittorie',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'Miglior: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Su $gameType';
  }

  @override
  String get statsAverageTotal => 'Totale finale medio';

  @override
  String get statsBestTotal => 'Miglior totale finale';

  @override
  String get statsMostBeaten => 'Avversario più sconfitto';

  @override
  String get statsOpenPlayerCard => 'apri la carta del giocatore';

  @override
  String get shareResult => 'Condividi il risultato';

  @override
  String get shareAnalysis => 'Condividi l\'analisi';

  @override
  String shareResultSubject(String gameName) {
    return 'Risultato: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Partita del $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points punti',
      one: '$points punto',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Punteggi mantenuti con $appName: $url';
  }

  @override
  String get shareFailed => 'La condivisione non ha potuto essere aperta';

  @override
  String get newGameNameLabel => 'Nome';

  @override
  String get newGameGameLabel => 'Gioco';

  @override
  String newGameAllGames(int count) {
    return 'Tutte le partite ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Giocatori · ordine dei posti';

  @override
  String get newGameDragToReorder => 'trascina per riordinare';

  @override
  String get newGameDealer => 'distribuisce';

  @override
  String get newGameAddPlayer => 'Aggiungi un giocatore';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inizia · $count giocatori',
      one: 'Inizia · 1 giocatore',
      zero: 'Inizia',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Chi sta giocando?';

  @override
  String get whoIsPlayingSearchHint => 'Nome, o un nuovo giocatore';

  @override
  String get whoIsPlayingFrequent => 'Spesso gioca con te';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Stessi giocatori di \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Crea \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi $count giocatori',
      one: 'Aggiungi 1 giocatore',
      zero: 'Fatto',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Partita $number';
  }

  @override
  String get pwaUpdateReady => 'Una nuova versione di CountScore è pronta';

  @override
  String get pwaUpdateReload => 'Ricarica';

  @override
  String get thresholdIsRequired =>
      'Una soglia è richiesta per questa condizione';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'La soglia non può essere sopra $maxString';
  }

  @override
  String get deletionImpossible => 'Eliminazione impossibile';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite usano questo tipo: non possono essere eliminate.',
      one: '1 partita usa questo tipo: non può essere eliminata.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Vuoi davvero eliminare il tipo di gioco \"$name\"?';
  }

  @override
  String get winDirectionChangeTitle => 'Invertire chi vince?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count partite terminate di questo tipo avranno le loro classifiche invertite: i loro vincitori diventano gli ultimi.',
      one: '1 partita terminata di questo tipo avrà la sua classifica invertita: il suo vincitore diventa l\'ultimo.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'La condizione di fine partita premia l\'opposto del vincitore scelto. Una regola della casa potrebbe volerlo esattamente così.';

  @override
  String get rulesOutOfDateTitle => 'Aggiornare le regole?';

  @override
  String get rulesOutOfDateMessage =>
      'Le regole di questo tipo descrivono ancora la vecchia condizione.';

  @override
  String get later => 'Dopo';

  @override
  String get currentIcon => 'Icona corrente';

  @override
  String get currentColor => 'Colore corrente';

  @override
  String get groupDeviceClaimOwner => 'Rivendica la proprietà';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" è proprietario del gruppo ma non è stata vista da molto tempo. Acquisire la proprietà su questo dispositivo?';
  }

  @override
  String get groupDeviceOwnerClaimed =>
      'Questo dispositivo ora possiede il gruppo.';

  @override
  String get groupErrorOwnerActive =>
      'Il proprietario del gruppo è stato visto di recente: la proprietà non può essere reclamata.';

  @override
  String get groupCreatedOwnerExplain =>
      'Gruppo creato. Questo dispositivo lo possiede; il ruolo può essere affidato a un altro in Dispositivi.';

  @override
  String get boardEliminated => 'Eliminato';

  @override
  String get soundsSection => 'Suoni';

  @override
  String get gameSounds => 'Suoni partita';

  @override
  String get gameSoundsDescription =>
      'Un suono quando un giocatore viene eliminato, quando la partita viene vinta e quando il timer scade';

  @override
  String get turnTimer => 'Timer turno';

  @override
  String get turnTimerLess => 'Meno tempo';

  @override
  String get turnTimerMore => 'Più tempo';

  @override
  String get turnTimerStart => 'Inizia';

  @override
  String get turnTimerPause => 'Pausa';

  @override
  String get turnTimerReset => 'Reimposta';

  @override
  String get turnTimerTimeUp => 'Tempo scaduto!';

  @override
  String get configShareOpen => 'Condividi tramite codice QR';

  @override
  String get configShareTitle => 'Condividi questa configurazione';

  @override
  String get configShareExplainServer =>
      'Scansiona questo codice con un altro telefono per configurarlo con lo stesso server.';

  @override
  String configShareExplainGroup(String name) {
    return 'Scansiona questo codice con un altro telefono per configurarlo con lo stesso server e unirti al gruppo $name. Contiene il codice invito del gruppo: mostralo solo alle persone che vuoi nel gruppo.';
  }

  @override
  String get configShareWebAppLabel => 'Indirizzo app web';

  @override
  String get configShareWebAppHelper =>
      'Dove il tuo server serve l\'app web CountScore, come https://countscore.example.com/countscore. Il codice apre questa pagina.';

  @override
  String get configShareWebAppNeeded =>
      'Inserisci l\'indirizzo dell\'app web per mostrare il codice.';

  @override
  String get configShareQrLabel =>
      'Codice QR del collegamento di configurazione';

  @override
  String get configShareCopyLink => 'Copia collegamento';

  @override
  String get configShareLinkCopied => 'Collegamento copiato';

  @override
  String get configShareTooLong =>
      'Questo collegamento è troppo lungo per stare in un codice QR. Usa \"Copia collegamento\" invece.';

  @override
  String get replaceConfigTitle => 'Sostituire la configurazione?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Ora: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Nuovo: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'codice invito $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'Questo dispositivo abbandonerà il gruppo $name. Le sue partite rimangono su questo dispositivo.';
  }

  @override
  String get replaceConfigConfirm => 'Sostituisci';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count modifiche su questo dispositivo non hanno ancora raggiunto il gruppo. Se te ne vai ora, il gruppo non le riceverà mai.',
      one: '1 modifica su questo dispositivo non ha ancora raggiunto il gruppo. Se te ne vai ora, il gruppo non la riceverà mai.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Lascia comunque';

  @override
  String get replaceConfigDone => 'Configurazione sostituita';

  @override
  String get replaceConfigUnchanged =>
      'Questo dispositivo utilizza già questa configurazione';

  @override
  String get joinLinkHandOverMessage =>
      'Questo collegamento può aprirsi nell\'app Android di CountScore. Se l\'app non è installata, il Play Store si apre invece.';

  @override
  String get joinLinkOpenInApp => 'Apri nell\'app';

  @override
  String get joinLinkContinueHere => 'Continua nel browser';
}
