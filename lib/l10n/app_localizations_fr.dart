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
  String get version => 'Version 1.0.1';

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
  String get createNewPlayer => 'Créer un nouveau joueur';

  @override
  String get newPlayerName => 'Nom du nouveau joueur';

  @override
  String get noPlayersFound => 'Aucun joueur trouvé';

  @override
  String get allPlayersSelected => 'Tous les joueurs ont été sélectionnés';

  @override
  String get close => 'Fermer';
}
