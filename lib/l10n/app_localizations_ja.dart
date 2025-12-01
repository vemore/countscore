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
  String get createdOn => '作成日';

  @override
  String get newWithSamePlayers => '同じプレイヤーで新規作成';

  @override
  String get newGameSuffix => '(新規)';

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
  String get filterByGameType => 'ゲームタイプで絞り込み';

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
  String get winRule => '勝利ルール';

  @override
  String get lowestScoreWins => '最低スコアが勝ち';

  @override
  String get highestScoreWins => '最高スコアが勝ち';

  @override
  String get lowestScoreExample => '例：ゴルフ、ハーツ';

  @override
  String get highestScoreExample => '例：ラミー、ブリッジ';

  @override
  String get players => 'プレイヤー';

  @override
  String get add => '追加';

  @override
  String get pleaseEnterName => '名前を入力してください';

  @override
  String get atLeast2PlayersRequired => '最低2人のプレイヤーが必要です';

  @override
  String playerNumber(int index) {
    return 'プレイヤー$index';
  }

  @override
  String get selectPlayer => 'プレイヤーを選択...';

  @override
  String get clear => 'クリア';

  @override
  String get remove => '削除';

  @override
  String get createGame => 'ゲームを作成';

  @override
  String get game => 'ゲーム';

  @override
  String get editGame => 'ゲームを編集';

  @override
  String get editGameDialogTitle => 'ゲームを編集';

  @override
  String get gameSettings => 'ゲーム設定';

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
  String get addRound => 'ラウンドを追加';

  @override
  String get score => 'スコア';

  @override
  String get enterScore => 'スコアを入力';

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
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人のプレイヤー: $names',
      zero: 'プレイヤーがいません',
    );
    return '$_temp0';
  }

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
  String get predefined => 'デフォルト';

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
  String get overallStatistics => '全体統計';

  @override
  String get byGameType => 'ゲームタイプ別';

  @override
  String get rate => '率';

  @override
  String get version => 'バージョン 1.0.0';

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
  String get credits => 'クレジット';

  @override
  String get appIconCredit => 'アプリアイコン';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'プレイヤーを選択';

  @override
  String get search => '検索';

  @override
  String get searchOrCreate => '検索 / 作成';

  @override
  String get createNewPlayer => '新しいプレイヤーを作成';

  @override
  String get newPlayerName => '新しいプレイヤー名';

  @override
  String get noPlayersFound => 'プレイヤーが見つかりません';

  @override
  String get allPlayersSelected => 'すべてのプレイヤーが選択されています';

  @override
  String get close => '閉じる';

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
