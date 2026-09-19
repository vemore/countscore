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

  /// Menu option to create new game with same players
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle avec mêmes joueurs'**
  String get newWithSamePlayers;

  /// Button on the end-of-game ranking, and menu entry of a finished game: starts a new game with the same game type and the same players in the same order, opened on its board
  ///
  /// In fr, this message translates to:
  /// **'Rejouer'**
  String get playAgain;

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

  /// Board button that opens the score keypad on the next round; round is its number
  ///
  /// In fr, this message translates to:
  /// **'Tour {round}'**
  String boardRoundButton(int round);

  /// Score keypad: whose score is typed, and in which round
  ///
  /// In fr, this message translates to:
  /// **'{player} · tour {round}'**
  String keypadCaption(String player, int round);

  /// Score keypad, from five players: whose score is typed, the round, and the player's place in the round (4/8)
  ///
  /// In fr, this message translates to:
  /// **'{player} · tour {round} · {position}/{count}'**
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  );

  /// Score keypad: the player's total once the typed score is added
  ///
  /// In fr, this message translates to:
  /// **'total après : {total}'**
  String keypadTotalAfter(int total);

  /// Score keypad key that moves to the next player of the round, named. The name goes on its own line, after the line break: the key is narrow, and a label left to wrap by itself can break inside a word or before punctuation
  ///
  /// In fr, this message translates to:
  /// **'Suivant\n{player}'**
  String keypadNext(String player);

  /// Score keypad key, on the round's last player: writes the whole round
  ///
  /// In fr, this message translates to:
  /// **'Valider le tour'**
  String get keypadValidateRound;

  /// Score keypad shortcut key, ZapZap games only: a zero for the player who called ZapZap
  ///
  /// In fr, this message translates to:
  /// **'0 ZapZap'**
  String get keypadZeroZapZap;

  /// Tooltip of the score keypad's ± key
  ///
  /// In fr, this message translates to:
  /// **'Changer le signe'**
  String get keypadToggleSign;

  /// Tooltip of the score keypad's backspace key
  ///
  /// In fr, this message translates to:
  /// **'Effacer un chiffre'**
  String get keypadBackspace;

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

  /// Search input label
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

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

  /// Game over when the first player's total reaches the threshold (>=)
  ///
  /// In fr, this message translates to:
  /// **'Premier joueur à atteindre'**
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

  /// Action on the game-end screen, when the rule ended the game: back to the board with the game still open
  ///
  /// In fr, this message translates to:
  /// **'Continuer à jouer'**
  String get continuePlay;

  /// Headline of the game-end screen: who won
  ///
  /// In fr, this message translates to:
  /// **'{name} gagne'**
  String gameEndWinner(String name);

  /// Headline of the game-end screen when several players share first place
  ///
  /// In fr, this message translates to:
  /// **'Égalité : {names}'**
  String gameEndTie(String names);

  /// Number of rounds played, in the game-end screen's summary line (e.g. 'ZapZap · 6 tours · le score le plus bas gagne')
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} tour} other{{count} tours}}'**
  String gameEndRounds(int count);

  /// Win rule in the game-end screen's summary line, lower-case as it follows a separator
  ///
  /// In fr, this message translates to:
  /// **'le score le plus bas gagne'**
  String get gameEndLowestWins;

  /// Win rule in the game-end screen's summary line, lower-case as it follows a separator
  ///
  /// In fr, this message translates to:
  /// **'le score le plus haut gagne'**
  String get gameEndHighestWins;

  /// Button on the game-end screen that opens the game analysis
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get gameEndAnalysis;

  /// Tooltip of the board's app-bar button that reopens the game-end screen of a finished game
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get gameEndResults;

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

  /// Snackbar action that reverts the action just confirmed
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// Snackbar confirming a finished game was just reopened
  ///
  /// In fr, this message translates to:
  /// **'Partie rouverte'**
  String get gameReopened;

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

  /// Title of the game-rules screen
  ///
  /// In fr, this message translates to:
  /// **'Règles du jeu'**
  String get gameRulesTitle;

  /// Section header: how CountScore scores this game type
  ///
  /// In fr, this message translates to:
  /// **'Dans CountScore'**
  String get gameRulesInApp;

  /// Section header above the rules text itself
  ///
  /// In fr, this message translates to:
  /// **'Les règles'**
  String get gameRulesSection;

  /// Derived line: the game type has no player elimination threshold
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'élimination en cours de partie'**
  String get gameRulesNoElimination;

  /// Derived line: a player is out above the elimination threshold
  ///
  /// In fr, this message translates to:
  /// **'Un joueur est éliminé au-dessus de {threshold} points'**
  String gameRulesEliminationOver(int threshold);

  /// Derived line: a player is out below the elimination threshold
  ///
  /// In fr, this message translates to:
  /// **'Un joueur est éliminé en dessous de {threshold} points'**
  String gameRulesEliminationUnder(int threshold);

  /// Derived line: game over as soon as a player reaches the threshold (a total equal to it ends the game)
  ///
  /// In fr, this message translates to:
  /// **'La partie s\'arrête dès qu\'un joueur atteint {threshold} points'**
  String gameRulesEndFirstOver(int threshold);

  /// Derived line: game over when the first player drops under the threshold
  ///
  /// In fr, this message translates to:
  /// **'La partie s\'arrête dès qu\'un joueur descend sous {threshold} points'**
  String gameRulesEndFirstUnder(int threshold);

  /// Derived line: game over when the last player passes the threshold
  ///
  /// In fr, this message translates to:
  /// **'La partie s\'arrête quand tous les joueurs sauf un dépassent {threshold} points'**
  String gameRulesEndLastOver(int threshold);

  /// Derived line: game over when the last player drops under the threshold
  ///
  /// In fr, this message translates to:
  /// **'La partie s\'arrête quand tous les joueurs sauf un descendent sous {threshold} points'**
  String gameRulesEndLastUnder(int threshold);

  /// Derived line: the game type has no automatic game-over condition
  ///
  /// In fr, this message translates to:
  /// **'Pas de fin automatique : vous décidez quand la partie s\'arrête'**
  String get gameRulesNoEnd;

  /// Empty state on the rules screen: nothing shipped and nothing written
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de règles'**
  String get gameRulesEmptyTitle;

  /// Empty state hint inviting the user to write the rules
  ///
  /// In fr, this message translates to:
  /// **'Notez comment votre table compte les points : tout le monde aura la même version.'**
  String get gameRulesEmptyHint;

  /// Button that opens the editor when no rules exist yet
  ///
  /// In fr, this message translates to:
  /// **'Écrire les règles'**
  String get gameRulesWrite;

  /// Title of the rules editor
  ///
  /// In fr, this message translates to:
  /// **'Modifier les règles'**
  String get gameRulesEditTitle;

  /// Placeholder inside the rules editor text field
  ///
  /// In fr, this message translates to:
  /// **'Les règles de votre table. Le Markdown est accepté.'**
  String get gameRulesEditorHint;

  /// Footnote shown when the displayed rules were written by the user
  ///
  /// In fr, this message translates to:
  /// **'Règles de votre groupe'**
  String get gameRulesFromGroup;

  /// Action that discards the user's rules and brings the shipped ones back
  ///
  /// In fr, this message translates to:
  /// **'Rétablir les règles d\'origine'**
  String get gameRulesRestoreDefault;

  /// Snackbar after the user's rules are saved
  ///
  /// In fr, this message translates to:
  /// **'Règles enregistrées'**
  String get gameRulesSaved;

  /// Snackbar after the shipped rules are restored
  ///
  /// In fr, this message translates to:
  /// **'Règles d\'origine rétablies'**
  String get gameRulesRestored;

  /// Footnote on the shipped rules: original summary, trademarks used descriptively
  ///
  /// In fr, this message translates to:
  /// **'Résumé rédigé pour CountScore à partir des règles couramment jouées. Les noms de jeux appartiennent à leurs propriétaires et ne sont cités qu\'à titre descriptif.'**
  String get gameRulesDisclaimer;

  /// Built-in game type: ZapZap (the app's own game)
  ///
  /// In fr, this message translates to:
  /// **'ZapZap'**
  String get gameTypeNameZapzap;

  /// Not displayed: what gameTypeNameZapzap sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'ZapZap'**
  String get gameTypeNameZapzapSortKey;

  /// Built-in game type: Uno
  ///
  /// In fr, this message translates to:
  /// **'Uno'**
  String get gameTypeNameUno;

  /// Not displayed: what gameTypeNameUno sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Uno'**
  String get gameTypeNameUnoSortKey;

  /// Built-in game type: Scrabble
  ///
  /// In fr, this message translates to:
  /// **'Scrabble'**
  String get gameTypeNameScrabble;

  /// Not displayed: what gameTypeNameScrabble sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Scrabble'**
  String get gameTypeNameScrabbleSortKey;

  /// Built-in game type: the catch-all type, for a game with no preset
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get gameTypeNameOther;

  /// Not displayed: what gameTypeNameOther sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get gameTypeNameOtherSortKey;

  /// Built-in game type: Skyjo
  ///
  /// In fr, this message translates to:
  /// **'Skyjo'**
  String get gameTypeNameSkyjo;

  /// Not displayed: what gameTypeNameSkyjo sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Skyjo'**
  String get gameTypeNameSkyjoSortKey;

  /// Built-in game type: the President card game
  ///
  /// In fr, this message translates to:
  /// **'Président'**
  String get gameTypeNamePresident;

  /// Not displayed: what gameTypeNamePresident sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Président'**
  String get gameTypeNamePresidentSortKey;

  /// Built-in game type: Belote
  ///
  /// In fr, this message translates to:
  /// **'Belote'**
  String get gameTypeNameBelote;

  /// Not displayed: what gameTypeNameBelote sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Belote'**
  String get gameTypeNameBeloteSortKey;

  /// Built-in game type: Tarot (the trick-taking card game)
  ///
  /// In fr, this message translates to:
  /// **'Tarot'**
  String get gameTypeNameTarot;

  /// Not displayed: what gameTypeNameTarot sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Tarot'**
  String get gameTypeNameTarotSortKey;

  /// Built-in game type: Bridge
  ///
  /// In fr, this message translates to:
  /// **'Bridge'**
  String get gameTypeNameBridge;

  /// Not displayed: what gameTypeNameBridge sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Bridge'**
  String get gameTypeNameBridgeSortKey;

  /// Built-in game type: Rummy
  ///
  /// In fr, this message translates to:
  /// **'Rami'**
  String get gameTypeNameRami;

  /// Not displayed: what gameTypeNameRami sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Rami'**
  String get gameTypeNameRamiSortKey;

  /// Built-in game type: Coinche (Belote with a bid)
  ///
  /// In fr, this message translates to:
  /// **'Coinche'**
  String get gameTypeNameCoinche;

  /// Not displayed: what gameTypeNameCoinche sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Coinche'**
  String get gameTypeNameCoincheSortKey;

  /// Built-in game type: Yahtzee
  ///
  /// In fr, this message translates to:
  /// **'Yahtzee'**
  String get gameTypeNameYahtzee;

  /// Not displayed: what gameTypeNameYahtzee sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Yahtzee'**
  String get gameTypeNameYahtzeeSortKey;

  /// Built-in game type: Phase 10
  ///
  /// In fr, this message translates to:
  /// **'Phase 10'**
  String get gameTypeNamePhase10;

  /// Not displayed: what gameTypeNamePhase10 sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Phase 10'**
  String get gameTypeNamePhase10SortKey;

  /// Built-in game type: Flip 7
  ///
  /// In fr, this message translates to:
  /// **'Flip 7'**
  String get gameTypeNameFlip7;

  /// Not displayed: what gameTypeNameFlip7 sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Flip 7'**
  String get gameTypeNameFlip7SortKey;

  /// Built-in game type: Mille Bornes
  ///
  /// In fr, this message translates to:
  /// **'Mille Bornes'**
  String get gameTypeNameMilleBornes;

  /// Not displayed: what gameTypeNameMilleBornes sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Mille Bornes'**
  String get gameTypeNameMilleBornesSortKey;

  /// Built-in game type: Rummikub
  ///
  /// In fr, this message translates to:
  /// **'Rummikub'**
  String get gameTypeNameRummikub;

  /// Not displayed: what gameTypeNameRummikub sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Rummikub'**
  String get gameTypeNameRummikubSortKey;

  /// Built-in game type: the '6 takes' card game
  ///
  /// In fr, this message translates to:
  /// **'6 qui prend'**
  String get gameTypeNameSixNimmt;

  /// Not displayed: what gameTypeNameSixNimmt sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'6 qui prend'**
  String get gameTypeNameSixNimmtSortKey;

  /// Built-in game type: Qwirkle
  ///
  /// In fr, this message translates to:
  /// **'Qwirkle'**
  String get gameTypeNameQwirkle;

  /// Not displayed: what gameTypeNameQwirkle sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Qwirkle'**
  String get gameTypeNameQwirkleSortKey;

  /// Built-in game type: Farkle
  ///
  /// In fr, this message translates to:
  /// **'Farkle'**
  String get gameTypeNameFarkle;

  /// Not displayed: what gameTypeNameFarkle sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Farkle'**
  String get gameTypeNameFarkleSortKey;

  /// Built-in game type: Canasta
  ///
  /// In fr, this message translates to:
  /// **'Canasta'**
  String get gameTypeNameCanasta;

  /// Not displayed: what gameTypeNameCanasta sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Canasta'**
  String get gameTypeNameCanastaSortKey;

  /// Built-in game type: Wizard
  ///
  /// In fr, this message translates to:
  /// **'Wizard'**
  String get gameTypeNameWizard;

  /// Not displayed: what gameTypeNameWizard sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Wizard'**
  String get gameTypeNameWizardSortKey;

  /// Built-in game type: Triomino
  ///
  /// In fr, this message translates to:
  /// **'Triomino'**
  String get gameTypeNameTriomino;

  /// Not displayed: what gameTypeNameTriomino sorts by in game-type lists. Equal to the name in every locale but zh, where it is the pinyin of the name, tone numbers after each syllable, one space between syllables (lib/utils/game_type_name.dart).
  ///
  /// In fr, this message translates to:
  /// **'Triomino'**
  String get gameTypeNameTriominoSortKey;

  /// Marks the device that owns the group in the group's device list
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get groupDeviceOwner;

  /// Action, offered to the owner only, handing the group's owner role to another device
  ///
  /// In fr, this message translates to:
  /// **'Nommer propriétaire'**
  String get groupDeviceMakeOwner;

  /// Confirmation before handing the owner role to another device
  ///
  /// In fr, this message translates to:
  /// **'Confier le groupe à « {label} » ? Cet appareil ne pourra plus exclure d\'appareil ni changer le code d\'invitation.'**
  String groupDeviceMakeOwnerConfirm(String label);

  /// Shown after the owner role was handed to another device
  ///
  /// In fr, this message translates to:
  /// **'« {label} » est maintenant propriétaire du groupe.'**
  String groupDeviceOwnerChanged(String label);

  /// Explanation under the title of the devices sheet, shown to a device that does not own the group
  ///
  /// In fr, this message translates to:
  /// **'Seul le propriétaire du groupe peut exclure un appareil ou changer le code d\'invitation.'**
  String get groupDevicesExplainMember;

  /// The server refused an action reserved to the group's owner
  ///
  /// In fr, this message translates to:
  /// **'Réservé au propriétaire du groupe'**
  String get groupErrorNotOwner;

  /// Game board overflow-menu item and dialog title: draws one of the game's players at random to start
  ///
  /// In fr, this message translates to:
  /// **'Qui commence ?'**
  String get whoStarts;

  /// Button in the Who starts? dialog that draws another player at random
  ///
  /// In fr, this message translates to:
  /// **'Tirer à nouveau'**
  String get whoStartsAgain;

  /// Button on the home screen's Resume card: opens the most recently played game that is still open
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resumeGame;

  /// Section header above the list of games on the home screen, under the Resume card
  ///
  /// In fr, this message translates to:
  /// **'Récentes'**
  String get recentGames;

  /// Status pill on a game card of the home screen: the game is not finished
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get gameInProgress;

  /// Which round an open game is at, on the home screen's Resume card, after the game type (e.g. 'ZapZap · tour 7')
  ///
  /// In fr, this message translates to:
  /// **'tour {number}'**
  String roundNumber(int number);

  /// On the home screen's Resume card: who is in the lead and their total
  ///
  /// In fr, this message translates to:
  /// **'{name} mène · {score}'**
  String gameLeader(String name, int score);

  /// Tooltip and screen-reader label of the winner pill on a finished game's card
  ///
  /// In fr, this message translates to:
  /// **'Gagnée par {name}'**
  String gameWonBy(String name);

  /// A player's place under their total on the board (1er, 2e...)
  ///
  /// In fr, this message translates to:
  /// **'{rank, plural, =1{1er} other{{rank}e}}'**
  String boardRank(int rank);

  /// Board app-bar toggle: switch to one row per player
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par joueur'**
  String get boardViewRows;

  /// Board app-bar toggle: switch back to one column (lane) per player
  ///
  /// In fr, this message translates to:
  /// **'Une colonne par joueur'**
  String get boardViewLanes;

  /// One-row-per-player board: sort the rows in seat order (the other choice is the ranking)
  ///
  /// In fr, this message translates to:
  /// **'Ordre de jeu'**
  String get boardSeatOrder;

  /// Short round column header in the one-row-per-player board (T4)
  ///
  /// In fr, this message translates to:
  /// **'T{number}'**
  String boardRoundShort(int number);

  /// Column header of the player names in the one-row-per-player board
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get boardPlayer;

  /// Column header of the totals in the one-row-per-player board
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get boardTotal;

  /// Screen-reader label of the crown on the leading player's lane
  ///
  /// In fr, this message translates to:
  /// **'En tête'**
  String get boardLeader;

  /// Settings → Group button, and the title of the screen it opens: the group's comment style, language and LLM usage
  ///
  /// In fr, this message translates to:
  /// **'Commentaires et usage'**
  String get groupSettingsTitle;

  /// Explains what the group's comment settings apply to, at the top of the group settings screen
  ///
  /// In fr, this message translates to:
  /// **'Le style et la langue des commentaires que le serveur rédige pour les parties du groupe. Tous les membres peuvent les changer.'**
  String get groupSettingsDescription;

  /// Label of the choice of the group's comment style
  ///
  /// In fr, this message translates to:
  /// **'Style des commentaires'**
  String get groupCommentStyle;

  /// Group comment style: tells the game as a story
  ///
  /// In fr, this message translates to:
  /// **'Narratif'**
  String get groupCommentStyleNarrative;

  /// Group comment style: funny, teasing
  ///
  /// In fr, this message translates to:
  /// **'Humoristique'**
  String get groupCommentStyleHumorous;

  /// Group comment style: dry, statistics-minded
  ///
  /// In fr, this message translates to:
  /// **'Analytique'**
  String get groupCommentStyleAnalytical;

  /// Label of the dropdown picking the language of the group's comments
  ///
  /// In fr, this message translates to:
  /// **'Langue des commentaires'**
  String get groupCommentLanguage;

  /// Snackbar after the group's comment style or language was changed on the server
  ///
  /// In fr, this message translates to:
  /// **'Réglages du groupe enregistrés'**
  String get groupSettingsSaved;

  /// Heading of the group's LLM spending this month
  ///
  /// In fr, this message translates to:
  /// **'Usage du LLM ce mois-ci'**
  String get groupUsageTitle;

  /// The group's LLM spending against its monthly budget; both are formatted amounts in US dollars
  ///
  /// In fr, this message translates to:
  /// **'{used} dépensés sur {budget}'**
  String groupUsageAmount(String used, String budget);

  /// When the group's monthly LLM spending starts again from zero
  ///
  /// In fr, this message translates to:
  /// **'Remise à zéro le {date}'**
  String groupUsageResets(String date);

  /// Title of the leaderboard's hero card: the player with the best win rate
  ///
  /// In fr, this message translates to:
  /// **'Meilleur taux de victoire'**
  String get statsBestWinRate;

  /// Hero card detail: wins out of games of the selected game type
  ///
  /// In fr, this message translates to:
  /// **'{wins, plural, =0{Aucune victoire sur {games}} one{{wins} victoire sur {games}} other{{wins} victoires sur {games}}}'**
  String statsWinsOutOfGames(int wins, int games);

  /// Leaderboard column header above the players
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get statsColumnPlayer;

  /// Leaderboard column header above the number of games
  ///
  /// In fr, this message translates to:
  /// **'Parties'**
  String get statsColumnGames;

  /// Leaderboard row of a player with too few finished games to be ranked
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} partie · hors classement} other{{count} parties · hors classement}}'**
  String statsUnranked(int count);

  /// Note under the leaderboard: the ranking threshold and how to open a player card
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Classement à partir de {count} partie terminée. Touchez un joueur pour voir sa fiche.} other{Classement à partir de {count} parties terminées. Touchez un joueur pour voir sa fiche.}}'**
  String statsLeaderboardFooter(int count);

  /// Player card tile: label under the number of games
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{partie} other{parties}}'**
  String statsGamesLabel(int count);

  /// Player card tile: label under the number of wins
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{victoire} other{victoires}}'**
  String statsWinsLabel(int count);

  /// Player card tile: label under the average final place
  ///
  /// In fr, this message translates to:
  /// **'rang moyen'**
  String get statsAverageRank;

  /// Player card: title of the chart of the final place over the last games
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Rang, dernière partie} other{Rang, {count} dernières parties}}'**
  String statsRankChartTitle(int count);

  /// Player card: the final places are getting better
  ///
  /// In fr, this message translates to:
  /// **'en progrès'**
  String get statsTrendImproving;

  /// Player card: the final places are getting worse
  ///
  /// In fr, this message translates to:
  /// **'en recul'**
  String get statsTrendDeclining;

  /// Player card: the final places neither improve nor decline
  ///
  /// In fr, this message translates to:
  /// **'régulier'**
  String get statsTrendSteady;

  /// Short ordinal of a final place, on the rank chart axis (1st, 4th). The place is passed as a string so that a select can pick the irregular forms.
  ///
  /// In fr, this message translates to:
  /// **'{rank, select, 1{1er} other{{rank}e}}'**
  String statsRankOrdinal(String rank);

  /// Player card chip: the current run of consecutive wins
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Pas de série en cours} one{Série : {count} victoire} other{Série : {count} victoires}}'**
  String statsWinStreak(int count);

  /// Player card chip: the best final total on this game type
  ///
  /// In fr, this message translates to:
  /// **'Record : {total}'**
  String statsRecord(int total);

  /// Player card section header: figures on one game type
  ///
  /// In fr, this message translates to:
  /// **'Sur {gameType}'**
  String statsOnGameType(String gameType);

  /// Player card row: the mean final total
  ///
  /// In fr, this message translates to:
  /// **'Total final moyen'**
  String get statsAverageTotal;

  /// Player card row: the best final total (lowest when the lowest score wins)
  ///
  /// In fr, this message translates to:
  /// **'Meilleur total final'**
  String get statsBestTotal;

  /// Player card row: the opponent this player most often finished ahead of
  ///
  /// In fr, this message translates to:
  /// **'Adversaire le plus battu'**
  String get statsMostBeaten;

  /// Accessibility hint on a leaderboard row: opens the player's card
  ///
  /// In fr, this message translates to:
  /// **'voir la fiche'**
  String get statsOpenPlayerCard;

  /// Tooltip of the share button on the game-end and ranking screens: opens the system share sheet with the standings as text
  ///
  /// In fr, this message translates to:
  /// **'Partager le résultat'**
  String get shareResult;

  /// Tooltip of the share button on the game analysis screen: shares the standings and the commentary as text
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'analyse'**
  String get shareAnalysis;

  /// Subject of the shared result (used by e-mail apps and the web e-mail fallback)
  ///
  /// In fr, this message translates to:
  /// **'Résultat : {gameName}'**
  String shareResultSubject(String gameName);

  /// First line of the shared result text: when the game was played
  ///
  /// In fr, this message translates to:
  /// **'Partie du {date}'**
  String shareResultTitle(String date);

  /// One line of the standings in the shared result text: place, player name, total
  ///
  /// In fr, this message translates to:
  /// **'{rank}. {name} : {points, plural, one{{points} point} other{{points} points}}'**
  String shareResultStanding(int rank, String name, int points);

  /// Last line of the shared result text: names the app and links to its Play Store listing (no tracking parameter)
  ///
  /// In fr, this message translates to:
  /// **'Scores comptés avec {appName} : {url}'**
  String shareResultFooter(String appName, String url);

  /// Snackbar when the system share sheet (or the web fallback) could not be opened
  ///
  /// In fr, this message translates to:
  /// **'Le partage n\'a pas pu s\'ouvrir'**
  String get shareFailed;

  /// Overline above the game name field on the New game screen (shown in capitals)
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get newGameNameLabel;

  /// Overline above the game-type tiles on the New game screen (shown in capitals)
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get newGameGameLabel;

  /// Link that opens the full list of game types; count is how many exist
  ///
  /// In fr, this message translates to:
  /// **'Tous les jeux ({count})'**
  String newGameAllGames(int count);

  /// Overline above the players on the New game screen: their order is the seat order (shown in capitals)
  ///
  /// In fr, this message translates to:
  /// **'Joueurs · ordre de jeu'**
  String get newGamePlayersLabel;

  /// Hint next to the players overline: drag a row by its handle to change the seat order
  ///
  /// In fr, this message translates to:
  /// **'glisser pour réordonner'**
  String get newGameDragToReorder;

  /// Small badge on the first seat: this player deals (plays first)
  ///
  /// In fr, this message translates to:
  /// **'donne'**
  String get newGameDealer;

  /// Dashed row under the players that opens the "who's playing" sheet
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get newGameAddPlayer;

  /// Primary button that creates the game and opens its board
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Commencer} =1{Commencer · 1 joueur} other{Commencer · {count} joueurs}}'**
  String newGameStart(int count);

  /// Title of the sheet where players are picked for a new game
  ///
  /// In fr, this message translates to:
  /// **'Qui joue ?'**
  String get whoIsPlayingTitle;

  /// Hint of the search field that filters known players, or names a new one
  ///
  /// In fr, this message translates to:
  /// **'Nom, ou nouveau joueur'**
  String get whoIsPlayingSearchHint;

  /// Overline above the known players, most frequent first (shown in capitals)
  ///
  /// In fr, this message translates to:
  /// **'Joue souvent avec vous'**
  String get whoIsPlayingFrequent;

  /// Action that picks the players of the last game, in the same order
  ///
  /// In fr, this message translates to:
  /// **'Mêmes joueurs que « {gameName} »'**
  String whoIsPlayingSameAs(String gameName);

  /// Action that creates a new player with the name typed in the search field
  ///
  /// In fr, this message translates to:
  /// **'Créer « {name} »'**
  String whoIsPlayingCreate(String name);

  /// Button that closes the sheet and seats the chosen players; count is how many are chosen
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Valider} =1{Ajouter 1 joueur} other{Ajouter {count} joueurs}}'**
  String whoIsPlayingConfirm(int count);

  /// Name the New game screen suggests for the very first game; later games count on from the previous game's name
  ///
  /// In fr, this message translates to:
  /// **'Partie {number}'**
  String defaultGameName(int number);
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
