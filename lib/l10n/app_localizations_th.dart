// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'หน้าแรก';

  @override
  String get playersListTitle => 'รายชื่อผู้เล่น';

  @override
  String get gameTypesTitle => 'ประเภทเกม';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get aboutTitle => 'เกี่ยวกับ';

  @override
  String get newGame => 'เกมใหม่';

  @override
  String get noGames => 'ไม่มีเกม';

  @override
  String get noGamesOfThisType => 'ไม่มีเกมของประเภทนี้';

  @override
  String get createFirstGame => 'สร้างเกมแรกของคุณ';

  @override
  String get newWithSamePlayers => 'เกมใหม่ผู้เล่นเดิม';

  @override
  String get playAgain => 'เล่นอีกครั้ง';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get delete => 'ลบ';

  @override
  String get confirmDeletion => 'ยืนยันการลบ';

  @override
  String confirmDeleteGame(String name) {
    return 'คุณต้องการลบเกม \"$name\" จริงหรือ';
  }

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get renameGame => 'เปลี่ยนชื่อเกม';

  @override
  String get gameName => 'ชื่อเกม';

  @override
  String get save => 'บันทึก';

  @override
  String get allGames => 'เกมทั้งหมด';

  @override
  String get filterGames => 'กรองเกม';

  @override
  String get applyFilter => 'ใช้';

  @override
  String get resetFilter => 'รีเซ็ต';

  @override
  String get selectGameType => 'เลือกประเภทเกม';

  @override
  String get gameType => 'ประเภทเกม';

  @override
  String get loadingGameTypes => 'กำลังโหลดประเภทเกม...';

  @override
  String get lowestScoreWins => 'คะแนนต่ำสุดชนะ';

  @override
  String get highestScoreWins => 'คะแนนสูงสุดชนะ';

  @override
  String get players => 'ผู้เล่น';

  @override
  String get add => 'เพิ่ม';

  @override
  String get pleaseEnterName => 'กรุณาป้อนชื่อ';

  @override
  String get clear => 'ล้าง';

  @override
  String get remove => 'นำออก';

  @override
  String get game => 'เกม';

  @override
  String get editGame => 'แก้ไขเกม';

  @override
  String get editGameDialogTitle => 'แก้ไขเกม';

  @override
  String get removePlayer => 'นำผู้เล่นออก';

  @override
  String get addPlayerToGame => 'เพิ่มผู้เล่น';

  @override
  String get warningRemovePlayer =>
      'คำเตือน! การนำผู้เล่นนี้ออกจะลบคะแนนทั้งหมดของเขา/เธอจากเกมนี้ การกระทำนี้ไม่สามารถเลิกทำได้';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'คุณต้องการนำ $playerName ออกจากเกมนี้จริงหรือ';
  }

  @override
  String get playerRemoved => 'นำผู้เล่นออกจากเกมแล้ว';

  @override
  String get deleteLastRound => 'ลบรอบสุดท้าย';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get confirmDeleteLastRound => 'ลบรอบสุดท้ายหรือ';

  @override
  String get noPlayersInGame => 'ไม่มีผู้เล่นในเกมนี้';

  @override
  String get round => 'รอบ';

  @override
  String boardRoundButton(int round) {
    return 'รอบ $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · รอบ $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · รอบ $round · $position/$count';
  }

  @override
  String keypadTotalAfter(String total) {
    return 'รวมหลังจากนี้: $total';
  }

  @override
  String keypadNext(String player) {
    return 'ถัดไป\n$player';
  }

  @override
  String get keypadValidateRound => 'ยืนยันรอบ';

  @override
  String get keypadToggleSign => 'เปลี่ยนเครื่องหมาย';

  @override
  String get keypadBackspace => 'ลบตัวเลข';

  @override
  String get keypadShortcutTitle => 'ปุ่มลัดแป้นพิมพ์';

  @override
  String get keypadShortcutKind => 'ประเภทปุ่ม';

  @override
  String get keypadShortcutKindValue => 'ป้อนค่า';

  @override
  String get keypadShortcutKindMultiply => 'คูณคะแนน (บวกเท่านั้น)';

  @override
  String get keypadShortcutKindAdd => 'เพิ่มในคะแนน';

  @override
  String get keypadShortcutAmount => 'ตัวเลข';

  @override
  String get keypadShortcutLabel => 'ป้ายกำกับปุ่ม (ตัวเลือก)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'จำนวนเต็มระหว่าง $min และ $max นอกเหนือจากศูนย์';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'จำนวนเต็มระหว่าง $min และ $max';
  }

  @override
  String get appearance => 'รูปลักษณ์';

  @override
  String get light => 'สว่าง';

  @override
  String get dark => 'มืด';

  @override
  String get system => 'ระบบ';

  @override
  String get screen => 'จอแสดงผล';

  @override
  String get keepScreenAwake => 'เปิดใจของจอแสดงผล';

  @override
  String get keepScreenAwakeDescription =>
      'ป้องกันไม่ให้จอแสดงผลหลับไประหว่างเล่นเกม';

  @override
  String get backup => 'สำรองข้อมูล';

  @override
  String get exportDatabase => 'ส่งออกฐานข้อมูล';

  @override
  String get exportDatabaseDescription => 'บันทึกเกมทั้งหมดของคุณลงในไฟล์';

  @override
  String get databaseExportedTo => 'ส่งออกฐานข้อมูลไปยัง:';

  @override
  String get errorDuringExport => 'ข้อผิดพลาดระหว่างการส่งออก:';

  @override
  String get importDatabase => 'นำเข้าฐานข้อมูล';

  @override
  String get importDatabaseDescription => 'คืนค่าเกมของคุณจากไฟล์สำรองข้อมูล';

  @override
  String get confirmation => 'ยืนยัน';

  @override
  String get importWarning =>
      'การนำเข้าจะแทนที่ข้อมูลปัจจุบันของคุณทั้งหมด ระบบจะสร้างสำรองข้อมูลโดยอัตโนมัติก่อนการนำเข้า\n\nคุณต้องการดำเนินการต่อหรือไม่';

  @override
  String get import => 'นำเข้า';

  @override
  String get databaseImportedSuccessfully => 'นำเข้าฐานข้อมูลสำเร็จแล้ว';

  @override
  String get importSuccessful => 'นำเข้าสำเร็จ';

  @override
  String get importSuccessMessage =>
      'นำเข้าฐานข้อมูลสำเร็จแล้ว\n\nแอปพลิเคชันจะปิดตอนนี้ กรุณาเปิดใหม่เพื่อดูข้อมูลใหม่';

  @override
  String get ok => 'ตกลง';

  @override
  String get errorDuringImport => 'ข้อผิดพลาดระหว่างการนำเข้า:';

  @override
  String get noPlayers => 'ไม่มีผู้เล่น';

  @override
  String get playersAppearMessage => 'ผู้เล่นจะปรากฏที่นี่เมื่อ\nคุณสร้างเกม';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เกม',
      one: '1 เกม',
      zero: '0 เกม',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ชัยชนะ',
      one: '1 ชัยชนะ',
      zero: '0 ชัยชนะ',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'เปลี่ยนสี';

  @override
  String get renamePlayer => 'เปลี่ยนชื่อผู้เล่น';

  @override
  String get newName => 'ชื่อใหม่';

  @override
  String playerRenamedTo(String name) {
    return 'เปลี่ยนชื่อผู้เล่นเป็น \"$name\"';
  }

  @override
  String get deletePlayer => 'ลบผู้เล่น';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'คุณต้องการลบ \"$name\" จริงหรือ\n\nผู้เล่นนี้จะถูกนำออกจากเกม $count เกม';
  }

  @override
  String playerDeleted(String name) {
    return 'ลบผู้เล่น \"$name\" แล้ว';
  }

  @override
  String get chooseColor => 'เลือกสี';

  @override
  String get noGameTypes => 'ไม่มีประเภทเกม';

  @override
  String get edit => 'แก้ไข';

  @override
  String get newType => 'ประเภทใหม่';

  @override
  String get editType => 'แก้ไขประเภท';

  @override
  String get newGameType => 'ประเภทเกมใหม่';

  @override
  String get gameTypeName => 'ชื่อประเภทเกม';

  @override
  String get icon => 'ไอคอน:';

  @override
  String get color => 'สี:';

  @override
  String get chooseIcon => 'เลือกไอคอน';

  @override
  String get nameIsRequired => 'ต้องระบุชื่อ';

  @override
  String get create => 'สร้าง';

  @override
  String get ranking => 'การจัดอันดับ';

  @override
  String get noCurrentGame => 'ไม่มีเกมปัจจุบัน';

  @override
  String get noScoresRecorded => 'ไม่มีคะแนนที่บันทึก';

  @override
  String get playerStatistics => 'สถิติผู้เล่น';

  @override
  String get noStatisticsAvailable => 'ไม่มีสถิติที่พร้อมใช้งาน';

  @override
  String get gamesPlayed => 'เกมที่เล่น';

  @override
  String get wins => 'ชัยชนะ';

  @override
  String get winRate => 'อัตราชัยชนะ';

  @override
  String get byGameType => 'ตามประเภทเกม';

  @override
  String get rate => 'อัตรา';

  @override
  String version(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get appDescription =>
      'แอปพลิเคชันจัดการคะแนนสำหรับเซสชั่นเกมของคุณโดย Vincent Moreau';

  @override
  String get features => 'คุณสมบัติ';

  @override
  String get featureDifferentGameTypes => 'ประเภทเกมต่างๆ';

  @override
  String get featurePlayerManagement => 'การจัดการผู้เล่น';

  @override
  String get featureDetailedStatistics => 'สถิติโดยละเอียด';

  @override
  String get featureCustomization => 'การปรับแต่ง';

  @override
  String get featureDarkLightTheme => 'ธีมมืด/สว่าง';

  @override
  String get featureGroupSharing => 'การแชร์ในกลุ่ม';

  @override
  String get featureGameAnalysis => 'การวิเคราะห์เกม AI';

  @override
  String get rateApp => 'ให้คะแนน CountScore';

  @override
  String get search => 'ค้นหา';

  @override
  String get newPlayerName => 'ชื่อผู้เล่นใหม่';

  @override
  String get noPlayersFound => 'ไม่พบผู้เล่น';

  @override
  String get close => 'ปิด';

  @override
  String get playerEliminationCondition => 'เงื่อนไขการตัดสินผู้เล่น';

  @override
  String get gameOverCondition => 'เงื่อนไขสิ้นสุดเกม';

  @override
  String get none => 'ไม่มี';

  @override
  String get overThreshold => 'เกินขีดจำกัด';

  @override
  String get underThreshold => 'ต่ำกว่าขีดจำกัด';

  @override
  String get firstPlayerOver => 'ผู้เล่นคนแรกถึง';

  @override
  String get firstPlayerUnder => 'ผู้เล่นคนแรกต่ำกว่า';

  @override
  String get lastPlayerOver => 'ผู้เล่นคนสุดท้ายที่เหลือ (อื่นๆ เกิน)';

  @override
  String get lastPlayerUnder => 'ผู้เล่นคนสุดท้ายที่เหลือ (อื่นๆ ต่ำกว่า)';

  @override
  String get threshold => 'ขีดจำกัด';

  @override
  String get conditionType => 'ประเภทเงื่อนไข';

  @override
  String get continuePlay => 'เล่นต่อ';

  @override
  String gameEndWinner(String name) {
    return '$name ชนะ';
  }

  @override
  String gameEndTie(String names) {
    return 'เสมอ: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รอบ',
      one: '$count รอบ',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'คะแนนต่ำสุดชนะ';

  @override
  String get gameEndHighestWins => 'คะแนนสูงสุดชนะ';

  @override
  String get gameEndAnalysis => 'การวิเคราะห์';

  @override
  String get gameEndResults => 'ผลลัพธ์';

  @override
  String get rankingEliminationNote =>
      'จัดอันดับตามลำดับการตัดสิน: ผู้ที่ออกไปช้ากว่าจัดอันดับสูงกว่า ไม่ว่าจะเป็นจำนวนเงินเท่าใด';

  @override
  String get endGame => 'สิ้นสุดเกม';

  @override
  String get reopenGame => 'เปิดเกมอีกครั้ง';

  @override
  String get gameFinished => 'เสร็จสิ้น';

  @override
  String get undo => 'เลิกทำ';

  @override
  String get gameReopened => 'เปิดเกมอีกครั้งแล้ว';

  @override
  String get comment => 'ความเห็น';

  @override
  String get enterComment => 'ป้อนความเห็น';

  @override
  String get analyzeGame => 'วิเคราะห์เกม';

  @override
  String get analysisTitle => 'การวิเคราะห์เกม';

  @override
  String get analysisStyle => 'สไตล์การวิเคราะห์';

  @override
  String get analysisStyleProfessor => 'ศาสตราจารย์';

  @override
  String get analysisStyleCommentator => 'ผู้ประกาศกีฬา';

  @override
  String get analysisStyleDocumentary => 'สารคดีสัตว์ป่า';

  @override
  String get analysisStyleNoir => 'นักสืบ';

  @override
  String get analysisStyleBard => 'กวีคนสำราญ';

  @override
  String get analysisStyleCoach => 'โค้ช';

  @override
  String get analysisStyleConsultant => 'ที่ปรึกษา';

  @override
  String get analysisStyleAstrologer => 'นักโหราศาสตร์';

  @override
  String get analysisStyleRealityTv => 'รายการโทรทัศน์จริง';

  @override
  String get generatingAnalysis => 'สร้างการวิเคราะห์...';

  @override
  String get generateAnalysis => 'สร้างการวิเคราะห์';

  @override
  String get regenerateAnalysis => 'สร้างการวิเคราะห์ใหม่';

  @override
  String get deleteAnalysis => 'ลบการวิเคราะห์';

  @override
  String get confirmRegenerateAnalysis =>
      'สร้างใหม่ หรือไม่ การวิเคราะห์ปัจจุบันจะถูกแทนที่';

  @override
  String get confirmDeleteAnalysis => 'ลบการวิเคราะห์สำหรับเกมนี้หรือ';

  @override
  String get analysisError => 'ไม่สามารถสร้างการวิเคราะห์';

  @override
  String get analysisErrorUnavailable =>
      'เซิร์ฟเวอร์วิเคราะห์หมดอายุชั่วคราว ลองใหม่ภายหลัง';

  @override
  String get analysisErrorGroupBudget =>
      'กลุ่มของคุณใช้งบประมาณการวิเคราะห์หมดสำหรับเดือนนี้ ต่ออายุในตอนเริ่มต้นของเดือนหน้า';

  @override
  String get analysisStyleGroupDefault =>
      'ไม่ได้เลือกสไตล์: เกมที่แชร์นี้จะถูกวิเคราะห์ในสไตล์และภาษาของกลุ่ม';

  @override
  String analysisErrorStatus(int status) {
    return 'ไม่สามารถสร้างการวิเคราะห์ (HTTP $status)';
  }

  @override
  String get retry => 'ลองใหม่';

  @override
  String analysisGeneratedAt(String date) {
    return 'สร้างเมื่อ $date';
  }

  @override
  String get serverSection => 'เซิร์ฟเวอร์';

  @override
  String get backendUrlLabel => 'URL เซิร์ฟเวอร์';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'คุณสมบัติที่เชื่อมต่อต้องการเซิร์ฟเวอร์ CountScore ติดตั้งแบบที่โฮสต์ด้วยตัวเองจากโฟลเดอร์ backend/ และป้อน URL ที่นี่ ไม่มีเซิร์ฟเวอร์ ข้อมูลจะไม่ออกจากอุปกรณ์นี้';

  @override
  String get backendNotConfigured => 'ไม่ได้กำหนดค่าเซิร์ฟเวอร์';

  @override
  String get backendUrlInvalid =>
      'ที่อยู่ไม่ถูกต้อง ป้อน URL เต็มเช่น https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// ยอมรับได้เฉพาะบนเครือข่ายท้องถิ่นเท่านั้น ใช้ https:// สำหรับเซิร์ฟเวอร์สาธารณะ';

  @override
  String get testConnection => 'ทดสอบการเชื่อมต่อ';

  @override
  String get connectionOk => 'เซิร์ฟเวอร์ตอบสนอง';

  @override
  String get connectionFailed => 'เซิร์ฟเวอร์ไม่ตอบสนอง';

  @override
  String get serverUrlSaved => 'บันทึกเซิร์ฟเวอร์';

  @override
  String get analysisRequiresBackend =>
      'การวิเคราะห์นี้ต้องการเซิร์ฟเวอร์ กำหนดค่าหนึ่งในการตั้งค่า';

  @override
  String get openSettings => 'เปิดการตั้งค่า';

  @override
  String get serverUrlCleared => 'ล้างเซิร์ฟเวอร์';

  @override
  String get groupSection => 'กลุ่ม';

  @override
  String get groupDescription =>
      'แชร์เกมกับอุปกรณ์อื่นในกลุ่มของคุณ เกมที่แชร์ผู้เล่น คะแนน ความเห็น และการวิเคราะห์ของพวกเขาจะถูกส่งไปยังเซิร์ฟเวอร์ของคุณ เกมอื่นๆ จะอยู่บนอุปกรณ์นี้';

  @override
  String get groupNeedsServer => 'ตั้งค่าเซิร์ฟเวอร์ก่อน';

  @override
  String get groupCreate => 'สร้างกลุ่ม';

  @override
  String get groupJoin => 'เข้าร่วมกลุ่ม';

  @override
  String get groupNameLabel => 'ชื่อกลุ่ม';

  @override
  String get groupNicknameLabel => 'ชื่อเล่นของคุณ';

  @override
  String get groupNicknameHint => 'สมาชิกอื่นๆ ในกลุ่มจะเห็น';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'ชื่อเล่นของคุณ: $nickname';
  }

  @override
  String get groupNicknameEdit => 'เปลี่ยนชื่อเล่นของคุณ';

  @override
  String get shareTokenLabel => 'โค้ดเชิญ';

  @override
  String get shareTokenHint => 'วางโค้ดที่สมาชิกกลุ่มส่ง';

  @override
  String groupCurrent(String name) {
    return 'กลุ่ม: $name';
  }

  @override
  String get shareTokenExplain =>
      'ส่งโค้ดนี้ไปยังอุปกรณ์ที่ควรเข้าร่วมกลุ่ม ใครที่มีโค้ดนี้ก็สามารถเข้าร่วมได้';

  @override
  String get shareTokenCopy => 'คัดลอกโค้ด';

  @override
  String get shareTokenCopied => 'คัดลอกโค้ดแล้ว';

  @override
  String get shareTokenRotate => 'โค้ดใหม่';

  @override
  String get shareTokenRotateConfirm =>
      'โค้ดเก่าจะไม่ให้อยู่ใจใหญ่เข้าร่วมกลุ่มอีกต่อไป อุปกรณ์ที่อยู่ในกลุ่มแล้วจะไม่ได้รับผลกระทบ';

  @override
  String get groupLeave => 'ออกจากกลุ่ม';

  @override
  String get groupLeaveConfirm =>
      'อุปกรณ์นี้ออกจากกลุ่ม เกมที่แชร์จะอยู่บนอุปกรณ์นี้แต่จะไม่ซิงค์อีกต่อไป';

  @override
  String get groupLeft => 'ออกจากกลุ่มแล้ว';

  @override
  String get groupJoined => 'เข้าร่วมกลุ่มแล้ว';

  @override
  String get clearServerLeavesGroup =>
      'ล้างเซิร์ฟเวอร์ออกจากกลุ่ม เกมที่แชร์จะอยู่บนอุปกรณ์นี้';

  @override
  String get syncNow => 'ซิงค์ตอนนี้';

  @override
  String syncStatusIdle(String time) {
    return 'ซิงค์เมื่อ $time';
  }

  @override
  String get syncStatusSyncing => 'กำลังซิงค์...';

  @override
  String get syncStatusOffline =>
      'เซิร์ฟเวอร์ไม่สามารถเข้าถึงได้ — การเปลี่ยนแปลงจะถูกส่งภายหลัง';

  @override
  String get syncStatusUnauthorized =>
      'เซิร์ฟเวอร์ไม่ยอมรับอุปกรณ์นี้อีกต่อไป ออกจากกลุ่มแล้วเข้าร่วมใหม่';

  @override
  String get syncStatusError => 'ข้อผิดพลาดเซิร์ฟเวอร์ระหว่างซิงค์';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การเปลี่ยนแปลงรอดำเนิน',
      one: '1 การเปลี่ยนแปลงรอดำเนิน',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การเปลี่ยนแปลงถูกปฏิเสธโดยเซิร์ฟเวอร์',
      one: '1 การเปลี่ยนแปลงถูกปฏิเสธโดยเซิร์ฟเวอร์',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken => 'โค้ดเชิญที่ไม่รู้จักหรือถูกแทนที่';

  @override
  String get groupErrorRateLimited => 'มีการพยายามมากเกินไป ลองใหม่ในหนึ่งนาที';

  @override
  String get groupErrorUnreachable => 'เซิร์ฟเวอร์ไม่สามารถเข้าถึงได้';

  @override
  String get groupErrorServer => 'ข้อผิดพลาดเซิร์ฟเวอร์';

  @override
  String get shareWithGroup => 'แชร์กับกลุ่ม';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'อุปกรณ์ในกลุ่ม $name จะดูและแก้ไขเกมนี้';
  }

  @override
  String shareGameConfirm(String name) {
    return 'เกม ผู้เล่น คะแนน และความเห็นของเกมจะถูกส่งไปยัง $name ไม่สามารถยกเลิกการแชร์ได้';
  }

  @override
  String get gameSharedDone => 'แชร์เกมกับกลุ่มแล้ว';

  @override
  String get gameSharedBadge => 'เกมที่แชร์';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'ชื่อเหล่านี้ไม่สามารถแชร์ได้: $names ใช้ตัวอักษร ตัวเลข ช่องว่าง ยัติภังค์ เครื่องหมายอัญประกาศหรือจุด (32 ตัวอักษรมากที่สุด)';
  }

  @override
  String roundRenumbered(int number) {
    return 'รอบนี้ได้ถูกป้อนแล้วบนอุปกรณ์อื่น จึงกลายเป็นรอบ $number';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'เกม \"$name\" ถูกลบบนอุปกรณ์อื่น';
  }

  @override
  String get groupDevices => 'อุปกรณ์';

  @override
  String get groupDevicesExplain =>
      'โทรศัพท์ที่หายไปหรือขายได้อาจถูกนำออกจากกลุ่มที่นี่';

  @override
  String get groupDeviceThisOne => 'อุปกรณ์นี้';

  @override
  String groupDeviceLastSeen(String date) {
    return 'เห็นเมื่อ $date';
  }

  @override
  String get groupDeviceRevoke => 'นำออก';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'นำ \"$label\" ออกจากกลุ่ม หรือไม่ จะไม่สามารถซิงค์อีกต่อไป โค้ดเชิญจะเปลี่ยนด้วย: สมาชิกจะเก็บการเข้าถึงของพวกเขา แต่คุณจะต้องแชร์โค้ดใหม่เพื่อเชิญคนอื่น';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" ถูกนำออกแล้ว โค้ดเชิญเปลี่ยนแล้ว';
  }

  @override
  String get reportCommentary => 'รายงานบทวิจารณ์นี้';

  @override
  String get reportCommentarySubject => 'CountScore — รายงานบทวิจารณ์ AI';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'อะไรผิดกับบทวิจารณ์ที่สร้างโดย AI นี้\n\n\n---\nการอ้างอิง: $reference\nบทวิจารณ์:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'ไม่พบแอปอีเมล เขียนถึง $email เพื่อรายงานบทวิจารณ์นี้';
  }

  @override
  String get gameRulesTitle => 'กฎเกม';

  @override
  String get gameRulesInApp => 'ใน CountScore';

  @override
  String get gameRulesSection => 'กฎ';

  @override
  String get gameRulesNoElimination => 'ไม่มีการตัดสินในการเล่น';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'ผู้เล่นถูกตัดสินหากเกิน $threshold คะแนน';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'ผู้เล่นถูกตัดสินหากต่ำกว่า $threshold คะแนน';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'เกมจบทันทีที่ผู้เล่นถึง $threshold คะแนน';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'เกมจบทันทีที่ผู้เล่นต่ำกว่า $threshold คะแนน';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'เกมจบเมื่อผู้เล่นทุกคนยกเว้นหนึ่งเกิน $threshold คะแนน';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'เกมจบเมื่อผู้เล่นทุกคนยกเว้นหนึ่งต่ำกว่า $threshold คะแนน';
  }

  @override
  String get gameRulesNoEnd =>
      'ไม่มีจุดสิ้นสุดโดยอัตโนมัติ: คุณตัดสินใจเมื่อเกมจบ';

  @override
  String get gameRulesEmptyTitle => 'ยังไม่มีกฎ';

  @override
  String get gameRulesEmptyHint =>
      'จดวิธีการนับคะแนนของโต๊ะของคุณ — ทุกคนจะมีเวอร์ชันเดียวกัน';

  @override
  String get gameRulesWrite => 'เขียนกฎ';

  @override
  String get gameRulesEditTitle => 'แก้ไขกฎ';

  @override
  String get gameRulesEditorHint => 'กฎของโต๊ะของคุณ รองรับ Markdown';

  @override
  String get gameRulesFromGroup => 'กฎของกลุ่มของคุณ';

  @override
  String get gameRulesRestoreDefault => 'คืนค่าเป็นกฎดั้งเดิม';

  @override
  String get gameRulesSaved => 'บันทึกกฎแล้ว';

  @override
  String get gameRulesRestored => 'คืนค่าเป็นกฎดั้งเดิมแล้ว';

  @override
  String get gameRulesDisclaimer =>
      'สรุปที่เขียนขึ้นสำหรับ CountScore จากกฎที่เล่นกันทั่วไป ชื่อเกมเป็นของเจ้าของและใช้โดยอธิบายเท่านั้น';

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
  String get gameTypeNameOther => 'อื่นๆ';

  @override
  String get gameTypeNameOtherSortKey => 'อื่นๆ';

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
  String get groupDeviceOwner => 'เจ้าของ';

  @override
  String get groupDeviceMakeOwner => 'ตั้งเป็นเจ้าของ';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'มอบกลุ่มให้ \"$label\" หรือไม่ อุปกรณ์นี้จะไม่สามารถนำอุปกรณ์ออกหรือเปลี่ยนโค้ดเชิญได้อีกต่อไป';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" เป็นเจ้าของกลุ่มแล้ว';
  }

  @override
  String get groupDevicesExplainMember =>
      'เฉพาะเจ้าของกลุ่มเท่านั้นที่สามารถนำอุปกรณ์ออกหรือเปลี่ยนโค้ดเชิญ';

  @override
  String get groupErrorNotOwner =>
      'เฉพาะเจ้าของกลุ่มเท่านั้นที่สามารถทำสิ่งนี้ได้';

  @override
  String get whoStarts => 'ใครเริ่มต้น';

  @override
  String get whoStartsAgain => 'จับสลากใหม่';

  @override
  String get diceRoller => 'ม้วนลูกเต๋า';

  @override
  String get diceCount => 'จำนวนลูกเต๋า';

  @override
  String get diceRollAgain => 'ม้วนอีกครั้ง';

  @override
  String diceTotal(int total) {
    return 'รวม: $total';
  }

  @override
  String get resumeGame => 'ดำเนินการต่อ';

  @override
  String get recentGames => 'ล่าสุด';

  @override
  String get gameInProgress => 'อยู่ระหว่างดำเนิน';

  @override
  String roundNumber(int number) {
    return 'รอบ $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name นำ · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'ชนะโดย $name';
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
  String get boardViewRows => 'หนึ่งแถวต่อผู้เล่น';

  @override
  String get boardViewLanes => 'หนึ่งคอลัมน์ต่อผู้เล่น';

  @override
  String get boardSeatOrder => 'ลำดับที่นั่ง';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'ผู้เล่น';

  @override
  String get boardTotal => 'รวม';

  @override
  String get boardLeader => 'นำ';

  @override
  String get groupSettingsTitle => 'ความเห็นและการใช้งาน';

  @override
  String get groupSettingsDescription =>
      'สไตล์และภาษาของความเห็นที่เซิร์ฟเวอร์เขียนสำหรับเกมของกลุ่ม สมาชิกใดสามารถเปลี่ยนได้';

  @override
  String get groupCommentStyle => 'สไตล์ความเห็น';

  @override
  String get groupCommentStyleNarrative => 'บู๎ค';

  @override
  String get groupCommentStyleHumorous => 'ตลกขบขัน';

  @override
  String get groupCommentStyleAnalytical => 'วิเคราะห์';

  @override
  String get groupCommentLanguage => 'ภาษาความเห็น';

  @override
  String get groupSettingsSaved => 'บันทึกการตั้งค่ากลุ่มแล้ว';

  @override
  String get groupUsageTitle => 'การใช้ LLM เดือนนี้';

  @override
  String groupUsageAmount(String used, String budget) {
    return 'ใช้ $used จาก $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'รีเซ็ตเมื่อ $date';
  }

  @override
  String get statsBestWinRate => 'อัตราชัยชนะที่ดีที่สุด';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins ชัยชนะจาก $games',
      one: '$wins ชัยชนะจาก $games',
      zero: 'ไม่มีชัยชนะจาก $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'ผู้เล่น';

  @override
  String get statsColumnGames => 'เกม';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เกม · ยังไม่ได้จัดอันดับ',
      one: '$count เกม · ยังไม่ได้จัดอันดับ',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จัดอันดับจากเกมจบ $count เกม แตะผู้เล่นเพื่อดูการ์ดของพวกเขา',
      one: 'จัดอันดับจากเกมจบ $count เกม แตะผู้เล่นเพื่อดูการ์ดของพวกเขา',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เกม',
      one: 'เกม',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ชัยชนะ',
      one: 'ชัยชนะ',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'สถานที่เฉลี่ย';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'สถานที่ $count เกมสุดท้าย',
      one: 'สถานที่ เกมสุดท้าย',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'ดีขึ้น';

  @override
  String get statsTrendDeclining => 'แย่ลง';

  @override
  String get statsTrendSteady => 'คงที่';

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
      other: 'สตรีค: $count ชัยชนะ',
      one: 'สตรีค: $count ชัยชนะ',
      zero: 'ไม่มีชัยชนะติดต่อกัน',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'ที่ดีที่สุด: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'บน $gameType';
  }

  @override
  String get statsAverageTotal => 'รวมสุดท้ายเฉลี่ย';

  @override
  String get statsBestTotal => 'รวมสุดท้ายที่ดีที่สุด';

  @override
  String get statsMostBeaten => 'คู่ต่อสู้ที่พบบ่อยที่สุด';

  @override
  String get statsOpenPlayerCard => 'เปิดการ์ดผู้เล่น';

  @override
  String get shareResult => 'แชร์ผลลัพธ์';

  @override
  String get shareAnalysis => 'แชร์การวิเคราะห์';

  @override
  String shareResultSubject(String gameName) {
    return 'ผลลัพธ์: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'เกมของ $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points คะแนน',
      one: '$points คะแนน',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'คะแนนที่เก็บไว้ด้วย $appName: $url';
  }

  @override
  String get shareFailed => 'ไม่สามารถเปิดการแชร์';

  @override
  String get newGameNameLabel => 'ชื่อ';

  @override
  String get newGameGameLabel => 'เกม';

  @override
  String newGameAllGames(int count) {
    return 'เกมทั้งหมด ($count)';
  }

  @override
  String get newGamePlayersLabel => 'ผู้เล่น · ลำดับที่นั่ง';

  @override
  String get newGameDragToReorder => 'ลากเพื่อเรียงลำดับใหม่';

  @override
  String get newGameDealer => 'จ่าย';

  @override
  String get newGameAddPlayer => 'เพิ่มผู้เล่น';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เริ่ม · $count ผู้เล่น',
      one: 'เริ่ม · 1 ผู้เล่น',
      zero: 'เริ่ม',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'ใครกำลังเล่น';

  @override
  String get whoIsPlayingSearchHint => 'ชื่อ หรือผู้เล่นใหม่';

  @override
  String get whoIsPlayingFrequent => 'มักเล่นกับคุณ';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'ผู้เล่นเดียวกับ \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'สร้าง \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่ม $count ผู้เล่น',
      one: 'เพิ่ม 1 ผู้เล่น',
      zero: 'เสร็จสิ้น',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'เกม $number';
  }

  @override
  String get pwaUpdateReady => 'เวอร์ชันใหม่ของ CountScore พร้อมใช้งาน';

  @override
  String get pwaUpdateReload => 'โหลดใหม่';

  @override
  String get thresholdIsRequired => 'จำเป็นต้องมีขีดจำกัด';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'ขีดจำกัดไม่สามารถสูงกว่า $maxString';
  }

  @override
  String get deletionImpossible => 'ไม่สามารถลบ';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เกมใช้ประเภทนี้: ไม่สามารถลบได้',
      one: '1 เกมใช้ประเภทนี้: ไม่สามารถลบได้',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'คุณต้องการลบประเภทเกม \"$name\" จริงหรือ';
  }

  @override
  String get winDirectionChangeTitle => 'สลับผู้ชนะหรือไม่';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count เกมจบของประเภทนี้จะมีการจัดอันดับสลับไป: ผู้ชนะกลายเป็นคนสุดท้าย',
      one: '1 เกมจบของประเภทนี้จะมีการจัดอันดับสลับไป: ผู้ชนะกลายเป็นคนสุดท้าย',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'เงื่อนไขสิ้นสุดเกมให้รางวัลตรงกันข้ามของผู้ชนะที่เลือก กฎของบ้านอาจต้องการสิ่งนี้';

  @override
  String get rulesOutOfDateTitle => 'อัพเดตกฎหรือไม่';

  @override
  String get rulesOutOfDateMessage => 'กฎของประเภทนี้ยังคงอธิบายเงื่อนไขเก่า';

  @override
  String get later => 'ภายหลัง';

  @override
  String get currentIcon => 'ไอคอนปัจจุบัน';

  @override
  String get currentColor => 'สีปัจจุบัน';

  @override
  String get groupDeviceClaimOwner => 'เรียกร้องความเป็นเจ้าของ';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" เป็นเจ้าของกลุ่ม แต่ไม่เห็นมานาน คุณต้องการขอความเป็นเจ้าของบนอุปกรณ์นี้หรือไม่';
  }

  @override
  String get groupDeviceOwnerClaimed => 'อุปกรณ์นี้เป็นเจ้าของกลุ่มแล้ว';

  @override
  String get groupErrorOwnerActive =>
      'เจ้าของกลุ่มเห็นเมื่อเร็ว ๆ นี้: ไม่สามารถเรียกร้องความเป็นเจ้าของได้';

  @override
  String get groupCreatedOwnerExplain =>
      'สร้างกลุ่มแล้ว อุปกรณ์นี้เป็นเจ้าของ บทบาทสามารถมอบให้อีกอุปกรณ์ในอุปกรณ์';

  @override
  String get boardEliminated => 'ตัดสิน';

  @override
  String get soundsSection => 'เสียง';

  @override
  String get gameSounds => 'เสียงเกม';

  @override
  String get gameSoundsDescription =>
      'เสียงเมื่อผู้เล่นถูกตัดสิน เมื่อชนะเกม และเมื่อหมดเวลา';

  @override
  String get turnTimer => 'ตัวจับเวลา';

  @override
  String get turnTimerLess => 'เวลาน้อยกว่า';

  @override
  String get turnTimerMore => 'เวลามากขึ้น';

  @override
  String get turnTimerStart => 'เริ่ม';

  @override
  String get turnTimerPause => 'หยุดชั่วคราว';

  @override
  String get turnTimerReset => 'รีเซ็ต';

  @override
  String get turnTimerTimeUp => 'หมดเวลา';

  @override
  String get configShareOpen => 'แชร์ด้วยโค้ด QR';

  @override
  String get configShareTitle => 'แชร์การกำหนดค่านี้';

  @override
  String get configShareExplainServer =>
      'สแกนรหัสนี้ด้วยโทรศัพท์อื่นเพื่อตั้งค่าด้วยเซิร์ฟเวอร์เดียวกัน';

  @override
  String configShareExplainGroup(String name) {
    return 'สแกนรหัสนี้ด้วยโทรศัพท์อื่นเพื่อตั้งค่าด้วยเซิร์ฟเวอร์เดียวกันและเข้าร่วมกลุ่ม $name รหัสนี้มีโค้ดเชิญกลุ่ม: แสดงเฉพาะให้กับผู้คนที่คุณต้องการในกลุ่ม';
  }

  @override
  String get configShareWebAppLabel => 'ที่อยู่เว็บแอป';

  @override
  String get configShareWebAppHelper =>
      'ที่เซิร์ฟเวอร์ให้บริการเว็บแอป CountScore เช่น https://countscore.example.com/countscore รหัสเปิดหน้านี้';

  @override
  String get configShareWebAppNeeded => 'ป้อนที่อยู่เว็บแอปเพื่อแสดงรหัส';

  @override
  String get configShareQrLabel => 'โค้ด QR ของลิงก์การกำหนดค่า';

  @override
  String get configShareCopyLink => 'คัดลอกลิงก์';

  @override
  String get configShareLinkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get configShareTooLong =>
      'ลิงก์นี้ยาวเกินไปที่จะใส่ในโค้ด QR ใช้ \"คัดลอกลิงก์\" แทน';

  @override
  String get replaceConfigTitle => 'แทนที่การกำหนดค่าหรือไม่';

  @override
  String replaceConfigCurrent(String value) {
    return 'ตอนนี้: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'ใหม่: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'โค้ดเชิญ $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'อุปกรณ์นี้จะออกจากกลุ่ม $name เกมของมันจะอยู่บนอุปกรณ์นี้';
  }

  @override
  String get replaceConfigConfirm => 'แทนที่';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count การเปลี่ยนแปลงบนอุปกรณ์นี้ยังไม่ได้ถึงกลุ่ม หากคุณออกตอนนี้ กลุ่มจะไม่รับมันเลย',
      one: '1 การเปลี่ยนแปลงบนอุปกรณ์นี้ยังไม่ได้ถึงกลุ่ม หากคุณออกตอนนี้ กลุ่มจะไม่รับมันเลย',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'ออกไปต่อ';

  @override
  String get replaceConfigDone => 'แทนที่การกำหนดค่าแล้ว';

  @override
  String get replaceConfigUnchanged => 'อุปกรณ์นี้ใช้การกำหนดค่านี้แล้ว';

  @override
  String get joinLinkHandOverMessage =>
      'ลิงก์นี้อาจเปิดในแอป CountScore Android ถ้าไม่มีแอปติดตั้ง Play Store จะเปิดแทน';

  @override
  String get joinLinkOpenInApp => 'เปิดในแอป';

  @override
  String get joinLinkContinueHere => 'ดำเนินการต่อในเบราวเซอร์';
}
