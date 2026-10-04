// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String get playersListTitle => 'Danh sách người chơi';

  @override
  String get gameTypesTitle => 'Loại trò chơi';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get aboutTitle => 'Thông tin';

  @override
  String get newGame => 'Trò chơi mới';

  @override
  String get noGames => 'Chưa có trò chơi';

  @override
  String get noGamesOfThisType => 'Chưa có trò chơi loại này';

  @override
  String get createFirstGame => 'Tạo trò chơi đầu tiên của bạn';

  @override
  String get newWithSamePlayers => 'Trò chơi mới với cùng người chơi';

  @override
  String get playAgain => 'Chơi lại';

  @override
  String get rename => 'Đổi tên';

  @override
  String get delete => 'Xóa';

  @override
  String get confirmDeletion => 'Xác nhận xóa';

  @override
  String confirmDeleteGame(String name) {
    return 'Bạn có thực sự muốn xóa trò chơi \"$name\" không?';
  }

  @override
  String get cancel => 'Hủy';

  @override
  String get renameGame => 'Đổi tên trò chơi';

  @override
  String get gameName => 'Tên trò chơi';

  @override
  String get save => 'Lưu';

  @override
  String get allGames => 'Tất cả trò chơi';

  @override
  String get filterGames => 'Lọc trò chơi';

  @override
  String get applyFilter => 'Áp dụng';

  @override
  String get resetFilter => 'Đặt lại';

  @override
  String get selectGameType => 'Chọn loại trò chơi';

  @override
  String get gameType => 'Loại trò chơi';

  @override
  String get loadingGameTypes => 'Đang tải loại trò chơi...';

  @override
  String get lowestScoreWins => 'Điểm thấp nhất thắng';

  @override
  String get highestScoreWins => 'Điểm cao nhất thắng';

  @override
  String get players => 'Người chơi';

  @override
  String get add => 'Thêm';

  @override
  String get pleaseEnterName => 'Vui lòng nhập tên';

  @override
  String get clear => 'Xóa';

  @override
  String get remove => 'Loại bỏ';

  @override
  String get game => 'Trò chơi';

  @override
  String get editGame => 'Chỉnh sửa trò chơi';

  @override
  String get editGameDialogTitle => 'Chỉnh sửa trò chơi';

  @override
  String get removePlayer => 'Loại bỏ người chơi';

  @override
  String get addPlayerToGame => 'Thêm người chơi';

  @override
  String get warningRemovePlayer =>
      'Cảnh báo! Loại bỏ người chơi này sẽ xóa tất cả điểm của họ khỏi trò chơi này. Thao tác này không thể hoàn tác.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Bạn có thực sự muốn loại bỏ $playerName khỏi trò chơi này không?';
  }

  @override
  String get playerRemoved => 'Người chơi đã bị loại bỏ khỏi trò chơi';

  @override
  String get deleteLastRound => 'Xóa vòng cuối cùng';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get confirmDeleteLastRound => 'Xóa vòng cuối cùng?';

  @override
  String get noPlayersInGame => 'Không có người chơi trong trò chơi này';

  @override
  String get round => 'Vòng';

  @override
  String boardRoundButton(int round) {
    return 'Vòng $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · vòng $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · vòng $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'tổng sau: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Tiếp theo\n$player';
  }

  @override
  String get keypadValidateRound => 'Xác nhận vòng';

  @override
  String get keypadToggleSign => 'Đổi dấu';

  @override
  String get keypadBackspace => 'Xóa một chữ số';

  @override
  String get keypadShortcutTitle => 'Phím tắt bàn phím';

  @override
  String get keypadShortcutKind => 'Loại phím';

  @override
  String get keypadShortcutKindValue => 'Nhập một giá trị';

  @override
  String get keypadShortcutKindMultiply => 'Nhân điểm (chỉ dương)';

  @override
  String get keypadShortcutKindAdd => 'Cộng vào điểm';

  @override
  String get keypadShortcutAmount => 'Số';

  @override
  String get keypadShortcutLabel => 'Nhãn phím (tùy chọn)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'Số nguyên từ $min đến $max, khác 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'Số nguyên từ $min đến $max';
  }

  @override
  String get appearance => 'Giao diện';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get system => 'Hệ thống';

  @override
  String get screen => 'Màn hình';

  @override
  String get keepScreenAwake => 'Giữ màn hình sáng';

  @override
  String get keepScreenAwakeDescription =>
      'Ngăn màn hình tắt trong quá trình chơi';

  @override
  String get backup => 'Sao lưu';

  @override
  String get exportDatabase => 'Xuất cơ sở dữ liệu';

  @override
  String get exportDatabaseDescription =>
      'Lưu tất cả trò chơi của bạn vào một tệp';

  @override
  String get databaseExportedTo => 'Cơ sở dữ liệu đã xuất đến:';

  @override
  String get errorDuringExport => 'Lỗi trong khi xuất:';

  @override
  String get importDatabase => 'Nhập cơ sở dữ liệu';

  @override
  String get importDatabaseDescription =>
      'Khôi phục trò chơi của bạn từ tệp sao lưu';

  @override
  String get confirmation => 'Xác nhận';

  @override
  String get importWarning =>
      'Nhập sẽ thay thế tất cả dữ liệu hiện tại của bạn. Một bản sao lưu tự động sẽ được tạo trước khi nhập.\n\nBạn có muốn tiếp tục không?';

  @override
  String get import => 'Nhập';

  @override
  String get databaseImportedSuccessfully => 'Cơ sở dữ liệu đã nhập thành công';

  @override
  String get importSuccessful => 'Nhập thành công';

  @override
  String get importSuccessMessage =>
      'Cơ sở dữ liệu đã được nhập thành công.\n\nUng dụng sẽ đóng ngay bây giờ. Vui lòng mở lại để xem dữ liệu mới.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Lỗi trong khi nhập:';

  @override
  String get noPlayers => 'Không có người chơi';

  @override
  String get playersAppearMessage =>
      'Người chơi sẽ xuất hiện ở đây khi\nbạn đã tạo các trò chơi';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trò chơi',
      one: '1 trò chơi',
      zero: '0 trò chơi',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chiến thắng',
      one: '1 chiến thắng',
      zero: '0 chiến thắng',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Đổi màu';

  @override
  String get renamePlayer => 'Đổi tên người chơi';

  @override
  String get newName => 'Tên mới';

  @override
  String playerRenamedTo(String name) {
    return 'Người chơi được đổi tên thành \"$name\"';
  }

  @override
  String get deletePlayer => 'Xóa người chơi';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Bạn có thực sự muốn xóa \"$name\" không?\n\nNguời chơi này sẽ bị loại bỏ khỏi tất cả $count trò chơi.';
  }

  @override
  String playerDeleted(String name) {
    return 'Người chơi \"$name\" đã bị xóa';
  }

  @override
  String get chooseColor => 'Chọn một màu';

  @override
  String get noGameTypes => 'Chưa có loại trò chơi';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get newType => 'Loại mới';

  @override
  String get editType => 'Chỉnh sửa loại';

  @override
  String get newGameType => 'Loại trò chơi mới';

  @override
  String get gameTypeName => 'Tên loại trò chơi';

  @override
  String get icon => 'Biểu tượng:';

  @override
  String get color => 'Màu:';

  @override
  String get chooseIcon => 'Chọn một biểu tượng';

  @override
  String get nameIsRequired => 'Tên là bắt buộc';

  @override
  String get create => 'Tạo';

  @override
  String get ranking => 'Xếp hạng';

  @override
  String get noCurrentGame => 'Không có trò chơi nào đang diễn ra';

  @override
  String get noScoresRecorded => 'Chưa ghi lại điểm nào';

  @override
  String get playerStatistics => 'Thống kê người chơi';

  @override
  String get noStatisticsAvailable => 'Không có thống kê nào';

  @override
  String get gamesPlayed => 'Trò chơi đã chơi';

  @override
  String get wins => 'Chiến thắng';

  @override
  String get winRate => 'Tỷ lệ thắng';

  @override
  String get byGameType => 'Theo loại trò chơi';

  @override
  String get rate => 'Tỷ lệ';

  @override
  String version(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get appDescription =>
      'Ứng dụng quản lý điểm cho các trò chơi của bạn bởi Vincent Moreau';

  @override
  String get features => 'Tính năng';

  @override
  String get featureDifferentGameTypes => 'Các loại trò chơi khác nhau';

  @override
  String get featurePlayerManagement => 'Quản lý người chơi';

  @override
  String get featureDetailedStatistics => 'Thống kê chi tiết';

  @override
  String get featureCustomization => 'Tùy chỉnh';

  @override
  String get featureDarkLightTheme => 'Chế độ tối/sáng';

  @override
  String get featureGroupSharing => 'Chia sẻ nhóm';

  @override
  String get featureGameAnalysis => 'Phân tích trò chơi bằng AI';

  @override
  String get rateApp => 'Đánh giá CountScore';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get newPlayerName => 'Tên người chơi mới';

  @override
  String get noPlayersFound => 'Không tìm thấy người chơi nào';

  @override
  String get close => 'Đóng';

  @override
  String get playerEliminationCondition => 'Điều kiện loại bỏ người chơi';

  @override
  String get gameOverCondition => 'Điều kiện kết thúc trò chơi';

  @override
  String get none => 'Không có';

  @override
  String get overThreshold => 'Vượt quá ngưỡng';

  @override
  String get underThreshold => 'Dưới ngưỡng';

  @override
  String get firstPlayerOver => 'Người chơi đầu tiên đạt';

  @override
  String get firstPlayerUnder => 'Người chơi đầu tiên dưới';

  @override
  String get lastPlayerOver =>
      'Người chơi cuối cùng còn lại (những người khác vượt quá)';

  @override
  String get lastPlayerUnder =>
      'Người chơi cuối cùng còn lại (những người khác dưới)';

  @override
  String get threshold => 'Ngưỡng';

  @override
  String get conditionType => 'Loại điều kiện';

  @override
  String get continuePlay => 'Tiếp tục chơi';

  @override
  String gameEndWinner(String name) {
    return '$name thắng';
  }

  @override
  String gameEndTie(String names) {
    return 'Hòa: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vòng',
      one: '$count vòng',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'điểm thấp nhất thắng';

  @override
  String get gameEndHighestWins => 'điểm cao nhất thắng';

  @override
  String get gameEndAnalysis => 'Phân tích';

  @override
  String get gameEndResults => 'Kết quả';

  @override
  String get rankingEliminationNote =>
      'Xếp hạng theo thứ tự loại bỏ: người nào bị loại sau xếp trước, bất kể tổng điểm.';

  @override
  String get endGame => 'Kết thúc trò chơi';

  @override
  String get reopenGame => 'Mở lại trò chơi';

  @override
  String get gameFinished => 'Đã hoàn thành';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get gameReopened => 'Trò chơi đã mở lại';

  @override
  String get comment => 'Bình luận';

  @override
  String get enterComment => 'Nhập bình luận';

  @override
  String get analyzeGame => 'Phân tích trò chơi';

  @override
  String get analysisTitle => 'Phân tích trò chơi';

  @override
  String get analysisStyle => 'Phong cách phân tích';

  @override
  String get analysisStyleProfessor => 'Giáo sư';

  @override
  String get analysisStyleCommentator => 'Bình luận viên thể thao';

  @override
  String get analysisStyleDocumentary => 'Phim tài liệu thiên nhiên';

  @override
  String get analysisStyleNoir => 'Thám tử';

  @override
  String get analysisStyleBard => 'Nhạc sĩ';

  @override
  String get analysisStyleCoach => 'Huấn luyện viên';

  @override
  String get analysisStyleConsultant => 'Cố vấn';

  @override
  String get analysisStyleAstrologer => 'Nhà chiêm tinh';

  @override
  String get analysisStyleRealityTv => 'Chương trình thực tế';

  @override
  String get generatingAnalysis => 'Đang tạo phân tích…';

  @override
  String get generateAnalysis => 'Tạo phân tích';

  @override
  String get regenerateAnalysis => 'Tạo lại phân tích';

  @override
  String get deleteAnalysis => 'Xóa phân tích';

  @override
  String get confirmRegenerateAnalysis =>
      'Tạo lại? Phân tích hiện tại sẽ bị thay thế.';

  @override
  String get confirmDeleteAnalysis => 'Xóa phân tích cho trò chơi này?';

  @override
  String get analysisError => 'Không thể tạo phân tích';

  @override
  String get analysisErrorUnavailable =>
      'Máy chủ phân tích tạm thời không khả dụng. Thử lại sau.';

  @override
  String get analysisErrorGroupBudget =>
      'Nhóm của bạn đã hết ngân sách phân tích cho tháng này. Nó sẽ được cấp lại vào đầu tháng sau.';

  @override
  String get analysisStyleGroupDefault =>
      'Chưa chọn phong cách: trò chơi chia sẻ này được phân tích theo phong cách và ngôn ngữ của nhóm.';

  @override
  String analysisErrorStatus(int status) {
    return 'Không thể tạo phân tích (HTTP $status)';
  }

  @override
  String get retry => 'Thử lại';

  @override
  String analysisGeneratedAt(String date) {
    return 'Được tạo vào $date';
  }

  @override
  String get serverSection => 'Máy chủ';

  @override
  String get backendUrlLabel => 'URL máy chủ';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Các tính năng kết nối cần máy chủ CountScore. Cài đặt một máy chủ từ thư mục backend/ và nhập địa chỉ của nó tại đây. Không có máy chủ, không có dữ liệu nào rời khỏi thiết bị này.';

  @override
  String get backendNotConfigured => 'Chưa cấu hình máy chủ';

  @override
  String get backendUrlInvalid =>
      'Địa chỉ không hợp lệ. Nhập URL đầy đủ, ví dụ https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// chỉ được chấp nhận trên mạng cục bộ. Sử dụng https:// cho máy chủ công khai.';

  @override
  String get testConnection => 'Kiểm tra kết nối';

  @override
  String get connectionOk => 'Máy chủ đang phản hồi';

  @override
  String get connectionFailed => 'Máy chủ không phản hồi';

  @override
  String get serverUrlSaved => 'Máy chủ đã lưu';

  @override
  String get analysisRequiresBackend =>
      'Phân tích này cần máy chủ. Cấu hình một máy chủ trong cài đặt.';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get serverUrlCleared => 'Máy chủ đã xóa';

  @override
  String get groupSection => 'Nhóm';

  @override
  String get groupDescription =>
      'Chia sẻ trò chơi với các thiết bị khác trong nhóm. Các trò chơi chia sẻ, người chơi, điểm, bình luận và phân tích của chúng được gửi đến máy chủ của bạn; các trò chơi khác ở lại trên thiết bị này.';

  @override
  String get groupNeedsServer => 'Trước tiên hãy cài đặt máy chủ ở trên.';

  @override
  String get groupCreate => 'Tạo một nhóm';

  @override
  String get groupJoin => 'Tham gia nhóm';

  @override
  String get groupNameLabel => 'Tên nhóm';

  @override
  String get groupNicknameLabel => 'Biệt danh của bạn';

  @override
  String get groupNicknameHint => 'Những người khác trong nhóm sẽ thấy nó';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Biệt danh của bạn: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Thay đổi biệt danh của bạn';

  @override
  String get shareTokenLabel => 'Mã mời';

  @override
  String get shareTokenHint => 'Dán mã mà thành viên nhóm gửi cho bạn';

  @override
  String groupCurrent(String name) {
    return 'Nhóm: $name';
  }

  @override
  String get shareTokenExplain =>
      'Gửi mã này đến các thiết bị nên tham gia nhóm. Bất kỳ ai có nó đều có thể tham gia.';

  @override
  String get shareTokenCopy => 'Sao chép mã';

  @override
  String get shareTokenCopied => 'Mã đã sao chép';

  @override
  String get shareTokenRotate => 'Mã mới';

  @override
  String get shareTokenRotateConfirm =>
      'Mã cũ sẽ không cho phép bất kỳ ai tham gia nhóm. Các thiết bị đã ở trong nhóm không bị ảnh hưởng.';

  @override
  String get groupLeave => 'Rời nhóm';

  @override
  String get groupLeaveConfirm =>
      'Thiết bị này rời nhóm. Các trò chơi chia sẻ ở lại trên thiết bị này nhưng sẽ không còn đồng bộ.';

  @override
  String get groupLeft => 'Đã rời nhóm';

  @override
  String get groupJoined => 'Đã tham gia nhóm';

  @override
  String get clearServerLeavesGroup =>
      'Xóa máy chủ sẽ rời nhóm. Các trò chơi chia sẻ ở lại trên thiết bị này.';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String syncStatusIdle(String time) {
    return 'Đã đồng bộ lúc $time';
  }

  @override
  String get syncStatusSyncing => 'Đang đồng bộ…';

  @override
  String get syncStatusOffline =>
      'Máy chủ không thể tiếp cận — các thay đổi sẽ được gửi sau';

  @override
  String get syncStatusUnauthorized =>
      'Máy chủ không còn chấp nhận thiết bị này. Rời nhóm, rồi tham gia lại.';

  @override
  String get syncStatusError => 'Lỗi máy chủ trong khi đồng bộ';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thay đổi đang chờ',
      one: '1 thay đổi đang chờ',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thay đổi bị từ chối bởi máy chủ',
      one: '1 thay đổi bị từ chối bởi máy chủ',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'Mã mời không rõ hoặc bị thay thế';

  @override
  String get groupErrorRateLimited =>
      'Quá nhiều lần thử. Thử lại trong một phút.';

  @override
  String get groupErrorUnreachable => 'Máy chủ không thể tiếp cận';

  @override
  String get groupErrorServer => 'Lỗi máy chủ';

  @override
  String get shareWithGroup => 'Chia sẻ với nhóm';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Các thiết bị trong nhóm $name sẽ xem và chỉnh sửa trò chơi này';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Trò chơi, người chơi, điểm và bình luận của nó sẽ được gửi đến nhóm $name. Chia sẻ không thể được hoàn tác.';
  }

  @override
  String get gameSharedDone => 'Trò chơi đã chia sẻ với nhóm';

  @override
  String get gameSharedBadge => 'Trò chơi chia sẻ';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Những tên này không thể chia sẻ: $names. Sử dụng chữ cái, chữ số, khoảng trắng, dấu gạch ngang, dấu nháy hoặc dấu chấm (tối đa 32 ký tự).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Vòng đó đã được nhập trên thiết bị khác, nên nó trở thành vòng $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" đã bị xóa trên thiết bị khác';
  }

  @override
  String get groupDevices => 'Thiết bị';

  @override
  String get groupDevicesExplain =>
      'Điện thoại bị mất hoặc đã bán có thể bị loại bỏ khỏi nhóm ở đây.';

  @override
  String get groupDeviceThisOne => 'Thiết bị này';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Lần cuối cùng thấy $date';
  }

  @override
  String get groupDeviceRevoke => 'Loại bỏ';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Loại bỏ \"$label\" khỏi nhóm? Nó sẽ không còn đồng bộ. Mã mời cũng thay đổi: các thành viên giữ quyền truy cập, nhưng bạn sẽ cần chia sẻ mã mới để mời ai đó.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" đã bị loại bỏ. Mã mời đã thay đổi.';
  }

  @override
  String get reportCommentary => 'Báo cáo bình luận này';

  @override
  String get reportCommentarySubject => 'CountScore — báo cáo bình luận AI';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Cái gì không ổn với bình luận được tạo bởi AI này?\n\n\n---\nTham chiếu: $reference\nBình luận:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Không tìm thấy ứng dụng email. Viết thư đến $email để báo cáo bình luận này.';
  }

  @override
  String get gameRulesTitle => 'Quy tắc trò chơi';

  @override
  String get gameRulesInApp => 'Trong CountScore';

  @override
  String get gameRulesSection => 'Các quy tắc';

  @override
  String get gameRulesNoElimination => 'Không có loại bỏ trong quá trình chơi';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Một người chơi bị loại trên $threshold điểm';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Một người chơi bị loại dưới $threshold điểm';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Trò chơi kết thúc ngay khi một người chơi đạt $threshold điểm';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Trò chơi kết thúc ngay khi một người chơi dưới $threshold điểm';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Trò chơi kết thúc khi tất cả người chơi ngoài một người vượt quá $threshold điểm';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Trò chơi kết thúc khi tất cả người chơi ngoài một người dưới $threshold điểm';
  }

  @override
  String get gameRulesNoEnd =>
      'Không có kết thúc tự động: bạn quyết định khi nào trò chơi kết thúc';

  @override
  String get gameRulesEmptyTitle => 'Chưa có quy tắc';

  @override
  String get gameRulesEmptyHint =>
      'Viết cách bàn bạn tính điểm — mọi người sẽ có cùng phiên bản.';

  @override
  String get gameRulesWrite => 'Viết quy tắc';

  @override
  String get gameRulesEditTitle => 'Chỉnh sửa quy tắc';

  @override
  String get gameRulesEditorHint =>
      'Quy tắc của bàn bạn. Markdown được hỗ trợ.';

  @override
  String get gameRulesFromGroup => 'Quy tắc của nhóm bạn';

  @override
  String get gameRulesRestoreDefault => 'Khôi phục quy tắc gốc';

  @override
  String get gameRulesSaved => 'Quy tắc đã lưu';

  @override
  String get gameRulesRestored => 'Quy tắc gốc đã khôi phục';

  @override
  String get gameRulesDisclaimer =>
      'Tóm tắt được viết cho CountScore từ các quy tắc như chúng thường được chơi. Tên trò chơi thuộc về chủ sở hữu tương ứng của chúng và chỉ được sử dụng mô tả.';

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
  String get gameTypeNameOther => 'Khác';

  @override
  String get gameTypeNameOtherSortKey => 'Khác';

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
  String get groupDeviceOwner => 'Chủ sở hữu';

  @override
  String get groupDeviceMakeOwner => 'Làm chủ sở hữu';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Chuyển nhóm cho \"$label\"? Thiết bị này sẽ không còn có khả năng loại bỏ thiết bị hoặc thay đổi mã mời.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" hiện sở hữu nhóm.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Chỉ chủ sở hữu nhóm mới có thể loại bỏ thiết bị hoặc thay đổi mã mời.';

  @override
  String get groupErrorNotOwner =>
      'Chỉ chủ sở hữu nhóm mới có thể làm điều này';

  @override
  String get whoStarts => 'Ai bắt đầu?';

  @override
  String get whoStartsAgain => 'Quay lại';

  @override
  String get diceRoller => 'Lăn xúc xắc';

  @override
  String get diceCount => 'Số xúc xắc';

  @override
  String get diceRollAgain => 'Quay lại';

  @override
  String diceTotal(int total) {
    return 'Tổng: $total';
  }

  @override
  String get resumeGame => 'Tiếp tục';

  @override
  String get recentGames => 'Gần đây';

  @override
  String get gameInProgress => 'Đang diễn ra';

  @override
  String roundNumber(int number) {
    return 'vòng $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name dẫn · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Thắng bởi $name';
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
  String get boardViewRows => 'Một hàng cho mỗi người chơi';

  @override
  String get boardViewLanes => 'Một cột cho mỗi người chơi';

  @override
  String get boardSeatOrder => 'Thứ tự chỗ ngồi';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'Người chơi';

  @override
  String get boardTotal => 'Tổng';

  @override
  String get boardLeader => 'Dẫn';

  @override
  String get groupSettingsTitle => 'Bình luận và sử dụng';

  @override
  String get groupSettingsDescription =>
      'Phong cách và ngôn ngữ của các bình luận mà máy chủ viết cho các trò chơi của nhóm. Bất kỳ thành viên nào cũng có thể thay đổi chúng.';

  @override
  String get groupCommentStyle => 'Phong cách bình luận';

  @override
  String get groupCommentStyleNarrative => 'Tường thuật';

  @override
  String get groupCommentStyleHumorous => 'Hài hước';

  @override
  String get groupCommentStyleAnalytical => 'Phân tích';

  @override
  String get groupCommentLanguage => 'Ngôn ngữ bình luận';

  @override
  String get groupSettingsSaved => 'Cài đặt nhóm đã lưu';

  @override
  String get groupUsageTitle => 'Sử dụng LLM tháng này';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used được sử dụng của $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Đặt lại vào $date';
  }

  @override
  String get statsBestWinRate => 'Tỷ lệ thắng tốt nhất';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins chiến thắng trong $games',
      one: '$wins chiến thắng trong $games',
      zero: 'Không có chiến thắng trong $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Người chơi';

  @override
  String get statsColumnGames => 'Trò chơi';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trò chơi · chưa được xếp hạng',
      one: '$count trò chơi · chưa được xếp hạng',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Xếp hạng từ $count trò chơi hoàn thành. Nhấn vào một người chơi để xem thẻ của họ.',
      one:
          'Xếp hạng từ $count trò chơi hoàn thành. Nhấn vào một người chơi để xem thẻ của họ.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trò chơi',
      one: 'trò chơi',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'chiến thắng',
      one: 'chiến thắng',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'vị trí trung bình';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vị trí, $count trò chơi cuối cùng',
      one: 'Vị trí, trò chơi cuối cùng',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'đang cải thiện';

  @override
  String get statsTrendDeclining => 'đang suy giảm';

  @override
  String get statsTrendSteady => 'ổn định';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1',
      '2': '2',
      '3': '3',
      'other': '$rank',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chuỗi: $count chiến thắng',
      one: 'Chuỗi: $count chiến thắng',
      zero: 'Không có chuỗi thắng',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Tốt nhất: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Trên $gameType';
  }

  @override
  String get statsAverageTotal => 'Tổng điểm cuối cùng trung bình';

  @override
  String get statsBestTotal => 'Tổng điểm cuối cùng tốt nhất';

  @override
  String get statsMostBeaten => 'Đối thủ bị đánh bại nhiều nhất';

  @override
  String get statsOpenPlayerCard => 'mở thẻ người chơi';

  @override
  String get shareResult => 'Chia sẻ kết quả';

  @override
  String get shareAnalysis => 'Chia sẻ phân tích';

  @override
  String shareResultSubject(String gameName) {
    return 'Kết quả: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Trò chơi của $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points điểm',
      one: '$points điểm',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Điểm được ghi bằng $appName: $url';
  }

  @override
  String get shareFailed => 'Không thể mở chia sẻ';

  @override
  String get newGameNameLabel => 'Tên';

  @override
  String get newGameGameLabel => 'Trò chơi';

  @override
  String newGameAllGames(int count) {
    return 'Tất cả trò chơi ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Người chơi · thứ tự chỗ ngồi';

  @override
  String get newGameDragToReorder => 'kéo để sắp xếp lại';

  @override
  String get newGameDealer => 'chia';

  @override
  String get newGameAddPlayer => 'Thêm một người chơi';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bắt đầu · $count người chơi',
      one: 'Bắt đầu · 1 người chơi',
      zero: 'Bắt đầu',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Ai đang chơi?';

  @override
  String get whoIsPlayingSearchHint => 'Tên, hoặc một người chơi mới';

  @override
  String get whoIsPlayingFrequent => 'Thường xuyên chơi với bạn';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Cùng người chơi như \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Tạo \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count người chơi',
      one: 'Thêm 1 người chơi',
      zero: 'Xong',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Trò chơi $number';
  }

  @override
  String get pwaUpdateReady => 'Phiên bản mới của CountScore đã sẵn sàng';

  @override
  String get pwaUpdateReload => 'Tải lại';

  @override
  String get thresholdIsRequired => 'Ngưỡng là bắt buộc cho điều kiện này';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Ngưỡng không thể vượt quá $maxString';
  }

  @override
  String get deletionImpossible => 'Không thể xóa';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trò chơi sử dụng loại này: chúng không thể bị xóa.',
      one: '1 trò chơi sử dụng loại này: nó không thể bị xóa.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Bạn có thực sự muốn xóa loại trò chơi \"$name\" không?';
  }

  @override
  String get winDirectionChangeTitle => 'Đảo ngược ai thắng?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count trò chơi hoàn thành loại này sẽ có bảng xếp hạng bị đảo ngược: những người chiến thắng sẽ trở thành những người cuối cùng.',
      one: '1 trò chơi hoàn thành loại này sẽ có bảng xếp hạng bị đảo ngược: người chiến thắng sẽ trở thành người cuối cùng.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'Điều kiện kết thúc trò chơi làm phương hướng ngược lại của lựa chọn người chiến thắng. Một quy tắc nhà có thể muốn chính xác như vậy.';

  @override
  String get rulesOutOfDateTitle => 'Cập nhật quy tắc?';

  @override
  String get rulesOutOfDateMessage =>
      'Các quy tắc loại này vẫn mô tả điều kiện cũ.';

  @override
  String get later => 'Sau';

  @override
  String get currentIcon => 'Biểu tượng hiện tại';

  @override
  String get currentColor => 'Màu hiện tại';

  @override
  String get groupDeviceClaimOwner => 'Yêu cầu quyền sở hữu';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" sở hữu nhóm nhưng chưa thấy từ lâu. Lấy quyền sở hữu thiết bị này không?';
  }

  @override
  String get groupDeviceOwnerClaimed => 'Thiết bị này hiện sở hữu nhóm.';

  @override
  String get groupErrorOwnerActive =>
      'Chủ sở hữu nhóm đã thấy gần đây: không thể yêu cầu quyền sở hữu.';

  @override
  String get groupCreatedOwnerExplain =>
      'Nhóm được tạo. Thiết bị này sở hữu nó; vai trò có thể được chuyển giao cho thiết bị khác trong Thiết bị.';

  @override
  String get boardEliminated => 'Bị loại';

  @override
  String get soundsSection => 'Âm thanh';

  @override
  String get gameSounds => 'Âm thanh trò chơi';

  @override
  String get gameSoundsDescription =>
      'Âm thanh khi một người chơi bị loại, khi trò chơi được thắng và khi hết giờ hẹn';

  @override
  String get turnTimer => 'Hẹn giờ lượt';

  @override
  String get turnTimerLess => 'Ít thời gian hơn';

  @override
  String get turnTimerMore => 'Thêm thời gian';

  @override
  String get turnTimerStart => 'Bắt đầu';

  @override
  String get turnTimerPause => 'Tạm dừng';

  @override
  String get turnTimerReset => 'Đặt lại';

  @override
  String get turnTimerTimeUp => 'Hết giờ!';

  @override
  String get configShareOpen => 'Chia sẻ qua mã QR';

  @override
  String get configShareTitle => 'Chia sẻ cấu hình này';

  @override
  String get configShareExplainServer =>
      'Quét mã này bằng điện thoại khác để thiết lập cùng máy chủ.';

  @override
  String configShareExplainGroup(String name) {
    return 'Quét mã này bằng điện thoại khác để thiết lập cùng máy chủ và tham gia nhóm $name. Nó chứa mã mời của nhóm: chỉ hiển thị cho những người bạn muốn trong nhóm.';
  }

  @override
  String get configShareWebAppLabel => 'Địa chỉ ứng dụng web';

  @override
  String get configShareWebAppHelper =>
      'Nơi máy chủ phục vụ ứng dụng web CountScore, chẳng hạn như https://countscore.example.com/countscore. Mã mở trang này.';

  @override
  String get configShareWebAppNeeded =>
      'Nhập địa chỉ ứng dụng web để hiển thị mã.';

  @override
  String get configShareQrLabel => 'Mã QR của liên kết cấu hình';

  @override
  String get configShareCopyLink => 'Sao chép liên kết';

  @override
  String get configShareLinkCopied => 'Liên kết đã sao chép';

  @override
  String get configShareTooLong =>
      'Liên kết này quá dài để vừa vào mã QR. Sử dụng \"Sao chép liên kết\" thay thế.';

  @override
  String get replaceConfigTitle => 'Thay thế cấu hình?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Bây giờ: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Mới: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'mã mời $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'Thiết bị này sẽ rời nhóm $name. Các trò chơi của nó ở lại thiết bị này.';
  }

  @override
  String get replaceConfigConfirm => 'Thay thế';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count thay đổi trên thiết bị này chưa tới nhóm. Nếu bạn rời đi ngay bây giờ, nhóm sẽ không bao giờ nhận được chúng.',
      one: '1 thay đổi trên thiết bị này chưa tới nhóm. Nếu bạn rời đi ngay bây giờ, nhóm sẽ không bao giờ nhận được nó.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Rời dù sao đi nữa';

  @override
  String get replaceConfigDone => 'Cấu hình đã thay thế';

  @override
  String get replaceConfigUnchanged => 'Thiết bị này đã sử dụng cấu hình này';

  @override
  String get joinLinkHandOverMessage =>
      'Liên kết này có thể mở trong ứng dụng CountScore Android. Nếu ứng dụng không được cài đặt, Play Store sẽ mở thay thế.';

  @override
  String get joinLinkOpenInApp => 'Mở trong ứng dụng';

  @override
  String get joinLinkContinueHere => 'Tiếp tục trong trình duyệt';
}
