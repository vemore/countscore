// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'होम';

  @override
  String get playersListTitle => 'खिलाड़ियों की सूची';

  @override
  String get gameTypesTitle => 'खेल के प्रकार';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get aboutTitle => 'के बारे में';

  @override
  String get newGame => 'नया खेल';

  @override
  String get noGames => 'कोई खेल नहीं';

  @override
  String get noGamesOfThisType => 'इस प्रकार का कोई खेल नहीं';

  @override
  String get createFirstGame => 'अपना पहला खेल बनाएं';

  @override
  String get createdOn => 'बनाया गया';

  @override
  String get newWithSamePlayers => 'उन्हीं खिलाड़ियों के साथ नया';

  @override
  String get newGameSuffix => '(नया)';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get delete => 'हटाएं';

  @override
  String get confirmDeletion => 'हटाने की पुष्टि करें';

  @override
  String confirmDeleteGame(String name) {
    return 'क्या आप वाकई \"$name\" खेल को हटाना चाहते हैं?';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get renameGame => 'खेल का नाम बदलें';

  @override
  String get gameName => 'खेल का नाम';

  @override
  String get save => 'सहेजें';

  @override
  String get filterByGameType => 'खेल के प्रकार से फ़िल्टर करें';

  @override
  String get allGames => 'सभी खेल';

  @override
  String get filterGames => 'गेम फ़िल्टर करें';

  @override
  String get applyFilter => 'लागू करें';

  @override
  String get resetFilter => 'रीसेट करें';

  @override
  String get selectGameType => 'एक गेम प्रकार चुनें';

  @override
  String get gameType => 'खेल का प्रकार';

  @override
  String get loadingGameTypes => 'खेल के प्रकार लोड हो रहे हैं...';

  @override
  String get winRule => 'जीत का नियम';

  @override
  String get lowestScoreWins => 'सबसे कम स्कोर जीतता है';

  @override
  String get highestScoreWins => 'सबसे अधिक स्कोर जीतता है';

  @override
  String get lowestScoreExample => 'उदा: गोल्फ, हार्ट्स';

  @override
  String get highestScoreExample => 'उदा: रम्मी, ब्रिज';

  @override
  String get players => 'खिलाड़ी';

  @override
  String get add => 'जोड़ें';

  @override
  String get pleaseEnterName => 'कृपया नाम दर्ज करें';

  @override
  String get atLeast2PlayersRequired => 'कम से कम 2 खिलाड़ी आवश्यक हैं';

  @override
  String playerNumber(int index) {
    return 'खिलाड़ी $index';
  }

  @override
  String get selectPlayer => 'एक खिलाड़ी चुनें...';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get remove => 'हटाएं';

  @override
  String get createGame => 'खेल बनाएं';

  @override
  String get game => 'खेल';

  @override
  String get editGame => 'गेम संपादित करें';

  @override
  String get editGameDialogTitle => 'गेम संपादित करें';

  @override
  String get gameSettings => 'गेम सेटिंग्स';

  @override
  String get removePlayer => 'खिलाड़ी हटाएं';

  @override
  String get addPlayerToGame => 'खिलाड़ी जोड़ें';

  @override
  String get warningRemovePlayer =>
      'चेतावनी! इस खिलाड़ी को हटाने से इस गेम से उनके सभी स्कोर हट जाएंगे। यह क्रिया अपरिवर्तनीय है।';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'क्या आप वाकई इस गेम से $playerName को हटाना चाहते हैं?';
  }

  @override
  String get playerRemoved => 'खिलाड़ी गेम से हटा दिया गया';

  @override
  String get deleteLastRound => 'अंतिम राउंड हटाएं';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get confirmDeleteLastRound => 'अंतिम राउंड हटाएं?';

  @override
  String get noPlayersInGame => 'इस खेल में कोई खिलाड़ी नहीं';

  @override
  String get round => 'राउंड';

  @override
  String get addRound => 'राउंड जोड़ें';

  @override
  String get score => 'स्कोर';

  @override
  String get enterScore => 'स्कोर दर्ज करें';

  @override
  String get appearance => 'रूप-रंग';

  @override
  String get light => 'हल्का';

  @override
  String get dark => 'गहरा';

  @override
  String get system => 'सिस्टम';

  @override
  String get screen => 'स्क्रीन';

  @override
  String get keepScreenAwake => 'स्क्रीन को जगाए रखें';

  @override
  String get keepScreenAwakeDescription =>
      'खेल के दौरान स्क्रीन को स्लीप से रोकता है';

  @override
  String get backup => 'बैकअप';

  @override
  String get exportDatabase => 'डेटाबेस निर्यात करें';

  @override
  String get exportDatabaseDescription =>
      'अपने सभी खेलों को एक फ़ाइल में सहेजें';

  @override
  String get databaseExportedTo => 'डेटाबेस यहां निर्यात किया गया:';

  @override
  String get errorDuringExport => 'निर्यात के दौरान त्रुटि:';

  @override
  String get importDatabase => 'डेटाबेस आयात करें';

  @override
  String get importDatabaseDescription =>
      'बैकअप फ़ाइल से अपने खेलों को पुनर्स्थापित करें';

  @override
  String get confirmation => 'पुष्टि';

  @override
  String get importWarning =>
      'आयात करने से आपका सभी वर्तमान डेटा बदल जाएगा। आयात से पहले एक स्वचालित बैकअप बनाया जाएगा।\n\nक्या आप जारी रखना चाहते हैं?';

  @override
  String get import => 'आयात करें';

  @override
  String get databaseImportedSuccessfully =>
      'डेटाबेस सफलतापूर्वक आयात किया गया';

  @override
  String get importSuccessful => 'आयात सफल';

  @override
  String get importSuccessMessage =>
      'डेटाबेस सफलतापूर्वक आयात किया गया है।\n\nएप्लिकेशन अब बंद हो जाएगी। नया डेटा देखने के लिए कृपया इसे फिर से खोलें।';

  @override
  String get ok => 'ठीक है';

  @override
  String get errorDuringImport => 'आयात के दौरान त्रुटि:';

  @override
  String get noPlayers => 'कोई खिलाड़ी नहीं';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खिलाड़ी: $names',
      one: '1 खिलाड़ी: $names',
      zero: 'कोई खिलाड़ी नहीं',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'जब आप खेल बनाएंगे\nतो खिलाड़ी यहां दिखाई देंगे';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खेल',
      one: '1 खेल',
      zero: '0 खेल',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जीत',
      one: '1 जीत',
      zero: '0 जीत',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'रंग बदलें';

  @override
  String get renamePlayer => 'खिलाड़ी का नाम बदलें';

  @override
  String get newName => 'नया नाम';

  @override
  String playerRenamedTo(String name) {
    return 'खिलाड़ी का नाम \"$name\" रखा गया';
  }

  @override
  String get deletePlayer => 'खिलाड़ी हटाएं';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'क्या आप वाकई \"$name\" को हटाना चाहते हैं?\n\nयह खिलाड़ी सभी $count खेल(खेलों) से हटा दिया जाएगा।';
  }

  @override
  String playerDeleted(String name) {
    return 'खिलाड़ी \"$name\" हटाया गया';
  }

  @override
  String get chooseColor => 'रंग चुनें';

  @override
  String get noGameTypes => 'कोई खेल प्रकार नहीं';

  @override
  String get predefined => 'डिफ़ॉल्ट';

  @override
  String get edit => 'संपादित करें';

  @override
  String get newType => 'नया प्रकार';

  @override
  String get editType => 'प्रकार संपादित करें';

  @override
  String get newGameType => 'नया खेल प्रकार';

  @override
  String get gameTypeName => 'खेल प्रकार का नाम';

  @override
  String get icon => 'आइकन:';

  @override
  String get color => 'रंग:';

  @override
  String get chooseIcon => 'आइकन चुनें';

  @override
  String get nameIsRequired => 'नाम आवश्यक है';

  @override
  String get create => 'बनाएं';

  @override
  String get ranking => 'रैंकिंग';

  @override
  String get noCurrentGame => 'कोई वर्तमान खेल नहीं';

  @override
  String get noScoresRecorded => 'कोई स्कोर रिकॉर्ड नहीं किया गया';

  @override
  String get playerStatistics => 'खिलाड़ी सांख्यिकी';

  @override
  String get noStatisticsAvailable => 'कोई सांख्यिकी उपलब्ध नहीं';

  @override
  String get gamesPlayed => 'खेले गए खेल';

  @override
  String get wins => 'जीत';

  @override
  String get winRate => 'जीत दर';

  @override
  String get overallStatistics => 'समग्र सांख्यिकी';

  @override
  String get byGameType => 'खेल प्रकार के अनुसार';

  @override
  String get rate => 'दर';

  @override
  String get version => 'संस्करण 1.0.0';

  @override
  String get appDescription =>
      'Vincent Moreau द्वारा आपके गेम सत्रों के लिए स्कोर प्रबंधन एप्लिकेशन';

  @override
  String get features => 'विशेषताएं';

  @override
  String get featureDifferentGameTypes => 'विभिन्न खेल प्रकार';

  @override
  String get featurePlayerManagement => 'खिलाड़ी प्रबंधन';

  @override
  String get featureDetailedStatistics => 'विस्तृत सांख्यिकी';

  @override
  String get featureCustomization => 'अनुकूलन';

  @override
  String get featureDarkLightTheme => 'गहरा/हल्का थीम';

  @override
  String get credits => 'श्रेय';

  @override
  String get appIconCredit => 'ऐप आइकन';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'एक खिलाड़ी चुनें';

  @override
  String get search => 'खोजें';

  @override
  String get searchOrCreate => 'खोजें / बनाएं';

  @override
  String get createNewPlayer => 'नया खिलाड़ी बनाएं';

  @override
  String get newPlayerName => 'नए खिलाड़ी का नाम';

  @override
  String get noPlayersFound => 'कोई खिलाड़ी नहीं मिला';

  @override
  String get allPlayersSelected => 'सभी खिलाड़ी चुने जा चुके हैं';

  @override
  String get close => 'बंद करें';

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
  String get firstPlayerOver => 'First player over';

  @override
  String get firstPlayerUnder => 'First player under';

  @override
  String get lastPlayerOver => 'Last player over';

  @override
  String get lastPlayerUnder => 'Last player under';

  @override
  String get threshold => 'Threshold';

  @override
  String get conditionType => 'Condition Type';

  @override
  String get gameOverTitle => 'Game Over!';

  @override
  String get gameOverMessage => 'Game over condition reached. End game now?';

  @override
  String get continuePlay => 'Continue Playing';

  @override
  String get endGame => 'End Game';
}
