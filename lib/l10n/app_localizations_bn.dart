// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'হোম';

  @override
  String get playersListTitle => 'খেলোয়াড়ের তালিকা';

  @override
  String get gameTypesTitle => 'খেলার ধরন';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get aboutTitle => 'সম্পর্কে';

  @override
  String get newGame => 'নতুন খেলা';

  @override
  String get noGames => 'কোন খেলা নেই';

  @override
  String get noGamesOfThisType => 'এই ধরনের কোন খেলা নেই';

  @override
  String get createFirstGame => 'আপনার প্রথম খেলা তৈরি করুন';

  @override
  String get newWithSamePlayers => 'একই খেলোয়াড়দের সাথে নতুন';

  @override
  String get playAgain => 'আবার খেলুন';

  @override
  String get rename => 'পুনর্নামকরণ করুন';

  @override
  String get delete => 'মুছুন';

  @override
  String get confirmDeletion => 'মুছে ফেলার নিশ্চয়তা';

  @override
  String confirmDeleteGame(String name) {
    return 'আপনি সত্যিই \"$name\" খেলাটি মুছতে চান?';
  }

  @override
  String get cancel => 'বাতিল করুন';

  @override
  String get renameGame => 'খেলার নাম পরিবর্তন করুন';

  @override
  String get gameName => 'খেলার নাম';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get allGames => 'সকল খেলা';

  @override
  String get filterGames => 'খেলা ফিল্টার করুন';

  @override
  String get applyFilter => 'প্রয়োগ করুন';

  @override
  String get resetFilter => 'রিসেট করুন';

  @override
  String get selectGameType => 'একটি খেলার ধরন নির্বাচন করুন';

  @override
  String get gameType => 'খেলার ধরন';

  @override
  String get loadingGameTypes => 'খেলার ধরন লোড হচ্ছে...';

  @override
  String get lowestScoreWins => 'সর্বনিম্ন স্কোর জয়ী হয়';

  @override
  String get highestScoreWins => 'সর্বোচ্চ স্কোর জয়ী হয়';

  @override
  String get players => 'খেলোয়াড়';

  @override
  String get add => 'যোগ করুন';

  @override
  String get pleaseEnterName => 'অনুগ্রহ করে একটি নাম লিখুন';

  @override
  String get clear => 'পরিষ্কার করুন';

  @override
  String get remove => 'সরান';

  @override
  String get game => 'খেলা';

  @override
  String get editGame => 'খেলা সম্পাদনা করুন';

  @override
  String get editGameDialogTitle => 'খেলা সম্পাদনা করুন';

  @override
  String get removePlayer => 'খেলোয়াড় সরান';

  @override
  String get addPlayerToGame => 'খেলোয়াড় যোগ করুন';

  @override
  String get warningRemovePlayer =>
      'সতর্কতা! এই খেলোয়াড়কে সরিয়ে দিলে এই খেলা থেকে তাদের সমস্ত স্কোর মুছে যাবে। এই কাজটি অপরিবর্তনীয়।';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'আপনি সত্যিই এই খেলা থেকে $playerName কে সরাতে চান?';
  }

  @override
  String get playerRemoved => 'খেলোয়াড় খেলা থেকে সরানো হয়েছে';

  @override
  String get deleteLastRound => 'শেষ রাউন্ড মুছুন';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get confirmDeleteLastRound => 'শেষ রাউন্ড মুছে ফেলবেন?';

  @override
  String get noPlayersInGame => 'এই খেলায় কোন খেলোয়াড় নেই';

  @override
  String get round => 'রাউন্ড';

  @override
  String boardRoundButton(int round) {
    return 'রাউন্ড $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · রাউন্ড $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · রাউন্ড $round · $position/$count';
  }

  @override
  String keypadTotalAfter(String total) {
    return 'মোট পরে: $total';
  }

  @override
  String keypadNext(String player) {
    return 'পরবর্তী\n$player';
  }

  @override
  String get keypadValidateRound => 'রাউন্ড যাচাই করুন';

  @override
  String get keypadToggleSign => 'চিহ্ন পরিবর্তন করুন';

  @override
  String get keypadBackspace => 'একটি ডিজিট মুছুন';

  @override
  String get keypadShortcutTitle => 'কীপ্যাড শর্টকাট';

  @override
  String get keypadShortcutKind => 'কী ধরন';

  @override
  String get keypadShortcutKindValue => 'একটি মূল্য লিখুন';

  @override
  String get keypadShortcutKindMultiply => 'স্কোর গুণ করুন (শুধুমাত্র ধনাত্মক)';

  @override
  String get keypadShortcutKindAdd => 'স্কোরে যোগ করুন';

  @override
  String get keypadShortcutAmount => 'সংখ্যা';

  @override
  String get keypadShortcutLabel => 'কী লেবেল (ঐচ্ছিক)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return '$min এবং $max এর মধ্যে একটি পূর্ণ সংখ্যা, 0 ছাড়া অন্য কিছু';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return '$min এবং $max এর মধ্যে একটি পূর্ণ সংখ্যা';
  }

  @override
  String get appearance => 'চেহারা';

  @override
  String get light => 'হালকা';

  @override
  String get dark => 'গাঢ়';

  @override
  String get system => 'সিস্টেম';

  @override
  String get screen => 'পর্দা';

  @override
  String get keepScreenAwake => 'পর্দা জাগিয়ে রাখুন';

  @override
  String get keepScreenAwakeDescription =>
      'খেলার সময় স্ক্রিনকে ঘুমাতে দেয় না';

  @override
  String get backup => 'ব্যাকআপ';

  @override
  String get exportDatabase => 'ডাটাবেস রপ্তানি করুন';

  @override
  String get exportDatabaseDescription =>
      'আপনার সমস্ত খেলা একটি ফাইলে সংরক্ষণ করুন';

  @override
  String get databaseExportedTo => 'ডাটাবেস রপ্তানি করা হয়েছে:';

  @override
  String get errorDuringExport => 'রপ্তানির সময় ত্রুটি:';

  @override
  String get importDatabase => 'ডাটাবেস আমদানি করুন';

  @override
  String get importDatabaseDescription =>
      'একটি ব্যাকআপ ফাইল থেকে আপনার খেলা পুনরুদ্ধার করুন';

  @override
  String get confirmation => 'নিশ্চিতকরণ';

  @override
  String get importWarning =>
      'আমদানি করা হলে আপনার সমস্ত বর্তমান ডেটা প্রতিস্থাপিত হবে। আমদানির আগে একটি স্বয়ংক্রিয় ব্যাকআপ তৈরি করা হবে।\n\nআপনি চালিয়ে যেতে চান?';

  @override
  String get import => 'আমদানি করুন';

  @override
  String get databaseImportedSuccessfully =>
      'ডাটাবেস সফলভাবে আমদানি করা হয়েছে';

  @override
  String get importSuccessful => 'আমদানি সফল';

  @override
  String get importSuccessMessage =>
      'ডাটাবেস সফলভাবে আমদানি করা হয়েছে।\n\nএখন অ্যাপ্লিকেশনটি বন্ধ হবে। নতুন ডেটা দেখতে অনুগ্রহ করে এটি আবার খুলুন।';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get errorDuringImport => 'আমদানির সময় ত্রুটি:';

  @override
  String get noPlayers => 'কোন খেলোয়াড় নেই';

  @override
  String get playersAppearMessage =>
      'একবার আপনি খেলা তৈরি করার পরে খেলোয়াড়রা এখানে উপস্থিত হবে';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count খেলা',
      one: '1 খেলা',
      zero: '0 খেলা',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count জয়',
      one: '1 জয়',
      zero: '0 জয়',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'রঙ পরিবর্তন করুন';

  @override
  String get renamePlayer => 'খেলোয়াড়ের নাম পরিবর্তন করুন';

  @override
  String get newName => 'নতুন নাম';

  @override
  String playerRenamedTo(String name) {
    return 'খেলোয়াড়ের নাম \"$name\" এ পরিবর্তিত হয়েছে';
  }

  @override
  String get deletePlayer => 'খেলোয়াড় মুছুন';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'আপনি সত্যিই \"$name\" মুছতে চান?\n\nএই খেলোয়াড় $count খেলা থেকে সরানো হবে।';
  }

  @override
  String playerDeleted(String name) {
    return 'খেলোয়াড় \"$name\" মুছা হয়েছে';
  }

  @override
  String get chooseColor => 'একটি রঙ নির্বাচন করুন';

  @override
  String get noGameTypes => 'কোন খেলার ধরন নেই';

  @override
  String get edit => 'সম্পাদনা করুন';

  @override
  String get newType => 'নতুন ধরন';

  @override
  String get editType => 'ধরন সম্পাদনা করুন';

  @override
  String get newGameType => 'নতুন খেলার ধরন';

  @override
  String get gameTypeName => 'খেলার ধরনের নাম';

  @override
  String get icon => 'আইকন:';

  @override
  String get color => 'রঙ:';

  @override
  String get chooseIcon => 'একটি আইকন নির্বাচন করুন';

  @override
  String get nameIsRequired => 'নাম প্রয়োজন';

  @override
  String get create => 'তৈরি করুন';

  @override
  String get ranking => 'র‍্যাঙ্কিং';

  @override
  String get noCurrentGame => 'বর্তমানে কোন খেলা নেই';

  @override
  String get noScoresRecorded => 'কোন স্কোর রেকর্ড করা হয়নি';

  @override
  String get playerStatistics => 'খেলোয়াড়ের পরিসংখ্যান';

  @override
  String get noStatisticsAvailable => 'কোন পরিসংখ্যান উপলব্ধ নেই';

  @override
  String get gamesPlayed => 'খেলা খেলা হয়েছে';

  @override
  String get wins => 'জয়';

  @override
  String get winRate => 'জয়ের হার';

  @override
  String get byGameType => 'খেলার ধরন অনুযায়ী';

  @override
  String get rate => 'হার';

  @override
  String version(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get appDescription =>
      'Vincent Moreau দ্বারা আপনার খেলার সেশনের জন্য স্কোর ব্যবস্থাপনা অ্যাপ্লিকেশন';

  @override
  String get features => 'বৈশিষ্ট্য';

  @override
  String get featureDifferentGameTypes => 'বিভিন্ন খেলার ধরন';

  @override
  String get featurePlayerManagement => 'খেলোয়াড় ব্যবস্থাপনা';

  @override
  String get featureDetailedStatistics => 'বিস্তারিত পরিসংখ্যান';

  @override
  String get featureCustomization => 'কাস্টমাইজেশন';

  @override
  String get featureDarkLightTheme => 'গাঢ় / হালকা থিম';

  @override
  String get featureGroupSharing => 'গ্রুপ শেয়ারিং';

  @override
  String get featureGameAnalysis => 'AI গেম বিশ্লেষণ';

  @override
  String get rateApp => 'CountScore রেট করুন';

  @override
  String get search => 'খুঁজুন';

  @override
  String get newPlayerName => 'নতুন খেলোয়াড়ের নাম';

  @override
  String get noPlayersFound => 'কোন খেলোয়াড় পাওয়া যায়নি';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get playerEliminationCondition => 'খেলোয়াড় নির্মূলকরণের শর্ত';

  @override
  String get gameOverCondition => 'গেম শেষ হওয়ার শর্ত';

  @override
  String get none => 'কোনটিই নয়';

  @override
  String get overThreshold => 'সীমা অতিক্রম করে';

  @override
  String get underThreshold => 'সীমার নিচে';

  @override
  String get firstPlayerOver => 'প্রথম খেলোয়াড় পৌঁছায়';

  @override
  String get firstPlayerUnder => 'প্রথম খেলোয়াড় নিচে';

  @override
  String get lastPlayerOver => 'শেষ খেলোয়াড় দাঁড়িয়ে আছে (অন্যরা উপরে)';

  @override
  String get lastPlayerUnder => 'শেষ খেলোয়াড় দাঁড়িয়ে আছে (অন্যরা নিচে)';

  @override
  String get threshold => 'সীমা';

  @override
  String get conditionType => 'শর্তের ধরন';

  @override
  String get continuePlay => 'খেলা চালিয়ে যান';

  @override
  String gameEndWinner(String name) {
    return '$name জয়ী হয়';
  }

  @override
  String gameEndTie(String names) {
    return 'টাই: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count রাউন্ড',
      one: '$count রাউন্ড',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'সর্বনিম্ন স্কোর জয়ী হয়';

  @override
  String get gameEndHighestWins => 'সর্বোচ্চ স্কোর জয়ী হয়';

  @override
  String get gameEndAnalysis => 'বিশ্লেষণ';

  @override
  String get gameEndResults => 'ফলাফল';

  @override
  String get rankingEliminationNote =>
      'নির্মূলকরণের ক্রম অনুসারে র‍্যাঙ্ক করা হয়েছে: যে ব্যক্তি পরে বেরিয়ে আসে সে র‍্যাঙ্ক করে, মোট যাই হোক না কেন।';

  @override
  String get endGame => 'খেলা শেষ করুন';

  @override
  String get reopenGame => 'খেলা আবার খুলুন';

  @override
  String get gameFinished => 'শেষ';

  @override
  String get undo => 'পূর্বাবস্থায় ফিরিয়ে আনুন';

  @override
  String get gameReopened => 'খেলা আবার খোলা হয়েছে';

  @override
  String get comment => 'মন্তব্য';

  @override
  String get enterComment => 'একটি মন্তব্য লিখুন';

  @override
  String get analyzeGame => 'খেলা বিশ্লেষণ করুন';

  @override
  String get analysisTitle => 'খেলা বিশ্লেষণ';

  @override
  String get analysisStyle => 'বিশ্লেষণের শৈলী';

  @override
  String get analysisStyleProfessor => 'অধ্যাপক';

  @override
  String get analysisStyleCommentator => 'ক্রীড়া ভাষ্যকার';

  @override
  String get analysisStyleDocumentary => 'বন্যপ্রাণী ডকুমেন্টারি';

  @override
  String get analysisStyleNoir => 'গোয়েন্দা';

  @override
  String get analysisStyleBard => 'বার্ড';

  @override
  String get analysisStyleCoach => 'কোচ';

  @override
  String get analysisStyleConsultant => 'পরামর্শদাতা';

  @override
  String get analysisStyleAstrologer => 'জ্যোতিষী';

  @override
  String get analysisStyleRealityTv => 'রিয়েলিটি শো';

  @override
  String get generatingAnalysis => 'বিশ্লেষণ তৈরি হচ্ছে…';

  @override
  String get generateAnalysis => 'বিশ্লেষণ তৈরি করুন';

  @override
  String get regenerateAnalysis => 'বিশ্লেষণ পুনরায় তৈরি করুন';

  @override
  String get deleteAnalysis => 'বিশ্লেষণ মুছুন';

  @override
  String get confirmRegenerateAnalysis =>
      'পুনরায় তৈরি করবেন? বর্তমান বিশ্লেষণ প্রতিস্থাপিত হবে।';

  @override
  String get confirmDeleteAnalysis => 'এই খেলার বিশ্লেষণ মুছে ফেলবেন?';

  @override
  String get analysisError => 'বিশ্লেষণ তৈরিতে ব্যর্থ';

  @override
  String get analysisErrorUnavailable =>
      'বিশ্লেষণ সার্ভার সাময়িকভাবে অনুপলব্ধ। পরে আবার চেষ্টা করুন।';

  @override
  String get analysisErrorGroupBudget =>
      'আপনার গ্রুপ এই মাসের জন্য তার বিশ্লেষণ বাজেট ব্যয় করেছে। এটি পরের মাসের শুরুতে নবায়িত হয়।';

  @override
  String get analysisStyleGroupDefault =>
      'কোন শৈলী নির্বাচিত নয়: এই ভাগ করা খেলা গ্রুপের শৈলী এবং ভাষায় বিশ্লেষণ করা হয়।';

  @override
  String analysisErrorStatus(int status) {
    return 'বিশ্লেষণ তৈরিতে ব্যর্থ (HTTP $status)';
  }

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String analysisGeneratedAt(String date) {
    return '$date এ তৈরি';
  }

  @override
  String get serverSection => 'সার্ভার';

  @override
  String get backendUrlLabel => 'সার্ভার ইউআরএল';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'সংযুক্ত বৈশিষ্ট্যগুলির জন্য একটি CountScore সার্ভার প্রয়োজন। backend/ ফোল্ডার থেকে একটি ইনস্টল করুন এবং এখানে এর ঠিকানা লিখুন। কোন সার্ভার ছাড়াই, কোন ডেটা কখনও এই ডিভাইস ছেড়ে যায় না।';

  @override
  String get backendNotConfigured => 'কোন সার্ভার কনফিগার করা হয়নি';

  @override
  String get backendUrlInvalid =>
      'অবৈধ ঠিকানা। একটি সম্পূর্ণ ইউআরএল লিখুন, উদাহরণস্বরূপ https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// শুধুমাত্র স্থানীয় নেটওয়ার্কে গৃহীত হয়। একটি পাবলিক সার্ভারের জন্য https:// ব্যবহার করুন।';

  @override
  String get testConnection => 'সংযোগ পরীক্ষা করুন';

  @override
  String get connectionOk => 'সার্ভার প্রতিক্রিয়া জানাচ্ছে';

  @override
  String get connectionFailed => 'সার্ভার প্রতিক্রিয়া জানাচ্ছে না';

  @override
  String get serverUrlSaved => 'সার্ভার সংরক্ষিত';

  @override
  String get analysisRequiresBackend =>
      'এই বিশ্লেষণের জন্য একটি সার্ভার প্রয়োজন। সেটিংসে একটি কনফিগার করুন।';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get serverUrlCleared => 'সার্ভার সাফ করা হয়েছে';

  @override
  String get groupSection => 'গ্রুপ';

  @override
  String get groupDescription =>
      'আপনার গ্রুপের অন্যান্য ডিভাইসের সাথে খেলা শেয়ার করুন। ভাগ করা খেলা, তাদের খেলোয়াড়, স্কোর, মন্তব্য এবং বিশ্লেষণ আপনার সার্ভারে পাঠানো হয়; অন্যান্য খেলা এই ডিভাইসে থাকে।';

  @override
  String get groupNeedsServer => 'আগে উপরে একটি সার্ভার সেট আপ করুন।';

  @override
  String get groupCreate => 'একটি গ্রুপ তৈরি করুন';

  @override
  String get groupJoin => 'একটি গ্রুপে যোগ দিন';

  @override
  String get groupNameLabel => 'গ্রুপের নাম';

  @override
  String get groupNicknameLabel => 'আপনার ডাকনাম';

  @override
  String get groupNicknameHint => 'গ্রুপে অন্যরা এটি দেখবে';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'আপনার ডাকনাম: $nickname';
  }

  @override
  String get groupNicknameEdit => 'আপনার ডাকনাম পরিবর্তন করুন';

  @override
  String get shareTokenLabel => 'আমন্ত্রণ কোড';

  @override
  String get shareTokenHint =>
      'একজন গ্রুপ সদস্য যে কোডটি পাঠিয়েছে তা পেস্ট করুন';

  @override
  String groupCurrent(String name) {
    return 'গ্রুপ: $name';
  }

  @override
  String get shareTokenExplain =>
      'এই কোডটি সেই ডিভাইসগুলিতে পাঠান যা গ্রুপে যোগদান করা উচিত। যে কেউ যার কাছে এটি আছে তারা যোগদান করতে পারে।';

  @override
  String get shareTokenCopy => 'কোড কপি করুন';

  @override
  String get shareTokenCopied => 'কোড কপি করা হয়েছে';

  @override
  String get shareTokenRotate => 'নতুন কোড';

  @override
  String get shareTokenRotateConfirm =>
      'পুরানো কোডটি আর কাউকে যোগদান করতে দেবে না। গ্রুপে ইতিমধ্যে থাকা ডিভাইসগুলি প্রভাবিত হয় না।';

  @override
  String get groupLeave => 'গ্রুপ ছেড়ে যান';

  @override
  String get groupLeaveConfirm =>
      'এই ডিভাইস গ্রুপ ছেড়ে যায়। ভাগ করা খেলা এই ডিভাইসে থাকে তবে আর সিঙ্ক করবে না।';

  @override
  String get groupLeft => 'গ্রুপ ছেড়ে গেছে';

  @override
  String get groupJoined => 'গ্রুপে যোগ দিয়েছে';

  @override
  String get clearServerLeavesGroup =>
      'সার্ভার সাফ করা গ্রুপ ছেড়ে যায়। ভাগ করা খেলা এই ডিভাইসে থাকে।';

  @override
  String get syncNow => 'এখনই সিঙ্ক করুন';

  @override
  String syncStatusIdle(String time) {
    return '$time এ সিঙ্ক করা হয়েছে';
  }

  @override
  String get syncStatusSyncing => 'সিঙ্ক করছি…';

  @override
  String get syncStatusOffline =>
      'সার্ভার অপৌঁছানো — পরিবর্তনগুলি পরে পাঠানো হবে';

  @override
  String get syncStatusUnauthorized =>
      'সার্ভার আর এই ডিভাইসটি গ্রহণ করে না। গ্রুপ ছেড়ে যান, তারপর আবার যোগদান করুন।';

  @override
  String get syncStatusError => 'সিঙ্ক করার সময় সার্ভার ত্রুটি';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count পরিবর্তন অপেক্ষা করছে',
      one: '1 অপেক্ষা করছে পরিবর্তন',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'সার্ভার দ্বারা $count পরিবর্তন প্রত্যাখ্যান করা হয়েছে',
      one: 'সার্ভার দ্বারা 1 পরিবর্তন প্রত্যাখ্যান করা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'অজানা বা প্রতিস্থাপিত আমন্ত্রণ কোড';

  @override
  String get groupErrorRateLimited =>
      'অনেক প্রচেষ্টা। একটি মিনিটে আবার চেষ্টা করুন।';

  @override
  String get groupErrorUnreachable => 'সার্ভার অপৌঁছানো';

  @override
  String get groupErrorServer => 'সার্ভার ত্রুটি';

  @override
  String get shareWithGroup => 'গ্রুপের সাথে শেয়ার করুন';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name এ ডিভাইসগুলি এই খেলাটি দেখতে এবং সম্পাদনা করতে পারবে';
  }

  @override
  String shareGameConfirm(String name) {
    return 'খেলাটি, এর খেলোয়াড়, স্কোর এবং মন্তব্য $name এ পাঠানো হবে। শেয়ারিং পূর্বাবস্থায় ফিরিয়ে আনা যায় না।';
  }

  @override
  String get gameSharedDone => 'গ্রুপের সাথে খেলা শেয়ার করা হয়েছে';

  @override
  String get gameSharedBadge => 'ভাগ করা খেলা';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'এই নামগুলি শেয়ার করা যায় না: $names। অক্ষর, সংখ্যা, স্পেস, হাইফেন, অ্যাপোস্ট্রফ বা পিরিয়ড ব্যবহার করুন (সর্বাধিক 32 অক্ষর)।';
  }

  @override
  String roundRenumbered(int number) {
    return 'সেই রাউন্ডটি ইতিমধ্যে অন্য ডিভাইসে প্রবেশ করা হয়েছিল, তাই এটি রাউন্ড $number হয়ে গেছে।';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" অন্য ডিভাইসে মুছা হয়েছে';
  }

  @override
  String get groupDevices => 'ডিভাইস';

  @override
  String get groupDevicesExplain =>
      'হারানো বা বিক্রি করা ফোন এখানে গ্রুপ থেকে সরানো যেতে পারে।';

  @override
  String get groupDeviceThisOne => 'এই ডিভাইস';

  @override
  String groupDeviceLastSeen(String date) {
    return 'শেষ দেখা $date';
  }

  @override
  String get groupDeviceRevoke => 'সরান';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'গ্রুপ থেকে \"$label\" সরিয়ে দিন? এটি আর সিঙ্ক করবে না। আমন্ত্রণ কোডটিও পরিবর্তিত হয়: সদস্যরা তাদের অ্যাক্সেস রাখে, তবে আপনাকে নতুন কোডটি শেয়ার করতে হবে যাকে আমন্ত্রণ জানাতে হবে।';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" সরানো হয়েছে। আমন্ত্রণ কোডটি পরিবর্তিত হয়েছে।';
  }

  @override
  String get reportCommentary => 'এই মন্তব্য রিপোর্ট করুন';

  @override
  String get reportCommentarySubject => 'CountScore — AI মন্তব্য রিপোর্ট';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'এই AI-উৎপাদিত মন্তব্যটির সাথে কী ভুল?\n\n\n---\nসংদর্ভ: $reference\nমন্তব্য:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'কোন ইমেল অ্যাপ পাওয়া যায়নি। এই মন্তব্য রিপোর্ট করতে $email এ লিখুন।';
  }

  @override
  String get gameRulesTitle => 'খেলার নিয়ম';

  @override
  String get gameRulesInApp => 'CountScore এ';

  @override
  String get gameRulesSection => 'নিয়ম';

  @override
  String get gameRulesNoElimination => 'খেলার সময় কোন নির্মূলন নেই';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'একটি খেলোয়াড় $threshold পয়েন্টের উপরে নির্মূল হয়';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'একটি খেলোয়াড় $threshold পয়েন্টের নিচে নির্মূল হয়';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'একটি খেলোয়াড় $threshold পয়েন্টে পৌঁছানোর সাথে সাথে খেলা শেষ হয়';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'একটি খেলোয়াড় $threshold পয়েন্টের নিচে নেমে যাওয়ার সাথে সাথে খেলা শেষ হয়';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'খেলা শেষ হয় যখন একজন ছাড়া প্রতিটি খেলোয়াড় $threshold পয়েন্টের উপরে থাকে';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'খেলা শেষ হয় যখন একজন ছাড়া প্রতিটি খেলোয়াড় $threshold পয়েন্টের নিচে থাকে';
  }

  @override
  String get gameRulesNoEnd =>
      'কোন স্বয়ংক্রিয় সমাপ্তি নেই: আপনি সিদ্ধান্ত নেন যখন খেলা শেষ হয়';

  @override
  String get gameRulesEmptyTitle => 'এখনও কোন নিয়ম নেই';

  @override
  String get gameRulesEmptyHint =>
      'আপনার টেবিল কীভাবে পয়েন্টগুলি গণনা করে তা লিখুন — সবাই একই সংস্করণ পাবে।';

  @override
  String get gameRulesWrite => 'নিয়ম লিখুন';

  @override
  String get gameRulesEditTitle => 'নিয়ম সম্পাদনা করুন';

  @override
  String get gameRulesEditorHint => 'আপনার টেবিলের নিয়ম। মার্কডাউন সমর্থিত।';

  @override
  String get gameRulesFromGroup => 'আপনার গ্রুপের নিয়ম';

  @override
  String get gameRulesRestoreDefault => 'মূল নিয়মগুলি পুনরুদ্ধার করুন';

  @override
  String get gameRulesSaved => 'নিয়ম সংরক্ষিত';

  @override
  String get gameRulesRestored => 'মূল নিয়মগুলি পুনরুদ্ধার করা হয়েছে';

  @override
  String get gameRulesDisclaimer =>
      'সেগুলি সাধারণত কীভাবে খেলা হয় তার নিয়মগুলি থেকে CountScore এর জন্য লিখা সারসংক্ষেপ। খেলার নামগুলি তাদের নিজ নিজ মালিকদের অন্তর্গত এবং শুধুমাত্র বর্ণনামূলকভাবে ব্যবহৃত হয়।';

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
  String get gameTypeNameOther => 'অন্যান্য';

  @override
  String get gameTypeNameOtherSortKey => 'অন্যান্য';

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
  String get groupDeviceOwner => 'মালিক';

  @override
  String get groupDeviceMakeOwner => 'মালিক করুন';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'গ্রুপটি \"$label\" এ হস্তান্তর করবেন? এই ডিভাইসটি আর ডিভাইস সরাতে বা আমন্ত্রণ কোড পরিবর্তন করতে পারবে না।';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" এখন গ্রুপের মালিক।';
  }

  @override
  String get groupDevicesExplainMember =>
      'শুধুমাত্র গ্রুপের মালিক একটি ডিভাইস সরাতে বা আমন্ত্রণ কোড পরিবর্তন করতে পারে।';

  @override
  String get groupErrorNotOwner => 'শুধুমাত্র গ্রুপের মালিক এটি করতে পারে';

  @override
  String get whoStarts => 'কে শুরু করে?';

  @override
  String get whoStartsAgain => 'আবার ড্র করুন';

  @override
  String get diceRoller => 'ডাইস রোল করুন';

  @override
  String get diceCount => 'ডাইসের সংখ্যা';

  @override
  String get diceRollAgain => 'আবার রোল করুন';

  @override
  String diceTotal(int total) {
    return 'মোট: $total';
  }

  @override
  String get resumeGame => 'পুনরায় শুরু করুন';

  @override
  String get recentGames => 'সাম্প্রতিক';

  @override
  String get gameInProgress => 'চলছে';

  @override
  String roundNumber(int number) {
    return 'রাউন্ড $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name নেতৃত্ব দেয় · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name দ্বারা জিতেছে';
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
  String get boardViewRows => 'প্রতি খেলোয়াড় এক সারি';

  @override
  String get boardViewLanes => 'প্রতি খেলোয়াড় এক স্তম্ভ';

  @override
  String get boardSeatOrder => 'আসন ক্রম';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'খেলোয়াড়';

  @override
  String get boardTotal => 'মোট';

  @override
  String get boardLeader => 'নেতৃত্ব দিচ্ছে';

  @override
  String get groupSettingsTitle => 'মন্তব্য এবং ব্যবহার';

  @override
  String get groupSettingsDescription =>
      'সার্ভার গ্রুপের খেলার জন্য যে মন্তব্য লেখে তার শৈলী এবং ভাষা। যেকোনো সদস্য এটি পরিবর্তন করতে পারে।';

  @override
  String get groupCommentStyle => 'মন্তব্য শৈলী';

  @override
  String get groupCommentStyleNarrative => 'আখ্যান';

  @override
  String get groupCommentStyleHumorous => 'হাস্যরস';

  @override
  String get groupCommentStyleAnalytical => 'বিশ্লেষণাত্মক';

  @override
  String get groupCommentLanguage => 'মন্তব্যের ভাষা';

  @override
  String get groupSettingsSaved => 'গ্রুপ সেটিংস সংরক্ষিত';

  @override
  String get groupUsageTitle => 'এই মাসে LLM ব্যবহার';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$budget এর $used ব্যয় করা হয়েছে';
  }

  @override
  String groupUsageResets(String date) {
    return '$date এ রিসেট হয়';
  }

  @override
  String get statsBestWinRate => 'সর্বোত্তম জয়ের হার';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins $games এর মধ্যে জয়',
      one: '$wins $games এর মধ্যে জয়',
      zero: 'খেলার বাইরে কোন জয় নেই $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'খেলোয়াড়';

  @override
  String get statsColumnGames => 'খেলা';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count খেলা · এখনও র‍্যাঙ্ক করা হয়নি',
      one: '$count খেলা · এখনও র‍্যাঙ্ক করা হয়নি',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count সমাপ্ত খেলা থেকে র‍্যাঙ্ক করা হয়েছে। তাদের কার্ড দেখতে একজন খেলোয়াড়কে ট্যাপ করুন।',
      one:
          '$count সমাপ্ত খেলা থেকে র‍্যাঙ্ক করা হয়েছে। তাদের কার্ড দেখতে একজন খেলোয়াড়কে ট্যাপ করুন।',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'খেলা',
      one: 'খেলা',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'জয়',
      one: 'জয়',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'গড় স্থান';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'স্থান, শেষ $count খেলা',
      one: 'স্থান, শেষ খেলা',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'উন্নতি হচ্ছে';

  @override
  String get statsTrendDeclining => 'পিছিয়ে যাচ্ছে';

  @override
  String get statsTrendSteady => 'স্থির';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1ম',
      '2': '2য়',
      '3': '3য়',
      '4': '4র্থ',
      '6': '6ষ্ঠ',
      'other': '$rankম',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ধারা: $count জয়',
      one: 'ধারা: $count জয়',
      zero: 'কোন জয়ের ধারা নেই',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'সেরা: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType এ';
  }

  @override
  String get statsAverageTotal => 'গড় চূড়ান্ত মোট';

  @override
  String get statsBestTotal => 'সর্বোত্তম চূড়ান্ত মোট';

  @override
  String get statsMostBeaten => 'সবচেয়ে বেশি হারানো প্রতিদ্বন্দ্বী';

  @override
  String get statsOpenPlayerCard => 'খেলোয়াড়ের কার্ড খুলুন';

  @override
  String get shareResult => 'ফলাফল শেয়ার করুন';

  @override
  String get shareAnalysis => 'বিশ্লেষণ শেয়ার করুন';

  @override
  String shareResultSubject(String gameName) {
    return 'ফলাফল: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date এর খেলা';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points পয়েন্ট',
      one: '$points পয়েন্ট',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'স্কোর রাখা হয়েছে $appName এর সাথে: $url';
  }

  @override
  String get shareFailed => 'শেয়ারিং খোলা যায়নি';

  @override
  String get newGameNameLabel => 'নাম';

  @override
  String get newGameGameLabel => 'খেলা';

  @override
  String newGameAllGames(int count) {
    return 'সকল খেলা ($count)';
  }

  @override
  String get newGamePlayersLabel => 'খেলোয়াড় · আসন ক্রম';

  @override
  String get newGameDragToReorder => 'পুনরায় অর্ডার করতে টেনে আনুন';

  @override
  String get newGameDealer => 'ডিল করে';

  @override
  String get newGameAddPlayer => 'একজন খেলোয়াড় যোগ করুন';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'শুরু করুন · $count খেলোয়াড়',
      one: 'শুরু করুন · 1 খেলোয়াড়',
      zero: 'শুরু করুন',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'কে খেলছে?';

  @override
  String get whoIsPlayingSearchHint => 'নাম, বা একটি নতুন খেলোয়াড়';

  @override
  String get whoIsPlayingFrequent => 'প্রায়ই আপনার সাথে খেলে';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '\"$gameName\" এর মতো একই খেলোয়াড়';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '\"$name\" তৈরি করুন';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count খেলোয়াড় যোগ করুন',
      one: '1 খেলোয়াড় যোগ করুন',
      zero: 'সম্পূর্ণ',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'খেলা $number';
  }

  @override
  String get pwaUpdateReady => 'CountScore এর একটি নতুন সংস্করণ প্রস্তুত';

  @override
  String get pwaUpdateReload => 'পুনরায় লোড করুন';

  @override
  String get thresholdIsRequired => 'এই শর্তের জন্য একটি সীমা প্রয়োজন';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'সীমা $maxString এর উপরে হতে পারে না';
  }

  @override
  String get deletionImpossible => 'মুছে ফেলা অসম্ভব';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count খেলা এই ধরন ব্যবহার করে: এটি মুছে ফেলা যায় না।',
      one: '1 খেলা এই ধরন ব্যবহার করে: এটি মুছে ফেলা যায় না।',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'আপনি সত্যিই খেলার ধরন \"$name\" মুছতে চান?';
  }

  @override
  String get winDirectionChangeTitle => 'জয়ীকে বিপরীত করবেন?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'এই ধরনের $count সমাপ্ত খেলার র‍্যাঙ্কিং বিপরীত হবে: তাদের বিজয়ী শেষ হয়ে যায়।',
      one: 'এই ধরনের 1 সমাপ্ত খেলার র‍্যাঙ্কিং বিপরীত হবে: এর বিজয়ী শেষ হয়ে যায়।',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'খেলা শেষের শর্ত নির্বাচিত বিজয়ীর বিপরীতকে পুরস্কৃত করে। একটি বাড়ির নিয়ম সম্ভবত ঠিক এটাই চায়।';

  @override
  String get rulesOutOfDateTitle => 'নিয়মগুলি আপডেট করবেন?';

  @override
  String get rulesOutOfDateMessage =>
      'এই ধরনের নিয়মগুলি এখনও পুরানো শর্তটি বর্ণনা করে।';

  @override
  String get later => 'পরে';

  @override
  String get currentIcon => 'বর্তমান আইকন';

  @override
  String get currentColor => 'বর্তমান রঙ';

  @override
  String get groupDeviceClaimOwner => 'মালিকানা দাবি করুন';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" গ্রুপের মালিক তবে দীর্ঘকাল দেখা যায়নি। এই ডিভাইসে মালিকানা নিতে চান?';
  }

  @override
  String get groupDeviceOwnerClaimed => 'এই ডিভাইস এখন গ্রুপের মালিক।';

  @override
  String get groupErrorOwnerActive =>
      'গ্রুপের মালিক সম্প্রতি দেখা গেছে: মালিকানা দাবি করা যায় না।';

  @override
  String get groupCreatedOwnerExplain =>
      'গ্রুপ তৈরি। এই ডিভাইস এর মালিক; ভূমিকা ডিভাইসে হস্তান্তর করা যায়।';

  @override
  String get boardEliminated => 'নির্মূল';

  @override
  String get soundsSection => 'শব্দ';

  @override
  String get gameSounds => 'খেলার শব্দ';

  @override
  String get gameSoundsDescription =>
      'যখন একজন খেলোয়াড় নির্মূল হয়, যখন খেলা জেতা যায় এবং যখন টাইমার শেষ হয় তখন একটি শব্দ';

  @override
  String get turnTimer => 'পালার টাইমার';

  @override
  String get turnTimerLess => 'কম সময়';

  @override
  String get turnTimerMore => 'আরও সময়';

  @override
  String get turnTimerStart => 'শুরু করুন';

  @override
  String get turnTimerPause => 'থামান';

  @override
  String get turnTimerReset => 'রিসেট করুন';

  @override
  String get turnTimerTimeUp => 'সময়ের শেষ!';

  @override
  String get configShareOpen => 'QR কোড দ্বারা শেয়ার করুন';

  @override
  String get configShareTitle => 'এই কনফিগারেশন শেয়ার করুন';

  @override
  String get configShareExplainServer =>
      'অন্য একটি ফোন দিয়ে এই কোডটি স্ক্যান করুন এটিকে একই সার্ভারের সাথে সেট আপ করতে।';

  @override
  String configShareExplainGroup(String name) {
    return 'অন্য একটি ফোন দিয়ে এই কোডটি স্ক্যান করুন এটিকে একই সার্ভারের সাথে সেট আপ করতে এবং গ্রুপ $name এ যোগদান করতে। এটিতে গ্রুপের আমন্ত্রণ কোড রয়েছে: এটি শুধুমাত্র এমন মানুষদের কাছে দেখান যাদের আপনি গ্রুপে চান।';
  }

  @override
  String get configShareWebAppLabel => 'ওয়েব অ্যাপ ঠিকানা';

  @override
  String get configShareWebAppHelper =>
      'আপনার সার্ভার CountScore ওয়েব অ্যাপ পরিবেশন করে, যেমন https://countscore.example.com/countscore। কোডটি এই পাতা খোলে।';

  @override
  String get configShareWebAppNeeded =>
      'কোডটি দেখাতে ওয়েব অ্যাপ ঠিকানা লিখুন।';

  @override
  String get configShareQrLabel => 'কনফিগারেশন লিঙ্কের QR কোড';

  @override
  String get configShareCopyLink => 'লিঙ্ক কপি করুন';

  @override
  String get configShareLinkCopied => 'লিঙ্ক কপি করা হয়েছে';

  @override
  String get configShareTooLong =>
      'এই লিঙ্কটি QR কোডে ফিট করার জন্য খুব দীর্ঘ। পরিবর্তে \"লিঙ্ক কপি করুন\" ব্যবহার করুন।';

  @override
  String get replaceConfigTitle => 'কনফিগারেশন প্রতিস্থাপন করবেন?';

  @override
  String replaceConfigCurrent(String value) {
    return 'এখন: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'নতুন: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'আমন্ত্রণ কোড $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'এই ডিভাইস গ্রুপ $name ছেড়ে যাবে। এর খেলা এই ডিভাইসে থাকে।';
  }

  @override
  String get replaceConfigConfirm => 'প্রতিস্থাপন করুন';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'এই ডিভাইসে $count পরিবর্তন এখনও গ্রুপে পৌঁছায়নি। আপনি এখন চলে গেলে, গ্রুপ এটি কখনই পাবে না।',
      one: 'এই ডিভাইসে 1 পরিবর্তন এখনও গ্রুপে পৌঁছায়নি। আপনি এখন চলে গেলে, গ্রুপ এটি কখনই পাবে না।',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'যাহোক যান';

  @override
  String get replaceConfigDone => 'কনফিগারেশন প্রতিস্থাপিত';

  @override
  String get replaceConfigUnchanged =>
      'এই ডিভাইস ইতিমধ্যে এই কনফিগারেশন ব্যবহার করে';

  @override
  String get joinLinkHandOverMessage =>
      'এই লিঙ্কটি CountScore Android অ্যাপে খোলা যেতে পারে। অ্যাপ ইনস্টল না থাকলে, Play Store খোলে।';

  @override
  String get joinLinkOpenInApp => 'অ্যাপে খুলুন';

  @override
  String get joinLinkContinueHere => 'ব্রাউজারে চালিয়ে যান';
}
