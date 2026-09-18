// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get playersListTitle => 'Liste des joueurs';

  @override
  String get gameTypesTitle => 'Types de jeux';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get noGames => 'Aucune partie';

  @override
  String get noGamesOfThisType => 'Aucune partie de ce type';

  @override
  String get createFirstGame => 'Créez votre première partie';

  @override
  String get createdOn => 'Créé le';

  @override
  String get newWithSamePlayers => 'Nouvelle avec mêmes joueurs';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String confirmDeleteGame(String name) {
    return 'Voulez-vous vraiment supprimer la partie \"$name\" ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get renameGame => 'Renommer la partie';

  @override
  String get gameName => 'Nom de la partie';

  @override
  String get save => 'Enregistrer';

  @override
  String get filterByGameType => 'Filtrer par type de jeu';

  @override
  String get allGames => 'Tous les jeux';

  @override
  String get filterGames => 'Filtrer les parties';

  @override
  String get applyFilter => 'Appliquer';

  @override
  String get resetFilter => 'Réinitialiser';

  @override
  String get selectGameType => 'Sélectionnez un type de jeu';

  @override
  String get gameType => 'Type de jeu';

  @override
  String get loadingGameTypes => 'Chargement des types de jeux...';

  @override
  String get winRule => 'Règle de victoire';

  @override
  String get lowestScoreWins => 'Plus petit score gagne';

  @override
  String get highestScoreWins => 'Plus grand score gagne';

  @override
  String get lowestScoreExample => 'Ex: Golf, Hearts';

  @override
  String get highestScoreExample => 'Ex: Rami, Belote';

  @override
  String get players => 'Joueurs';

  @override
  String get add => 'Ajouter';

  @override
  String get pleaseEnterName => 'Veuillez entrer un nom';

  @override
  String get atLeast2PlayersRequired => 'Au moins 2 joueurs sont requis';

  @override
  String playerNumber(int index) {
    return 'Joueur $index';
  }

  @override
  String get selectPlayer => 'Sélectionner un joueur...';

  @override
  String get clear => 'Effacer';

  @override
  String get remove => 'Retirer';

  @override
  String get createGame => 'Créer la partie';

  @override
  String get game => 'Partie';

  @override
  String get editGame => 'Modifier la partie';

  @override
  String get editGameDialogTitle => 'Modifier la partie';

  @override
  String get gameSettings => 'Paramètres de la partie';

  @override
  String get removePlayer => 'Retirer le joueur';

  @override
  String get addPlayerToGame => 'Ajouter un joueur';

  @override
  String get warningRemovePlayer =>
      'Attention ! Retirer ce joueur supprimera tous ses scores de cette partie. Cette action est irréversible.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Voulez-vous vraiment retirer $playerName de cette partie ?';
  }

  @override
  String get playerRemoved => 'Joueur retiré de la partie';

  @override
  String get deleteLastRound => 'Supprimer dernier tour';

  @override
  String get confirm => 'Confirmer';

  @override
  String get confirmDeleteLastRound => 'Supprimer le dernier tour ?';

  @override
  String get noPlayersInGame => 'Aucun joueur dans cette partie';

  @override
  String get round => 'Tour';

  @override
  String get addRound => 'Ajouter un tour';

  @override
  String get score => 'Score';

  @override
  String get enterScore => 'Entrez le score';

  @override
  String get appearance => 'Apparence';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get screen => 'Écran';

  @override
  String get keepScreenAwake => 'Garder l\'écran allumé';

  @override
  String get keepScreenAwakeDescription =>
      'Empêche l\'écran de se mettre en veille pendant une partie';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get exportDatabase => 'Exporter la base de données';

  @override
  String get exportDatabaseDescription =>
      'Sauvegarder toutes vos parties dans un fichier';

  @override
  String get databaseExportedTo => 'Base de données exportée vers:';

  @override
  String get errorDuringExport => 'Erreur lors de l\'export:';

  @override
  String get importDatabase => 'Importer une base de données';

  @override
  String get importDatabaseDescription =>
      'Restaurer vos parties depuis un fichier de sauvegarde';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get importWarning =>
      'L\'importation remplacera toutes vos données actuelles. Une sauvegarde automatique sera créée avant l\'import.\n\nVoulez-vous continuer ?';

  @override
  String get import => 'Importer';

  @override
  String get databaseImportedSuccessfully =>
      'Base de données importée avec succès';

  @override
  String get importSuccessful => 'Import réussi';

  @override
  String get importSuccessMessage =>
      'La base de données a été importée avec succès.\n\nL\'application va maintenant se fermer. Veuillez la rouvrir pour voir les nouvelles données.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Erreur lors de l\'import:';

  @override
  String get noPlayers => 'Aucun joueur';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs: $names',
      one: '1 joueur: $names',
      zero: 'Aucun joueur',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Les joueurs apparaîtront ici une fois\nque vous aurez créé des parties';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties',
      one: '1 partie',
      zero: '0 partie',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires',
      one: '1 victoire',
      zero: '0 victoire',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Changer la couleur';

  @override
  String get renamePlayer => 'Renommer le joueur';

  @override
  String get newName => 'Nouveau nom';

  @override
  String playerRenamedTo(String name) {
    return 'Joueur renommé en \"$name\"';
  }

  @override
  String get deletePlayer => 'Supprimer le joueur';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Voulez-vous vraiment supprimer \"$name\" ?\n\nCe joueur sera supprimé de toutes les $count partie(s).';
  }

  @override
  String playerDeleted(String name) {
    return 'Joueur \"$name\" supprimé';
  }

  @override
  String get chooseColor => 'Choisir une couleur';

  @override
  String get noGameTypes => 'Aucun type de jeu';

  @override
  String get predefined => 'Prédéfini';

  @override
  String get edit => 'Modifier';

  @override
  String get newType => 'Nouveau type';

  @override
  String get editType => 'Modifier le type';

  @override
  String get newGameType => 'Nouveau type de jeu';

  @override
  String get gameTypeName => 'Nom du type de jeu';

  @override
  String get icon => 'Icône:';

  @override
  String get color => 'Couleur:';

  @override
  String get chooseIcon => 'Choisir une icône';

  @override
  String get nameIsRequired => 'Le nom est requis';

  @override
  String get create => 'Créer';

  @override
  String get ranking => 'Classement';

  @override
  String get noCurrentGame => 'Aucune partie en cours';

  @override
  String get noScoresRecorded => 'Aucun score enregistré';

  @override
  String get playerStatistics => 'Statistiques des joueurs';

  @override
  String get noStatisticsAvailable => 'Aucune statistique disponible';

  @override
  String get gamesPlayed => 'Parties jouées';

  @override
  String get wins => 'Victoires';

  @override
  String get winRate => 'Taux de victoire';

  @override
  String get overallStatistics => 'Statistiques globales';

  @override
  String get byGameType => 'Par type de jeu';

  @override
  String get rate => 'Taux';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get appDescription =>
      'Application de gestion de scores pour vos parties de jeux par Vincent Moreau';

  @override
  String get features => 'Fonctionnalités';

  @override
  String get featureDifferentGameTypes => 'Différents types de jeux';

  @override
  String get featurePlayerManagement => 'Gestion des joueurs';

  @override
  String get featureDetailedStatistics => 'Statistiques détaillées';

  @override
  String get featureCustomization => 'Personnalisation';

  @override
  String get featureDarkLightTheme => 'Thème sombre/clair';

  @override
  String get featureGroupSharing => 'Partage en groupe';

  @override
  String get featureGameAnalysis => 'Analyse des parties par IA';

  @override
  String get rateApp => 'Noter CountScore';

  @override
  String get credits => 'Crédits';

  @override
  String get appIconCredit => 'Icône de l\'application';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Sélectionner un joueur';

  @override
  String get search => 'Rechercher';

  @override
  String get searchOrCreate => 'Rechercher / Créer';

  @override
  String get createNewPlayer => 'Créer un nouveau joueur';

  @override
  String get newPlayerName => 'Nom du nouveau joueur';

  @override
  String get noPlayersFound => 'Aucun joueur trouvé';

  @override
  String get allPlayersSelected => 'Tous les joueurs ont été sélectionnés';

  @override
  String get close => 'Fermer';

  @override
  String get playerEliminationCondition => 'Condition d\'élimination du joueur';

  @override
  String get gameOverCondition => 'Condition de fin de partie';

  @override
  String get none => 'Aucune';

  @override
  String get overThreshold => 'Au-dessus du seuil';

  @override
  String get underThreshold => 'En dessous du seuil';

  @override
  String get firstPlayerOver => 'Premier joueur au-dessus';

  @override
  String get firstPlayerUnder => 'Premier joueur en dessous';

  @override
  String get lastPlayerOver => 'Dernier joueur au-dessus';

  @override
  String get lastPlayerUnder => 'Dernier joueur en dessous';

  @override
  String get threshold => 'Seuil';

  @override
  String get conditionType => 'Type de condition';

  @override
  String get gameOverTitle => 'Fin de partie !';

  @override
  String get gameOverMessage =>
      'La condition de fin de partie est atteinte. Terminer la partie maintenant ?';

  @override
  String get continuePlay => 'Continuer à jouer';

  @override
  String get endGame => 'Terminer la partie';

  @override
  String get reopenGame => 'Rouvrir la partie';

  @override
  String get gameFinished => 'Terminée';

  @override
  String get undo => 'Annuler';

  @override
  String get gameMarkedFinished => 'Partie terminée';

  @override
  String get gameReopened => 'Partie rouverte';

  @override
  String get comment => 'Commentaire';

  @override
  String get enterComment => 'Saisir un commentaire';

  @override
  String get analyzeGame => 'Analyser la partie';

  @override
  String get analysisTitle => 'Analyse de la partie';

  @override
  String get analysisStyle => 'Style d\'analyse';

  @override
  String get analysisStyleProfessor => 'Le professeur';

  @override
  String get analysisStyleCommentator => 'Le commentateur sportif';

  @override
  String get analysisStyleDocumentary => 'Le documentaire animalier';

  @override
  String get analysisStyleNoir => 'Le détective';

  @override
  String get analysisStyleBard => 'Le barde';

  @override
  String get analysisStyleCoach => 'Le coach';

  @override
  String get analysisStyleConsultant => 'Le consultant';

  @override
  String get analysisStyleAstrologer => 'L\'astrologue';

  @override
  String get analysisStyleRealityTv => 'La téléréalité';

  @override
  String get generatingAnalysis => 'Génération de l\'analyse en cours…';

  @override
  String get generateAnalysis => 'Générer l\'analyse';

  @override
  String get regenerateAnalysis => 'Régénérer l\'analyse';

  @override
  String get deleteAnalysis => 'Supprimer l\'analyse';

  @override
  String get confirmRegenerateAnalysis =>
      'Régénérer ? L\'analyse actuelle sera remplacée.';

  @override
  String get confirmDeleteAnalysis => 'Supprimer l\'analyse de cette partie ?';

  @override
  String get analysisError => 'Échec de la génération de l\'analyse';

  @override
  String get analysisErrorUnavailable =>
      'Le serveur d\'analyse est momentanément indisponible. Réessayez plus tard.';

  @override
  String analysisErrorStatus(int status) {
    return 'Échec de la génération de l\'analyse (HTTP $status)';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String analysisGeneratedAt(String date) {
    return 'Généré le $date';
  }

  @override
  String get serverSection => 'Serveur';

  @override
  String get backendUrlLabel => 'URL du serveur';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Les fonctions connectées nécessitent un serveur CountScore. Installez-en un depuis le dossier backend/ et indiquez son adresse ici. Sans serveur, aucune donnée ne quitte cet appareil.';

  @override
  String get backendNotConfigured => 'Aucun serveur configuré';

  @override
  String get backendUrlInvalid =>
      'Adresse invalide. Saisissez une URL complète, par exemple https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// n\'est accepté que sur un réseau local. Utilisez https:// pour un serveur public.';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get connectionOk => 'Le serveur répond';

  @override
  String get connectionFailed => 'Le serveur ne répond pas';

  @override
  String get serverUrlSaved => 'Serveur enregistré';

  @override
  String get analysisRequiresBackend =>
      'Cette analyse nécessite un serveur. Configurez-en un dans les paramètres.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get serverUrlCleared => 'Serveur effacé';

  @override
  String get groupSection => 'Groupe';

  @override
  String get groupDescription =>
      'Partagez des parties avec les autres appareils du groupe. Les parties partagées, leurs joueurs, scores, commentaires et analyses sont envoyés à votre serveur ; les autres parties restent sur cet appareil.';

  @override
  String get groupNeedsServer => 'Configurez d\'abord un serveur ci-dessus.';

  @override
  String get groupCreate => 'Créer un groupe';

  @override
  String get groupJoin => 'Rejoindre un groupe';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String get deviceLabelLabel => 'Nom de cet appareil';

  @override
  String get deviceLabelDefault => 'Mon appareil';

  @override
  String get shareTokenLabel => 'Code d\'invitation';

  @override
  String get shareTokenHint => 'Collez le code reçu d\'un membre du groupe';

  @override
  String groupCurrent(String name) {
    return 'Groupe : $name';
  }

  @override
  String get shareTokenExplain =>
      'Envoyez ce code aux appareils qui doivent rejoindre le groupe. Toute personne qui l\'a peut le rejoindre.';

  @override
  String get shareTokenCopy => 'Copier le code';

  @override
  String get shareTokenCopied => 'Code copié';

  @override
  String get shareTokenRotate => 'Nouveau code';

  @override
  String get shareTokenRotateConfirm =>
      'L\'ancien code ne permettra plus de rejoindre le groupe. Les appareils déjà membres ne sont pas concernés.';

  @override
  String get groupLeave => 'Quitter le groupe';

  @override
  String get groupLeaveConfirm =>
      'Cet appareil quitte le groupe. Les parties partagées restent sur cet appareil mais ne seront plus synchronisées.';

  @override
  String get groupLeft => 'Groupe quitté';

  @override
  String get groupJoined => 'Groupe rejoint';

  @override
  String get clearServerLeavesGroup =>
      'Effacer le serveur fait quitter le groupe. Les parties partagées restent sur cet appareil.';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String syncStatusIdle(String time) {
    return 'Synchronisé à $time';
  }

  @override
  String get syncStatusSyncing => 'Synchronisation…';

  @override
  String get syncStatusOffline =>
      'Serveur injoignable — les modifications seront envoyées plus tard';

  @override
  String get syncStatusUnauthorized =>
      'Le serveur n\'accepte plus cet appareil. Quittez le groupe puis rejoignez-le à nouveau.';

  @override
  String get syncStatusError => 'Erreur du serveur pendant la synchronisation';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications en attente',
      one: '1 modification en attente',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications refusées par le serveur',
      one: '1 modification refusée par le serveur',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'Code d\'invitation inconnu ou remplacé';

  @override
  String get groupErrorRateLimited =>
      'Trop de tentatives. Réessayez dans une minute.';

  @override
  String get groupErrorUnreachable => 'Serveur injoignable';

  @override
  String get groupErrorServer => 'Erreur du serveur';

  @override
  String get shareWithGroup => 'Partager avec le groupe';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Les appareils du groupe $name verront et modifieront cette partie';
  }

  @override
  String shareGameConfirm(String name) {
    return 'La partie, ses joueurs, scores et commentaires seront envoyés au groupe $name. Le partage ne peut pas être annulé.';
  }

  @override
  String get gameSharedDone => 'Partie partagée avec le groupe';

  @override
  String get gameSharedBadge => 'Partie partagée';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Ces noms ne peuvent pas être partagés : $names. Utilisez des lettres, chiffres, espaces, tirets, apostrophes ou points (32 caractères au plus).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Cette manche avait déjà été saisie sur un autre appareil : elle devient la manche $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'La partie « $name » a été supprimée sur un autre appareil';
  }

  @override
  String get groupDevices => 'Appareils';

  @override
  String get groupDevicesExplain =>
      'Un téléphone perdu ou vendu peut être exclu du groupe ici.';

  @override
  String get groupDeviceThisOne => 'Cet appareil';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Vu pour la dernière fois : $date';
  }

  @override
  String get groupDeviceRevoke => 'Exclure';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Exclure « $label » du groupe ? Il ne pourra plus synchroniser. Le code d\'invitation change aussi : les membres gardent leur accès, mais il faudra partager le nouveau code pour inviter quelqu\'un.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '« $label » a été exclu. Le code d\'invitation a changé.';
  }

  @override
  String get reportCommentary => 'Signaler ce commentaire';

  @override
  String get reportCommentarySubject =>
      'CountScore — signalement d\'un commentaire IA';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Qu\'est-ce qui pose problème dans ce commentaire généré par IA ?\n\n\n---\nRéférence : $reference\nCommentaire :\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Aucune application e-mail trouvée. Écrivez à $email pour signaler ce commentaire.';
  }

  @override
  String get gameRulesTitle => 'Règles du jeu';

  @override
  String get gameRulesInApp => 'Dans CountScore';

  @override
  String get gameRulesSection => 'Les règles';

  @override
  String get gameRulesNoElimination => 'Pas d\'élimination en cours de partie';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Un joueur est éliminé au-dessus de $threshold points';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Un joueur est éliminé en dessous de $threshold points';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'La partie s\'arrête dès qu\'un joueur dépasse $threshold points';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'La partie s\'arrête dès qu\'un joueur descend sous $threshold points';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'La partie s\'arrête quand tous les joueurs sauf un dépassent $threshold points';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'La partie s\'arrête quand tous les joueurs sauf un descendent sous $threshold points';
  }

  @override
  String get gameRulesNoEnd =>
      'Pas de fin automatique : vous décidez quand la partie s\'arrête';

  @override
  String get gameRulesEmptyTitle => 'Pas encore de règles';

  @override
  String get gameRulesEmptyHint =>
      'Notez comment votre table compte les points : tout le monde aura la même version.';

  @override
  String get gameRulesWrite => 'Écrire les règles';

  @override
  String get gameRulesEditTitle => 'Modifier les règles';

  @override
  String get gameRulesEditorHint =>
      'Les règles de votre table. Le Markdown est accepté.';

  @override
  String get gameRulesFromGroup => 'Règles de votre groupe';

  @override
  String get gameRulesRestoreDefault => 'Rétablir les règles d\'origine';

  @override
  String get gameRulesSaved => 'Règles enregistrées';

  @override
  String get gameRulesRestored => 'Règles d\'origine rétablies';

  @override
  String get gameRulesDisclaimer =>
      'Résumé rédigé pour CountScore à partir des règles couramment jouées. Les noms de jeux appartiennent à leurs propriétaires et ne sont cités qu\'à titre descriptif.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Uno';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameOther => 'Autre';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'Président';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarot';

  @override
  String get gameTypeNameBridge => 'Bridge';

  @override
  String get gameTypeNameRami => 'Rami';

  @override
  String get gameTypeNameCoinche => 'Coinche';

  @override
  String get gameTypeNameYahtzee => 'Yahtzee';

  @override
  String get gameTypeNamePhase10 => 'Phase 10';

  @override
  String get gameTypeNameFlip7 => 'Flip 7';

  @override
  String get gameTypeNameMilleBornes => 'Mille Bornes';

  @override
  String get gameTypeNameRummikub => 'Rummikub';

  @override
  String get gameTypeNameSixNimmt => '6 qui prend';

  @override
  String get gameTypeNameQwirkle => 'Qwirkle';

  @override
  String get gameTypeNameFarkle => 'Farkle';

  @override
  String get gameTypeNameCanasta => 'Canasta';

  @override
  String get gameTypeNameWizard => 'Wizard';

  @override
  String get gameTypeNameTriomino => 'Triomino';

  @override
  String get groupDeviceOwner => 'Propriétaire';

  @override
  String get groupDeviceMakeOwner => 'Nommer propriétaire';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Confier le groupe à « $label » ? Cet appareil ne pourra plus exclure d\'appareil ni changer le code d\'invitation.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '« $label » est maintenant propriétaire du groupe.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Seul le propriétaire du groupe peut exclure un appareil ou changer le code d\'invitation.';

  @override
  String get groupErrorNotOwner => 'Réservé au propriétaire du groupe';

  @override
  String get whoStarts => 'Qui commence ?';

  @override
  String get whoStartsAgain => 'Tirer à nouveau';
}
