// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'ہوم';

  @override
  String get playersListTitle => 'کھلاڑیوں کی فہرست';

  @override
  String get gameTypesTitle => 'گیم کی اقسام';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get aboutTitle => 'کے بارے میں';

  @override
  String get newGame => 'نیا گیم';

  @override
  String get noGames => 'کوئی گیم نہیں';

  @override
  String get noGamesOfThisType => 'اس قسم کا کوئی گیم نہیں';

  @override
  String get createFirstGame => 'اپنا پہلا گیم بنائیں';

  @override
  String get newWithSamePlayers => 'ایک جیسے کھلاڑیوں کے ساتھ نیا';

  @override
  String get playAgain => 'دوبارہ کھیلیں';

  @override
  String get rename => 'دوبارہ نام دیں';

  @override
  String get delete => 'حذف کریں';

  @override
  String get confirmDeletion => 'حذف کی تصدیق کریں';

  @override
  String confirmDeleteGame(String name) {
    return 'کیا آپ واقعی \"$name\" گیم حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get renameGame => 'گیم کا نام تبدیل کریں';

  @override
  String get gameName => 'گیم کا نام';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get allGames => 'تمام گیمز';

  @override
  String get filterGames => 'گیمز کو فلٹر کریں';

  @override
  String get applyFilter => 'لاگو کریں';

  @override
  String get resetFilter => 'دوبارہ سیٹ کریں';

  @override
  String get selectGameType => 'گیم کی قسم منتخب کریں';

  @override
  String get gameType => 'گیم کی قسم';

  @override
  String get loadingGameTypes => 'گیم کی اقسام لوڈ ہو رہی ہیں...';

  @override
  String get lowestScoreWins => 'سب سے کم اسکور جیتتا ہے';

  @override
  String get highestScoreWins => 'سب سے زیادہ اسکور جیتتا ہے';

  @override
  String get players => 'کھلاڑی';

  @override
  String get add => 'شامل کریں';

  @override
  String get pleaseEnterName => 'براہ کرم نام درج کریں';

  @override
  String get clear => 'صاف کریں';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get game => 'گیم';

  @override
  String get editGame => 'گیم میں ترمیم کریں';

  @override
  String get editGameDialogTitle => 'گیم میں ترمیم کریں';

  @override
  String get removePlayer => 'کھلاڑی کو ہٹائیں';

  @override
  String get addPlayerToGame => 'کھلاڑی شامل کریں';

  @override
  String get warningRemovePlayer =>
      'انتباہ! اس کھلاڑی کو ہٹانے سے اس گیم میں ان کے تمام اسکورز حذف ہو جائیں گے۔ یہ کارروائی واپس نہیں کی جا سکتی۔';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'کیا آپ واقعی $playerName کو اس گیم سے ہٹانا چاہتے ہیں؟';
  }

  @override
  String get playerRemoved => 'کھلاڑی گیم سے ہٹایا گیا';

  @override
  String get deleteLastRound => 'آخری راؤنڈ حذف کریں';

  @override
  String get confirm => 'تصدیق کریں';

  @override
  String get confirmDeleteLastRound => 'آخری راؤنڈ حذف کریں؟';

  @override
  String get noPlayersInGame => 'اس گیم میں کوئی کھلاڑی نہیں';

  @override
  String get round => 'راؤنڈ';

  @override
  String boardRoundButton(int round) {
    return 'راؤنڈ $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · راؤنڈ $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · راؤنڈ $round · $position/$count';
  }

  @override
  String keypadTotalAfter(String total) {
    return 'کل ہے: $total';
  }

  @override
  String keypadNext(String player) {
    return 'اگلا\n$player';
  }

  @override
  String get keypadValidateRound => 'راؤنڈ تصدیق کریں';

  @override
  String get keypadToggleSign => 'علامت تبدیل کریں';

  @override
  String get keypadBackspace => 'ایک عدد حذف کریں';

  @override
  String get keypadShortcutTitle => 'کی شارٹ کٹ';

  @override
  String get keypadShortcutKind => 'کی کی قسم';

  @override
  String get keypadShortcutKindValue => 'ایک قیمت درج کریں';

  @override
  String get keypadShortcutKindMultiply => 'اسکور کو ضرب دیں (صرف مثبت)';

  @override
  String get keypadShortcutKindAdd => 'اسکور میں شامل کریں';

  @override
  String get keypadShortcutAmount => 'نمبر';

  @override
  String get keypadShortcutLabel => 'کی کا لیبل (اختیاری)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return '$min اور $max کے درمیان ایک مکمل نمبر، 0 کے علاوہ';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return '$min اور $max کے درمیان ایک مکمل نمبر';
  }

  @override
  String get appearance => 'شکل و صورت';

  @override
  String get light => 'روشن';

  @override
  String get dark => 'سیاہ';

  @override
  String get system => 'سسٹم';

  @override
  String get screen => 'اسکرین';

  @override
  String get keepScreenAwake => 'اسکرین کو جاگتا رکھیں';

  @override
  String get keepScreenAwakeDescription =>
      'گیم کے دوران اسکرین کو سونے سے روکتا ہے';

  @override
  String get backup => 'بیک اپ';

  @override
  String get exportDatabase => 'ڈیٹا بیس برآمد کریں';

  @override
  String get exportDatabaseDescription =>
      'اپنے تمام گیمز کو ایک فائل میں محفوظ کریں';

  @override
  String get databaseExportedTo => 'ڈیٹا بیس کو برآمد کیا گیا:';

  @override
  String get errorDuringExport => 'برآمدگی کے دوران خرابی:';

  @override
  String get importDatabase => 'ڈیٹا بیس درآمد کریں';

  @override
  String get importDatabaseDescription => 'بیک اپ فائل سے اپنے گیمز بحال کریں';

  @override
  String get confirmation => 'تصدیق';

  @override
  String get importWarning =>
      'درآمد سے آپ کی تمام موجودہ ڈیٹا کی جگہ لے لی جائے گی۔ درآمد سے پہلے خودکار بیک اپ بنایا جائے گا۔\n\nکیا آپ جاری رکھنا چاہتے ہیں؟';

  @override
  String get import => 'درآمد کریں';

  @override
  String get databaseImportedSuccessfully => 'ڈیٹا بیس کامیابی سے درآمد ہوا';

  @override
  String get importSuccessful => 'درآمد کامیاب';

  @override
  String get importSuccessMessage =>
      'ڈیٹا بیس کامیابی سے درآمد ہو گیا۔\n\nایپلیکیشن اب بند ہو جائے گی۔ نئی ڈیٹا دیکھنے کے لیے اسے دوبارہ کھولیں۔';

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get errorDuringImport => 'درآمد کے دوران خرابی:';

  @override
  String get noPlayers => 'کوئی کھلاڑی نہیں';

  @override
  String get playersAppearMessage =>
      'کھلاڑی یہاں ظاہر ہوں گے جب آپ\nگیمز بنائیں گے';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گیمز',
      one: '1 گیم',
      zero: '0 گیمز',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جیتیں',
      one: '1 جیت',
      zero: '0 جیتیں',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'رنگ تبدیل کریں';

  @override
  String get renamePlayer => 'کھلاڑی کا نام تبدیل کریں';

  @override
  String get newName => 'نیا نام';

  @override
  String playerRenamedTo(String name) {
    return 'کھلاڑی کا نام \"$name\" میں تبدیل ہو گیا';
  }

  @override
  String get deletePlayer => 'کھلاڑی کو حذف کریں';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'کیا آپ واقعی \"$name\" کو حذف کرنا چاہتے ہیں؟\n\nیہ کھلاڑی تمام $count گیم(ز) سے ہٹایا جائے گا۔';
  }

  @override
  String playerDeleted(String name) {
    return 'کھلاڑی \"$name\" حذف ہو گیا';
  }

  @override
  String get chooseColor => 'رنگ منتخب کریں';

  @override
  String get noGameTypes => 'گیم کی کوئی قسم نہیں';

  @override
  String get edit => 'ترمیم کریں';

  @override
  String get newType => 'نئی قسم';

  @override
  String get editType => 'قسم میں ترمیم کریں';

  @override
  String get newGameType => 'نئی گیم کی قسم';

  @override
  String get gameTypeName => 'گیم کی قسم کا نام';

  @override
  String get icon => 'آئیکن:';

  @override
  String get color => 'رنگ:';

  @override
  String get chooseIcon => 'آئیکن منتخب کریں';

  @override
  String get nameIsRequired => 'نام ضروری ہے';

  @override
  String get create => 'بنائیں';

  @override
  String get ranking => 'درجہ بندی';

  @override
  String get noCurrentGame => 'کوئی موجودہ گیم نہیں';

  @override
  String get noScoresRecorded => 'کوئی اسکور ریکارڈ نہیں ہوا';

  @override
  String get playerStatistics => 'کھلاڑی کی شماریات';

  @override
  String get noStatisticsAvailable => 'کوئی شماریات دستیاب نہیں';

  @override
  String get gamesPlayed => 'گیمز کھیلے گئے';

  @override
  String get wins => 'جیتیں';

  @override
  String get winRate => 'جیت کی شرح';

  @override
  String get byGameType => 'گیم کی قسم کے لحاظ سے';

  @override
  String get rate => 'شرح';

  @override
  String version(String version) {
    return 'ورژن $version';
  }

  @override
  String get appDescription =>
      'Vincent Moreau کی طرف سے اپنے گیم سیشن کے لیے اسکور مینجمنٹ ایپلیکیشن';

  @override
  String get features => 'خصوصیات';

  @override
  String get featureDifferentGameTypes => 'مختلف گیم کی اقسام';

  @override
  String get featurePlayerManagement => 'کھلاڑی کا انتظام';

  @override
  String get featureDetailedStatistics => 'تفصیلی شماریات';

  @override
  String get featureCustomization => 'اپنی مرضی سے بنانا';

  @override
  String get featureDarkLightTheme => 'سیاہ/روشن تھیم';

  @override
  String get featureGroupSharing => 'گروپ کا اشتراک';

  @override
  String get featureGameAnalysis => 'AI گیم تجزیہ';

  @override
  String get rateApp => 'CountScore کو ریٹ کریں';

  @override
  String get search => 'تلاش';

  @override
  String get newPlayerName => 'نیا کھلاڑی کا نام';

  @override
  String get noPlayersFound => 'کوئی کھلاڑی نہیں ملا';

  @override
  String get close => 'بند کریں';

  @override
  String get playerEliminationCondition => 'کھلاڑی کی ختم کرنے کی شرط';

  @override
  String get gameOverCondition => 'گیم ختم کرنے کی شرط';

  @override
  String get none => 'کوئی نہیں';

  @override
  String get overThreshold => 'حد سے زیادہ';

  @override
  String get underThreshold => 'حد سے کم';

  @override
  String get firstPlayerOver => 'پہلا کھلاڑی جو پہنچے';

  @override
  String get firstPlayerUnder => 'پہلا کھلاڑی نیچے';

  @override
  String get lastPlayerOver => 'آخری کھلاڑی باقی (دوسرے حد سے زیادہ)';

  @override
  String get lastPlayerUnder => 'آخری کھلاڑی باقی (دوسرے حد سے کم)';

  @override
  String get threshold => 'حد';

  @override
  String get conditionType => 'شرط کی قسم';

  @override
  String get continuePlay => 'کھیل جاری رکھیں';

  @override
  String gameEndWinner(String name) {
    return '$name جیتے';
  }

  @override
  String gameEndTie(String names) {
    return 'برابری: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count راؤنڈز',
      one: '$count راؤنڈ',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'سب سے کم اسکور جیتے';

  @override
  String get gameEndHighestWins => 'سب سے زیادہ اسکور جیتے';

  @override
  String get gameEndAnalysis => 'تجزیہ';

  @override
  String get gameEndResults => 'نتائج';

  @override
  String get rankingEliminationNote =>
      'ختم کرنے کی ترتیب کے لحاظ سے درجہ بندی: جو بعد میں نکلے وہ آگے درجہ بندی میں آتے ہیں، نقصان سے قطع نظر۔';

  @override
  String get endGame => 'گیم ختم کریں';

  @override
  String get reopenGame => 'گیم دوبارہ کھولیں';

  @override
  String get gameFinished => 'مکمل';

  @override
  String get undo => 'کالعدم کریں';

  @override
  String get gameReopened => 'گیم دوبارہ کھولا گیا';

  @override
  String get comment => 'تبصرہ';

  @override
  String get enterComment => 'تبصرہ درج کریں';

  @override
  String get analyzeGame => 'گیم کا تجزیہ کریں';

  @override
  String get analysisTitle => 'گیم کا تجزیہ';

  @override
  String get analysisStyle => 'تجزیہ کا انداز';

  @override
  String get analysisStyleProfessor => 'پروفیسر';

  @override
  String get analysisStyleCommentator => 'کھیل کی تبصریت';

  @override
  String get analysisStyleDocumentary => 'جنگلی دستاویز';

  @override
  String get analysisStyleNoir => 'جاسوس';

  @override
  String get analysisStyleBard => 'شاعر';

  @override
  String get analysisStyleCoach => 'کوچ';

  @override
  String get analysisStyleConsultant => 'مشیر';

  @override
  String get analysisStyleAstrologer => 'ماہر نجوم';

  @override
  String get analysisStyleRealityTv => 'حقیقت کے شو';

  @override
  String get generatingAnalysis => 'تجزیہ تیار ہو رہا ہے…';

  @override
  String get generateAnalysis => 'تجزیہ تیار کریں';

  @override
  String get regenerateAnalysis => 'تجزیہ دوبارہ تیار کریں';

  @override
  String get deleteAnalysis => 'تجزیہ حذف کریں';

  @override
  String get confirmRegenerateAnalysis =>
      'دوبارہ تیار کریں؟ موجودہ تجزیہ کی جگہ لے لی جائے گی۔';

  @override
  String get confirmDeleteAnalysis => 'اس گیم کے لیے تجزیہ حذف کریں؟';

  @override
  String get analysisError => 'تجزیہ تیار کرنے میں ناکامی';

  @override
  String get analysisErrorUnavailable =>
      'تجزیہ سرور عارضی طور پر دستیاب نہیں ہے۔ بعد میں دوبارہ کوشش کریں۔';

  @override
  String get analysisErrorGroupBudget =>
      'آپ کے گروپ نے اس ماہ کا تجزیہ بجٹ استعمال کر لیا ہے۔ یہ اگلے مہینے کی شروعات میں نئے سرے سے شروع ہوتا ہے۔';

  @override
  String get analysisStyleGroupDefault =>
      'کوئی انداز منتخب نہیں: یہ مشترکہ گیم گروپ کے انداز اور زبان میں تجزیہ ہے۔';

  @override
  String analysisErrorStatus(int status) {
    return 'تجزیہ تیار کرنے میں ناکامی (HTTP $status)';
  }

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String analysisGeneratedAt(String date) {
    return '$date پر تیار کیا گیا';
  }

  @override
  String get serverSection => 'سرور';

  @override
  String get backendUrlLabel => 'سرور کا URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'منسلک خصوصیات کو CountScore سرور کی ضرورت ہے۔ backend/ فولڈر سے ایک انسٹال کریں اور یہاں اس کا پتہ درج کریں۔ کوئی سرور نہ ہونے سے، کوئی ڈیٹا اس ڈیوائس سے باہر نہیں جاتا۔';

  @override
  String get backendNotConfigured => 'کوئی سرور کنفیگ نہیں ہے';

  @override
  String get backendUrlInvalid =>
      'غلط پتہ۔ مکمل URL درج کریں، مثال کے طور پر https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// صرف لوکل نیٹ ورک پر قبول ہے۔ عوامی سرور کے لیے https:// استعمال کریں۔';

  @override
  String get testConnection => 'کنکشن ٹیسٹ کریں';

  @override
  String get connectionOk => 'سرور جواب دے رہا ہے';

  @override
  String get connectionFailed => 'سرور جواب نہیں دے رہا';

  @override
  String get serverUrlSaved => 'سرور محفوظ کیا گیا';

  @override
  String get analysisRequiresBackend =>
      'یہ تجزیہ سرور کی ضرورت ہے۔ ترتیبات میں ایک کنفیگ کریں۔';

  @override
  String get openSettings => 'ترتیبات کھولیں';

  @override
  String get serverUrlCleared => 'سرور صاف کیا گیا';

  @override
  String get groupSection => 'گروپ';

  @override
  String get groupDescription =>
      'اپنے گروپ میں دوسری ڈیوائسز کے ساتھ گیمز کا اشتراک کریں۔ مشترکہ گیمز، ان کے کھلاڑی، اسکورز، تبصرے اور تجزیے آپ کے سرور پر بھیجے جاتے ہیں؛ دوسری گیمز اس ڈیوائس پر رہتے ہیں۔';

  @override
  String get groupNeedsServer => 'پہلے اوپر سرور سیٹ اپ کریں۔';

  @override
  String get groupCreate => 'گروپ بنائیں';

  @override
  String get groupJoin => 'گروپ میں شامل ہوں';

  @override
  String get groupNameLabel => 'گروپ کا نام';

  @override
  String get groupNicknameLabel => 'آپ کا نام';

  @override
  String get groupNicknameHint => 'گروپ میں دوسرے اسے دیکھیں گے';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'آپ کا نام: $nickname';
  }

  @override
  String get groupNicknameEdit => 'اپنا نام تبدیل کریں';

  @override
  String get shareTokenLabel => 'مدعو ضابطہ';

  @override
  String get shareTokenHint =>
      'گروپ کے کسی رکن نے جو ضابطہ بھیجا ہے اسے پیسٹ کریں';

  @override
  String groupCurrent(String name) {
    return 'گروپ: $name';
  }

  @override
  String get shareTokenExplain =>
      'یہ ضابطہ ان ڈیوائسز کو بھیجیں جو گروپ میں شامل ہونا چاہیں۔ جس کے پاس یہ ہے وہ شامل ہو سکتا ہے۔';

  @override
  String get shareTokenCopy => 'ضابطہ کاپی کریں';

  @override
  String get shareTokenCopied => 'ضابطہ کاپی کیا گیا';

  @override
  String get shareTokenRotate => 'نیا ضابطہ';

  @override
  String get shareTokenRotateConfirm =>
      'پرانا ضابطہ اب کسی کو گروپ میں شامل نہیں ہونے دے گا۔ گروپ میں پہلے سے موجود ڈیوائسز متاثر نہیں ہوں گی۔';

  @override
  String get groupLeave => 'گروپ چھوڑیں';

  @override
  String get groupLeaveConfirm =>
      'یہ ڈیوائس گروپ چھوڑتی ہے۔ مشترکہ گیمز اس ڈیوائس پر رہتے ہیں لیکن اب سنک نہیں ہوں گے۔';

  @override
  String get groupLeft => 'گروپ چھوڑ دیا گیا';

  @override
  String get groupJoined => 'گروپ میں شامل ہو گئے';

  @override
  String get clearServerLeavesGroup =>
      'سرور صاف کرنے سے گروپ چھوڑ دیا جاتا ہے۔ مشترکہ گیمز اس ڈیوائس پر رہتے ہیں۔';

  @override
  String get syncNow => 'اب سنک کریں';

  @override
  String syncStatusIdle(String time) {
    return '$time پر سنک کیا گیا';
  }

  @override
  String get syncStatusSyncing => 'سنک ہو رہا ہے…';

  @override
  String get syncStatusOffline =>
      'سرور قابل رسائی نہیں ہے — تبدیلیاں بعد میں بھیجی جائیں گی';

  @override
  String get syncStatusUnauthorized =>
      'سرور اب اس ڈیوائس کو قبول نہیں کرتا۔ گروپ چھوڑیں، پھر دوبارہ شامل ہوں۔';

  @override
  String get syncStatusError => 'سنک کے دوران سرور میں خرابی';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تبدیلیاں انتظار میں ہیں',
      one: '1 تبدیلی انتظار میں ہے',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سرور نے $count تبدیلیاں مسترد کیں',
      one: 'سرور نے 1 تبدیلی مسترد کی',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'نامعلوم یا متبدل مدعو ضابطہ';

  @override
  String get groupErrorRateLimited =>
      'بہت زیادہ کوششیں۔ ایک منٹ میں دوبارہ کوشش کریں۔';

  @override
  String get groupErrorUnreachable => 'سرور قابل رسائی نہیں';

  @override
  String get groupErrorServer => 'سرور کی خرابی';

  @override
  String get shareWithGroup => 'گروپ کے ساتھ شیئر کریں';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name میں ڈیوائسز یہ گیم دیکھیں گے اور ترمیم کریں گے';
  }

  @override
  String shareGameConfirm(String name) {
    return 'گیم، اس کے کھلاڑی، اسکورز اور تبصرے $name کو بھیجے جائیں گے۔ شیئرنگ کو کالعدم نہیں کیا جا سکتا۔';
  }

  @override
  String get gameSharedDone => 'گیم گروپ کے ساتھ شیئر کیا گیا';

  @override
  String get gameSharedBadge => 'مشترکہ گیم';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'یہ ناموں کا اشتراک نہیں کیا جا سکتا: $names۔ حروف، ہندسے، خالی جگہیں، ہائفن، اپوسٹرافیں یا نقطے استعمال کریں (زیادہ سے زیادہ 32 حروف)۔';
  }

  @override
  String roundRenumbered(int number) {
    return 'یہ راؤنڈ پہلے سے دوسری ڈیوائس پر درج تھا، اس لیے یہ راؤنڈ $number بن گیا۔';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" دوسری ڈیوائس پر حذف کیا گیا';
  }

  @override
  String get groupDevices => 'ڈیوائسز';

  @override
  String get groupDevicesExplain =>
      'کھوئی ہوئی یا بیچی گئی ڈیوائس کو یہاں گروپ سے ہٹایا جا سکتا ہے۔';

  @override
  String get groupDeviceThisOne => 'یہ ڈیوائس';

  @override
  String groupDeviceLastSeen(String date) {
    return '$date کو آخری بار دیکھی گئی';
  }

  @override
  String get groupDeviceRevoke => 'ہٹائیں';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'کیا \"$label\" کو گروپ سے ہٹانا ہے؟ یہ اب سنک نہیں ہوگا۔ مدعو ضابطہ بھی تبدیل ہو جائے گا: اراکین اپنی رسائی برقرار رکھتے ہیں، لیکن آپ کو کسی کو مدعو کرنے کے لیے نیا ضابطہ شیئر کرنا ہوگا۔';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" کو ہٹایا گیا۔ مدعو ضابطہ بدل گیا ہے۔';
  }

  @override
  String get reportCommentary => 'یہ تبصرہ رپورٹ کریں';

  @override
  String get reportCommentarySubject => 'CountScore — AI تبصرہ رپورٹ';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'اس AI تیار شدہ تبصرے میں کیا غلط ہے؟\n\n\n---\nحوالہ: $reference\nتبصرہ:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'کوئی ای میل ایپ نہیں ملی۔ اس تبصرے کی رپورٹ کرنے کے لیے $email کو لکھیں۔';
  }

  @override
  String get gameRulesTitle => 'گیم کے اصول';

  @override
  String get gameRulesInApp => 'CountScore میں';

  @override
  String get gameRulesSection => 'اصول';

  @override
  String get gameRulesNoElimination => 'کھیل کے دوران کوئی ختم نہیں';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'ایک کھلاڑی $threshold نکات سے اوپر ختم کر دیا جاتا ہے';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'ایک کھلاڑی $threshold نکات سے نیچے ختم کر دیا جاتا ہے';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'گیم فوری طور پر ختم ہوتی ہے جب کوئی کھلاڑی $threshold نکات تک پہنچتا ہے';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'گیم فوری طور پر ختم ہوتی ہے جب کوئی کھلاڑی $threshold نکات سے نیچے آتا ہے';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'گیم ختم ہوتا ہے جب سوائے ایک کھلاڑی کے سب $threshold نکات سے اوپر ہوں';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'گیم ختم ہوتا ہے جب سوائے ایک کھلاڑی کے سب $threshold نکات سے نیچے ہوں';
  }

  @override
  String get gameRulesNoEnd =>
      'کوئی خودکار اختتام نہیں: آپ طے کریں کہ گیم کب ختم ہے';

  @override
  String get gameRulesEmptyTitle => 'ابھی کوئی اصول نہیں';

  @override
  String get gameRulesEmptyHint =>
      'اپنی میز کے نکات کا حساب لگانے کا طریقہ لکھیں — سب کے پاس ایک جیسا ورژن ہوگا۔';

  @override
  String get gameRulesWrite => 'اصول لکھیں';

  @override
  String get gameRulesEditTitle => 'اصول میں ترمیم کریں';

  @override
  String get gameRulesEditorHint => 'آپ کی میز کے اصول۔ Markdown تھام ہے۔';

  @override
  String get gameRulesFromGroup => 'آپ کے گروپ کے اصول';

  @override
  String get gameRulesRestoreDefault => 'اصل اصول بحال کریں';

  @override
  String get gameRulesSaved => 'اصول محفوظ کیے گئے';

  @override
  String get gameRulesRestored => 'اصل اصول بحال کیے گئے';

  @override
  String get gameRulesDisclaimer =>
      'CountScore کے لیے لکھا گیا خلاصہ جیسے وہ عام طور پر کھیلے جاتے ہیں۔ گیم کے نام ان کے متعلقہ مالکان کے ہیں اور صرف وضاحتی طور پر استعمال کیے جاتے ہیں۔';

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
  String get gameTypeNameOther => 'دوسرا';

  @override
  String get gameTypeNameOtherSortKey => 'دوسرا';

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
  String get groupDeviceOwner => 'مالک';

  @override
  String get groupDeviceMakeOwner => 'مالک بنائیں';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'کیا \"$label\" کو گروپ سونپنا ہے؟ یہ ڈیوائس اب ڈیوائسز کو ہٹانے یا مدعو ضابطہ تبدیل کرنے کے قابل نہیں ہوگی۔';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" اب گروپ کا مالک ہے۔';
  }

  @override
  String get groupDevicesExplainMember =>
      'صرف گروپ کا مالک ڈیوائس کو ہٹا سکتا ہے یا مدعو ضابطہ تبدیل کر سکتا ہے۔';

  @override
  String get groupErrorNotOwner => 'صرف گروپ کا مالک یہ کر سکتا ہے';

  @override
  String get whoStarts => 'کون شروع کرتا ہے؟';

  @override
  String get whoStartsAgain => 'دوبارہ ڈرا کریں';

  @override
  String get diceRoller => 'ڈائس رول کریں';

  @override
  String get diceCount => 'ڈائس کی تعداد';

  @override
  String get diceRollAgain => 'دوبارہ رول کریں';

  @override
  String diceTotal(int total) {
    return 'کل: $total';
  }

  @override
  String get resumeGame => 'دوبارہ شروع کریں';

  @override
  String get recentGames => 'حالیہ';

  @override
  String get gameInProgress => 'جاری ہے';

  @override
  String roundNumber(int number) {
    return 'راؤنڈ $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name آگے ہے · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name نے جیتا';
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
  String get boardViewRows => 'ہر کھلاڑی کے لیے ایک قطار';

  @override
  String get boardViewLanes => 'ہر کھلاڑی کے لیے ایک کالم';

  @override
  String get boardSeatOrder => 'بیٹھنے کی ترتیب';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'کھلاڑی';

  @override
  String get boardTotal => 'کل';

  @override
  String get boardLeader => 'آگے ہے';

  @override
  String get groupSettingsTitle => 'تبصرے اور استعمال';

  @override
  String get groupSettingsDescription =>
      'انداز اور زبان گروپ کے گیمز کے لیے سرور لکھتا ہے۔ کوئی بھی رکن اسے تبدیل کر سکتا ہے۔';

  @override
  String get groupCommentStyle => 'تبصرے کا انداز';

  @override
  String get groupCommentStyleNarrative => 'کہانی';

  @override
  String get groupCommentStyleHumorous => 'مزاحیہ';

  @override
  String get groupCommentStyleAnalytical => 'تجزیاتی';

  @override
  String get groupCommentLanguage => 'تبصرے کی زبان';

  @override
  String get groupSettingsSaved => 'گروپ کی ترتیبات محفوظ کی گئیں';

  @override
  String get groupUsageTitle => 'اس ماہ LLM کا استعمال';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$budget میں سے $used خرچ کیا گیا';
  }

  @override
  String groupUsageResets(String date) {
    return '$date پر دوبارہ سیٹ ہوتا ہے';
  }

  @override
  String get statsBestWinRate => 'بہترین جیت کی شرح';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins جیتیں $games میں سے',
      one: '$wins جیت $games میں سے',
      zero: '$games میں سے کوئی جیت نہیں',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'کھلاڑی';

  @override
  String get statsColumnGames => 'گیمز';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گیمز · ابھی درجہ بندی نہیں',
      one: 'ایک گیم · ابھی درجہ بندی نہیں',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count مکمل گیمز سے درجہ بندی۔ کھلاڑی کو دیکھنے کے لیے تھپتھپائیں۔',
      one: '$count مکمل گیم سے درجہ بندی۔ کھلاڑی کو دیکھنے کے لیے تھپتھپائیں۔',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'گیمز',
      one: 'گیم',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جیتیں',
      one: 'جیت',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'اوسط جگہ';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جگہ، آخری $count گیمز',
      one: 'جگہ، آخری گیم',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'بہتری';

  @override
  String get statsTrendDeclining => 'خطرناک حال میں';

  @override
  String get statsTrendSteady => 'مستحکم';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': 'پہلا',
      '2': 'دوسرا',
      '3': 'تیسرا',
      '4': 'چوتھا',
      'other': '$rankواں',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلہ: $count جیتیں',
      one: 'سلسلہ: $count جیت',
      zero: 'کوئی جیت کی سلسلہ نہیں',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'بہترین: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType پر';
  }

  @override
  String get statsAverageTotal => 'اوسط حتمی کل';

  @override
  String get statsBestTotal => 'بہترین حتمی کل';

  @override
  String get statsMostBeaten => 'سب سے زیادہ شکست کھا ہوا مخالف';

  @override
  String get statsOpenPlayerCard => 'کھلاڑی کا کارڈ کھولیں';

  @override
  String get shareResult => 'نتیجہ شیئر کریں';

  @override
  String get shareAnalysis => 'تجزیہ شیئر کریں';

  @override
  String shareResultSubject(String gameName) {
    return 'نتیجہ: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date کا گیم';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points نکات',
      one: '$points نکہ',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'اسکورز $appName کے ساتھ رکھے گئے: $url';
  }

  @override
  String get shareFailed => 'شیئرنگ کھول نہیں سکا';

  @override
  String get newGameNameLabel => 'نام';

  @override
  String get newGameGameLabel => 'گیم';

  @override
  String newGameAllGames(int count) {
    return 'تمام گیمز ($count)';
  }

  @override
  String get newGamePlayersLabel => 'کھلاڑی · بیٹھنے کی ترتیب';

  @override
  String get newGameDragToReorder => 'دوبارہ ترتیب دینے کے لیے گھسیٹیں';

  @override
  String get newGameDealer => 'ڈیل کرتے ہیں';

  @override
  String get newGameAddPlayer => 'کھلاڑی شامل کریں';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'شروع کریں · $count کھلاڑی',
      one: 'شروع کریں · 1 کھلاڑی',
      zero: 'شروع کریں',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'کون کھیل رہے ہیں؟';

  @override
  String get whoIsPlayingSearchHint => 'نام، یا ایک نیا کھلاڑی';

  @override
  String get whoIsPlayingFrequent => 'اکثر آپ کے ساتھ کھیلتے ہیں';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '\"$gameName\" کے جیسے ہی کھلاڑی';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '\"$name\" بنائیں';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کھلاڑی شامل کریں',
      one: '1 کھلاڑی شامل کریں',
      zero: 'مکمل',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'گیم $number';
  }

  @override
  String get pwaUpdateReady => 'CountScore کا ایک نیا ورژن تیار ہے';

  @override
  String get pwaUpdateReload => 'دوبارہ لوڈ کریں';

  @override
  String get thresholdIsRequired => 'اس شرط کے لیے حد ضروری ہے';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'حد $maxString سے زیادہ نہیں ہو سکتی';
  }

  @override
  String get deletionImpossible => 'حذف کرنا ممکن نہیں';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count گیمز اس قسم کا استعمال کرتی ہیں: انہیں حذف نہیں کیا جا سکتا۔',
      one: '1 گیم اس قسم کا استعمال کرتی ہے: اسے حذف نہیں کیا جا سکتا۔',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'کیا آپ واقعی \"$name\" گیم کی قسم حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get winDirectionChangeTitle => 'جیتنے والے کو الٹایا جائے؟';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'اس قسم کی $count مکمل گیمز کی درجہ بندی الٹ دی جائے گی: ان کے جیتنے والے آخری بن جائیں گے۔',
      one: 'اس قسم کی 1 مکمل گیم کی درجہ بندی الٹ دی جائے گی: اس کا جیتنے والا آخری بن جائے گا۔',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'گیم ختم کرنے کی شرط منتخب جیتنے والے کے برعکس انعام دیتی ہے۔ گھر کا اصول بالکل یہی چاہے۔';

  @override
  String get rulesOutOfDateTitle => 'اصول اپڈیٹ کریں؟';

  @override
  String get rulesOutOfDateMessage =>
      'اس قسم کے اصول ابھی پرانی شرط کی وضاحت کرتے ہیں۔';

  @override
  String get later => 'بعد میں';

  @override
  String get currentIcon => 'موجودہ آئیکن';

  @override
  String get currentColor => 'موجودہ رنگ';

  @override
  String get groupDeviceClaimOwner => 'مالک ہونے کا دعویٰ کریں';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" گروپ کا مالک ہے لیکن کافی عرصے سے نہیں دیکھی گئی۔ اس ڈیوائس پر مالک ہونے کا دعویٰ کریں؟';
  }

  @override
  String get groupDeviceOwnerClaimed => 'یہ ڈیوائس اب گروپ کا مالک ہے۔';

  @override
  String get groupErrorOwnerActive =>
      'گروپ کے مالک کو حالیہ میں دیکھا گیا: مالک ہونے کا دعویٰ نہیں کیا جا سکتا۔';

  @override
  String get groupCreatedOwnerExplain =>
      'گروپ بنایا گیا۔ یہ ڈیوائس اس کی مالک ہے؛ یہ کردار ڈیوائسز میں دوسری کو سونپا جا سکتا ہے۔';

  @override
  String get boardEliminated => 'ختم';

  @override
  String get soundsSection => 'آوازیں';

  @override
  String get gameSounds => 'گیم کی آوازیں';

  @override
  String get gameSoundsDescription =>
      'ایک آواز جب کھلاڑی ختم ہو، جب گیم جیتی جائے اور جب ٹائمر ختم ہو';

  @override
  String get turnTimer => 'موڑ ٹائمر';

  @override
  String get turnTimerLess => 'کم وقت';

  @override
  String get turnTimerMore => 'زیادہ وقت';

  @override
  String get turnTimerStart => 'شروع کریں';

  @override
  String get turnTimerPause => 'روکیں';

  @override
  String get turnTimerReset => 'دوبارہ سیٹ کریں';

  @override
  String get turnTimerTimeUp => 'وقت ختم!';

  @override
  String get configShareOpen => 'QR کوڈ کے ذریعے شیئر کریں';

  @override
  String get configShareTitle => 'یہ ترتیب شیئر کریں';

  @override
  String get configShareExplainServer =>
      'اس کوڈ کو دوسری ڈیوائس کے ساتھ اسکین کریں تاکہ اسے ایک جیسے سرور کے ساتھ سیٹ کریں۔';

  @override
  String configShareExplainGroup(String name) {
    return 'اس کوڈ کو دوسری ڈیوائس کے ساتھ اسکین کریں تاکہ اسے ایک جیسے سرور کے ساتھ سیٹ کریں اور گروپ $name میں شامل ہوں۔ یہ گروپ کا مدعو ضابطہ رکھتا ہے: اسے صرف ان لوگوں کو دکھائیں جو آپ گروپ میں چاہتے ہیں۔';
  }

  @override
  String get configShareWebAppLabel => 'ویب ایپ کا پتہ';

  @override
  String get configShareWebAppHelper =>
      'جہاں آپ کا سرور CountScore ویب ایپ پیش کرتا ہے، جیسے https://countscore.example.com/countscore۔ کوڈ یہ صفحہ کھولتا ہے۔';

  @override
  String get configShareWebAppNeeded =>
      'کوڈ دکھانے کے لیے ویب ایپ کا پتہ درج کریں۔';

  @override
  String get configShareQrLabel => 'ترتیب کے لنک کا QR کوڈ';

  @override
  String get configShareCopyLink => 'لنک کاپی کریں';

  @override
  String get configShareLinkCopied => 'لنک کاپی کیا گیا';

  @override
  String get configShareTooLong =>
      'یہ لنک QR کوڈ میں فٹ ہونے کے لیے بہت لمبا ہے۔ اس کی بجائے \"لنک کاپی کریں\" استعمال کریں۔';

  @override
  String get replaceConfigTitle => 'ترتیب کی جگہ لے لیے؟';

  @override
  String replaceConfigCurrent(String value) {
    return 'اب: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'نیا: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'مدعو ضابطہ $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'یہ ڈیوائس گروپ $name چھوڑ دے گی۔ اس کے گیمز اس ڈیوائس پر رہتے ہیں۔';
  }

  @override
  String get replaceConfigConfirm => 'جگہ لے لیں';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'اس ڈیوائس پر $count تبدیلیاں ابھی گروپ تک نہیں پہنچیں۔ اگر آپ اب چھوڑتے ہیں، تو گروپ انہیں کبھی وصول نہیں کرے گا۔',
      one: 'اس ڈیوائس پر 1 تبدیلی ابھی گروپ تک نہیں پہنچی۔ اگر آپ اب چھوڑتے ہیں، تو گروپ اسے کبھی وصول نہیں کرے گا۔',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'ویسے بھی چھوڑیں';

  @override
  String get replaceConfigDone => 'ترتیب تبدیل کی گئی';

  @override
  String get replaceConfigUnchanged =>
      'یہ ڈیوائس پہلے سے یہ ترتیب استعمال کرتی ہے';

  @override
  String get joinLinkHandOverMessage =>
      'یہ لنک CountScore Android ایپ میں کھول سکتا ہے۔ اگر ایپ انسٹال نہیں ہے، تو Play Store کھلتا ہے۔';

  @override
  String get joinLinkOpenInApp => 'ایپ میں کھولیں';

  @override
  String get joinLinkContinueHere => 'براؤزر میں جاری رکھیں';
}
