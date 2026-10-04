// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => '홈';

  @override
  String get playersListTitle => '플레이어 목록';

  @override
  String get gameTypesTitle => '게임 유형';

  @override
  String get settingsTitle => '설정';

  @override
  String get aboutTitle => '정보';

  @override
  String get newGame => '새 게임';

  @override
  String get noGames => '게임이 없습니다';

  @override
  String get noGamesOfThisType => '이 유형의 게임이 없습니다';

  @override
  String get createFirstGame => '첫 번째 게임을 만들어보세요';

  @override
  String get newWithSamePlayers => '같은 플레이어로 새로 시작';

  @override
  String get playAgain => '다시 플레이';

  @override
  String get rename => '이름 변경';

  @override
  String get delete => '삭제';

  @override
  String get confirmDeletion => '삭제 확인';

  @override
  String confirmDeleteGame(String name) {
    return '\"$name\" 게임을 정말로 삭제하시겠습니까?';
  }

  @override
  String get cancel => '취소';

  @override
  String get renameGame => '게임 이름 변경';

  @override
  String get gameName => '게임 이름';

  @override
  String get save => '저장';

  @override
  String get allGames => '모든 게임';

  @override
  String get filterGames => '게임 필터';

  @override
  String get applyFilter => '적용';

  @override
  String get resetFilter => '초기화';

  @override
  String get selectGameType => '게임 유형 선택';

  @override
  String get gameType => '게임 유형';

  @override
  String get loadingGameTypes => '게임 유형 로드 중...';

  @override
  String get lowestScoreWins => '가장 낮은 점수 승리';

  @override
  String get highestScoreWins => '가장 높은 점수 승리';

  @override
  String get players => '플레이어';

  @override
  String get add => '추가';

  @override
  String get pleaseEnterName => '이름을 입력하세요';

  @override
  String get clear => '지우기';

  @override
  String get remove => '제거';

  @override
  String get game => '게임';

  @override
  String get editGame => '게임 편집';

  @override
  String get editGameDialogTitle => '게임 편집';

  @override
  String get removePlayer => '플레이어 제거';

  @override
  String get addPlayerToGame => '플레이어 추가';

  @override
  String get warningRemovePlayer =>
      '경고! 이 플레이어를 제거하면 이 게임에서 모든 점수가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String confirmRemovePlayer(String playerName) {
    return '$playerName을(를) 이 게임에서 정말로 제거하시겠습니까?';
  }

  @override
  String get playerRemoved => '게임에서 플레이어가 제거되었습니다';

  @override
  String get deleteLastRound => '마지막 라운드 삭제';

  @override
  String get confirm => '확인';

  @override
  String get confirmDeleteLastRound => '마지막 라운드를 삭제하시겠습니까?';

  @override
  String get noPlayersInGame => '이 게임에 플레이어가 없습니다';

  @override
  String get round => '라운드';

  @override
  String boardRoundButton(int round) {
    return '라운드 $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · 라운드 $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · 라운드 $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return '다음 합계: $total';
  }

  @override
  String keypadNext(String player) {
    return '다음\n$player';
  }

  @override
  String get keypadValidateRound => '라운드 확인';

  @override
  String get keypadToggleSign => '부호 변경';

  @override
  String get keypadBackspace => '숫자 삭제';

  @override
  String get keypadShortcutTitle => '키패드 단축키';

  @override
  String get keypadShortcutKind => '키 유형';

  @override
  String get keypadShortcutKindValue => '값 입력';

  @override
  String get keypadShortcutKindMultiply => '점수 곱하기 (양수만)';

  @override
  String get keypadShortcutKindAdd => '점수에 추가';

  @override
  String get keypadShortcutAmount => '숫자';

  @override
  String get keypadShortcutLabel => '키 레이블 (선택)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return '$min부터 $max까지의 정수, 0 제외';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return '$min부터 $max까지의 정수';
  }

  @override
  String get appearance => '외모';

  @override
  String get light => '밝음';

  @override
  String get dark => '어두움';

  @override
  String get system => '시스템';

  @override
  String get screen => '화면';

  @override
  String get keepScreenAwake => '화면 켜두기';

  @override
  String get keepScreenAwakeDescription => '게임 중에 화면이 잠드는 것을 방지합니다';

  @override
  String get backup => '백업';

  @override
  String get exportDatabase => '데이터베이스 내보내기';

  @override
  String get exportDatabaseDescription => '모든 게임을 파일에 저장하기';

  @override
  String get databaseExportedTo => '데이터베이스가 내보내졌습니다:';

  @override
  String get errorDuringExport => '내보내기 중 오류:';

  @override
  String get importDatabase => '데이터베이스 가져오기';

  @override
  String get importDatabaseDescription => '백업 파일에서 게임 복원하기';

  @override
  String get confirmation => '확인';

  @override
  String get importWarning =>
      '가져오기를 수행하면 현재 데이터가 모두 바뀝니다. 가져오기 전에 자동 백업이 생성됩니다.\n\n계속하시겠습니까?';

  @override
  String get import => '가져오기';

  @override
  String get databaseImportedSuccessfully => '데이터베이스가 성공적으로 가져와졌습니다';

  @override
  String get importSuccessful => '가져오기 성공';

  @override
  String get importSuccessMessage =>
      '데이터베이스가 성공적으로 가져와졌습니다.\n\n이제 애플리케이션이 종료됩니다. 다시 열어서 새 데이터를 확인하세요.';

  @override
  String get ok => '확인';

  @override
  String get errorDuringImport => '가져오기 중 오류:';

  @override
  String get noPlayers => '플레이어가 없습니다';

  @override
  String get playersAppearMessage => '게임을 만들면 플레이어가\n여기에 나타납니다';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '게임 $count개',
      one: '게임 1개',
      zero: '게임 0개',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '승리 $count개',
      one: '승리 1개',
      zero: '승리 0개',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => '색 변경';

  @override
  String get renamePlayer => '플레이어 이름 변경';

  @override
  String get newName => '새 이름';

  @override
  String playerRenamedTo(String name) {
    return '플레이어가 \"$name\"으로 이름이 변경되었습니다';
  }

  @override
  String get deletePlayer => '플레이어 삭제';

  @override
  String confirmDeletePlayer(String name, int count) {
    return '\"$name\"을(를) 정말로 삭제하시겠습니까?\n\n이 플레이어는 $count개의 게임에서 제거됩니다.';
  }

  @override
  String playerDeleted(String name) {
    return '플레이어 \"$name\"이(가) 삭제되었습니다';
  }

  @override
  String get chooseColor => '색 선택';

  @override
  String get noGameTypes => '게임 유형이 없습니다';

  @override
  String get edit => '편집';

  @override
  String get newType => '새 유형';

  @override
  String get editType => '유형 편집';

  @override
  String get newGameType => '새 게임 유형';

  @override
  String get gameTypeName => '게임 유형 이름';

  @override
  String get icon => '아이콘:';

  @override
  String get color => '색:';

  @override
  String get chooseIcon => '아이콘 선택';

  @override
  String get nameIsRequired => '이름은 필수입니다';

  @override
  String get create => '만들기';

  @override
  String get ranking => '순위';

  @override
  String get noCurrentGame => '현재 게임이 없습니다';

  @override
  String get noScoresRecorded => '기록된 점수가 없습니다';

  @override
  String get playerStatistics => '플레이어 통계';

  @override
  String get noStatisticsAvailable => '사용 가능한 통계가 없습니다';

  @override
  String get gamesPlayed => '플레이한 게임';

  @override
  String get wins => '승리';

  @override
  String get winRate => '승률';

  @override
  String get byGameType => '게임 유형별';

  @override
  String get rate => '비율';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get appDescription => 'Vincent Moreau의 게임 세션용 점수 관리 애플리케이션';

  @override
  String get features => '기능';

  @override
  String get featureDifferentGameTypes => '다양한 게임 유형';

  @override
  String get featurePlayerManagement => '플레이어 관리';

  @override
  String get featureDetailedStatistics => '상세 통계';

  @override
  String get featureCustomization => '커스터마이징';

  @override
  String get featureDarkLightTheme => '어두운/밝은 테마';

  @override
  String get featureGroupSharing => '그룹 공유';

  @override
  String get featureGameAnalysis => 'AI 게임 분석';

  @override
  String get rateApp => 'CountScore 평가';

  @override
  String get search => '검색';

  @override
  String get newPlayerName => '새 플레이어 이름';

  @override
  String get noPlayersFound => '플레이어를 찾을 수 없습니다';

  @override
  String get close => '닫기';

  @override
  String get playerEliminationCondition => '플레이어 탈락 조건';

  @override
  String get gameOverCondition => '게임 종료 조건';

  @override
  String get none => '없음';

  @override
  String get overThreshold => '임계값 초과';

  @override
  String get underThreshold => '임계값 미만';

  @override
  String get firstPlayerOver => '첫 번째로 도달';

  @override
  String get firstPlayerUnder => '첫 번째로 미만';

  @override
  String get lastPlayerOver => '마지막 플레이어 (나머지 초과)';

  @override
  String get lastPlayerUnder => '마지막 플레이어 (나머지 미만)';

  @override
  String get threshold => '임계값';

  @override
  String get conditionType => '조건 유형';

  @override
  String get continuePlay => '계속 플레이';

  @override
  String gameEndWinner(String name) {
    return '$name이(가) 승리했습니다';
  }

  @override
  String gameEndTie(String names) {
    return '무승부: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count라운드',
      one: '$count라운드',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => '가장 낮은 점수가 승리';

  @override
  String get gameEndHighestWins => '가장 높은 점수가 승리';

  @override
  String get gameEndAnalysis => '분석';

  @override
  String get gameEndResults => '결과';

  @override
  String get rankingEliminationNote =>
      '탈락 순서로 순위 매김: 나중에 탈락한 사람이 순위가 높고, 총점은 상관없습니다.';

  @override
  String get endGame => '게임 종료';

  @override
  String get reopenGame => '게임 다시 열기';

  @override
  String get gameFinished => '완료됨';

  @override
  String get undo => '실행 취소';

  @override
  String get gameReopened => '게임이 다시 열렸습니다';

  @override
  String get comment => '댓글';

  @override
  String get enterComment => '댓글 입력';

  @override
  String get analyzeGame => '게임 분석';

  @override
  String get analysisTitle => '게임 분석';

  @override
  String get analysisStyle => '분석 스타일';

  @override
  String get analysisStyleProfessor => '교수님';

  @override
  String get analysisStyleCommentator => '스포츠 해설가';

  @override
  String get analysisStyleDocumentary => '야생동물 다큐멘터리';

  @override
  String get analysisStyleNoir => '형사';

  @override
  String get analysisStyleBard => '음유시인';

  @override
  String get analysisStyleCoach => '코치';

  @override
  String get analysisStyleConsultant => '컨설턴트';

  @override
  String get analysisStyleAstrologer => '점성술사';

  @override
  String get analysisStyleRealityTv => '리얼리티 쇼';

  @override
  String get generatingAnalysis => '분석 생성 중…';

  @override
  String get generateAnalysis => '분석 생성';

  @override
  String get regenerateAnalysis => '분석 다시 생성';

  @override
  String get deleteAnalysis => '분석 삭제';

  @override
  String get confirmRegenerateAnalysis => '다시 생성하시겠습니까? 현재 분석이 교체됩니다.';

  @override
  String get confirmDeleteAnalysis => '이 게임의 분석을 삭제하시겠습니까?';

  @override
  String get analysisError => '분석 생성 실패';

  @override
  String get analysisErrorUnavailable =>
      '분석 서버를 일시적으로 사용할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get analysisErrorGroupBudget =>
      '그룹이 이번 달 분석 예산을 다 사용했습니다. 다음 달 초에 갱신됩니다.';

  @override
  String get analysisStyleGroupDefault =>
      '선택한 스타일이 없습니다: 이 공유 게임은 그룹의 스타일과 언어로 분석됩니다.';

  @override
  String analysisErrorStatus(int status) {
    return '분석 생성 실패 (HTTP $status)';
  }

  @override
  String get retry => '다시 시도';

  @override
  String analysisGeneratedAt(String date) {
    return '$date에 생성됨';
  }

  @override
  String get serverSection => '서버';

  @override
  String get backendUrlLabel => '서버 URL';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      '연결된 기능에는 CountScore 서버가 필요합니다. backend/ 폴더에서 하나를 설치하고 주소를 여기에 입력하세요. 서버가 없으면 데이터가 이 기기를 떠나지 않습니다.';

  @override
  String get backendNotConfigured => '구성된 서버 없음';

  @override
  String get backendUrlInvalid =>
      '잘못된 주소입니다. https://countscore.example.com과 같은 전체 URL을 입력하세요';

  @override
  String get backendUrlInsecure =>
      'http://은 로컬 네트워크에서만 허용됩니다. 공개 서버의 경우 https://를 사용하세요.';

  @override
  String get testConnection => '연결 테스트';

  @override
  String get connectionOk => '서버가 응답합니다';

  @override
  String get connectionFailed => '서버가 응답하지 않습니다';

  @override
  String get serverUrlSaved => '서버가 저장되었습니다';

  @override
  String get analysisRequiresBackend => '이 분석에는 서버가 필요합니다. 설정에서 하나를 구성하세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get serverUrlCleared => '서버가 지워졌습니다';

  @override
  String get groupSection => '그룹';

  @override
  String get groupDescription =>
      '그룹의 다른 기기와 게임을 공유하세요. 공유 게임, 플레이어, 점수, 댓글 및 분석이 서버로 전송됩니다. 다른 게임은 이 기기에 남아있습니다.';

  @override
  String get groupNeedsServer => '먼저 위에서 서버를 설정하세요.';

  @override
  String get groupCreate => '그룹 만들기';

  @override
  String get groupJoin => '그룹 참여';

  @override
  String get groupNameLabel => '그룹 이름';

  @override
  String get groupNicknameLabel => '당신의 닉네임';

  @override
  String get groupNicknameHint => '그룹의 다른 사람들이 볼 것입니다';

  @override
  String groupNicknameCurrent(String nickname) {
    return '당신의 닉네임: $nickname';
  }

  @override
  String get groupNicknameEdit => '닉네임 변경';

  @override
  String get shareTokenLabel => '초대 코드';

  @override
  String get shareTokenHint => '그룹 구성원이 보낸 코드를 붙여넣으세요';

  @override
  String groupCurrent(String name) {
    return '그룹: $name';
  }

  @override
  String get shareTokenExplain =>
      '이 코드를 그룹에 참여해야 하는 기기로 보내세요. 코드를 가진 사람은 누구나 참여할 수 있습니다.';

  @override
  String get shareTokenCopy => '코드 복사';

  @override
  String get shareTokenCopied => '코드가 복사되었습니다';

  @override
  String get shareTokenRotate => '새 코드';

  @override
  String get shareTokenRotateConfirm =>
      '이전 코드는 더 이상 누구도 그룹에 참여할 수 없게 합니다. 이미 그룹의 기기는 영향을 받지 않습니다.';

  @override
  String get groupLeave => '그룹 나가기';

  @override
  String get groupLeaveConfirm =>
      '이 기기가 그룹을 떠납니다. 공유 게임은 이 기기에 남아있지만 더 이상 동기화되지 않습니다.';

  @override
  String get groupLeft => '그룹을 나갔습니다';

  @override
  String get groupJoined => '그룹에 참여했습니다';

  @override
  String get clearServerLeavesGroup => '서버를 지우면 그룹을 떠납니다. 공유 게임은 이 기기에 남아있습니다.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String syncStatusIdle(String time) {
    return '$time에 동기화됨';
  }

  @override
  String get syncStatusSyncing => '동기화 중…';

  @override
  String get syncStatusOffline => '서버에 연결할 수 없음 — 변경 사항이 나중에 전송됩니다';

  @override
  String get syncStatusUnauthorized =>
      '서버가 더 이상 이 기기를 허용하지 않습니다. 그룹을 나간 후 다시 참여하세요.';

  @override
  String get syncStatusError => '동기화 중 서버 오류';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 변경 대기',
      one: '1개의 변경 대기',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '서버가 거부한 $count개의 변경',
      one: '서버가 거부한 1개의 변경',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => '알 수 없거나 교체된 초대 코드';

  @override
  String get groupErrorRateLimited => '너무 많은 시도입니다. 1분 후에 다시 시도하세요.';

  @override
  String get groupErrorUnreachable => '서버에 연결할 수 없음';

  @override
  String get groupErrorServer => '서버 오류';

  @override
  String get shareWithGroup => '그룹과 공유';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name의 기기가 이 게임을 보고 편집할 것입니다';
  }

  @override
  String shareGameConfirm(String name) {
    return '게임, 플레이어, 점수 및 댓글이 $name으로 전송됩니다. 공유는 취소할 수 없습니다.';
  }

  @override
  String get gameSharedDone => '게임이 그룹과 공유되었습니다';

  @override
  String get gameSharedBadge => '공유 게임';

  @override
  String invalidPlayerNamesForSync(String names) {
    return '이 이름은 공유할 수 없습니다: $names. 문자, 숫자, 공백, 하이픈, 아포스트로피 또는 마침표를 사용하세요 (최대 32자).';
  }

  @override
  String roundRenumbered(int number) {
    return '그 라운드는 이미 다른 기기에서 입력되었으므로 라운드 $number이 되었습니다.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\"은(는) 다른 기기에서 삭제되었습니다';
  }

  @override
  String get groupDevices => '기기';

  @override
  String get groupDevicesExplain => '잃어버렸거나 판매한 휴대폰을 여기서 그룹에서 제거할 수 있습니다.';

  @override
  String get groupDeviceThisOne => '이 기기';

  @override
  String groupDeviceLastSeen(String date) {
    return '마지막으로 본 시간 $date';
  }

  @override
  String get groupDeviceRevoke => '제거';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '\"$label\"을(를) 그룹에서 제거하시겠습니까? 더 이상 동기화되지 않을 것입니다. 초대 코드도 변경됩니다: 구성원이 액세스를 유지하지만 새 코드를 공유해야 합니다.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\"이(가) 제거되었습니다. 초대 코드가 변경되었습니다.';
  }

  @override
  String get reportCommentary => '이 평론 신고';

  @override
  String get reportCommentarySubject => 'CountScore — AI 평론 신고';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return '이 AI 생성 평론에 뭔가 잘못되었나요?\n\n\n---\n참조: $reference\n평론:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return '이메일 앱을 찾을 수 없습니다. $email에 이 평론을 신고해 주세요.';
  }

  @override
  String get gameRulesTitle => '게임 규칙';

  @override
  String get gameRulesInApp => 'CountScore에서';

  @override
  String get gameRulesSection => '규칙';

  @override
  String get gameRulesNoElimination => '플레이 중 탈락 없음';

  @override
  String gameRulesEliminationOver(int threshold) {
    return '플레이어가 $threshold점을 초과하면 탈락';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return '플레이어가 $threshold점 미만이면 탈락';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return '플레이어가 $threshold점에 도달하면 게임 종료';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return '플레이어가 $threshold점 미만이 되면 게임 종료';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return '한 명을 제외한 모든 플레이어가 $threshold점을 초과하면 게임 종료';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return '한 명을 제외한 모든 플레이어가 $threshold점 미만이 되면 게임 종료';
  }

  @override
  String get gameRulesNoEnd => '자동 종료 없음: 게임이 끝나는 시점을 직접 결정하세요';

  @override
  String get gameRulesEmptyTitle => '아직 규칙이 없습니다';

  @override
  String get gameRulesEmptyHint => '테이블의 규칙을 작성하세요 — 모두 같은 버전을 가질 것입니다.';

  @override
  String get gameRulesWrite => '규칙 작성';

  @override
  String get gameRulesEditTitle => '규칙 편집';

  @override
  String get gameRulesEditorHint => '당신의 테이블 규칙입니다. 마크다운이 지원됩니다.';

  @override
  String get gameRulesFromGroup => '그룹의 규칙';

  @override
  String get gameRulesRestoreDefault => '원래 규칙 복원';

  @override
  String get gameRulesSaved => '규칙이 저장되었습니다';

  @override
  String get gameRulesRestored => '원래 규칙이 복원되었습니다';

  @override
  String get gameRulesDisclaimer =>
      '일반적으로 플레이되는 규칙에서 CountScore용으로 작성된 요약입니다. 게임 이름은 각각의 소유자에게 속하며 설명용으로만 사용됩니다.';

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
  String get gameTypeNameOther => '기타';

  @override
  String get gameTypeNameOtherSortKey => '기타';

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
  String get groupDeviceOwner => '소유자';

  @override
  String get groupDeviceMakeOwner => '소유자로 지정';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return '그룹을 \"$label\"에 넘기시겠습니까? 이 기기는 더 이상 기기를 제거하거나 초대 코드를 변경할 수 없을 것입니다.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\"이(가) 이제 그룹을 소유합니다.';
  }

  @override
  String get groupDevicesExplainMember =>
      '그룹 소유자만 기기를 제거하거나 초대 코드를 변경할 수 있습니다.';

  @override
  String get groupErrorNotOwner => '그룹 소유자만 가능합니다';

  @override
  String get whoStarts => '누가 시작하나요?';

  @override
  String get whoStartsAgain => '다시 뽑기';

  @override
  String get diceRoller => '주사위 굴리기';

  @override
  String get diceCount => '주사위 개수';

  @override
  String get diceRollAgain => '다시 굴리기';

  @override
  String diceTotal(int total) {
    return '합계: $total';
  }

  @override
  String get resumeGame => '재개';

  @override
  String get recentGames => '최근';

  @override
  String get gameInProgress => '진행 중';

  @override
  String roundNumber(int number) {
    return '라운드 $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name이(가) 앞서고 있습니다 · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name이(가) 승리했습니다';
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
  String get boardViewRows => '플레이어당 1줄';

  @override
  String get boardViewLanes => '플레이어당 1열';

  @override
  String get boardSeatOrder => '게임 순서';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => '플레이어';

  @override
  String get boardTotal => '점수';

  @override
  String get boardLeader => '선두';

  @override
  String get groupSettingsTitle => '댓글 및 사용';

  @override
  String get groupSettingsDescription =>
      '서버가 그룹의 게임을 위해 작성하는 댓글의 스타일과 언어입니다. 모든 구성원이 변경할 수 있습니다.';

  @override
  String get groupCommentStyle => '댓글 스타일';

  @override
  String get groupCommentStyleNarrative => '서사적';

  @override
  String get groupCommentStyleHumorous => '재미있게';

  @override
  String get groupCommentStyleAnalytical => '분석적';

  @override
  String get groupCommentLanguage => '댓글 언어';

  @override
  String get groupSettingsSaved => '그룹 설정이 저장되었습니다';

  @override
  String get groupUsageTitle => '이번 달 LLM 사용량';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used개 사용 중 $budget개';
  }

  @override
  String groupUsageResets(String date) {
    return '$date에 초기화됨';
  }

  @override
  String get statsBestWinRate => '최고 승률';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '게임 $games개 중 $wins승',
      one: '게임 $games개 중 $wins승',
      zero: '게임 $games개 중 승리 없음',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => '플레이어';

  @override
  String get statsColumnGames => '게임';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count게임 · 아직 순위 없음',
      one: '$count게임 · 아직 순위 없음',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 완료된 게임에서 순위. 플레이어를 탭하여 카드를 보세요.',
      one: '$count개의 완료된 게임에서 순위. 플레이어를 탭하여 카드를 보세요.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '게임',
      one: '게임',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '승리',
      one: '승리',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => '평균 순위';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '순위, 마지막 $count게임',
      one: '순위, 마지막 게임',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => '향상 중';

  @override
  String get statsTrendDeclining => '하락 중';

  @override
  String get statsTrendSteady => '안정적';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1위',
      '2': '2위',
      '3': '3위',
      'other': '$rank위',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '연승: $count승',
      one: '연승: $count승',
      zero: '연승 없음',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return '최고: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType에서';
  }

  @override
  String get statsAverageTotal => '평균 최종 점수';

  @override
  String get statsBestTotal => '최고 최종 점수';

  @override
  String get statsMostBeaten => '가장 많이 이긴 상대';

  @override
  String get statsOpenPlayerCard => '플레이어 카드 열기';

  @override
  String get shareResult => '결과 공유';

  @override
  String get shareAnalysis => '분석 공유';

  @override
  String shareResultSubject(String gameName) {
    return '결과: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date의 게임';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points점',
      one: '$points점',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return '$appName로 점수를 기록했습니다: $url';
  }

  @override
  String get shareFailed => '공유를 열 수 없습니다';

  @override
  String get newGameNameLabel => '이름';

  @override
  String get newGameGameLabel => '게임';

  @override
  String newGameAllGames(int count) {
    return '모든 게임 ($count)';
  }

  @override
  String get newGamePlayersLabel => '플레이어 · 게임 순서';

  @override
  String get newGameDragToReorder => '순서 변경하려면 드래그';

  @override
  String get newGameDealer => '딜러';

  @override
  String get newGameAddPlayer => '플레이어 추가';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '시작 · $count명의 플레이어',
      one: '시작 · 1명의 플레이어',
      zero: '시작',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => '누가 플레이하나요?';

  @override
  String get whoIsPlayingSearchHint => '이름 또는 새 플레이어';

  @override
  String get whoIsPlayingFrequent => '자주 함께 플레이';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '\"$gameName\"과 같은 플레이어';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '\"$name\" 만들기';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명의 플레이어 추가',
      one: '1명의 플레이어 추가',
      zero: '완료',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return '게임 $number';
  }

  @override
  String get pwaUpdateReady => 'CountScore의 새 버전이 준비되었습니다';

  @override
  String get pwaUpdateReload => '새로고침';

  @override
  String get thresholdIsRequired => '이 조건에는 임계값이 필수입니다';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '임계값이 $maxString을(를) 초과할 수 없습니다';
  }

  @override
  String get deletionImpossible => '삭제 불가능';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 게임이 이 유형을 사용합니다: 삭제할 수 없습니다.',
      one: '1개의 게임이 이 유형을 사용합니다: 삭제할 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return '게임 유형 \"$name\"을(를) 정말로 삭제하시겠습니까?';
  }

  @override
  String get winDirectionChangeTitle => '승리 방향을 반전하시겠습니까?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 유형의 $count개 완료 게임의 순위가 반전됩니다: 우승자가 마지막이 됩니다.',
      one: '이 유형의 1개 완료 게임의 순위가 반전됩니다: 우승자가 마지막이 됩니다.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      '게임 종료 조건이 선택한 우승자의 반대를 보상합니다. 집의 규칙이 정확히 이것을 원할 수 있습니다.';

  @override
  String get rulesOutOfDateTitle => '규칙을 업데이트하시겠습니까?';

  @override
  String get rulesOutOfDateMessage => '이 유형의 규칙은 여전히 이전 조건을 설명합니다.';

  @override
  String get later => '나중에';

  @override
  String get currentIcon => '현재 아이콘';

  @override
  String get currentColor => '현재 색상';

  @override
  String get groupDeviceClaimOwner => '소유권 청구';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\"은(는) 그룹을 소유하지만 오래된 상태입니다. 이 기기에서 소유권을 청구하시겠습니까?';
  }

  @override
  String get groupDeviceOwnerClaimed => '이 기기가 이제 그룹을 소유합니다.';

  @override
  String get groupErrorOwnerActive => '그룹의 소유자가 최근에 활동했습니다: 소유권을 청구할 수 없습니다.';

  @override
  String get groupCreatedOwnerExplain =>
      '그룹이 만들어졌습니다. 이 기기가 소유하고 있습니다. 이 역할은 기기의 다른 부분에서 위임할 수 있습니다.';

  @override
  String get boardEliminated => '탈락';

  @override
  String get soundsSection => '음향';

  @override
  String get gameSounds => '게임 음향';

  @override
  String get gameSoundsDescription => '플레이어가 탈락하거나 게임을 이기거나 타이머가 끝날 때 나는 음향';

  @override
  String get turnTimer => '턴 타이머';

  @override
  String get turnTimerLess => '시간 감소';

  @override
  String get turnTimerMore => '시간 증가';

  @override
  String get turnTimerStart => '시작';

  @override
  String get turnTimerPause => '일시 중지';

  @override
  String get turnTimerReset => '초기화';

  @override
  String get turnTimerTimeUp => '시간 종료!';

  @override
  String get configShareOpen => 'QR 코드로 공유';

  @override
  String get configShareTitle => '이 구성 공유';

  @override
  String get configShareExplainServer => '다른 휴대폰으로 이 코드를 스캔하여 동일한 서버로 설정하세요.';

  @override
  String configShareExplainGroup(String name) {
    return '다른 휴대폰으로 이 코드를 스캔하여 동일한 서버로 설정하고 그룹 $name에 참여하세요. 그룹의 초대 코드를 포함합니다: 그룹에 참여하기를 원하는 사람에게만 표시하세요.';
  }

  @override
  String get configShareWebAppLabel => '웹 앱 주소';

  @override
  String get configShareWebAppHelper =>
      '서버가 CountScore 웹 앱을 제공하는 주소입니다 (예: https://countscore.example.com/countscore). 코드가 이 페이지를 엽니다.';

  @override
  String get configShareWebAppNeeded => 'QR 코드를 표시하려면 웹 앱 주소를 입력하세요.';

  @override
  String get configShareQrLabel => '구성 링크의 QR 코드';

  @override
  String get configShareCopyLink => '링크 복사';

  @override
  String get configShareLinkCopied => '링크가 복사되었습니다';

  @override
  String get configShareTooLong => '이 링크는 QR 코드에 맞기에 너무 깁니다. \"링크 복사\"를 사용하세요.';

  @override
  String get replaceConfigTitle => '구성을 교체하시겠습니까?';

  @override
  String replaceConfigCurrent(String value) {
    return '현재: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return '새: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return '초대 코드 $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return '이 기기가 그룹 $name을 떠날 것입니다. 게임은 이 기기에 남아있습니다.';
  }

  @override
  String get replaceConfigConfirm => '교체';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 기기의 $count개 변경이 아직 그룹에 도달하지 않았습니다. 지금 떠나면 그룹은 절대 받지 못합니다.',
      one: '이 기기의 1개 변경이 아직 그룹에 도달하지 않았습니다. 지금 떠나면 그룹은 절대 받지 못합니다.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => '어쨌든 떠나기';

  @override
  String get replaceConfigDone => '구성이 교체되었습니다';

  @override
  String get replaceConfigUnchanged => '이 기기는 이미 이 구성을 사용합니다';

  @override
  String get joinLinkHandOverMessage =>
      '이 링크는 CountScore Android 앱에서 열 수 있습니다. 앱이 설치되지 않으면 Play 스토어가 대신 열립니다.';

  @override
  String get joinLinkOpenInApp => '앱에서 열기';

  @override
  String get joinLinkContinueHere => '브라우저에서 계속';
}
