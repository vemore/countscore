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
  String get createdOn => 'أنشئت في';

  @override
  String get newWithSamePlayers => 'جديدة بنفس اللاعبين';

  @override
  String get newGameSuffix => '(جديدة)';

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
  String get addRound => 'إضافة جولة';

  @override
  String get score => 'النتيجة';

  @override
  String get enterScore => 'أدخل النتيجة';

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
  String get version => 'الإصدار 1.0.1';

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
