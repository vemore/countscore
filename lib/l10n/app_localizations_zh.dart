// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => '主页';

  @override
  String get playersListTitle => '玩家列表';

  @override
  String get gameTypesTitle => '游戏类型';

  @override
  String get settingsTitle => '设置';

  @override
  String get aboutTitle => '关于';

  @override
  String get newGame => '新游戏';

  @override
  String get noGames => '没有游戏';

  @override
  String get noGamesOfThisType => '没有此类型的游戏';

  @override
  String get createFirstGame => '创建您的第一个游戏';

  @override
  String get createdOn => '创建于';

  @override
  String get newWithSamePlayers => '使用相同玩家创建新游戏';

  @override
  String get newGameSuffix => '(新)';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get confirmDeletion => '确认删除';

  @override
  String confirmDeleteGame(String name) {
    return '您确定要删除游戏 $name 吗?';
  }

  @override
  String get cancel => '取消';

  @override
  String get renameGame => '重命名游戏';

  @override
  String get gameName => '游戏名称';

  @override
  String get save => '保存';

  @override
  String get filterByGameType => '按游戏类型筛选';

  @override
  String get allGames => '所有游戏';

  @override
  String get gameType => '游戏类型';

  @override
  String get loadingGameTypes => '正在加载游戏类型...';

  @override
  String get winRule => '胜利规则';

  @override
  String get lowestScoreWins => '最低分获胜';

  @override
  String get highestScoreWins => '最高分获胜';

  @override
  String get lowestScoreExample => '例如:高尔夫、红心大战';

  @override
  String get highestScoreExample => '例如:拉米、桥牌';

  @override
  String get players => '玩家';

  @override
  String get add => '添加';

  @override
  String get pleaseEnterName => '请输入名称';

  @override
  String get atLeast2PlayersRequired => '至少需要2名玩家';

  @override
  String playerNumber(int index) {
    return '玩家$index';
  }

  @override
  String get selectPlayer => '选择玩家...';

  @override
  String get clear => '清除';

  @override
  String get remove => '移除';

  @override
  String get createGame => '创建游戏';

  @override
  String get game => '游戏';

  @override
  String get deleteLastRound => '删除最后一轮';

  @override
  String get confirm => '确认';

  @override
  String get confirmDeleteLastRound => '删除最后一轮?';

  @override
  String get noPlayersInGame => '此游戏中没有玩家';

  @override
  String get round => '轮次';

  @override
  String get addRound => '添加轮次';

  @override
  String get score => '分数';

  @override
  String get enterScore => '输入分数';

  @override
  String get appearance => '外观';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get system => '系统';

  @override
  String get screen => '屏幕';

  @override
  String get keepScreenAwake => '保持屏幕常亮';

  @override
  String get keepScreenAwakeDescription => '防止游戏期间屏幕休眠';

  @override
  String get backup => '备份';

  @override
  String get exportDatabase => '导出数据库';

  @override
  String get exportDatabaseDescription => '将所有游戏保存到文件';

  @override
  String get databaseExportedTo => '数据库已导出至:';

  @override
  String get errorDuringExport => '导出时出错:';

  @override
  String get importDatabase => '导入数据库';

  @override
  String get importDatabaseDescription => '从备份文件恢复您的游戏';

  @override
  String get confirmation => '确认';

  @override
  String get importWarning => '导入将替换所有当前数据。导入前会自动创建备份。\n\n您要继续吗?';

  @override
  String get import => '导入';

  @override
  String get databaseImportedSuccessfully => '数据库导入成功';

  @override
  String get importSuccessful => '导入成功';

  @override
  String get importSuccessMessage => '数据库已成功导入。\n\n应用程序现在将关闭。请重新打开以查看新数据。';

  @override
  String get ok => '确定';

  @override
  String get errorDuringImport => '导入时出错:';

  @override
  String get noPlayers => '没有玩家';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count位玩家: $names',
      one: '1位玩家: $names',
      zero: '没有玩家',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage => '创建游戏后\n玩家将显示在此处';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count场游戏',
      zero: '0场游戏',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count次胜利',
      zero: '0次胜利',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => '更改颜色';

  @override
  String get renamePlayer => '重命名玩家';

  @override
  String get newName => '新名称';

  @override
  String playerRenamedTo(String name) {
    return '玩家已重命名为 $name';
  }

  @override
  String get deletePlayer => '删除玩家';

  @override
  String confirmDeletePlayer(String name, int count) {
    return '您确定要删除 $name 吗?\n\n此玩家将从所有 $count 个游戏中删除。';
  }

  @override
  String playerDeleted(String name) {
    return '玩家 $name 已删除';
  }

  @override
  String get chooseColor => '选择颜色';

  @override
  String get noGameTypes => '没有游戏类型';

  @override
  String get predefined => '默认';

  @override
  String get edit => '编辑';

  @override
  String get newType => '新类型';

  @override
  String get editType => '编辑类型';

  @override
  String get newGameType => '新游戏类型';

  @override
  String get gameTypeName => '游戏类型名称';

  @override
  String get icon => '图标:';

  @override
  String get color => '颜色:';

  @override
  String get chooseIcon => '选择图标';

  @override
  String get nameIsRequired => '名称为必填项';

  @override
  String get create => '创建';

  @override
  String get ranking => '排名';

  @override
  String get noCurrentGame => '没有当前游戏';

  @override
  String get noScoresRecorded => '没有记录的分数';

  @override
  String get playerStatistics => '玩家统计';

  @override
  String get noStatisticsAvailable => '没有可用的统计数据';

  @override
  String get gamesPlayed => '已玩游戏';

  @override
  String get wins => '胜利';

  @override
  String get winRate => '胜率';

  @override
  String get overallStatistics => '总体统计';

  @override
  String get byGameType => '按游戏类型';

  @override
  String get rate => '比率';

  @override
  String get version => '版本 1.0.1';

  @override
  String get appDescription => '由Vincent Moreau开发的游戏会话分数管理应用';

  @override
  String get features => '功能';

  @override
  String get featureDifferentGameTypes => '不同的游戏类型';

  @override
  String get featurePlayerManagement => '玩家管理';

  @override
  String get featureDetailedStatistics => '详细统计';

  @override
  String get featureCustomization => '自定义';

  @override
  String get featureDarkLightTheme => '深色/浅色主题';

  @override
  String get credits => '致谢';

  @override
  String get appIconCredit => '应用图标';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => '选择玩家';

  @override
  String get search => '搜索';

  @override
  String get createNewPlayer => '创建新玩家';

  @override
  String get newPlayerName => '新玩家名称';

  @override
  String get noPlayersFound => '未找到玩家';

  @override
  String get allPlayersSelected => '所有玩家已被选择';

  @override
  String get close => '关闭';

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
