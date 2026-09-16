import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In fr, this message translates to:
  /// **'CountScore'**
  String get appTitle;

  /// Home screen title
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// Players list screen title
  ///
  /// In fr, this message translates to:
  /// **'Liste des joueurs'**
  String get playersListTitle;

  /// Game types screen title
  ///
  /// In fr, this message translates to:
  /// **'Types de jeux'**
  String get gameTypesTitle;

  /// Settings screen title
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// About screen title
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTitle;

  /// New game button text
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie'**
  String get newGame;

  /// Message when no games exist
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie'**
  String get noGames;

  /// Message when no games of a specific type exist
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie de ce type'**
  String get noGamesOfThisType;

  /// Message prompting user to create first game
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première partie'**
  String get createFirstGame;

  /// Label for creation date
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get createdOn;

  /// Menu option to create new game with same players
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle avec mêmes joueurs'**
  String get newWithSamePlayers;

  /// Suffix added to game name when creating a copy
  ///
  /// In fr, this message translates to:
  /// **'(nouvelle)'**
  String get newGameSuffix;

  /// Menu option to rename
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get rename;

  /// Menu option to delete
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// Title for deletion confirmation dialog
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletion;

  /// Confirmation message for game deletion
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer la partie \"{name}\" ?'**
  String confirmDeleteGame(String name);

  /// Cancel button text
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Dialog title for renaming a game
  ///
  /// In fr, this message translates to:
  /// **'Renommer la partie'**
  String get renameGame;

  /// Label for game name input field
  ///
  /// In fr, this message translates to:
  /// **'Nom de la partie'**
  String get gameName;

  /// Save button text
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Label for game type filter
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par type de jeu'**
  String get filterByGameType;

  /// Option to show all games (no filter)
  ///
  /// In fr, this message translates to:
  /// **'Tous les jeux'**
  String get allGames;

  /// Title for filter bottom sheet
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les parties'**
  String get filterGames;

  /// Button to apply filter
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get applyFilter;

  /// Button to reset filter
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetFilter;

  /// Instruction text in filter bottom sheet
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un type de jeu'**
  String get selectGameType;

  /// Label for game type
  ///
  /// In fr, this message translates to:
  /// **'Type de jeu'**
  String get gameType;

  /// Loading message for game types
  ///
  /// In fr, this message translates to:
  /// **'Chargement des types de jeux...'**
  String get loadingGameTypes;

  /// Label for win rule selection
  ///
  /// In fr, this message translates to:
  /// **'Règle de victoire'**
  String get winRule;

  /// Win rule option: lowest score wins
  ///
  /// In fr, this message translates to:
  /// **'Plus petit score gagne'**
  String get lowestScoreWins;

  /// Win rule option: highest score wins
  ///
  /// In fr, this message translates to:
  /// **'Plus grand score gagne'**
  String get highestScoreWins;

  /// Examples of games with lowest score wins
  ///
  /// In fr, this message translates to:
  /// **'Ex: Golf, Hearts'**
  String get lowestScoreExample;

  /// Examples of games with highest score wins
  ///
  /// In fr, this message translates to:
  /// **'Ex: Rami, Belote'**
  String get highestScoreExample;

  /// Label for players section
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get players;

  /// Add button text
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// Validation message for empty name
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom'**
  String get pleaseEnterName;

  /// Validation message for minimum players
  ///
  /// In fr, this message translates to:
  /// **'Au moins 2 joueurs sont requis'**
  String get atLeast2PlayersRequired;

  /// Label for player number
  ///
  /// In fr, this message translates to:
  /// **'Joueur {index}'**
  String playerNumber(int index);

  /// Placeholder for player selection
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un joueur...'**
  String get selectPlayer;

  /// Clear button text
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clear;

  /// Remove button text
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// Create game button text
  ///
  /// In fr, this message translates to:
  /// **'Créer la partie'**
  String get createGame;

  /// Generic game label (fallback)
  ///
  /// In fr, this message translates to:
  /// **'Partie'**
  String get game;

  /// Menu option to edit the current game
  ///
  /// In fr, this message translates to:
  /// **'Modifier la partie'**
  String get editGame;

  /// Title for edit game dialog
  ///
  /// In fr, this message translates to:
  /// **'Modifier la partie'**
  String get editGameDialogTitle;

  /// Section title for game settings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de la partie'**
  String get gameSettings;

  /// Button to remove a player from the game
  ///
  /// In fr, this message translates to:
  /// **'Retirer le joueur'**
  String get removePlayer;

  /// Button to add a player to the game
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get addPlayerToGame;

  /// Warning message when removing a player
  ///
  /// In fr, this message translates to:
  /// **'Attention ! Retirer ce joueur supprimera tous ses scores de cette partie. Cette action est irréversible.'**
  String get warningRemovePlayer;

  /// Confirmation message for removing a player
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment retirer {playerName} de cette partie ?'**
  String confirmRemovePlayer(String playerName);

  /// Success message after removing a player
  ///
  /// In fr, this message translates to:
  /// **'Joueur retiré de la partie'**
  String get playerRemoved;

  /// Menu option to delete last round
  ///
  /// In fr, this message translates to:
  /// **'Supprimer dernier tour'**
  String get deleteLastRound;

  /// Confirm button text
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// Confirmation message for deleting last round
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dernier tour ?'**
  String get confirmDeleteLastRound;

  /// Message when game has no players
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur dans cette partie'**
  String get noPlayersInGame;

  /// Label for round
  ///
  /// In fr, this message translates to:
  /// **'Tour'**
  String get round;

  /// Button text to add a round
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un tour'**
  String get addRound;

  /// Label for score
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get score;

  /// Placeholder for score input
  ///
  /// In fr, this message translates to:
  /// **'Entrez le score'**
  String get enterScore;

  /// Settings section for appearance
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// Light theme option
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get light;

  /// Dark theme option
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get dark;

  /// System theme option
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get system;

  /// Settings section for screen
  ///
  /// In fr, this message translates to:
  /// **'Écran'**
  String get screen;

  /// Setting to keep screen awake
  ///
  /// In fr, this message translates to:
  /// **'Garder l\'écran allumé'**
  String get keepScreenAwake;

  /// Description for keep screen awake setting
  ///
  /// In fr, this message translates to:
  /// **'Empêche l\'écran de se mettre en veille pendant une partie'**
  String get keepScreenAwakeDescription;

  /// Settings section for backup
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backup;

  /// Option to export database
  ///
  /// In fr, this message translates to:
  /// **'Exporter la base de données'**
  String get exportDatabase;

  /// Description for export database option
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder toutes vos parties dans un fichier'**
  String get exportDatabaseDescription;

  /// Success message for database export
  ///
  /// In fr, this message translates to:
  /// **'Base de données exportée vers:'**
  String get databaseExportedTo;

  /// Error message prefix for export failure
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'export:'**
  String get errorDuringExport;

  /// Option to import database
  ///
  /// In fr, this message translates to:
  /// **'Importer une base de données'**
  String get importDatabase;

  /// Description for import database option
  ///
  /// In fr, this message translates to:
  /// **'Restaurer vos parties depuis un fichier de sauvegarde'**
  String get importDatabaseDescription;

  /// Confirmation dialog title
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// Warning message before importing database
  ///
  /// In fr, this message translates to:
  /// **'L\'importation remplacera toutes vos données actuelles. Une sauvegarde automatique sera créée avant l\'import.\n\nVoulez-vous continuer ?'**
  String get importWarning;

  /// Import button text
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get import;

  /// Success title for database import
  ///
  /// In fr, this message translates to:
  /// **'Base de données importée avec succès'**
  String get databaseImportedSuccessfully;

  /// Import successful title
  ///
  /// In fr, this message translates to:
  /// **'Import réussi'**
  String get importSuccessful;

  /// Success message for database import
  ///
  /// In fr, this message translates to:
  /// **'La base de données a été importée avec succès.\n\nL\'application va maintenant se fermer. Veuillez la rouvrir pour voir les nouvelles données.'**
  String get importSuccessMessage;

  /// OK button text
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error message prefix for import failure
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'import:'**
  String get errorDuringImport;

  /// Message when no players exist
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur'**
  String get noPlayers;

  /// Players list summary with count and names
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun joueur} =1{1 joueur: {names}} other{{count} joueurs: {names}}}'**
  String playersListSummary(int count, String names);

  /// Message explaining when players will appear
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs apparaîtront ici une fois\nque vous aurez créé des parties'**
  String get playersAppearMessage;

  /// Games count with plural forms
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 partie} =1{1 partie} other{{count} parties}}'**
  String gamesCount(int count);

  /// Wins count with plural forms
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 victoire} =1{1 victoire} other{{count} victoires}}'**
  String winsCount(int count);

  /// Option to change color
  ///
  /// In fr, this message translates to:
  /// **'Changer la couleur'**
  String get changeColor;

  /// Dialog title for renaming a player
  ///
  /// In fr, this message translates to:
  /// **'Renommer le joueur'**
  String get renamePlayer;

  /// Label for new name input
  ///
  /// In fr, this message translates to:
  /// **'Nouveau nom'**
  String get newName;

  /// Success message for player rename
  ///
  /// In fr, this message translates to:
  /// **'Joueur renommé en \"{name}\"'**
  String playerRenamedTo(String name);

  /// Dialog title for deleting a player
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le joueur'**
  String get deletePlayer;

  /// Confirmation message for player deletion
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer \"{name}\" ?\n\nCe joueur sera supprimé de toutes les {count} partie(s).'**
  String confirmDeletePlayer(String name, int count);

  /// Success message for player deletion
  ///
  /// In fr, this message translates to:
  /// **'Joueur \"{name}\" supprimé'**
  String playerDeleted(String name);

  /// Dialog title for color picker
  ///
  /// In fr, this message translates to:
  /// **'Choisir une couleur'**
  String get chooseColor;

  /// Message when no game types exist
  ///
  /// In fr, this message translates to:
  /// **'Aucun type de jeu'**
  String get noGameTypes;

  /// Label for predefined/default game types
  ///
  /// In fr, this message translates to:
  /// **'Prédéfini'**
  String get predefined;

  /// Edit button text
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// Button text to create new type
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type'**
  String get newType;

  /// Dialog title for editing game type
  ///
  /// In fr, this message translates to:
  /// **'Modifier le type'**
  String get editType;

  /// Dialog title for creating new game type
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type de jeu'**
  String get newGameType;

  /// Label for game type name input
  ///
  /// In fr, this message translates to:
  /// **'Nom du type de jeu'**
  String get gameTypeName;

  /// Label for icon selection
  ///
  /// In fr, this message translates to:
  /// **'Icône:'**
  String get icon;

  /// Label for color selection
  ///
  /// In fr, this message translates to:
  /// **'Couleur:'**
  String get color;

  /// Dialog title for icon picker
  ///
  /// In fr, this message translates to:
  /// **'Choisir une icône'**
  String get chooseIcon;

  /// Validation message for required name
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameIsRequired;

  /// Create button text
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// Ranking screen title
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get ranking;

  /// Message when no current game exists
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie en cours'**
  String get noCurrentGame;

  /// Message when no scores are recorded
  ///
  /// In fr, this message translates to:
  /// **'Aucun score enregistré'**
  String get noScoresRecorded;

  /// Player statistics screen title
  ///
  /// In fr, this message translates to:
  /// **'Statistiques des joueurs'**
  String get playerStatistics;

  /// Message when no statistics are available
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique disponible'**
  String get noStatisticsAvailable;

  /// Label for games played
  ///
  /// In fr, this message translates to:
  /// **'Parties jouées'**
  String get gamesPlayed;

  /// Label for wins
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get wins;

  /// Label for win rate
  ///
  /// In fr, this message translates to:
  /// **'Taux de victoire'**
  String get winRate;

  /// Title for overall statistics section
  ///
  /// In fr, this message translates to:
  /// **'Statistiques globales'**
  String get overallStatistics;

  /// Title for by-game-type statistics section
  ///
  /// In fr, this message translates to:
  /// **'Par type de jeu'**
  String get byGameType;

  /// Label for rate
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get rate;

  /// Application version line on the About screen, read from pubspec at runtime
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// Application description
  ///
  /// In fr, this message translates to:
  /// **'Application de gestion de scores pour vos parties de jeux par Vincent Moreau'**
  String get appDescription;

  /// Features section title
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalités'**
  String get features;

  /// Feature: different game types
  ///
  /// In fr, this message translates to:
  /// **'Différents types de jeux'**
  String get featureDifferentGameTypes;

  /// Feature: player management
  ///
  /// In fr, this message translates to:
  /// **'Gestion des joueurs'**
  String get featurePlayerManagement;

  /// Feature: detailed statistics
  ///
  /// In fr, this message translates to:
  /// **'Statistiques détaillées'**
  String get featureDetailedStatistics;

  /// Feature: customization
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation'**
  String get featureCustomization;

  /// Feature: dark/light theme
  ///
  /// In fr, this message translates to:
  /// **'Thème sombre/clair'**
  String get featureDarkLightTheme;

  /// Feature: sharing games with a group through the self-hosted server
  ///
  /// In fr, this message translates to:
  /// **'Partage en groupe'**
  String get featureGroupSharing;

  /// Feature: LLM-generated analysis of a finished game, any game type
  ///
  /// In fr, this message translates to:
  /// **'Analyse des parties par IA'**
  String get featureGameAnalysis;

  /// About screen entry opening the app's Play Store listing
  ///
  /// In fr, this message translates to:
  /// **'Noter CountScore'**
  String get rateApp;

  /// Credits section title
  ///
  /// In fr, this message translates to:
  /// **'Crédits'**
  String get credits;

  /// App icon credit label
  ///
  /// In fr, this message translates to:
  /// **'Icône de l\'application'**
  String get appIconCredit;

  /// Artist name for app icon
  ///
  /// In fr, this message translates to:
  /// **'efendi.sign'**
  String get artistName;

  /// Title for player selection dialog
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un joueur'**
  String get selectPlayerDialogTitle;

  /// Search input label
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// Search or create player input label
  ///
  /// In fr, this message translates to:
  /// **'Rechercher / Créer'**
  String get searchOrCreate;

  /// Button text to create new player
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau joueur'**
  String get createNewPlayer;

  /// Label for new player name input
  ///
  /// In fr, this message translates to:
  /// **'Nom du nouveau joueur'**
  String get newPlayerName;

  /// Message when search returns no players
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur trouvé'**
  String get noPlayersFound;

  /// Message when all available players are selected
  ///
  /// In fr, this message translates to:
  /// **'Tous les joueurs ont été sélectionnés'**
  String get allPlayersSelected;

  /// Close button text
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Label for player elimination condition section
  ///
  /// In fr, this message translates to:
  /// **'Condition d\'élimination du joueur'**
  String get playerEliminationCondition;

  /// Label for game over condition section
  ///
  /// In fr, this message translates to:
  /// **'Condition de fin de partie'**
  String get gameOverCondition;

  /// Option for no condition
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get none;

  /// Player dead condition: over threshold
  ///
  /// In fr, this message translates to:
  /// **'Au-dessus du seuil'**
  String get overThreshold;

  /// Player dead condition: under threshold
  ///
  /// In fr, this message translates to:
  /// **'En dessous du seuil'**
  String get underThreshold;

  /// Game over when first player goes over threshold
  ///
  /// In fr, this message translates to:
  /// **'Premier joueur au-dessus'**
  String get firstPlayerOver;

  /// Game over when first player goes under threshold
  ///
  /// In fr, this message translates to:
  /// **'Premier joueur en dessous'**
  String get firstPlayerUnder;

  /// Game over when last player goes over threshold
  ///
  /// In fr, this message translates to:
  /// **'Dernier joueur au-dessus'**
  String get lastPlayerOver;

  /// Game over when last player goes under threshold
  ///
  /// In fr, this message translates to:
  /// **'Dernier joueur en dessous'**
  String get lastPlayerUnder;

  /// Label for threshold value input
  ///
  /// In fr, this message translates to:
  /// **'Seuil'**
  String get threshold;

  /// Label for condition type dropdown
  ///
  /// In fr, this message translates to:
  /// **'Type de condition'**
  String get conditionType;

  /// Title for game over dialog
  ///
  /// In fr, this message translates to:
  /// **'Fin de partie !'**
  String get gameOverTitle;

  /// Message in game over dialog
  ///
  /// In fr, this message translates to:
  /// **'La condition de fin de partie est atteinte. Terminer la partie maintenant ?'**
  String get gameOverMessage;

  /// Button to continue playing despite game over
  ///
  /// In fr, this message translates to:
  /// **'Continuer à jouer'**
  String get continuePlay;

  /// Button to end the game
  ///
  /// In fr, this message translates to:
  /// **'Terminer la partie'**
  String get endGame;

  /// Menu action that reopens a game previously marked finished
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir la partie'**
  String get reopenGame;

  /// Badge shown on a finished game in the game list
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get gameFinished;

  /// No description provided for @comment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire'**
  String get comment;

  /// No description provided for @enterComment.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un commentaire'**
  String get enterComment;

  /// Menu item to launch LLM-based game analysis
  ///
  /// In fr, this message translates to:
  /// **'Analyser la partie'**
  String get analyzeGame;

  /// Title of the analysis screen
  ///
  /// In fr, this message translates to:
  /// **'Analyse de la partie'**
  String get analysisTitle;

  /// Label of the row of chips picking the voice an analysis is written in
  ///
  /// In fr, this message translates to:
  /// **'Style d\'analyse'**
  String get analysisStyle;

  /// Analysis style: caustic, unfair professor who marks out of 20 — the default
  ///
  /// In fr, this message translates to:
  /// **'Le professeur'**
  String get analysisStyleProfessor;

  /// Analysis style: live sports commentator
  ///
  /// In fr, this message translates to:
  /// **'Le commentateur sportif'**
  String get analysisStyleCommentator;

  /// Analysis style: wildlife documentary narrator
  ///
  /// In fr, this message translates to:
  /// **'Le documentaire animalier'**
  String get analysisStyleDocumentary;

  /// Analysis style: film-noir private detective
  ///
  /// In fr, this message translates to:
  /// **'Le détective'**
  String get analysisStyleNoir;

  /// Analysis style: medieval bard singing an epic
  ///
  /// In fr, this message translates to:
  /// **'Le barde'**
  String get analysisStyleBard;

  /// Analysis style: warm, encouraging coach
  ///
  /// In fr, this message translates to:
  /// **'Le coach'**
  String get analysisStyleCoach;

  /// Analysis style: management consultant's quarterly review, as parody
  ///
  /// In fr, this message translates to:
  /// **'Le consultant'**
  String get analysisStyleConsultant;

  /// Analysis style: astrologer reading the game like a star chart
  ///
  /// In fr, this message translates to:
  /// **'L\'astrologue'**
  String get analysisStyleAstrologer;

  /// Analysis style: reality-TV voice-over
  ///
  /// In fr, this message translates to:
  /// **'La téléréalité'**
  String get analysisStyleRealityTv;

  /// Shown while the LLM is generating
  ///
  /// In fr, this message translates to:
  /// **'Génération de l\'analyse en cours…'**
  String get generatingAnalysis;

  /// Button to start generating an analysis
  ///
  /// In fr, this message translates to:
  /// **'Générer l\'analyse'**
  String get generateAnalysis;

  /// Tooltip / label for regenerate action
  ///
  /// In fr, this message translates to:
  /// **'Régénérer l\'analyse'**
  String get regenerateAnalysis;

  /// Tooltip / label for delete action
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'analyse'**
  String get deleteAnalysis;

  /// Confirmation dialog content for regenerating
  ///
  /// In fr, this message translates to:
  /// **'Régénérer ? L\'analyse actuelle sera remplacée.'**
  String get confirmRegenerateAnalysis;

  /// Confirmation dialog content for deleting analysis
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'analyse de cette partie ?'**
  String get confirmDeleteAnalysis;

  /// Error message when LLM call fails
  ///
  /// In fr, this message translates to:
  /// **'Échec de la génération de l\'analyse'**
  String get analysisError;

  /// Analysis failure when the server answers 503: its LLM provider is unavailable or out of quota. Temporary, so it tells the user to retry later rather than showing an HTTP code
  ///
  /// In fr, this message translates to:
  /// **'Le serveur d\'analyse est momentanément indisponible. Réessayez plus tard.'**
  String get analysisErrorUnavailable;

  /// Analysis failure carrying the HTTP status returned by the user's own server
  ///
  /// In fr, this message translates to:
  /// **'Échec de la génération de l\'analyse (HTTP {status})'**
  String analysisErrorStatus(int status);

  /// Retry button
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Footer with the analysis generation date
  ///
  /// In fr, this message translates to:
  /// **'Généré le {date}'**
  String analysisGeneratedAt(String date);

  /// Section title for the self-hosted backend settings
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get serverSection;

  /// Label of the backend base URL text field
  ///
  /// In fr, this message translates to:
  /// **'URL du serveur'**
  String get backendUrlLabel;

  /// Placeholder text inside the backend URL field
  ///
  /// In fr, this message translates to:
  /// **'https://countscore.example.com'**
  String get backendUrlHint;

  /// Explains that connected features need a self-hosted server
  ///
  /// In fr, this message translates to:
  /// **'Les fonctions connectées nécessitent un serveur CountScore. Installez-en un depuis le dossier backend/ et indiquez son adresse ici. Sans serveur, aucune donnée ne quitte cet appareil.'**
  String get backendUrlDescription;

  /// Shown under the field when no backend URL is set
  ///
  /// In fr, this message translates to:
  /// **'Aucun serveur configuré'**
  String get backendNotConfigured;

  /// Validation error for a URL that is not a usable http(s) address
  ///
  /// In fr, this message translates to:
  /// **'Adresse invalide. Saisissez une URL complète, par exemple https://countscore.example.com'**
  String get backendUrlInvalid;

  /// Validation error for http:// on a public host
  ///
  /// In fr, this message translates to:
  /// **'http:// n\'est accepté que sur un réseau local. Utilisez https:// pour un serveur public.'**
  String get backendUrlInsecure;

  /// Button that calls GET /health on the configured server
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get testConnection;

  /// Result of a successful connection test
  ///
  /// In fr, this message translates to:
  /// **'Le serveur répond'**
  String get connectionOk;

  /// Result of a failed connection test
  ///
  /// In fr, this message translates to:
  /// **'Le serveur ne répond pas'**
  String get connectionFailed;

  /// Snackbar shown after the backend URL is saved
  ///
  /// In fr, this message translates to:
  /// **'Serveur enregistré'**
  String get serverUrlSaved;

  /// Empty state on the analysis screen when no server is configured
  ///
  /// In fr, this message translates to:
  /// **'Cette analyse nécessite un serveur. Configurez-en un dans les paramètres.'**
  String get analysisRequiresBackend;

  /// Button that opens the settings screen
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les paramètres'**
  String get openSettings;

  /// Snackbar shown after the backend URL is cleared
  ///
  /// In fr, this message translates to:
  /// **'Serveur effacé'**
  String get serverUrlCleared;

  /// Section title for group sharing in Settings
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get groupSection;

  /// Explains group sharing and what it sends to the user's server
  ///
  /// In fr, this message translates to:
  /// **'Partagez des parties avec les autres appareils du groupe. Les parties partagées, leurs joueurs, scores, commentaires et analyses sont envoyés à votre serveur ; les autres parties restent sur cet appareil.'**
  String get groupDescription;

  /// Shown in the group section when no server URL is configured
  ///
  /// In fr, this message translates to:
  /// **'Configurez d\'abord un serveur ci-dessus.'**
  String get groupNeedsServer;

  /// Button: create a new group
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get groupCreate;

  /// Button: join an existing group with an invite code
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un groupe'**
  String get groupJoin;

  /// Text field label: name of the group being created
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupNameLabel;

  /// Text field label: how this device is named in the group
  ///
  /// In fr, this message translates to:
  /// **'Nom de cet appareil'**
  String get deviceLabelLabel;

  /// Default value of the device name field
  ///
  /// In fr, this message translates to:
  /// **'Mon appareil'**
  String get deviceLabelDefault;

  /// Label of the group invite code (the share token)
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get shareTokenLabel;

  /// Hint inside the invite code field when joining
  ///
  /// In fr, this message translates to:
  /// **'Collez le code reçu d\'un membre du groupe'**
  String get shareTokenHint;

  /// Shows which group this device is in
  ///
  /// In fr, this message translates to:
  /// **'Groupe : {name}'**
  String groupCurrent(String name);

  /// Explains what to do with the invite code
  ///
  /// In fr, this message translates to:
  /// **'Envoyez ce code aux appareils qui doivent rejoindre le groupe. Toute personne qui l\'a peut le rejoindre.'**
  String get shareTokenExplain;

  /// Button: copy the invite code
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get shareTokenCopy;

  /// Snackbar after copying the invite code
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get shareTokenCopied;

  /// Button: replace the invite code with a new one
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get shareTokenRotate;

  /// Confirmation before replacing the invite code
  ///
  /// In fr, this message translates to:
  /// **'L\'ancien code ne permettra plus de rejoindre le groupe. Les appareils déjà membres ne sont pas concernés.'**
  String get shareTokenRotateConfirm;

  /// Button: leave the group
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get groupLeave;

  /// Confirmation before leaving the group
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil quitte le groupe. Les parties partagées restent sur cet appareil mais ne seront plus synchronisées.'**
  String get groupLeaveConfirm;

  /// Snackbar after leaving the group
  ///
  /// In fr, this message translates to:
  /// **'Groupe quitté'**
  String get groupLeft;

  /// Snackbar after creating or joining a group
  ///
  /// In fr, this message translates to:
  /// **'Groupe rejoint'**
  String get groupJoined;

  /// Confirmation when clearing the server URL while in a group
  ///
  /// In fr, this message translates to:
  /// **'Effacer le serveur fait quitter le groupe. Les parties partagées restent sur cet appareil.'**
  String get clearServerLeavesGroup;

  /// Button: sync with the server now
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get syncNow;

  /// Sync status: up to date, with the time of the last successful sync
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé à {time}'**
  String syncStatusIdle(String time);

  /// Sync status: in progress
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncStatusSyncing;

  /// Sync status: server unreachable, changes kept for later
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable — les modifications seront envoyées plus tard'**
  String get syncStatusOffline;

  /// Sync status: the server no longer accepts this device
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n\'accepte plus cet appareil. Quittez le groupe puis rejoignez-le à nouveau.'**
  String get syncStatusUnauthorized;

  /// Sync status: the server answered with an error
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur pendant la synchronisation'**
  String get syncStatusError;

  /// Number of local changes not yet sent to the server
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modification en attente} other{{count} modifications en attente}}'**
  String syncPending(int count);

  /// Number of local changes the server refused for good
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modification refusée par le serveur} other{{count} modifications refusées par le serveur}}'**
  String syncRejected(int count);

  /// Join failed: the invite code is unknown or was replaced
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation inconnu ou remplacé'**
  String get groupErrorUnknownToken;

  /// Create/join refused by the server's rate limit
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans une minute.'**
  String get groupErrorRateLimited;

  /// Group action failed: no answer from the server
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable'**
  String get groupErrorUnreachable;

  /// Group action failed: the server answered with an error
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur'**
  String get groupErrorServer;

  /// Switch on game creation and menu entry on the game board: share this game
  ///
  /// In fr, this message translates to:
  /// **'Partager avec le groupe'**
  String get shareWithGroup;

  /// Subtitle of the share switch when creating a game
  ///
  /// In fr, this message translates to:
  /// **'Les appareils du groupe {name} verront et modifieront cette partie'**
  String shareWithGroupSubtitle(String name);

  /// Confirmation before sharing an existing game
  ///
  /// In fr, this message translates to:
  /// **'La partie, ses joueurs, scores et commentaires seront envoyés au groupe {name}. Le partage ne peut pas être annulé.'**
  String shareGameConfirm(String name);

  /// Snackbar after a game was shared
  ///
  /// In fr, this message translates to:
  /// **'Partie partagée avec le groupe'**
  String get gameSharedDone;

  /// Tooltip of the icon marking a shared game
  ///
  /// In fr, this message translates to:
  /// **'Partie partagée'**
  String get gameSharedBadge;

  /// Sharing refused because some player names use characters the server does not accept
  ///
  /// In fr, this message translates to:
  /// **'Ces noms ne peuvent pas être partagés : {names}. Utilisez des lettres, chiffres, espaces, tirets, apostrophes ou points (32 caractères au plus).'**
  String invalidPlayerNamesForSync(String names);

  /// Snackbar: a round entered here clashed with one entered on another device and was moved
  ///
  /// In fr, this message translates to:
  /// **'Cette manche avait déjà été saisie sur un autre appareil : elle devient la manche {number}.'**
  String roundRenumbered(int number);

  /// Snackbar when the open shared game was deleted on another device, which closes the board
  ///
  /// In fr, this message translates to:
  /// **'La partie « {name} » a été supprimée sur un autre appareil'**
  String gameDeletedElsewhere(String name);

  /// Button in Settings → Group, and title of the sheet listing the group's devices
  ///
  /// In fr, this message translates to:
  /// **'Appareils'**
  String get groupDevices;

  /// Explanation under the title of the devices sheet
  ///
  /// In fr, this message translates to:
  /// **'Un téléphone perdu ou vendu peut être exclu du groupe ici.'**
  String get groupDevicesExplain;

  /// Marks the current device in the group's device list
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get groupDeviceThisOne;

  /// When a device last talked to the server
  ///
  /// In fr, this message translates to:
  /// **'Vu pour la dernière fois : {date}'**
  String groupDeviceLastSeen(String date);

  /// Action removing another device from the group
  ///
  /// In fr, this message translates to:
  /// **'Exclure'**
  String get groupDeviceRevoke;

  /// Confirmation before removing a device; the invite code is rotated at the same time
  ///
  /// In fr, this message translates to:
  /// **'Exclure « {label} » du groupe ? Il ne pourra plus synchroniser. Le code d\'invitation change aussi : les membres gardent leur accès, mais il faudra partager le nouveau code pour inviter quelqu\'un.'**
  String groupDeviceRevokeConfirm(String label);

  /// Shown after a device was removed
  ///
  /// In fr, this message translates to:
  /// **'« {label} » a été exclu. Le code d\'invitation a changé.'**
  String groupDeviceRevoked(String label);

  /// App bar action on the AI analysis screen that opens an email to report offensive or wrong generated content (Play AI-Generated Content policy)
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce commentaire'**
  String get reportCommentary;

  /// Subject of the prefilled report email for an AI commentary
  ///
  /// In fr, this message translates to:
  /// **'CountScore — signalement d\'un commentaire IA'**
  String get reportCommentarySubject;

  /// Body of the prefilled report email. The blank lines are where the user writes; reference and commentary are filled in by the app
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui pose problème dans ce commentaire généré par IA ?\n\n\n---\nRéférence : {reference}\nCommentaire :\n{commentary}'**
  String reportCommentaryBody(String reference, String commentary);

  /// Snackbar when no email app can open the report email
  ///
  /// In fr, this message translates to:
  /// **'Aucune application e-mail trouvée. Écrivez à {email} pour signaler ce commentaire.'**
  String reportCommentaryNoMailApp(String email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
