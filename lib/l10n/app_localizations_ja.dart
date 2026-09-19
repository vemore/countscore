// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get playersListTitle => 'プレイヤー一覧';

  @override
  String get gameTypesTitle => 'ゲームタイプ';

  @override
  String get settingsTitle => '設定';

  @override
  String get aboutTitle => 'アプリについて';

  @override
  String get newGame => '新しいゲーム';

  @override
  String get noGames => 'ゲームがありません';

  @override
  String get noGamesOfThisType => 'このタイプのゲームはありません';

  @override
  String get createFirstGame => '最初のゲームを作成';

  @override
  String get newWithSamePlayers => '同じプレイヤーで新規作成';

  @override
  String get playAgain => 'もう一度遊ぶ';

  @override
  String get rename => '名前を変更';

  @override
  String get delete => '削除';

  @override
  String get confirmDeletion => '削除の確認';

  @override
  String confirmDeleteGame(String name) {
    return 'ゲーム「$name」を本当に削除しますか？';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get renameGame => 'ゲーム名を変更';

  @override
  String get gameName => 'ゲーム名';

  @override
  String get save => '保存';

  @override
  String get allGames => 'すべてのゲーム';

  @override
  String get filterGames => 'ゲームを絞り込む';

  @override
  String get applyFilter => '適用';

  @override
  String get resetFilter => 'リセット';

  @override
  String get selectGameType => 'ゲームタイプを選択';

  @override
  String get gameType => 'ゲームタイプ';

  @override
  String get loadingGameTypes => 'ゲームタイプを読み込み中...';

  @override
  String get lowestScoreWins => '最低スコアが勝ち';

  @override
  String get highestScoreWins => '最高スコアが勝ち';

  @override
  String get players => 'プレイヤー';

  @override
  String get add => '追加';

  @override
  String get pleaseEnterName => '名前を入力してください';

  @override
  String get clear => 'クリア';

  @override
  String get remove => '削除';

  @override
  String get game => 'ゲーム';

  @override
  String get editGame => 'ゲームを編集';

  @override
  String get editGameDialogTitle => 'ゲームを編集';

  @override
  String get removePlayer => 'プレイヤーを削除';

  @override
  String get addPlayerToGame => 'プレイヤーを追加';

  @override
  String get warningRemovePlayer =>
      '警告！このプレイヤーを削除すると、このゲームからすべてのスコアが削除されます。この操作は元に戻せません。';

  @override
  String confirmRemovePlayer(String playerName) {
    return '本当に$playerNameをこのゲームから削除しますか？';
  }

  @override
  String get playerRemoved => 'プレイヤーがゲームから削除されました';

  @override
  String get deleteLastRound => '最後のラウンドを削除';

  @override
  String get confirm => '確認';

  @override
  String get confirmDeleteLastRound => '最後のラウンドを削除しますか？';

  @override
  String get noPlayersInGame => 'このゲームにプレイヤーがいません';

  @override
  String get round => 'ラウンド';

  @override
  String boardRoundButton(int round) {
    return 'ラウンド $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · ラウンド $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · ラウンド $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return '入力後の合計: $total';
  }

  @override
  String keypadNext(String player) {
    return '次へ\n$player';
  }

  @override
  String get keypadValidateRound => 'ラウンドを確定';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => '符号を切り替え';

  @override
  String get keypadBackspace => '1桁削除';

  @override
  String get appearance => '外観';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get system => 'システム';

  @override
  String get screen => '画面';

  @override
  String get keepScreenAwake => '画面をオンに保つ';

  @override
  String get keepScreenAwakeDescription => 'ゲーム中に画面がスリープするのを防ぎます';

  @override
  String get backup => 'バックアップ';

  @override
  String get exportDatabase => 'データベースをエクスポート';

  @override
  String get exportDatabaseDescription => 'すべてのゲームをファイルに保存';

  @override
  String get databaseExportedTo => 'データベースをエクスポートしました：';

  @override
  String get errorDuringExport => 'エクスポート中にエラー：';

  @override
  String get importDatabase => 'データベースをインポート';

  @override
  String get importDatabaseDescription => 'バックアップファイルからゲームを復元';

  @override
  String get confirmation => '確認';

  @override
  String get importWarning =>
      'インポートすると現在のすべてのデータが置き換えられます。インポート前に自動バックアップが作成されます。\n\n続行しますか？';

  @override
  String get import => 'インポート';

  @override
  String get databaseImportedSuccessfully => 'データベースのインポートに成功しました';

  @override
  String get importSuccessful => 'インポート成功';

  @override
  String get importSuccessMessage =>
      'データベースのインポートに成功しました。\n\nアプリを一度終了します。新しいデータを確認するには再度開いてください。';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'インポート中にエラー：';

  @override
  String get noPlayers => 'プレイヤーがいません';

  @override
  String get playersAppearMessage => 'ゲームを作成すると\nプレイヤーがここに表示されます';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countゲーム',
      zero: '0ゲーム',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count勝',
      zero: '0勝',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => '色を変更';

  @override
  String get renamePlayer => 'プレイヤー名を変更';

  @override
  String get newName => '新しい名前';

  @override
  String playerRenamedTo(String name) {
    return 'プレイヤー名を「$name」に変更しました';
  }

  @override
  String get deletePlayer => 'プレイヤーを削除';

  @override
  String confirmDeletePlayer(String name, int count) {
    return '本当に「$name」を削除しますか？\n\nこのプレイヤーは$countつのゲームから削除されます。';
  }

  @override
  String playerDeleted(String name) {
    return 'プレイヤー「$name」を削除しました';
  }

  @override
  String get chooseColor => '色を選択';

  @override
  String get noGameTypes => 'ゲームタイプがありません';

  @override
  String get edit => '編集';

  @override
  String get newType => '新しいタイプ';

  @override
  String get editType => 'タイプを編集';

  @override
  String get newGameType => '新しいゲームタイプ';

  @override
  String get gameTypeName => 'ゲームタイプ名';

  @override
  String get icon => 'アイコン：';

  @override
  String get color => '色：';

  @override
  String get chooseIcon => 'アイコンを選択';

  @override
  String get nameIsRequired => '名前は必須です';

  @override
  String get create => '作成';

  @override
  String get ranking => 'ランキング';

  @override
  String get noCurrentGame => '現在のゲームがありません';

  @override
  String get noScoresRecorded => '記録されたスコアがありません';

  @override
  String get playerStatistics => 'プレイヤー統計';

  @override
  String get noStatisticsAvailable => '統計情報がありません';

  @override
  String get gamesPlayed => 'プレイしたゲーム';

  @override
  String get wins => '勝利';

  @override
  String get winRate => '勝率';

  @override
  String get byGameType => 'ゲームタイプ別';

  @override
  String get rate => '率';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get appDescription => 'Vincent Moreauによるゲームセッション用のスコア管理アプリ';

  @override
  String get features => '機能';

  @override
  String get featureDifferentGameTypes => 'さまざまなゲームタイプ';

  @override
  String get featurePlayerManagement => 'プレイヤー管理';

  @override
  String get featureDetailedStatistics => '詳細な統計';

  @override
  String get featureCustomization => 'カスタマイズ';

  @override
  String get featureDarkLightTheme => 'ダーク/ライトテーマ';

  @override
  String get featureGroupSharing => 'グループ共有';

  @override
  String get featureGameAnalysis => 'AIによる対戦分析';

  @override
  String get rateApp => 'CountScore を評価する';

  @override
  String get credits => 'クレジット';

  @override
  String get appIconCredit => 'アプリアイコン';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get search => '検索';

  @override
  String get newPlayerName => '新しいプレイヤー名';

  @override
  String get noPlayersFound => 'プレイヤーが見つかりません';

  @override
  String get close => '閉じる';

  @override
  String get playerEliminationCondition => 'プレイヤー脱落条件';

  @override
  String get gameOverCondition => 'ゲーム終了条件';

  @override
  String get none => 'なし';

  @override
  String get overThreshold => 'しきい値を超える';

  @override
  String get underThreshold => 'しきい値を下回る';

  @override
  String get firstPlayerOver => '最初に到達したプレイヤー';

  @override
  String get firstPlayerUnder => '最初のプレイヤーが下回る';

  @override
  String get lastPlayerOver => '最後のプレイヤーが超える';

  @override
  String get lastPlayerUnder => '最後のプレイヤーが下回る';

  @override
  String get threshold => 'しきい値';

  @override
  String get conditionType => '条件の種類';

  @override
  String get continuePlay => '続ける';

  @override
  String gameEndWinner(String name) {
    return '$nameの勝ち';
  }

  @override
  String gameEndTie(String names) {
    return '引き分け：$names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countラウンド',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => '低得点の勝ち';

  @override
  String get gameEndHighestWins => '高得点の勝ち';

  @override
  String get gameEndAnalysis => '分析';

  @override
  String get gameEndResults => '結果';

  @override
  String get endGame => 'ゲームを終了';

  @override
  String get reopenGame => 'ゲームを再開';

  @override
  String get gameFinished => '終了済み';

  @override
  String get undo => '元に戻す';

  @override
  String get gameReopened => 'ゲームを再開しました';

  @override
  String get comment => 'コメント';

  @override
  String get enterComment => 'コメントを入力';

  @override
  String get analyzeGame => 'ゲームを分析';

  @override
  String get analysisTitle => 'ゲーム分析';

  @override
  String get analysisStyle => '分析のスタイル';

  @override
  String get analysisStyleProfessor => '教授';

  @override
  String get analysisStyleCommentator => 'スポーツ実況';

  @override
  String get analysisStyleDocumentary => '動物ドキュメンタリー';

  @override
  String get analysisStyleNoir => '探偵';

  @override
  String get analysisStyleBard => '吟遊詩人';

  @override
  String get analysisStyleCoach => 'コーチ';

  @override
  String get analysisStyleConsultant => 'コンサルタント';

  @override
  String get analysisStyleAstrologer => '占星術師';

  @override
  String get analysisStyleRealityTv => 'リアリティ番組';

  @override
  String get generatingAnalysis => '分析を生成中…';

  @override
  String get generateAnalysis => '分析を生成';

  @override
  String get regenerateAnalysis => '分析を再生成';

  @override
  String get deleteAnalysis => '分析を削除';

  @override
  String get confirmRegenerateAnalysis => '再生成しますか？現在の分析は置き換えられます。';

  @override
  String get confirmDeleteAnalysis => 'このゲームの分析を削除しますか？';

  @override
  String get analysisError => '分析の生成に失敗しました';

  @override
  String get analysisErrorUnavailable =>
      '分析サーバーは一時的に利用できません。しばらくしてからもう一度お試しください。';

  @override
  String analysisErrorStatus(int status) {
    return '分析の生成に失敗しました (HTTP $status)';
  }

  @override
  String get retry => '再試行';

  @override
  String analysisGeneratedAt(String date) {
    return '$date に生成';
  }

  @override
  String get serverSection => 'サーバー';

  @override
  String get backendUrlLabel => 'サーバーの URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'オンライン機能には CountScore サーバーが必要です。backend/ フォルダーから自分で用意し、そのアドレスをここに入力してください。サーバーが未設定の場合、データが端末から送信されることはありません。';

  @override
  String get backendNotConfigured => 'サーバーが未設定です';

  @override
  String get backendUrlInvalid =>
      'https://countscore.example.com のような完全な URL を入力してください';

  @override
  String get backendUrlInsecure =>
      'http:// はローカルネットワークでのみ使用できます。公開サーバーには https:// を使用してください。';

  @override
  String get testConnection => '接続をテスト';

  @override
  String get connectionOk => 'サーバーは応答しています';

  @override
  String get connectionFailed => 'サーバーが応答しません';

  @override
  String get serverUrlSaved => 'サーバーを保存しました';

  @override
  String get analysisRequiresBackend => 'この分析にはサーバーが必要です。設定から構成してください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get serverUrlCleared => 'サーバーを消去しました';

  @override
  String get groupSection => 'グループ';

  @override
  String get groupDescription =>
      'グループ内の他の端末とゲームを共有します。共有したゲームとそのプレイヤー、スコア、コメント、分析はあなたのサーバーに送信されます。それ以外のゲームはこの端末に残ります。';

  @override
  String get groupNeedsServer => 'まず上でサーバーを設定してください。';

  @override
  String get groupCreate => 'グループを作成';

  @override
  String get groupJoin => 'グループに参加';

  @override
  String get groupNameLabel => 'グループ名';

  @override
  String get deviceLabelLabel => 'この端末の名前';

  @override
  String get deviceLabelDefault => 'マイ端末';

  @override
  String get shareTokenLabel => '招待コード';

  @override
  String get shareTokenHint => 'グループのメンバーから届いたコードを貼り付けてください';

  @override
  String groupCurrent(String name) {
    return 'グループ：$name';
  }

  @override
  String get shareTokenExplain =>
      'グループに参加する端末にこのコードを送ってください。コードを知っている人は誰でも参加できます。';

  @override
  String get shareTokenCopy => 'コードをコピー';

  @override
  String get shareTokenCopied => 'コードをコピーしました';

  @override
  String get shareTokenRotate => '新しいコード';

  @override
  String get shareTokenRotateConfirm =>
      '古いコードでは参加できなくなります。すでにグループにいる端末には影響しません。';

  @override
  String get groupLeave => 'グループを退出';

  @override
  String get groupLeaveConfirm =>
      'この端末はグループを退出します。共有したゲームは端末に残りますが、同期されなくなります。';

  @override
  String get groupLeft => 'グループを退出しました';

  @override
  String get groupJoined => 'グループに参加しました';

  @override
  String get clearServerLeavesGroup =>
      'サーバーを消去するとグループを退出します。共有したゲームはこの端末に残ります。';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String syncStatusIdle(String time) {
    return '$time に同期済み';
  }

  @override
  String get syncStatusSyncing => '同期中…';

  @override
  String get syncStatusOffline => 'サーバーに接続できません。変更は後で送信されます';

  @override
  String get syncStatusUnauthorized =>
      'サーバーがこの端末を受け付けなくなりました。グループを退出してから参加し直してください。';

  @override
  String get syncStatusError => '同期中にサーバーエラーが発生しました';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更が送信待ち',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更がサーバーに拒否されました',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => '招待コードが不明か、変更されています';

  @override
  String get groupErrorRateLimited => '試行回数が多すぎます。1分後にもう一度お試しください。';

  @override
  String get groupErrorUnreachable => 'サーバーに接続できません';

  @override
  String get groupErrorServer => 'サーバーエラー';

  @override
  String get shareWithGroup => 'グループと共有';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name の端末がこのゲームを閲覧・編集できます';
  }

  @override
  String shareGameConfirm(String name) {
    return 'このゲームとプレイヤー、スコア、コメントが $name に送信されます。共有は取り消せません。';
  }

  @override
  String get gameSharedDone => 'ゲームをグループと共有しました';

  @override
  String get gameSharedBadge => '共有ゲーム';

  @override
  String invalidPlayerNamesForSync(String names) {
    return '次の名前は共有できません：$names。文字、数字、スペース、ハイフン、アポストロフィ、ピリオドのみを使ってください（32文字以内）。';
  }

  @override
  String roundRenumbered(int number) {
    return 'そのラウンドは別の端末で入力済みだったため、ラウンド $number になりました。';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '「$name」は別の端末で削除されました';
  }

  @override
  String get groupDevices => 'デバイス';

  @override
  String get groupDevicesExplain => '紛失または売却したスマートフォンをここでグループから削除できます。';

  @override
  String get groupDeviceThisOne => 'このデバイス';

  @override
  String groupDeviceLastSeen(String date) {
    return '最終確認：$date';
  }

  @override
  String get groupDeviceRevoke => '削除';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '「$label」をグループから削除しますか？今後は同期されません。招待コードも変更されます。メンバーのアクセスはそのままですが、招待するには新しいコードを共有する必要があります。';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '「$label」を削除しました。招待コードが変更されました。';
  }

  @override
  String get reportCommentary => 'このコメントを報告';

  @override
  String get reportCommentarySubject => 'CountScore — AI コメントの報告';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'この AI 生成コメントのどこに問題がありますか？\n\n\n---\n参照：$reference\nコメント：\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'メールアプリが見つかりません。このコメントを報告するには $email までご連絡ください。';
  }

  @override
  String get gameRulesTitle => 'ゲームのルール';

  @override
  String get gameRulesInApp => 'CountScore では';

  @override
  String get gameRulesSection => 'ルール';

  @override
  String get gameRulesNoElimination => '対局中の脱落はありません';

  @override
  String gameRulesEliminationOver(int threshold) {
    return '$threshold 点を超えたプレイヤーは脱落します';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return '$threshold 点を下回ったプレイヤーは脱落します';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'いずれかのプレイヤーが $threshold 点に達した時点で終了します';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'いずれかのプレイヤーが $threshold 点を下回った時点で終了します';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return '1人を除く全プレイヤーが $threshold 点を超えた時点で終了します';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return '1人を除く全プレイヤーが $threshold 点を下回った時点で終了します';
  }

  @override
  String get gameRulesNoEnd => '自動終了はありません。終わりを決めるのはあなたです';

  @override
  String get gameRulesEmptyTitle => 'まだルールがありません';

  @override
  String get gameRulesEmptyHint => 'あなたの卓の点数の数え方を書いておけば、全員が同じルールを共有できます。';

  @override
  String get gameRulesWrite => 'ルールを書く';

  @override
  String get gameRulesEditTitle => 'ルールを編集';

  @override
  String get gameRulesEditorHint => 'あなたの卓のルール。Markdown が使えます。';

  @override
  String get gameRulesFromGroup => 'あなたのグループのルール';

  @override
  String get gameRulesRestoreDefault => '元のルールに戻す';

  @override
  String get gameRulesSaved => 'ルールを保存しました';

  @override
  String get gameRulesRestored => '元のルールに戻しました';

  @override
  String get gameRulesDisclaimer =>
      'この要約は、一般的に遊ばれているルールをもとに CountScore がまとめたものです。ゲーム名は各権利者に帰属し、説明のためにのみ使用しています。';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'ウノ';

  @override
  String get gameTypeNameUnoSortKey => 'ウノ';

  @override
  String get gameTypeNameScrabble => 'スクラブル';

  @override
  String get gameTypeNameScrabbleSortKey => 'スクラブル';

  @override
  String get gameTypeNameOther => 'その他';

  @override
  String get gameTypeNameOtherSortKey => 'その他';

  @override
  String get gameTypeNameSkyjo => 'スカイジョ';

  @override
  String get gameTypeNameSkyjoSortKey => 'スカイジョ';

  @override
  String get gameTypeNamePresident => '大富豪';

  @override
  String get gameTypeNamePresidentSortKey => '大富豪';

  @override
  String get gameTypeNameBelote => 'ベロット';

  @override
  String get gameTypeNameBeloteSortKey => 'ベロット';

  @override
  String get gameTypeNameTarot => 'タロット';

  @override
  String get gameTypeNameTarotSortKey => 'タロット';

  @override
  String get gameTypeNameBridge => 'ブリッジ';

  @override
  String get gameTypeNameBridgeSortKey => 'ブリッジ';

  @override
  String get gameTypeNameRami => 'ラミー';

  @override
  String get gameTypeNameRamiSortKey => 'ラミー';

  @override
  String get gameTypeNameCoinche => 'コワンシュ';

  @override
  String get gameTypeNameCoincheSortKey => 'コワンシュ';

  @override
  String get gameTypeNameYahtzee => 'ヤッツィー';

  @override
  String get gameTypeNameYahtzeeSortKey => 'ヤッツィー';

  @override
  String get gameTypeNamePhase10 => 'フェーズ 10';

  @override
  String get gameTypeNamePhase10SortKey => 'フェーズ 10';

  @override
  String get gameTypeNameFlip7 => 'フリップ 7';

  @override
  String get gameTypeNameFlip7SortKey => 'フリップ 7';

  @override
  String get gameTypeNameMilleBornes => 'ミルボルヌ';

  @override
  String get gameTypeNameMilleBornesSortKey => 'ミルボルヌ';

  @override
  String get gameTypeNameRummikub => 'ラミィキューブ';

  @override
  String get gameTypeNameRummikubSortKey => 'ラミィキューブ';

  @override
  String get gameTypeNameSixNimmt => 'ニムト';

  @override
  String get gameTypeNameSixNimmtSortKey => 'ニムト';

  @override
  String get gameTypeNameQwirkle => 'クワークル';

  @override
  String get gameTypeNameQwirkleSortKey => 'クワークル';

  @override
  String get gameTypeNameFarkle => 'ファークル';

  @override
  String get gameTypeNameFarkleSortKey => 'ファークル';

  @override
  String get gameTypeNameCanasta => 'カナスタ';

  @override
  String get gameTypeNameCanastaSortKey => 'カナスタ';

  @override
  String get gameTypeNameWizard => 'ウィザード';

  @override
  String get gameTypeNameWizardSortKey => 'ウィザード';

  @override
  String get gameTypeNameTriomino => 'トライオミノ';

  @override
  String get gameTypeNameTriominoSortKey => 'トライオミノ';

  @override
  String get groupDeviceOwner => 'オーナー';

  @override
  String get groupDeviceMakeOwner => 'オーナーにする';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'グループを「$label」に引き継ぎますか？このデバイスはデバイスの削除や招待コードの変更ができなくなります。';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '「$label」がグループのオーナーになりました。';
  }

  @override
  String get groupDevicesExplainMember =>
      'デバイスの削除や招待コードの変更ができるのはグループのオーナーだけです。';

  @override
  String get groupErrorNotOwner => 'この操作はグループのオーナーだけが行えます';

  @override
  String get whoStarts => '誰から始める？';

  @override
  String get whoStartsAgain => 'もう一度引く';

  @override
  String get resumeGame => '再開';

  @override
  String get recentGames => '最近';

  @override
  String get gameInProgress => '進行中';

  @override
  String roundNumber(int number) {
    return '第$numberラウンド';
  }

  @override
  String gameLeader(String name, int score) {
    return '$nameがリード · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$nameの勝ち';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '$rank位',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => '1人1行';

  @override
  String get boardViewLanes => '1人1列';

  @override
  String get boardSeatOrder => '手番順';

  @override
  String boardRoundShort(int number) {
    return '$number回';
  }

  @override
  String get boardPlayer => 'プレイヤー';

  @override
  String get boardTotal => '合計';

  @override
  String get boardLeader => 'トップ';

  @override
  String get groupSettingsTitle => 'コメントと利用状況';

  @override
  String get groupSettingsDescription =>
      'サーバーがグループの対戦について書くコメントのスタイルと言語です。どのメンバーでも変更できます。';

  @override
  String get groupCommentStyle => 'コメントのスタイル';

  @override
  String get groupCommentStyleNarrative => '物語風';

  @override
  String get groupCommentStyleHumorous => 'ユーモア';

  @override
  String get groupCommentStyleAnalytical => '分析的';

  @override
  String get groupCommentLanguage => 'コメントの言語';

  @override
  String get groupSettingsSaved => 'グループの設定を保存しました';

  @override
  String get groupUsageTitle => '今月の LLM 利用状況';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$budget のうち $used を使用';
  }

  @override
  String groupUsageResets(String date) {
    return '$date にリセット';
  }

  @override
  String get statsBestWinRate => '最高勝率';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$games戦$wins勝',
      zero: '$games戦 勝利なし',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'プレイヤー';

  @override
  String get statsColumnGames => '試合';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count試合 · ランク外',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '終了した試合が$count試合以上でランク入り。プレイヤーをタップするとカードを表示します。',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '試合',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '勝',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => '平均順位';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '順位、直近$count試合',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => '上昇中';

  @override
  String get statsTrendDeclining => '下降中';

  @override
  String get statsTrendSteady => '安定';

  @override
  String statsRankOrdinal(String rank) {
    return '$rank位';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count連勝中',
      zero: '連勝なし',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return '記録: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameTypeでの成績';
  }

  @override
  String get statsAverageTotal => '平均最終スコア';

  @override
  String get statsBestTotal => '最高最終スコア';

  @override
  String get statsMostBeaten => '最も多く勝った相手';

  @override
  String get statsOpenPlayerCard => 'プレイヤーカードを開く';

  @override
  String get shareResult => '結果を共有';

  @override
  String get shareAnalysis => '分析を共有';

  @override
  String shareResultSubject(String gameName) {
    return '結果：$gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$dateのゲーム';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points点',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return '$appNameでスコアを記録：$url';
  }

  @override
  String get shareFailed => '共有を開けませんでした';

  @override
  String get newGameNameLabel => '名前';

  @override
  String get newGameGameLabel => 'ゲーム';

  @override
  String newGameAllGames(int count) {
    return 'すべてのゲーム（$count）';
  }

  @override
  String get newGamePlayersLabel => 'プレイヤー · 席順';

  @override
  String get newGameDragToReorder => 'ドラッグで並べ替え';

  @override
  String get newGameDealer => '親';

  @override
  String get newGameAddPlayer => 'プレイヤーを追加';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '開始 · $count人',
      zero: '開始',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => '誰が遊ぶ？';

  @override
  String get whoIsPlayingSearchHint => '名前、または新しいプレイヤー';

  @override
  String get whoIsPlayingFrequent => 'よく一緒に遊ぶ人';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '「$gameName」と同じプレイヤー';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '「$name」を作成';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人を追加',
      zero: '完了',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'ゲーム$number';
  }
}
