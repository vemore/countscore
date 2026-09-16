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
  String version(String version) {
    return 'संस्करण $version';
  }

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
  String get featureGroupSharing => 'समूह साझाकरण';

  @override
  String get featureZapZapAnalysis => 'ZapZap खेल विश्लेषण';

  @override
  String get rateApp => 'CountScore को रेट करें';

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

  @override
  String get comment => 'टिप्पणी';

  @override
  String get enterComment => 'टिप्पणी दर्ज करें';

  @override
  String get analyzeGame => 'खेल का विश्लेषण करें';

  @override
  String get analysisTitle => 'खेल विश्लेषण';

  @override
  String get generatingAnalysis => 'विश्लेषण उत्पन्न हो रहा है…';

  @override
  String get generateAnalysis => 'विश्लेषण उत्पन्न करें';

  @override
  String get regenerateAnalysis => 'विश्लेषण पुनः उत्पन्न करें';

  @override
  String get deleteAnalysis => 'विश्लेषण हटाएँ';

  @override
  String get confirmRegenerateAnalysis =>
      'पुनः उत्पन्न करें? वर्तमान विश्लेषण बदला जाएगा।';

  @override
  String get confirmDeleteAnalysis => 'इस खेल का विश्लेषण हटाएँ?';

  @override
  String get analysisError => 'विश्लेषण उत्पन्न करने में विफल';

  @override
  String get analysisErrorUnavailable =>
      'विश्लेषण सर्वर अस्थायी रूप से उपलब्ध नहीं है। कृपया बाद में पुनः प्रयास करें।';

  @override
  String analysisErrorStatus(int status) {
    return 'विश्लेषण उत्पन्न करने में विफल (HTTP $status)';
  }

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String analysisGeneratedAt(String date) {
    return '$date को उत्पन्न';
  }

  @override
  String get serverSection => 'सर्वर';

  @override
  String get backendUrlLabel => 'सर्वर URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'कनेक्टेड सुविधाओं के लिए एक CountScore सर्वर आवश्यक है। इसे backend/ फ़ोल्डर से इंस्टॉल करें और उसका पता यहाँ दर्ज करें। सर्वर के बिना, कोई भी डेटा इस डिवाइस से बाहर नहीं जाता।';

  @override
  String get backendNotConfigured => 'कोई सर्वर कॉन्फ़िगर नहीं है';

  @override
  String get backendUrlInvalid =>
      'अमान्य पता। पूरा URL दर्ज करें, उदाहरण के लिए https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// केवल लोकल नेटवर्क पर स्वीकार किया जाता है। सार्वजनिक सर्वर के लिए https:// का उपयोग करें।';

  @override
  String get testConnection => 'कनेक्शन जाँचें';

  @override
  String get connectionOk => 'सर्वर प्रतिक्रिया दे रहा है';

  @override
  String get connectionFailed => 'सर्वर प्रतिक्रिया नहीं दे रहा है';

  @override
  String get serverUrlSaved => 'सर्वर सहेजा गया';

  @override
  String get analysisRequiresBackend =>
      'इस विश्लेषण के लिए एक सर्वर आवश्यक है। सेटिंग्स में एक कॉन्फ़िगर करें।';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get serverUrlCleared => 'सर्वर हटा दिया गया';

  @override
  String get groupSection => 'समूह';

  @override
  String get groupDescription =>
      'समूह के अन्य उपकरणों के साथ खेल साझा करें। साझा किए गए खेल, उनके खिलाड़ी, स्कोर, टिप्पणियाँ और विश्लेषण आपके सर्वर पर भेजे जाते हैं; बाकी खेल इसी उपकरण पर रहते हैं।';

  @override
  String get groupNeedsServer => 'पहले ऊपर एक सर्वर सेट करें।';

  @override
  String get groupCreate => 'समूह बनाएँ';

  @override
  String get groupJoin => 'समूह में शामिल हों';

  @override
  String get groupNameLabel => 'समूह का नाम';

  @override
  String get deviceLabelLabel => 'इस उपकरण का नाम';

  @override
  String get deviceLabelDefault => 'मेरा उपकरण';

  @override
  String get shareTokenLabel => 'आमंत्रण कोड';

  @override
  String get shareTokenHint => 'समूह के किसी सदस्य से मिला कोड चिपकाएँ';

  @override
  String groupCurrent(String name) {
    return 'समूह: $name';
  }

  @override
  String get shareTokenExplain =>
      'यह कोड उन उपकरणों को भेजें जिन्हें समूह में शामिल होना है। जिसके पास यह कोड है, वह शामिल हो सकता है।';

  @override
  String get shareTokenCopy => 'कोड कॉपी करें';

  @override
  String get shareTokenCopied => 'कोड कॉपी हो गया';

  @override
  String get shareTokenRotate => 'नया कोड';

  @override
  String get shareTokenRotateConfirm =>
      'पुराने कोड से अब कोई शामिल नहीं हो पाएगा। जो उपकरण पहले से समूह में हैं, उन पर असर नहीं पड़ेगा।';

  @override
  String get groupLeave => 'समूह छोड़ें';

  @override
  String get groupLeaveConfirm =>
      'यह उपकरण समूह छोड़ देगा। साझा किए गए खेल इसी उपकरण पर रहेंगे, पर अब सिंक नहीं होंगे।';

  @override
  String get groupLeft => 'समूह छोड़ दिया';

  @override
  String get groupJoined => 'समूह में शामिल हो गए';

  @override
  String get clearServerLeavesGroup =>
      'सर्वर हटाने से समूह छूट जाएगा। साझा किए गए खेल इसी उपकरण पर रहेंगे।';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String syncStatusIdle(String time) {
    return '$time पर सिंक हुआ';
  }

  @override
  String get syncStatusSyncing => 'सिंक हो रहा है…';

  @override
  String get syncStatusOffline =>
      'सर्वर तक पहुँच नहीं — बदलाव बाद में भेजे जाएँगे';

  @override
  String get syncStatusUnauthorized =>
      'सर्वर अब इस उपकरण को स्वीकार नहीं करता। समूह छोड़ें, फिर दोबारा शामिल हों।';

  @override
  String get syncStatusError => 'सिंक के दौरान सर्वर त्रुटि';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बदलाव बाकी हैं',
      one: '$count बदलाव बाकी है',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'सर्वर ने $count बदलाव अस्वीकार किए',
      one: 'सर्वर ने $count बदलाव अस्वीकार किया',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'आमंत्रण कोड अज्ञात है या बदल दिया गया है';

  @override
  String get groupErrorRateLimited =>
      'बहुत अधिक प्रयास। एक मिनट बाद फिर कोशिश करें।';

  @override
  String get groupErrorUnreachable => 'सर्वर तक पहुँच नहीं';

  @override
  String get groupErrorServer => 'सर्वर त्रुटि';

  @override
  String get shareWithGroup => 'समूह के साथ साझा करें';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name के उपकरण यह खेल देख और बदल सकेंगे';
  }

  @override
  String shareGameConfirm(String name) {
    return 'यह खेल, इसके खिलाड़ी, स्कोर और टिप्पणियाँ $name को भेजे जाएँगे। साझा करना वापस नहीं लिया जा सकता।';
  }

  @override
  String get gameSharedDone => 'खेल समूह के साथ साझा किया गया';

  @override
  String get gameSharedBadge => 'साझा खेल';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'ये नाम साझा नहीं किए जा सकते: $names। अक्षर, अंक, स्पेस, हाइफ़न, एपॉस्ट्रॉफ़ी या पूर्णविराम का ही उपयोग करें (अधिकतम 32 वर्ण)।';
  }

  @override
  String roundRenumbered(int number) {
    return 'यह राउंड किसी दूसरे उपकरण पर पहले ही दर्ज हो चुका था, इसलिए यह राउंड $number बन गया।';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" किसी दूसरे उपकरण पर हटा दिया गया';
  }

  @override
  String get groupDevices => 'डिवाइस';

  @override
  String get groupDevicesExplain =>
      'खोया या बेचा गया फ़ोन यहाँ से समूह से हटाया जा सकता है।';

  @override
  String get groupDeviceThisOne => 'यह डिवाइस';

  @override
  String groupDeviceLastSeen(String date) {
    return 'आख़िरी बार देखा गया: $date';
  }

  @override
  String get groupDeviceRevoke => 'हटाएँ';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '“$label” को समूह से हटाएँ? यह अब सिंक नहीं होगा। आमंत्रण कोड भी बदल जाएगा: सदस्यों की पहुँच बनी रहेगी, लेकिन किसी को आमंत्रित करने के लिए नया कोड साझा करना होगा।';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '“$label” हटा दिया गया। आमंत्रण कोड बदल गया है।';
  }

  @override
  String get reportCommentary => 'इस टिप्पणी की रिपोर्ट करें';

  @override
  String get reportCommentarySubject => 'CountScore — AI टिप्पणी की रिपोर्ट';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'इस AI-जनित टिप्पणी में क्या समस्या है?\n\n\n---\nसंदर्भ: $reference\nटिप्पणी:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'कोई ईमेल ऐप नहीं मिला। इस टिप्पणी की रिपोर्ट करने के लिए $email पर लिखें।';
  }
}
