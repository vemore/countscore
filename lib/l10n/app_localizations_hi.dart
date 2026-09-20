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
  String get newWithSamePlayers => 'उन्हीं खिलाड़ियों के साथ नया';

  @override
  String get playAgain => 'फिर से खेलें';

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
  String get lowestScoreWins => 'सबसे कम स्कोर जीतता है';

  @override
  String get highestScoreWins => 'सबसे अधिक स्कोर जीतता है';

  @override
  String get players => 'खिलाड़ी';

  @override
  String get add => 'जोड़ें';

  @override
  String get pleaseEnterName => 'कृपया नाम दर्ज करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get remove => 'हटाएं';

  @override
  String get game => 'खेल';

  @override
  String get editGame => 'गेम संपादित करें';

  @override
  String get editGameDialogTitle => 'गेम संपादित करें';

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
  String boardRoundButton(int round) {
    return 'राउंड $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · राउंड $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · राउंड $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'इसके बाद कुल: $total';
  }

  @override
  String keypadNext(String player) {
    return 'अगला\n$player';
  }

  @override
  String get keypadValidateRound => 'राउंड पक्का करें';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => 'चिह्न बदलें';

  @override
  String get keypadBackspace => 'एक अंक मिटाएँ';

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
  String get featureGameAnalysis => 'AI से खेल विश्लेषण';

  @override
  String get rateApp => 'CountScore को रेट करें';

  @override
  String get credits => 'श्रेय';

  @override
  String get appIconCredit => 'ऐप आइकन';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get search => 'खोजें';

  @override
  String get newPlayerName => 'नए खिलाड़ी का नाम';

  @override
  String get noPlayersFound => 'कोई खिलाड़ी नहीं मिला';

  @override
  String get close => 'बंद करें';

  @override
  String get playerEliminationCondition => 'खिलाड़ी के बाहर होने की शर्त';

  @override
  String get gameOverCondition => 'खेल समाप्ति की शर्त';

  @override
  String get none => 'कोई नहीं';

  @override
  String get overThreshold => 'सीमा से ऊपर';

  @override
  String get underThreshold => 'सीमा से नीचे';

  @override
  String get firstPlayerOver => 'पहला खिलाड़ी जो पहुँचे';

  @override
  String get firstPlayerUnder => 'पहला खिलाड़ी नीचे';

  @override
  String get lastPlayerOver => 'अंतिम खिलाड़ी ऊपर';

  @override
  String get lastPlayerUnder => 'अंतिम खिलाड़ी नीचे';

  @override
  String get threshold => 'सीमा';

  @override
  String get conditionType => 'शर्त का प्रकार';

  @override
  String get continuePlay => 'खेलते रहें';

  @override
  String gameEndWinner(String name) {
    return '$name की जीत';
  }

  @override
  String gameEndTie(String names) {
    return 'बराबरी: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count राउंड',
      one: '$count राउंड',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'सबसे कम स्कोर जीतता है';

  @override
  String get gameEndHighestWins => 'सबसे अधिक स्कोर जीतता है';

  @override
  String get gameEndAnalysis => 'विश्लेषण';

  @override
  String get gameEndResults => 'परिणाम';

  @override
  String get endGame => 'खेल समाप्त करें';

  @override
  String get reopenGame => 'खेल फिर से खोलें';

  @override
  String get gameFinished => 'समाप्त';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get gameReopened => 'गेम फिर से खोला गया';

  @override
  String get comment => 'टिप्पणी';

  @override
  String get enterComment => 'टिप्पणी दर्ज करें';

  @override
  String get analyzeGame => 'खेल का विश्लेषण करें';

  @override
  String get analysisTitle => 'खेल विश्लेषण';

  @override
  String get analysisStyle => 'विश्लेषण शैली';

  @override
  String get analysisStyleProfessor => 'प्रोफ़ेसर';

  @override
  String get analysisStyleCommentator => 'खेल कमेंटेटर';

  @override
  String get analysisStyleDocumentary => 'वन्यजीव वृत्तचित्र';

  @override
  String get analysisStyleNoir => 'जासूस';

  @override
  String get analysisStyleBard => 'चारण कवि';

  @override
  String get analysisStyleCoach => 'कोच';

  @override
  String get analysisStyleConsultant => 'सलाहकार';

  @override
  String get analysisStyleAstrologer => 'ज्योतिषी';

  @override
  String get analysisStyleRealityTv => 'रियलिटी शो';

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
  String get analysisErrorGroupBudget =>
      'आपके समूह ने इस महीने का विश्लेषण बजट खत्म कर दिया है। यह अगले महीने की शुरुआत में फिर से मिलेगा।';

  @override
  String get analysisStyleGroupDefault =>
      'कोई शैली नहीं चुनी गई: इस साझा खेल का विश्लेषण समूह की शैली और भाषा में होगा।';

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

  @override
  String get gameRulesTitle => 'खेल के नियम';

  @override
  String get gameRulesInApp => 'CountScore में';

  @override
  String get gameRulesSection => 'नियम';

  @override
  String get gameRulesNoElimination =>
      'खेल के दौरान कोई खिलाड़ी बाहर नहीं होता';

  @override
  String gameRulesEliminationOver(int threshold) {
    return '$threshold अंक से ऊपर जाने पर खिलाड़ी बाहर हो जाता है';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return '$threshold अंक से नीचे जाने पर खिलाड़ी बाहर हो जाता है';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'जैसे ही कोई खिलाड़ी $threshold अंक तक पहुँचता है, खेल समाप्त हो जाता है';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'जैसे ही कोई खिलाड़ी $threshold अंक से नीचे आता है, खेल समाप्त हो जाता है';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'जब एक को छोड़कर सभी खिलाड़ी $threshold अंक पार कर लेते हैं, तब खेल समाप्त होता है';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'जब एक को छोड़कर सभी खिलाड़ी $threshold अंक से नीचे आ जाते हैं, तब खेल समाप्त होता है';
  }

  @override
  String get gameRulesNoEnd =>
      'कोई स्वतः समाप्ति नहीं: खेल कब खत्म हो, यह आप तय करते हैं';

  @override
  String get gameRulesEmptyTitle => 'अभी कोई नियम नहीं';

  @override
  String get gameRulesEmptyHint =>
      'लिख लें कि आपकी मेज़ पर अंक कैसे गिने जाते हैं — फिर सबके पास एक ही संस्करण होगा।';

  @override
  String get gameRulesWrite => 'नियम लिखें';

  @override
  String get gameRulesEditTitle => 'नियम संपादित करें';

  @override
  String get gameRulesEditorHint => 'आपकी मेज़ के नियम। Markdown समर्थित है।';

  @override
  String get gameRulesFromGroup => 'आपके समूह के नियम';

  @override
  String get gameRulesRestoreDefault => 'मूल नियम पुनर्स्थापित करें';

  @override
  String get gameRulesSaved => 'नियम सहेजे गए';

  @override
  String get gameRulesRestored => 'मूल नियम पुनर्स्थापित किए गए';

  @override
  String get gameRulesDisclaimer =>
      'यह सारांश CountScore के लिए, आमतौर पर खेले जाने वाले नियमों के आधार पर लिखा गया है। खेलों के नाम उनके संबंधित स्वामियों के हैं और केवल वर्णनात्मक रूप से उपयोग किए गए हैं।';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'उनो';

  @override
  String get gameTypeNameUnoSortKey => 'उनो';

  @override
  String get gameTypeNameScrabble => 'स्क्रैबल';

  @override
  String get gameTypeNameScrabbleSortKey => 'स्क्रैबल';

  @override
  String get gameTypeNameOther => 'अन्य';

  @override
  String get gameTypeNameOtherSortKey => 'अन्य';

  @override
  String get gameTypeNameSkyjo => 'स्काईजो';

  @override
  String get gameTypeNameSkyjoSortKey => 'स्काईजो';

  @override
  String get gameTypeNamePresident => 'प्रेसिडेंट';

  @override
  String get gameTypeNamePresidentSortKey => 'प्रेसिडेंट';

  @override
  String get gameTypeNameBelote => 'बेलोत';

  @override
  String get gameTypeNameBeloteSortKey => 'बेलोत';

  @override
  String get gameTypeNameTarot => 'टैरो';

  @override
  String get gameTypeNameTarotSortKey => 'टैरो';

  @override
  String get gameTypeNameBridge => 'ब्रिज';

  @override
  String get gameTypeNameBridgeSortKey => 'ब्रिज';

  @override
  String get gameTypeNameRami => 'रमी';

  @override
  String get gameTypeNameRamiSortKey => 'रमी';

  @override
  String get gameTypeNameCoinche => 'कोएंश';

  @override
  String get gameTypeNameCoincheSortKey => 'कोएंश';

  @override
  String get gameTypeNameYahtzee => 'याहत्ज़ी';

  @override
  String get gameTypeNameYahtzeeSortKey => 'याहत्ज़ी';

  @override
  String get gameTypeNamePhase10 => 'फेज़ 10';

  @override
  String get gameTypeNamePhase10SortKey => 'फेज़ 10';

  @override
  String get gameTypeNameFlip7 => 'फ्लिप 7';

  @override
  String get gameTypeNameFlip7SortKey => 'फ्लिप 7';

  @override
  String get gameTypeNameMilleBornes => 'मिल बोर्न';

  @override
  String get gameTypeNameMilleBornesSortKey => 'मिल बोर्न';

  @override
  String get gameTypeNameRummikub => 'रमीक्यूब';

  @override
  String get gameTypeNameRummikubSortKey => 'रमीक्यूब';

  @override
  String get gameTypeNameSixNimmt => '6 निम्ट';

  @override
  String get gameTypeNameSixNimmtSortKey => '6 निम्ट';

  @override
  String get gameTypeNameQwirkle => 'क्विर्कल';

  @override
  String get gameTypeNameQwirkleSortKey => 'क्विर्कल';

  @override
  String get gameTypeNameFarkle => 'फार्कल';

  @override
  String get gameTypeNameFarkleSortKey => 'फार्कल';

  @override
  String get gameTypeNameCanasta => 'कनास्ता';

  @override
  String get gameTypeNameCanastaSortKey => 'कनास्ता';

  @override
  String get gameTypeNameWizard => 'विज़ार्ड';

  @override
  String get gameTypeNameWizardSortKey => 'विज़ार्ड';

  @override
  String get gameTypeNameTriomino => 'ट्रायोमिनो';

  @override
  String get gameTypeNameTriominoSortKey => 'ट्रायोमिनो';

  @override
  String get groupDeviceOwner => 'स्वामी';

  @override
  String get groupDeviceMakeOwner => 'स्वामी बनाएँ';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'समूह “$label” को सौंपें? यह डिवाइस फिर डिवाइस नहीं हटा पाएगा और आमंत्रण कोड नहीं बदल पाएगा।';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '“$label” अब समूह का स्वामी है।';
  }

  @override
  String get groupDevicesExplainMember =>
      'केवल समूह का स्वामी ही किसी डिवाइस को हटा सकता है या आमंत्रण कोड बदल सकता है।';

  @override
  String get groupErrorNotOwner => 'यह केवल समूह का स्वामी कर सकता है';

  @override
  String get whoStarts => 'कौन शुरू करेगा?';

  @override
  String get whoStartsAgain => 'फिर से चुनें';

  @override
  String get diceRoller => 'पासे फेंकें';

  @override
  String get diceCount => 'पासों की संख्या';

  @override
  String get diceRollAgain => 'फिर से फेंकें';

  @override
  String diceTotal(int total) {
    return 'कुल: $total';
  }

  @override
  String get resumeGame => 'जारी रखें';

  @override
  String get recentGames => 'हाल की';

  @override
  String get gameInProgress => 'जारी';

  @override
  String roundNumber(int number) {
    return 'राउंड $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name आगे · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name ने जीता';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: 'स्थान $rank',
      one: 'स्थान $rank',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'हर खिलाड़ी की एक पंक्ति';

  @override
  String get boardViewLanes => 'हर खिलाड़ी का एक कॉलम';

  @override
  String get boardSeatOrder => 'खेल का क्रम';

  @override
  String boardRoundShort(int number) {
    return 'रा$number';
  }

  @override
  String get boardPlayer => 'खिलाड़ी';

  @override
  String get boardTotal => 'कुल';

  @override
  String get boardLeader => 'सबसे आगे';

  @override
  String get groupSettingsTitle => 'टिप्पणियाँ और उपयोग';

  @override
  String get groupSettingsDescription =>
      'सर्वर समूह के खेलों के लिए जो टिप्पणियाँ लिखता है, उनकी शैली और भाषा। कोई भी सदस्य इन्हें बदल सकता है।';

  @override
  String get groupCommentStyle => 'टिप्पणी की शैली';

  @override
  String get groupCommentStyleNarrative => 'कथात्मक';

  @override
  String get groupCommentStyleHumorous => 'हास्यपूर्ण';

  @override
  String get groupCommentStyleAnalytical => 'विश्लेषणात्मक';

  @override
  String get groupCommentLanguage => 'टिप्पणी की भाषा';

  @override
  String get groupSettingsSaved => 'समूह की सेटिंग सहेजी गईं';

  @override
  String get groupUsageTitle => 'इस महीने LLM का उपयोग';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$budget में से $used खर्च';
  }

  @override
  String groupUsageResets(String date) {
    return '$date को रीसेट होगा';
  }

  @override
  String get statsBestWinRate => 'सबसे अच्छी जीत दर';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$games में $wins जीत',
      one: '$games में $wins जीत',
      zero: '$games में कोई जीत नहीं',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'खिलाड़ी';

  @override
  String get statsColumnGames => 'खेल';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खेल · अभी रैंक नहीं',
      one: '$count खेल · अभी रैंक नहीं',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count पूरे खेलों के बाद रैंक मिलती है। कार्ड देखने के लिए किसी खिलाड़ी पर टैप करें।',
      one:
          '$count पूरे खेल के बाद रैंक मिलती है। कार्ड देखने के लिए किसी खिलाड़ी पर टैप करें।',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'खेल',
      one: 'खेल',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'जीत',
      one: 'जीत',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'औसत स्थान';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्थान, पिछले $count खेल',
      one: 'स्थान, पिछला खेल',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'सुधार पर';

  @override
  String get statsTrendDeclining => 'गिरावट पर';

  @override
  String get statsTrendSteady => 'स्थिर';

  @override
  String statsRankOrdinal(String rank) {
    return '$rankवां';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'सिलसिला: $count जीत',
      one: 'सिलसिला: $count जीत',
      zero: 'कोई जीत का सिलसिला नहीं',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'रिकॉर्ड: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType में';
  }

  @override
  String get statsAverageTotal => 'औसत अंतिम योग';

  @override
  String get statsBestTotal => 'सबसे अच्छा अंतिम योग';

  @override
  String get statsMostBeaten => 'सबसे ज़्यादा हराया गया प्रतिद्वंद्वी';

  @override
  String get statsOpenPlayerCard => 'खिलाड़ी कार्ड खोलें';

  @override
  String get shareResult => 'परिणाम साझा करें';

  @override
  String get shareAnalysis => 'विश्लेषण साझा करें';

  @override
  String shareResultSubject(String gameName) {
    return 'परिणाम: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date का खेल';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points अंक',
      one: '$points अंक',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return '$appName से स्कोर रखे गए: $url';
  }

  @override
  String get shareFailed => 'साझा करना नहीं खुल सका';

  @override
  String get newGameNameLabel => 'नाम';

  @override
  String get newGameGameLabel => 'खेल';

  @override
  String newGameAllGames(int count) {
    return 'सभी खेल ($count)';
  }

  @override
  String get newGamePlayersLabel => 'खिलाड़ी · बैठने का क्रम';

  @override
  String get newGameDragToReorder => 'क्रम बदलने के लिए खींचें';

  @override
  String get newGameDealer => 'बाँटता है';

  @override
  String get newGameAddPlayer => 'खिलाड़ी जोड़ें';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'शुरू करें · $count खिलाड़ी',
      one: 'शुरू करें · 1 खिलाड़ी',
      zero: 'शुरू करें',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'कौन खेल रहा है?';

  @override
  String get whoIsPlayingSearchHint => 'नाम, या नया खिलाड़ी';

  @override
  String get whoIsPlayingFrequent => 'अक्सर आपके साथ खेलते हैं';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '“$gameName” वाले ही खिलाड़ी';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '“$name” बनाएँ';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खिलाड़ी जोड़ें',
      one: '1 खिलाड़ी जोड़ें',
      zero: 'हो गया',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'खेल $number';
  }

  @override
  String get pwaUpdateReady => 'CountScore का नया संस्करण तैयार है';

  @override
  String get pwaUpdateReload => 'फिर से लोड करें';

  @override
  String get thresholdIsRequired => 'इस शर्त के लिए एक सीमा आवश्यक है';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'सीमा $maxString से अधिक नहीं हो सकती';
  }

  @override
  String get deletionImpossible => 'विलोपन असंभव है';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count खेल इस प्रकार का उपयोग करते हैं: उन्हें हटाया नहीं जा सकता।',
      one: '1 खेल इस प्रकार का उपयोग करता है: इसे हटाया नहीं जा सकता।',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'क्या आप सच में गेम प्रकार \"$name\" को हटाना चाहते हैं?';
  }

  @override
  String get winDirectionChangeTitle => 'जीत की दिशा उलट दें?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'इस प्रकार के $count समाप्त खेल अपनी स्थिति उलट देंगे: उनके विजेता अंतिम हो जाएंगे।',
      one: 'इस प्रकार का 1 समाप्त खेल अपनी स्थिति उलट देगा: इसका विजेता अंतिम हो जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'गेम-ओवर शर्त चुने गए विजेता के विपरीत पुरस्कृत करती है। एक कस्टम नियम बिल्कुल यही चाह सकता है।';

  @override
  String get rulesOutOfDateTitle => 'नियमों को अपडेट करें?';

  @override
  String get rulesOutOfDateMessage =>
      'इस प्रकार के नियम अभी भी पुरानी स्थिति का वर्णन करते हैं।';

  @override
  String get later => 'बाद में';

  @override
  String get currentIcon => 'वर्तमान आइकन';

  @override
  String get currentColor => 'वर्तमान रंग';
}
