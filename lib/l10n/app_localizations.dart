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

  /// Application version
  ///
  /// In fr, this message translates to:
  /// **'Version 1.0.1'**
  String get version;

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
