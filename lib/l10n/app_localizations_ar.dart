// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get playersListTitle => 'قائمة اللاعبين';

  @override
  String get gameTypesTitle => 'أنواع الألعاب';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get aboutTitle => 'حول';

  @override
  String get newGame => 'لعبة جديدة';

  @override
  String get noGames => 'لا توجد ألعاب';

  @override
  String get noGamesOfThisType => 'لا توجد ألعاب من هذا النوع';

  @override
  String get createFirstGame => 'أنشئ لعبتك الأولى';

  @override
  String get newWithSamePlayers => 'جديدة بنفس اللاعبين';

  @override
  String get playAgain => 'العب مجددًا';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get delete => 'حذف';

  @override
  String get confirmDeletion => 'تأكيد الحذف';

  @override
  String confirmDeleteGame(String name) {
    return 'هل تريد حقاً حذف اللعبة \"$name\"؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get renameGame => 'إعادة تسمية اللعبة';

  @override
  String get gameName => 'اسم اللعبة';

  @override
  String get save => 'حفظ';

  @override
  String get filterByGameType => 'تصفية حسب نوع اللعبة';

  @override
  String get allGames => 'جميع الألعاب';

  @override
  String get filterGames => 'تصفية الألعاب';

  @override
  String get applyFilter => 'تطبيق';

  @override
  String get resetFilter => 'إعادة تعيين';

  @override
  String get selectGameType => 'اختر نوع اللعبة';

  @override
  String get gameType => 'نوع اللعبة';

  @override
  String get loadingGameTypes => 'جاري تحميل أنواع الألعاب...';

  @override
  String get winRule => 'قاعدة الفوز';

  @override
  String get lowestScoreWins => 'أقل نتيجة تفوز';

  @override
  String get highestScoreWins => 'أعلى نتيجة تفوز';

  @override
  String get lowestScoreExample => 'مثال: الغولف، القلوب';

  @override
  String get highestScoreExample => 'مثال: الرمي، البريدج';

  @override
  String get players => 'اللاعبون';

  @override
  String get add => 'إضافة';

  @override
  String get pleaseEnterName => 'الرجاء إدخال اسم';

  @override
  String get atLeast2PlayersRequired => 'يلزم لاعبان على الأقل';

  @override
  String playerNumber(int index) {
    return 'اللاعب $index';
  }

  @override
  String get selectPlayer => 'اختر لاعباً...';

  @override
  String get clear => 'مسح';

  @override
  String get remove => 'إزالة';

  @override
  String get createGame => 'إنشاء لعبة';

  @override
  String get game => 'اللعبة';

  @override
  String get editGame => 'تعديل اللعبة';

  @override
  String get editGameDialogTitle => 'تعديل اللعبة';

  @override
  String get gameSettings => 'إعدادات اللعبة';

  @override
  String get removePlayer => 'إزالة اللاعب';

  @override
  String get addPlayerToGame => 'إضافة لاعب';

  @override
  String get warningRemovePlayer =>
      'تحذير! إزالة هذا اللاعب ستحذف جميع نقاطه من هذه اللعبة. هذا الإجراء لا رجعة فيه.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'هل تريد حقاً إزالة $playerName من هذه اللعبة؟';
  }

  @override
  String get playerRemoved => 'تمت إزالة اللاعب من اللعبة';

  @override
  String get deleteLastRound => 'حذف الجولة الأخيرة';

  @override
  String get confirm => 'تأكيد';

  @override
  String get confirmDeleteLastRound => 'حذف الجولة الأخيرة؟';

  @override
  String get noPlayersInGame => 'لا يوجد لاعبون في هذه اللعبة';

  @override
  String get round => 'الجولة';

  @override
  String boardRoundButton(int round) {
    return 'الجولة $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · الجولة $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · الجولة $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'المجموع بعدها: $total';
  }

  @override
  String keypadNext(String player) {
    return 'التالي: $player';
  }

  @override
  String get keypadValidateRound => 'تأكيد الجولة';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => 'تغيير الإشارة';

  @override
  String get keypadBackspace => 'حذف رقم';

  @override
  String get appearance => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get screen => 'الشاشة';

  @override
  String get keepScreenAwake => 'إبقاء الشاشة مضاءة';

  @override
  String get keepScreenAwakeDescription =>
      'يمنع الشاشة من الإطفاء أثناء اللعبة';

  @override
  String get backup => 'النسخ الاحتياطي';

  @override
  String get exportDatabase => 'تصدير قاعدة البيانات';

  @override
  String get exportDatabaseDescription => 'احفظ جميع ألعابك في ملف';

  @override
  String get databaseExportedTo => 'تم تصدير قاعدة البيانات إلى:';

  @override
  String get errorDuringExport => 'خطأ أثناء التصدير:';

  @override
  String get importDatabase => 'استيراد قاعدة البيانات';

  @override
  String get importDatabaseDescription => 'استعد ألعابك من ملف نسخة احتياطية';

  @override
  String get confirmation => 'التأكيد';

  @override
  String get importWarning =>
      'سيؤدي الاستيراد إلى استبدال جميع بياناتك الحالية. سيتم إنشاء نسخة احتياطية تلقائية قبل الاستيراد.\n\nهل تريد المتابعة؟';

  @override
  String get import => 'استيراد';

  @override
  String get databaseImportedSuccessfully => 'تم استيراد قاعدة البيانات بنجاح';

  @override
  String get importSuccessful => 'نجح الاستيراد';

  @override
  String get importSuccessMessage =>
      'تم استيراد قاعدة البيانات بنجاح.\n\nسيتم إغلاق التطبيق الآن. يرجى فتحه مرة أخرى لرؤية البيانات الجديدة.';

  @override
  String get ok => 'موافق';

  @override
  String get errorDuringImport => 'خطأ أثناء الاستيراد:';

  @override
  String get noPlayers => 'لا يوجد لاعبون';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لاعبون: $names',
      two: 'لاعبان: $names',
      one: 'لاعب واحد: $names',
      zero: 'لا يوجد لاعبون',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage => 'سيظهر اللاعبون هنا بمجرد\nإنشاء الألعاب';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لعبة',
      two: 'لعبتان',
      one: 'لعبة واحدة',
      zero: '0 لعبة',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فوز',
      two: 'فوزان',
      one: 'فوز واحد',
      zero: '0 فوز',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'تغيير اللون';

  @override
  String get renamePlayer => 'إعادة تسمية اللاعب';

  @override
  String get newName => 'الاسم الجديد';

  @override
  String playerRenamedTo(String name) {
    return 'تمت إعادة تسمية اللاعب إلى \"$name\"';
  }

  @override
  String get deletePlayer => 'حذف اللاعب';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'هل تريد حقاً حذف \"$name\"؟\n\nسيتم إزالة هذا اللاعب من جميع $count لعبة (ألعاب).';
  }

  @override
  String playerDeleted(String name) {
    return 'تم حذف اللاعب \"$name\"';
  }

  @override
  String get chooseColor => 'اختر لوناً';

  @override
  String get noGameTypes => 'لا توجد أنواع ألعاب';

  @override
  String get predefined => 'افتراضي';

  @override
  String get edit => 'تعديل';

  @override
  String get newType => 'نوع جديد';

  @override
  String get editType => 'تعديل النوع';

  @override
  String get newGameType => 'نوع لعبة جديد';

  @override
  String get gameTypeName => 'اسم نوع اللعبة';

  @override
  String get icon => 'الأيقونة:';

  @override
  String get color => 'اللون:';

  @override
  String get chooseIcon => 'اختر أيقونة';

  @override
  String get nameIsRequired => 'الاسم مطلوب';

  @override
  String get create => 'إنشاء';

  @override
  String get ranking => 'الترتيب';

  @override
  String get noCurrentGame => 'لا توجد لعبة حالية';

  @override
  String get noScoresRecorded => 'لم يتم تسجيل نتائج';

  @override
  String get playerStatistics => 'إحصائيات اللاعب';

  @override
  String get noStatisticsAvailable => 'لا توجد إحصائيات متاحة';

  @override
  String get gamesPlayed => 'الألعاب الملعوبة';

  @override
  String get wins => 'الانتصارات';

  @override
  String get winRate => 'معدل الفوز';

  @override
  String get overallStatistics => 'الإحصائيات العامة';

  @override
  String get byGameType => 'حسب نوع اللعبة';

  @override
  String get rate => 'المعدل';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get appDescription =>
      'تطبيق إدارة النتائج لجلسات الألعاب الخاصة بك من Vincent Moreau';

  @override
  String get features => 'الميزات';

  @override
  String get featureDifferentGameTypes => 'أنواع ألعاب مختلفة';

  @override
  String get featurePlayerManagement => 'إدارة اللاعبين';

  @override
  String get featureDetailedStatistics => 'إحصائيات تفصيلية';

  @override
  String get featureCustomization => 'التخصيص';

  @override
  String get featureDarkLightTheme => 'الوضع الداكن/الفاتح';

  @override
  String get featureGroupSharing => 'المشاركة الجماعية';

  @override
  String get featureGameAnalysis => 'تحليل المباريات بالذكاء الاصطناعي';

  @override
  String get rateApp => 'قيّم CountScore';

  @override
  String get credits => 'الاعتمادات';

  @override
  String get appIconCredit => 'أيقونة التطبيق';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'اختر لاعباً';

  @override
  String get search => 'بحث';

  @override
  String get searchOrCreate => 'بحث / إنشاء';

  @override
  String get createNewPlayer => 'إنشاء لاعب جديد';

  @override
  String get newPlayerName => 'اسم اللاعب الجديد';

  @override
  String get noPlayersFound => 'لم يتم العثور على لاعبين';

  @override
  String get allPlayersSelected => 'تم اختيار جميع اللاعبين';

  @override
  String get close => 'إغلاق';

  @override
  String get playerEliminationCondition => 'شرط إقصاء اللاعب';

  @override
  String get gameOverCondition => 'شرط انتهاء اللعبة';

  @override
  String get none => 'بدون';

  @override
  String get overThreshold => 'فوق الحد';

  @override
  String get underThreshold => 'تحت الحد';

  @override
  String get firstPlayerOver => 'أول لاعب فوق الحد';

  @override
  String get firstPlayerUnder => 'أول لاعب تحت الحد';

  @override
  String get lastPlayerOver => 'آخر لاعب فوق الحد';

  @override
  String get lastPlayerUnder => 'آخر لاعب تحت الحد';

  @override
  String get threshold => 'الحد';

  @override
  String get conditionType => 'نوع الشرط';

  @override
  String get continuePlay => 'متابعة اللعب';

  @override
  String gameEndWinner(String name) {
    return 'الفائز: $name';
  }

  @override
  String gameEndTie(String names) {
    return 'تعادل: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جولة',
      many: '$count جولة',
      few: '$count جولات',
      two: 'جولتان',
      one: 'جولة واحدة',
      zero: 'لا جولات',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'أقل نتيجة تفوز';

  @override
  String get gameEndHighestWins => 'أعلى نتيجة تفوز';

  @override
  String get gameEndAnalysis => 'تحليل';

  @override
  String get gameEndResults => 'النتائج';

  @override
  String get endGame => 'إنهاء اللعبة';

  @override
  String get reopenGame => 'إعادة فتح اللعبة';

  @override
  String get gameFinished => 'منتهية';

  @override
  String get undo => 'تراجع';

  @override
  String get gameReopened => 'أُعيد فتح المباراة';

  @override
  String get comment => 'تعليق';

  @override
  String get enterComment => 'أدخل تعليقًا';

  @override
  String get analyzeGame => 'تحليل المباراة';

  @override
  String get analysisTitle => 'تحليل المباراة';

  @override
  String get analysisStyle => 'أسلوب التحليل';

  @override
  String get analysisStyleProfessor => 'الأستاذ';

  @override
  String get analysisStyleCommentator => 'المعلّق الرياضي';

  @override
  String get analysisStyleDocumentary => 'وثائقي الحياة البرّية';

  @override
  String get analysisStyleNoir => 'المحقّق';

  @override
  String get analysisStyleBard => 'الشاعر الجوّال';

  @override
  String get analysisStyleCoach => 'المدرّب';

  @override
  String get analysisStyleConsultant => 'المستشار';

  @override
  String get analysisStyleAstrologer => 'المنجّم';

  @override
  String get analysisStyleRealityTv => 'تلفزيون الواقع';

  @override
  String get generatingAnalysis => 'جارٍ إنشاء التحليل…';

  @override
  String get generateAnalysis => 'إنشاء التحليل';

  @override
  String get regenerateAnalysis => 'إعادة إنشاء التحليل';

  @override
  String get deleteAnalysis => 'حذف التحليل';

  @override
  String get confirmRegenerateAnalysis =>
      'إعادة الإنشاء؟ سيتم استبدال التحليل الحالي.';

  @override
  String get confirmDeleteAnalysis => 'حذف تحليل هذه المباراة؟';

  @override
  String get analysisError => 'فشل إنشاء التحليل';

  @override
  String get analysisErrorUnavailable =>
      'خادم التحليل غير متاح مؤقتًا. حاول مرة أخرى لاحقًا.';

  @override
  String analysisErrorStatus(int status) {
    return 'فشل إنشاء التحليل (HTTP $status)';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String analysisGeneratedAt(String date) {
    return 'تم الإنشاء في $date';
  }

  @override
  String get serverSection => 'الخادم';

  @override
  String get backendUrlLabel => 'عنوان الخادم';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'تتطلب الميزات المتصلة خادم CountScore. ثبّت خادمًا من مجلد backend/ وأدخل عنوانه هنا. بدون خادم، لا تغادر أي بيانات هذا الجهاز.';

  @override
  String get backendNotConfigured => 'لم يتم إعداد أي خادم';

  @override
  String get backendUrlInvalid =>
      'عنوان غير صالح. أدخل رابطًا كاملًا، مثل https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'لا يُقبل http:// إلا على شبكة محلية. استخدم https:// لخادم عام.';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get connectionOk => 'الخادم يستجيب';

  @override
  String get connectionFailed => 'الخادم لا يستجيب';

  @override
  String get serverUrlSaved => 'تم حفظ الخادم';

  @override
  String get analysisRequiresBackend =>
      'يتطلب هذا التحليل خادمًا. قم بإعداد واحد من الإعدادات.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get serverUrlCleared => 'تم مسح الخادم';

  @override
  String get groupSection => 'المجموعة';

  @override
  String get groupDescription =>
      'شارك الألعاب مع الأجهزة الأخرى في مجموعتك. تُرسل الألعاب المشتركة ولاعبوها ونتائجها وتعليقاتها وتحليلاتها إلى خادمك؛ أما باقي الألعاب فتبقى على هذا الجهاز.';

  @override
  String get groupNeedsServer => 'اضبط خادمًا أعلاه أولًا.';

  @override
  String get groupCreate => 'إنشاء مجموعة';

  @override
  String get groupJoin => 'الانضمام إلى مجموعة';

  @override
  String get groupNameLabel => 'اسم المجموعة';

  @override
  String get deviceLabelLabel => 'اسم هذا الجهاز';

  @override
  String get deviceLabelDefault => 'جهازي';

  @override
  String get shareTokenLabel => 'رمز الدعوة';

  @override
  String get shareTokenHint => 'الصق الرمز الذي أرسله إليك أحد أعضاء المجموعة';

  @override
  String groupCurrent(String name) {
    return 'المجموعة: $name';
  }

  @override
  String get shareTokenExplain =>
      'أرسل هذا الرمز إلى الأجهزة التي ينبغي أن تنضم إلى المجموعة. يمكن لأي شخص يملكه الانضمام.';

  @override
  String get shareTokenCopy => 'نسخ الرمز';

  @override
  String get shareTokenCopied => 'تم نسخ الرمز';

  @override
  String get shareTokenRotate => 'رمز جديد';

  @override
  String get shareTokenRotateConfirm =>
      'لن يسمح الرمز القديم بالانضمام بعد الآن. لا يتأثر الأجهزة الموجودة في المجموعة بالفعل.';

  @override
  String get groupLeave => 'مغادرة المجموعة';

  @override
  String get groupLeaveConfirm =>
      'سيغادر هذا الجهاز المجموعة. تبقى الألعاب المشتركة على هذا الجهاز لكنها لن تُزامَن بعد الآن.';

  @override
  String get groupLeft => 'غادرت المجموعة';

  @override
  String get groupJoined => 'انضممت إلى المجموعة';

  @override
  String get clearServerLeavesGroup =>
      'مسح الخادم يعني مغادرة المجموعة. تبقى الألعاب المشتركة على هذا الجهاز.';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String syncStatusIdle(String time) {
    return 'تمت المزامنة في $time';
  }

  @override
  String get syncStatusSyncing => 'جارٍ المزامنة…';

  @override
  String get syncStatusOffline =>
      'تعذّر الوصول إلى الخادم — ستُرسل التغييرات لاحقًا';

  @override
  String get syncStatusUnauthorized =>
      'لم يعد الخادم يقبل هذا الجهاز. غادر المجموعة ثم انضم إليها من جديد.';

  @override
  String get syncStatusError => 'خطأ في الخادم أثناء المزامنة';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير معلق',
      many: '$count تغييرًا معلقًا',
      few: '$count تغييرات معلقة',
      two: 'تغييران معلقان',
      one: 'تغيير واحد معلق',
      zero: 'لا تغييرات معلقة',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رفض الخادم $count تغيير',
      many: 'رفض الخادم $count تغييرًا',
      few: 'رفض الخادم $count تغييرات',
      two: 'رفض الخادم تغييرين',
      one: 'رفض الخادم تغييرًا واحدًا',
      zero: 'لم يرفض الخادم أي تغيير',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'رمز دعوة غير معروف أو تم استبداله';

  @override
  String get groupErrorRateLimited =>
      'محاولات كثيرة جدًا. أعد المحاولة بعد دقيقة.';

  @override
  String get groupErrorUnreachable => 'تعذّر الوصول إلى الخادم';

  @override
  String get groupErrorServer => 'خطأ في الخادم';

  @override
  String get shareWithGroup => 'مشاركة مع المجموعة';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'ستتمكن أجهزة $name من رؤية هذه اللعبة وتعديلها';
  }

  @override
  String shareGameConfirm(String name) {
    return 'ستُرسل اللعبة ولاعبوها ونتائجها وتعليقاتها إلى $name. لا يمكن التراجع عن المشاركة.';
  }

  @override
  String get gameSharedDone => 'تمت مشاركة اللعبة مع المجموعة';

  @override
  String get gameSharedBadge => 'لعبة مشتركة';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'لا يمكن مشاركة هذه الأسماء: $names. استخدم الحروف أو الأرقام أو المسافات أو الشرطات أو الفواصل العلوية أو النقاط (32 حرفًا كحد أقصى).';
  }

  @override
  String roundRenumbered(int number) {
    return 'سبق إدخال هذه الجولة على جهاز آخر، لذا أصبحت الجولة رقم $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'حُذفت اللعبة «$name» على جهاز آخر';
  }

  @override
  String get groupDevices => 'الأجهزة';

  @override
  String get groupDevicesExplain =>
      'يمكنك هنا إزالة هاتف مفقود أو مُباع من المجموعة.';

  @override
  String get groupDeviceThisOne => 'هذا الجهاز';

  @override
  String groupDeviceLastSeen(String date) {
    return 'آخر ظهور: $date';
  }

  @override
  String get groupDeviceRevoke => 'إزالة';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'هل تريد إزالة «$label» من المجموعة؟ لن تتم مزامنته بعد الآن. سيتغير رمز الدعوة أيضًا: يحتفظ الأعضاء بإمكانية الوصول، لكن يجب مشاركة الرمز الجديد لدعوة أي شخص.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return 'تمت إزالة «$label». تغيّر رمز الدعوة.';
  }

  @override
  String get reportCommentary => 'الإبلاغ عن هذا التعليق';

  @override
  String get reportCommentarySubject =>
      'CountScore — بلاغ عن تعليق ذكاء اصطناعي';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'ما المشكلة في هذا التعليق المُنشأ بالذكاء الاصطناعي؟\n\n\n---\nالمرجع: $reference\nالتعليق:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'لم يتم العثور على تطبيق بريد إلكتروني. راسلنا على $email للإبلاغ عن هذا التعليق.';
  }

  @override
  String get gameRulesTitle => 'قواعد اللعبة';

  @override
  String get gameRulesInApp => 'في CountScore';

  @override
  String get gameRulesSection => 'القواعد';

  @override
  String get gameRulesNoElimination => 'لا إقصاء أثناء اللعب';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'يُقصى اللاعب عند تجاوز $threshold نقطة';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'يُقصى اللاعب عند النزول تحت $threshold نقطة';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'تنتهي المباراة بمجرد تجاوز أحد اللاعبين $threshold نقطة';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'تنتهي المباراة بمجرد نزول أحد اللاعبين تحت $threshold نقطة';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'تنتهي المباراة عندما يتجاوز جميع اللاعبين إلا واحدًا $threshold نقطة';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'تنتهي المباراة عندما ينزل جميع اللاعبين إلا واحدًا تحت $threshold نقطة';
  }

  @override
  String get gameRulesNoEnd =>
      'لا نهاية تلقائية: أنت من يقرر متى تنتهي المباراة';

  @override
  String get gameRulesEmptyTitle => 'لا توجد قواعد بعد';

  @override
  String get gameRulesEmptyHint =>
      'دوّن كيف تُحتسب النقاط على طاولتك، فتصبح النسخة واحدة للجميع.';

  @override
  String get gameRulesWrite => 'اكتب القواعد';

  @override
  String get gameRulesEditTitle => 'تعديل القواعد';

  @override
  String get gameRulesEditorHint => 'قواعد طاولتك. صيغة Markdown مدعومة.';

  @override
  String get gameRulesFromGroup => 'قواعد مجموعتك';

  @override
  String get gameRulesRestoreDefault => 'استعادة القواعد الأصلية';

  @override
  String get gameRulesSaved => 'تم حفظ القواعد';

  @override
  String get gameRulesRestored => 'تمت استعادة القواعد الأصلية';

  @override
  String get gameRulesDisclaimer =>
      'مُلخَّص كُتب لـ CountScore استنادًا إلى القواعد الشائعة. أسماء الألعاب ملك لأصحابها وتُذكر لغرض الوصف فقط.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameUno => 'أونو';

  @override
  String get gameTypeNameScrabble => 'سكرابل';

  @override
  String get gameTypeNameOther => 'أخرى';

  @override
  String get gameTypeNameSkyjo => 'سكايجو';

  @override
  String get gameTypeNamePresident => 'الرئيس';

  @override
  String get gameTypeNameBelote => 'بيلوت';

  @override
  String get gameTypeNameTarot => 'تاروت';

  @override
  String get gameTypeNameBridge => 'بريدج';

  @override
  String get gameTypeNameRami => 'رامي';

  @override
  String get gameTypeNameCoinche => 'كوانش';

  @override
  String get gameTypeNameYahtzee => 'ياتزي';

  @override
  String get gameTypeNamePhase10 => 'فيز 10';

  @override
  String get gameTypeNameFlip7 => 'فليب 7';

  @override
  String get gameTypeNameMilleBornes => 'ميل بورن';

  @override
  String get gameTypeNameRummikub => 'روميكوب';

  @override
  String get gameTypeNameSixNimmt => 'خذ 6';

  @override
  String get gameTypeNameQwirkle => 'كويركل';

  @override
  String get gameTypeNameFarkle => 'فاركل';

  @override
  String get gameTypeNameCanasta => 'كاناستا';

  @override
  String get gameTypeNameWizard => 'ويزارد';

  @override
  String get gameTypeNameTriomino => 'تريومينو';

  @override
  String get groupDeviceOwner => 'المالك';

  @override
  String get groupDeviceMakeOwner => 'تعيين مالكًا';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'تسليم المجموعة إلى «$label»؟ لن يتمكن هذا الجهاز بعد ذلك من إزالة الأجهزة أو تغيير رمز الدعوة.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return 'أصبح «$label» مالك المجموعة.';
  }

  @override
  String get groupDevicesExplainMember =>
      'لا يمكن إلا لمالك المجموعة إزالة جهاز أو تغيير رمز الدعوة.';

  @override
  String get groupErrorNotOwner => 'هذا الإجراء متاح لمالك المجموعة فقط';

  @override
  String get whoStarts => 'من يبدأ؟';

  @override
  String get whoStartsAgain => 'اسحب مجددًا';

  @override
  String get resumeGame => 'استئناف';

  @override
  String get recentGames => 'الأخيرة';

  @override
  String get gameInProgress => 'جارية';

  @override
  String roundNumber(int number) {
    return 'الجولة $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name في الصدارة · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'فاز بها $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: 'المركز $rank',
      many: 'المركز $rank',
      few: 'المركز $rank',
      two: 'المركز $rank',
      one: 'المركز $rank',
      zero: 'المركز $rank',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'صف لكل لاعب';

  @override
  String get boardViewLanes => 'عمود لكل لاعب';

  @override
  String get boardSeatOrder => 'ترتيب اللعب';

  @override
  String boardRoundShort(int number) {
    return 'ج$number';
  }

  @override
  String get boardPlayer => 'اللاعب';

  @override
  String get boardTotal => 'المجموع';

  @override
  String get boardLeader => 'في الصدارة';

  @override
  String get groupSettingsTitle => 'التعليقات والاستهلاك';

  @override
  String get groupSettingsDescription =>
      'أسلوب ولغة التعليقات التي يكتبها الخادم لمباريات المجموعة. يمكن لأي عضو تغييرهما.';

  @override
  String get groupCommentStyle => 'أسلوب التعليقات';

  @override
  String get groupCommentStyleNarrative => 'سردي';

  @override
  String get groupCommentStyleHumorous => 'فكاهي';

  @override
  String get groupCommentStyleAnalytical => 'تحليلي';

  @override
  String get groupCommentLanguage => 'لغة التعليقات';

  @override
  String get groupSettingsSaved => 'تم حفظ إعدادات المجموعة';

  @override
  String get groupUsageTitle => 'استهلاك النموذج اللغوي هذا الشهر';

  @override
  String groupUsageAmount(String used, String budget) {
    return 'أُنفق $used من $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'يُعاد التعيين في $date';
  }

  @override
  String get statsBestWinRate => 'أفضل نسبة فوز';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins انتصار من $games',
      many: '$wins انتصارًا من $games',
      few: '$wins انتصارات من $games',
      two: 'فوزان من $games',
      one: 'فوز واحد من $games',
      zero: 'لا فوز من $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'اللاعب';

  @override
  String get statsColumnGames => 'المباريات';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مباراة · غير مصنّف بعد',
      many: '$count مباراة · غير مصنّف بعد',
      few: '$count مباريات · غير مصنّف بعد',
      two: 'مباراتان · غير مصنّف بعد',
      one: 'مباراة واحدة · غير مصنّف بعد',
      zero: 'لا مباريات · غير مصنّف بعد',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'التصنيف ابتداءً من $count مباراة منتهية. المس لاعبًا لعرض بطاقته.',
      many: 'التصنيف ابتداءً من $count مباراة منتهية. المس لاعبًا لعرض بطاقته.',
      few: 'التصنيف ابتداءً من $count مباريات منتهية. المس لاعبًا لعرض بطاقته.',
      two: 'التصنيف ابتداءً من مباراتين منتهيتين. المس لاعبًا لعرض بطاقته.',
      one: 'التصنيف ابتداءً من مباراة منتهية واحدة. المس لاعبًا لعرض بطاقته.',
      zero: 'التصنيف ابتداءً من $count مباراة منتهية. المس لاعبًا لعرض بطاقته.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مباراة',
      many: 'مباراة',
      few: 'مباريات',
      two: 'مباراتان',
      one: 'مباراة',
      zero: 'مباراة',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انتصار',
      many: 'انتصارًا',
      few: 'انتصارات',
      two: 'فوزان',
      one: 'فوز',
      zero: 'فوز',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'متوسط المركز';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المركز، آخر $count مباراة',
      many: 'المركز، آخر $count مباراة',
      few: 'المركز، آخر $count مباريات',
      two: 'المركز، آخر مباراتين',
      one: 'المركز، آخر مباراة',
      zero: 'المركز',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'في تحسّن';

  @override
  String get statsTrendDeclining => 'في تراجع';

  @override
  String get statsTrendSteady => 'ثابت';

  @override
  String statsRankOrdinal(String rank) {
    return 'المركز $rank';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة: $count انتصار',
      many: 'سلسلة: $count انتصارًا',
      few: 'سلسلة: $count انتصارات',
      two: 'سلسلة: فوزان',
      one: 'سلسلة: فوز واحد',
      zero: 'لا سلسلة انتصارات',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'الرقم القياسي: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'في $gameType';
  }

  @override
  String get statsAverageTotal => 'متوسط المجموع النهائي';

  @override
  String get statsBestTotal => 'أفضل مجموع نهائي';

  @override
  String get statsMostBeaten => 'الخصم الأكثر هزيمة';

  @override
  String get statsOpenPlayerCard => 'عرض بطاقة اللاعب';

  @override
  String get shareResult => 'مشاركة النتيجة';

  @override
  String get shareAnalysis => 'مشاركة التحليل';

  @override
  String shareResultSubject(String gameName) {
    return 'النتيجة: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'مباراة $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points نقطة',
      many: '$points نقطة',
      few: '$points نقاط',
      two: 'نقطتان',
      one: 'نقطة واحدة',
      zero: '$points نقطة',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'سُجّلت النقاط باستخدام $appName: $url';
  }

  @override
  String get shareFailed => 'تعذّر فتح المشاركة';
}
