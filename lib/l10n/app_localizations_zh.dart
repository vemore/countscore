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
  String get newWithSamePlayers => '使用相同玩家创建新游戏';

  @override
  String get playAgain => '再来一局';

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
  String get lowestScoreWins => '最低分获胜';

  @override
  String get highestScoreWins => '最高分获胜';

  @override
  String get players => '玩家';

  @override
  String get add => '添加';

  @override
  String get pleaseEnterName => '请输入名称';

  @override
  String get clear => '清除';

  @override
  String get remove => '移除';

  @override
  String get game => '游戏';

  @override
  String get editGame => '编辑游戏';

  @override
  String get editGameDialogTitle => '编辑游戏';

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
  String boardRoundButton(int round) {
    return '第 $round 轮';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · 第 $round 轮';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · 第 $round 轮 · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return '录入后总分：$total';
  }

  @override
  String keypadNext(String player) {
    return '下一位\n$player';
  }

  @override
  String get keypadValidateRound => '确认本轮';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => '切换正负号';

  @override
  String get keypadBackspace => '删除一位数字';

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
  String get byGameType => '按游戏类型';

  @override
  String get rate => '比率';

  @override
  String version(String version) {
    return '版本 $version';
  }

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
  String get featureGroupSharing => '群组共享';

  @override
  String get featureGameAnalysis => 'AI 对局分析';

  @override
  String get rateApp => '为 CountScore 评分';

  @override
  String get credits => '致谢';

  @override
  String get appIconCredit => '应用图标';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get search => '搜索';

  @override
  String get newPlayerName => '新玩家名称';

  @override
  String get noPlayersFound => '未找到玩家';

  @override
  String get close => '关闭';

  @override
  String get playerEliminationCondition => '玩家淘汰条件';

  @override
  String get gameOverCondition => '游戏结束条件';

  @override
  String get none => '无';

  @override
  String get overThreshold => '高于阈值';

  @override
  String get underThreshold => '低于阈值';

  @override
  String get firstPlayerOver => '第一位达到的玩家';

  @override
  String get firstPlayerUnder => '第一位玩家低于';

  @override
  String get lastPlayerOver => '最后一位玩家超过';

  @override
  String get lastPlayerUnder => '最后一位玩家低于';

  @override
  String get threshold => '阈值';

  @override
  String get conditionType => '条件类型';

  @override
  String get continuePlay => '继续游戏';

  @override
  String gameEndWinner(String name) {
    return '$name 获胜';
  }

  @override
  String gameEndTie(String names) {
    return '平局：$names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 轮',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => '最低分获胜';

  @override
  String get gameEndHighestWins => '最高分获胜';

  @override
  String get gameEndAnalysis => '分析';

  @override
  String get gameEndResults => '结果';

  @override
  String get endGame => '结束游戏';

  @override
  String get reopenGame => '重新开始游戏';

  @override
  String get gameFinished => '已结束';

  @override
  String get undo => '撤销';

  @override
  String get gameReopened => '游戏已重新开启';

  @override
  String get comment => '备注';

  @override
  String get enterComment => '输入备注';

  @override
  String get analyzeGame => '分析游戏';

  @override
  String get analysisTitle => '游戏分析';

  @override
  String get analysisStyle => '分析风格';

  @override
  String get analysisStyleProfessor => '教授';

  @override
  String get analysisStyleCommentator => '体育解说';

  @override
  String get analysisStyleDocumentary => '动物纪录片';

  @override
  String get analysisStyleNoir => '侦探';

  @override
  String get analysisStyleBard => '吟游诗人';

  @override
  String get analysisStyleCoach => '教练';

  @override
  String get analysisStyleConsultant => '顾问';

  @override
  String get analysisStyleAstrologer => '占星师';

  @override
  String get analysisStyleRealityTv => '真人秀';

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
  String get analysisErrorGroupBudget => '你的群组本月的分析预算已用完，将在下月初重置。';

  @override
  String get analysisStyleGroupDefault => '未选择风格：此共享对局将按群组的风格和语言进行分析。';

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

  @override
  String get groupDevices => '设备';

  @override
  String get groupDevicesExplain => '可在此将丢失或出售的手机移出群组。';

  @override
  String get groupDeviceThisOne => '本设备';

  @override
  String groupDeviceLastSeen(String date) {
    return '最近在线：$date';
  }

  @override
  String get groupDeviceRevoke => '移除';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '将“$label”移出群组？它将无法再同步。邀请码也会更换：现有成员不受影响，但邀请他人时需分享新的邀请码。';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '已移除“$label”。邀请码已更换。';
  }

  @override
  String get reportCommentary => '举报此评论';

  @override
  String get reportCommentarySubject => 'CountScore — 举报 AI 评论';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return '这条 AI 生成的评论有什么问题？\n\n\n---\n参考：$reference\n评论：\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return '未找到电子邮件应用。请发送邮件至 $email 举报此评论。';
  }

  @override
  String get gameRulesTitle => '游戏规则';

  @override
  String get gameRulesInApp => '在 CountScore 中';

  @override
  String get gameRulesSection => '规则';

  @override
  String get gameRulesNoElimination => '对局中不会淘汰玩家';

  @override
  String gameRulesEliminationOver(int threshold) {
    return '超过 $threshold 分的玩家被淘汰';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return '低于 $threshold 分的玩家被淘汰';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return '当有玩家达到 $threshold 分时，对局结束';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return '当有玩家低于 $threshold 分时，对局结束';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return '当除一名玩家外所有人都超过 $threshold 分时，对局结束';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return '当除一名玩家外所有人都低于 $threshold 分时，对局结束';
  }

  @override
  String get gameRulesNoEnd => '没有自动结束：由你决定何时收局';

  @override
  String get gameRulesEmptyTitle => '还没有规则';

  @override
  String get gameRulesEmptyHint => '把你们这桌的计分方式写下来，大家就有了同一个版本。';

  @override
  String get gameRulesWrite => '编写规则';

  @override
  String get gameRulesEditTitle => '编辑规则';

  @override
  String get gameRulesEditorHint => '你们这桌的规则。支持 Markdown。';

  @override
  String get gameRulesFromGroup => '你们小组的规则';

  @override
  String get gameRulesRestoreDefault => '恢复原始规则';

  @override
  String get gameRulesSaved => '规则已保存';

  @override
  String get gameRulesRestored => '已恢复原始规则';

  @override
  String get gameRulesDisclaimer =>
      '本摘要由 CountScore 依据通行玩法编写。游戏名称归各自所有者所有，此处仅作描述性使用。';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'UNO';

  @override
  String get gameTypeNameUnoSortKey => 'UNO';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameScrabbleSortKey => 'Scrabble';

  @override
  String get gameTypeNameOther => '其他';

  @override
  String get gameTypeNameOtherSortKey => 'qi2 ta1';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNameSkyjoSortKey => 'Skyjo';

  @override
  String get gameTypeNamePresident => '总统';

  @override
  String get gameTypeNamePresidentSortKey => 'zong3 tong3';

  @override
  String get gameTypeNameBelote => '贝洛特';

  @override
  String get gameTypeNameBeloteSortKey => 'bei4 luo4 te4';

  @override
  String get gameTypeNameTarot => '塔罗牌';

  @override
  String get gameTypeNameTarotSortKey => 'ta3 luo2 pai2';

  @override
  String get gameTypeNameBridge => '桥牌';

  @override
  String get gameTypeNameBridgeSortKey => 'qiao2 pai2';

  @override
  String get gameTypeNameRami => '拉米';

  @override
  String get gameTypeNameRamiSortKey => 'la1 mi3';

  @override
  String get gameTypeNameCoinche => 'Coinche';

  @override
  String get gameTypeNameCoincheSortKey => 'Coinche';

  @override
  String get gameTypeNameYahtzee => '快艇骰子';

  @override
  String get gameTypeNameYahtzeeSortKey => 'kuai4 ting3 tou2 zi5';

  @override
  String get gameTypeNamePhase10 => '阶段 10';

  @override
  String get gameTypeNamePhase10SortKey => 'jie1 duan4 10';

  @override
  String get gameTypeNameFlip7 => '翻牌 7';

  @override
  String get gameTypeNameFlip7SortKey => 'fan1 pai2 7';

  @override
  String get gameTypeNameMilleBornes => 'Mille Bornes';

  @override
  String get gameTypeNameMilleBornesSortKey => 'Mille Bornes';

  @override
  String get gameTypeNameRummikub => '拉密';

  @override
  String get gameTypeNameRummikubSortKey => 'la1 mi4';

  @override
  String get gameTypeNameSixNimmt => '6 nimmt!';

  @override
  String get gameTypeNameSixNimmtSortKey => '6 nimmt!';

  @override
  String get gameTypeNameQwirkle => 'Qwirkle';

  @override
  String get gameTypeNameQwirkleSortKey => 'Qwirkle';

  @override
  String get gameTypeNameFarkle => 'Farkle';

  @override
  String get gameTypeNameFarkleSortKey => 'Farkle';

  @override
  String get gameTypeNameCanasta => '凯纳斯特';

  @override
  String get gameTypeNameCanastaSortKey => 'kai3 na4 si1 te4';

  @override
  String get gameTypeNameWizard => 'Wizard';

  @override
  String get gameTypeNameWizardSortKey => 'Wizard';

  @override
  String get gameTypeNameTriomino => '三角骨牌';

  @override
  String get gameTypeNameTriominoSortKey => 'san1 jiao3 gu3 pai2';

  @override
  String get groupDeviceOwner => '所有者';

  @override
  String get groupDeviceMakeOwner => '设为所有者';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return '将群组移交给“$label”？本设备将无法再移除设备或更换邀请码。';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '“$label”现在是群组的所有者。';
  }

  @override
  String get groupDevicesExplainMember => '只有群组所有者才能移除设备或更换邀请码。';

  @override
  String get groupErrorNotOwner => '只有群组所有者才能执行此操作';

  @override
  String get whoStarts => '谁先开始？';

  @override
  String get whoStartsAgain => '重新抽取';

  @override
  String get resumeGame => '继续';

  @override
  String get recentGames => '最近';

  @override
  String get gameInProgress => '进行中';

  @override
  String roundNumber(int number) {
    return '第$number轮';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name领先 · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name获胜';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '第$rank',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => '每位玩家一行';

  @override
  String get boardViewLanes => '每位玩家一列';

  @override
  String get boardSeatOrder => '出牌顺序';

  @override
  String boardRoundShort(int number) {
    return '$number轮';
  }

  @override
  String get boardPlayer => '玩家';

  @override
  String get boardTotal => '总分';

  @override
  String get boardLeader => '领先';

  @override
  String get groupSettingsTitle => '评论与用量';

  @override
  String get groupSettingsDescription => '服务器为本群组对局撰写的评论的风格和语言。任何成员都可以修改。';

  @override
  String get groupCommentStyle => '评论风格';

  @override
  String get groupCommentStyleNarrative => '叙事';

  @override
  String get groupCommentStyleHumorous => '幽默';

  @override
  String get groupCommentStyleAnalytical => '分析';

  @override
  String get groupCommentLanguage => '评论语言';

  @override
  String get groupSettingsSaved => '群组设置已保存';

  @override
  String get groupUsageTitle => '本月 LLM 用量';

  @override
  String groupUsageAmount(String used, String budget) {
    return '已用 $used，预算 $budget';
  }

  @override
  String groupUsageResets(String date) {
    return '$date 重置';
  }

  @override
  String get statsBestWinRate => '最高胜率';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$games 局 $wins 胜',
      zero: '$games 局未胜',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => '玩家';

  @override
  String get statsColumnGames => '局数';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 局 · 暂未排名',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '完成 $count 局后参与排名。点按玩家查看其卡片。',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '局',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '胜',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => '平均名次';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '名次，最近 $count 局',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => '上升中';

  @override
  String get statsTrendDeclining => '下滑中';

  @override
  String get statsTrendSteady => '稳定';

  @override
  String statsRankOrdinal(String rank) {
    return '第$rank';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连胜 $count 局',
      zero: '暂无连胜',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return '纪录：$total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType 战绩';
  }

  @override
  String get statsAverageTotal => '平均最终总分';

  @override
  String get statsBestTotal => '最佳最终总分';

  @override
  String get statsMostBeaten => '最常击败的对手';

  @override
  String get statsOpenPlayerCard => '打开玩家卡片';

  @override
  String get shareResult => '分享结果';

  @override
  String get shareAnalysis => '分享分析';

  @override
  String shareResultSubject(String gameName) {
    return '结果：$gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date 的对局';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points 分',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return '用 $appName 记分：$url';
  }

  @override
  String get shareFailed => '无法打开分享';

  @override
  String get newGameNameLabel => '名称';

  @override
  String get newGameGameLabel => '游戏';

  @override
  String newGameAllGames(int count) {
    return '全部游戏（$count）';
  }

  @override
  String get newGamePlayersLabel => '玩家 · 座位顺序';

  @override
  String get newGameDragToReorder => '拖动以调整顺序';

  @override
  String get newGameDealer => '发牌';

  @override
  String get newGameAddPlayer => '添加玩家';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '开始 · $count 名玩家',
      zero: '开始',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => '谁来玩？';

  @override
  String get whoIsPlayingSearchHint => '姓名，或新玩家';

  @override
  String get whoIsPlayingFrequent => '常和你一起玩';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '与“$gameName”相同的玩家';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '创建“$name”';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '添加 $count 名玩家',
      zero: '完成',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return '游戏 $number';
  }
}
