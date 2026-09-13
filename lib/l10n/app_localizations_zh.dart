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
  String get filterGames => '筛选游戏';

  @override
  String get applyFilter => '应用';

  @override
  String get resetFilter => '重置';

  @override
  String get selectGameType => '选择游戏类型';

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
  String get editGame => '编辑游戏';

  @override
  String get editGameDialogTitle => '编辑游戏';

  @override
  String get gameSettings => '游戏设置';

  @override
  String get removePlayer => '移除玩家';

  @override
  String get addPlayerToGame => '添加玩家';

  @override
  String get warningRemovePlayer => '警告！移除此玩家将删除该玩家在此游戏中的所有分数。此操作不可撤销。';

  @override
  String confirmRemovePlayer(String playerName) {
    return '您确定要从此游戏中移除 $playerName 吗？';
  }

  @override
  String get playerRemoved => '玩家已从游戏中移除';

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
  String get version => '版本 1.0.0';

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
  String get searchOrCreate => '搜索 / 创建';

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

  @override
  String get comment => '备注';

  @override
  String get enterComment => '输入备注';

  @override
  String get analyzeGame => '分析游戏';

  @override
  String get analysisTitle => '游戏分析';

  @override
  String get generatingAnalysis => '正在生成分析…';

  @override
  String get generateAnalysis => '生成分析';

  @override
  String get regenerateAnalysis => '重新生成分析';

  @override
  String get deleteAnalysis => '删除分析';

  @override
  String get confirmRegenerateAnalysis => '重新生成？当前分析将被替换。';

  @override
  String get confirmDeleteAnalysis => '删除此游戏的分析？';

  @override
  String get analysisError => '生成分析失败';

  @override
  String get analysisErrorUnavailable => '分析服务器暂时不可用，请稍后再试。';

  @override
  String analysisErrorStatus(int status) {
    return '生成分析失败 (HTTP $status)';
  }

  @override
  String get retry => '重试';

  @override
  String analysisGeneratedAt(String date) {
    return '生成于 $date';
  }

  @override
  String get serverSection => '服务器';

  @override
  String get backendUrlLabel => '服务器地址';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      '联网功能需要一台 CountScore 服务器。请从 backend/ 目录自行部署，并在此填写其地址。未配置服务器时，任何数据都不会离开本设备。';

  @override
  String get backendNotConfigured => '未配置服务器';

  @override
  String get backendUrlInvalid =>
      '地址无效。请输入完整的 URL，例如 https://countscore.example.com';

  @override
  String get backendUrlInsecure => 'http:// 仅在局域网内可用。公网服务器请使用 https://。';

  @override
  String get testConnection => '测试连接';

  @override
  String get connectionOk => '服务器响应正常';

  @override
  String get connectionFailed => '服务器无响应';

  @override
  String get serverUrlSaved => '服务器已保存';

  @override
  String get analysisRequiresBackend => '此分析需要一台服务器。请在设置中配置。';

  @override
  String get openSettings => '打开设置';

  @override
  String get serverUrlCleared => '服务器已清除';

  @override
  String get groupSection => '群组';

  @override
  String get groupDescription =>
      '与群组中的其他设备共享对局。共享的对局及其玩家、分数、评论和分析会发送到您的服务器；其他对局只保留在本设备上。';

  @override
  String get groupNeedsServer => '请先在上方配置服务器。';

  @override
  String get groupCreate => '创建群组';

  @override
  String get groupJoin => '加入群组';

  @override
  String get groupNameLabel => '群组名称';

  @override
  String get deviceLabelLabel => '本设备名称';

  @override
  String get deviceLabelDefault => '我的设备';

  @override
  String get shareTokenLabel => '邀请码';

  @override
  String get shareTokenHint => '粘贴群组成员发给您的邀请码';

  @override
  String groupCurrent(String name) {
    return '群组：$name';
  }

  @override
  String get shareTokenExplain => '把此邀请码发给要加入群组的设备。任何拿到它的人都可以加入。';

  @override
  String get shareTokenCopy => '复制邀请码';

  @override
  String get shareTokenCopied => '已复制邀请码';

  @override
  String get shareTokenRotate => '更换邀请码';

  @override
  String get shareTokenRotateConfirm => '旧邀请码将无法再用于加入群组。已在群组中的设备不受影响。';

  @override
  String get groupLeave => '退出群组';

  @override
  String get groupLeaveConfirm => '本设备将退出群组。共享的对局仍保留在本设备上，但不再同步。';

  @override
  String get groupLeft => '已退出群组';

  @override
  String get groupJoined => '已加入群组';

  @override
  String get clearServerLeavesGroup => '清除服务器会退出群组。共享的对局仍保留在本设备上。';

  @override
  String get syncNow => '立即同步';

  @override
  String syncStatusIdle(String time) {
    return '已于 $time 同步';
  }

  @override
  String get syncStatusSyncing => '正在同步…';

  @override
  String get syncStatusOffline => '无法连接服务器——更改将稍后发送';

  @override
  String get syncStatusUnauthorized => '服务器不再接受本设备。请退出群组后重新加入。';

  @override
  String get syncStatusError => '同步时服务器出错';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项更改待发送',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '服务器拒绝了 $count 项更改',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => '邀请码无效或已被更换';

  @override
  String get groupErrorRateLimited => '尝试次数过多，请一分钟后再试。';

  @override
  String get groupErrorUnreachable => '无法连接服务器';

  @override
  String get groupErrorServer => '服务器错误';

  @override
  String get shareWithGroup => '与群组共享';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name 中的设备将能查看和编辑此对局';
  }

  @override
  String shareGameConfirm(String name) {
    return '此对局及其玩家、分数和评论将发送到 $name。共享后无法撤销。';
  }

  @override
  String get gameSharedDone => '对局已与群组共享';

  @override
  String get gameSharedBadge => '共享对局';

  @override
  String invalidPlayerNamesForSync(String names) {
    return '以下名称无法共享：$names。请只使用字母、数字、空格、连字符、撇号或句点（最多 32 个字符）。';
  }

  @override
  String roundRenumbered(int number) {
    return '该局已在另一台设备上录入，因此改为第 $number 局。';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '对局“$name”已在另一台设备上删除';
  }
}
