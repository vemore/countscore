// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Anasayfa';

  @override
  String get playersListTitle => 'Oyuncular Listesi';

  @override
  String get gameTypesTitle => 'Oyun Türleri';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get newGame => 'Yeni Oyun';

  @override
  String get noGames => 'Oyun yok';

  @override
  String get noGamesOfThisType => 'Bu türde oyun yok';

  @override
  String get createFirstGame => 'İlk oyununuzu oluşturun';

  @override
  String get newWithSamePlayers => 'Aynı oyuncularla yeni oyun';

  @override
  String get playAgain => 'Tekrar oyna';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get delete => 'Sil';

  @override
  String get confirmDeletion => 'Silmeyi onayla';

  @override
  String confirmDeleteGame(String name) {
    return '\"$name\" oyununu silmek istediğinizden emin misiniz?';
  }

  @override
  String get cancel => 'İptal';

  @override
  String get renameGame => 'Oyunu yeniden adlandır';

  @override
  String get gameName => 'Oyun adı';

  @override
  String get save => 'Kaydet';

  @override
  String get allGames => 'Tüm oyunlar';

  @override
  String get filterGames => 'Oyunları filtrele';

  @override
  String get applyFilter => 'Uygula';

  @override
  String get resetFilter => 'Sıfırla';

  @override
  String get selectGameType => 'Bir oyun türü seçin';

  @override
  String get gameType => 'Oyun türü';

  @override
  String get loadingGameTypes => 'Oyun türleri yükleniyor...';

  @override
  String get lowestScoreWins => 'En düşük skor kazanır';

  @override
  String get highestScoreWins => 'En yüksek skor kazanır';

  @override
  String get players => 'Oyuncular';

  @override
  String get add => 'Ekle';

  @override
  String get pleaseEnterName => 'Lütfen bir ad girin';

  @override
  String get clear => 'Temizle';

  @override
  String get remove => 'Kaldır';

  @override
  String get game => 'Oyun';

  @override
  String get editGame => 'Oyunu düzenle';

  @override
  String get editGameDialogTitle => 'Oyunu düzenle';

  @override
  String get removePlayer => 'Oyuncuyu kaldır';

  @override
  String get addPlayerToGame => 'Oyuncu ekle';

  @override
  String get warningRemovePlayer =>
      'Uyarı! Bu oyuncuyu kaldırmak, bu oyundaki tüm puanlarını silecektir. Bu işlem geri alınamaz.';

  @override
  String confirmRemovePlayer(String playerName) {
    return '$playerName oyuncusunu bu oyundan kaldırmak istediğinizden emin misiniz?';
  }

  @override
  String get playerRemoved => 'Oyuncu oyundan kaldırıldı';

  @override
  String get deleteLastRound => 'Son turu sil';

  @override
  String get confirm => 'Onayla';

  @override
  String get confirmDeleteLastRound => 'Son tur silinsin mi?';

  @override
  String get noPlayersInGame => 'Bu oyunda oyuncu yok';

  @override
  String get round => 'Tur';

  @override
  String boardRoundButton(int round) {
    return 'Tur $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · tur $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · tur $round · $position/$count';
  }

  @override
  String keypadTotalAfter(String total) {
    return 'sonra toplam: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Sonraki\n$player';
  }

  @override
  String get keypadValidateRound => 'Turu onayla';

  @override
  String get keypadToggleSign => 'İşareti değiştir';

  @override
  String get keypadBackspace => 'Bir rakam sil';

  @override
  String get keypadShortcutTitle => 'Tuş takısı kısayolu';

  @override
  String get keypadShortcutKind => 'Tuş türü';

  @override
  String get keypadShortcutKindValue => 'Bir değer gir';

  @override
  String get keypadShortcutKindMultiply => 'Puanı çarp (sadece pozitif)';

  @override
  String get keypadShortcutKindAdd => 'Puana ekle';

  @override
  String get keypadShortcutAmount => 'Sayı';

  @override
  String get keypadShortcutLabel => 'Tuş etiketi (isteğe bağlı)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return '$min ve $max arasında bir tam sayı, 0 dışında';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return '$min ve $max arasında bir tam sayı';
  }

  @override
  String get appearance => 'Görünüm';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get system => 'Sistem';

  @override
  String get screen => 'Ekran';

  @override
  String get keepScreenAwake => 'Ekranı açık tutun';

  @override
  String get keepScreenAwakeDescription =>
      'Oyun sırasında ekranın uyku moduna girmesini engeller';

  @override
  String get backup => 'Yedekleme';

  @override
  String get exportDatabase => 'Veritabanını dışa aktar';

  @override
  String get exportDatabaseDescription =>
      'Tüm oyunlarınızı bir dosyaya kaydedin';

  @override
  String get databaseExportedTo => 'Veritabanı dışa aktarıldı:';

  @override
  String get errorDuringExport => 'Dışa aktarma sırasında hata:';

  @override
  String get importDatabase => 'Veritabanını içe aktar';

  @override
  String get importDatabaseDescription =>
      'Oyunlarınızı yedek dosyasından geri yükleyin';

  @override
  String get confirmation => 'Onay';

  @override
  String get importWarning =>
      'İçe aktarma tüm mevcut verilerinizi değiştirecektir. İçe aktarmadan önce otomatik bir yedek oluşturulacaktır.\n\nDevam etmek ister misiniz?';

  @override
  String get import => 'İçe aktar';

  @override
  String get databaseImportedSuccessfully =>
      'Veritabanı başarıyla içe aktarıldı';

  @override
  String get importSuccessful => 'İçe aktarma başarılı';

  @override
  String get importSuccessMessage =>
      'Veritabanı başarıyla içe aktarıldı.\n\nUygulama şimdi kapatılacak. Yeni verileri görmek için lütfen tekrar açın.';

  @override
  String get ok => 'Tamam';

  @override
  String get errorDuringImport => 'İçe aktarma sırasında hata:';

  @override
  String get noPlayers => 'Oyuncu yok';

  @override
  String get playersAppearMessage =>
      'Oyunlar oluşturulduktan sonra\noyuncular burada görünecektir';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyun',
      one: '1 oyun',
      zero: '0 oyun',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zafer',
      one: '1 zafer',
      zero: '0 zafer',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Rengi değiştir';

  @override
  String get renamePlayer => 'Oyuncuyu yeniden adlandır';

  @override
  String get newName => 'Yeni ad';

  @override
  String playerRenamedTo(String name) {
    return 'Oyuncu \"$name\" olarak yeniden adlandırıldı';
  }

  @override
  String get deletePlayer => 'Oyuncuyu sil';

  @override
  String confirmDeletePlayer(String name, int count) {
    return '\"$name\" oyuncusunu silmek istediğinizden emin misiniz?\n\nBu oyuncu $count oyundan kaldırılacak.';
  }

  @override
  String playerDeleted(String name) {
    return '\"$name\" oyuncusu silindi';
  }

  @override
  String get chooseColor => 'Bir renk seçin';

  @override
  String get noGameTypes => 'Oyun türü yok';

  @override
  String get edit => 'Düzenle';

  @override
  String get newType => 'Yeni tür';

  @override
  String get editType => 'Türü düzenle';

  @override
  String get newGameType => 'Yeni oyun türü';

  @override
  String get gameTypeName => 'Oyun türü adı';

  @override
  String get icon => 'İkon:';

  @override
  String get color => 'Renk:';

  @override
  String get chooseIcon => 'Bir ikon seçin';

  @override
  String get nameIsRequired => 'Ad gereklidir';

  @override
  String get create => 'Oluştur';

  @override
  String get ranking => 'Sıralama';

  @override
  String get noCurrentGame => 'Mevcut oyun yok';

  @override
  String get noScoresRecorded => 'Hiçbir puan kaydedilmedi';

  @override
  String get playerStatistics => 'Oyuncu İstatistikleri';

  @override
  String get noStatisticsAvailable => 'İstatistik yok';

  @override
  String get gamesPlayed => 'Oynanan oyunlar';

  @override
  String get wins => 'Zafetler';

  @override
  String get winRate => 'Zafer yüzdesi';

  @override
  String get byGameType => 'Oyun türüne göre';

  @override
  String get rate => 'Oran';

  @override
  String version(String version) {
    return 'Sürüm $version';
  }

  @override
  String get appDescription =>
      'Oyun seanslarınız için skor yönetim uygulaması - Vincent Moreau';

  @override
  String get features => 'Özellikler';

  @override
  String get featureDifferentGameTypes => 'Farklı oyun türleri';

  @override
  String get featurePlayerManagement => 'Oyuncu yönetimi';

  @override
  String get featureDetailedStatistics => 'Ayrıntılı istatistikler';

  @override
  String get featureCustomization => 'Özelleştirme';

  @override
  String get featureDarkLightTheme => 'Koyu/açık tema';

  @override
  String get featureGroupSharing => 'Grup paylaşımı';

  @override
  String get featureGameAnalysis => 'Yapay zeka oyun analizi';

  @override
  String get rateApp => 'CountScore değerlendir';

  @override
  String get search => 'Ara';

  @override
  String get newPlayerName => 'Yeni oyuncu adı';

  @override
  String get noPlayersFound => 'Oyuncu bulunamadı';

  @override
  String get close => 'Kapat';

  @override
  String get playerEliminationCondition => 'Oyuncu Eleme Koşulu';

  @override
  String get gameOverCondition => 'Oyun Bitme Koşulu';

  @override
  String get none => 'Hiçbiri';

  @override
  String get overThreshold => 'Eşik değerini aş';

  @override
  String get underThreshold => 'Eşik değerinin altında';

  @override
  String get firstPlayerOver => 'İlk oyuncu ulaşır';

  @override
  String get firstPlayerUnder => 'İlk oyuncu altında';

  @override
  String get lastPlayerOver => 'Son kalan oyuncu (diğerleri üstünde)';

  @override
  String get lastPlayerUnder => 'Son kalan oyuncu (diğerleri altında)';

  @override
  String get threshold => 'Eşik değeri';

  @override
  String get conditionType => 'Koşul Türü';

  @override
  String get continuePlay => 'Oynamaya Devam Et';

  @override
  String gameEndWinner(String name) {
    return '$name kazanır';
  }

  @override
  String gameEndTie(String names) {
    return 'Berabere: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tur',
      one: '$count tur',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'en düşük skor kazanır';

  @override
  String get gameEndHighestWins => 'en yüksek skor kazanır';

  @override
  String get gameEndAnalysis => 'Analiz';

  @override
  String get gameEndResults => 'Sonuçlar';

  @override
  String get rankingEliminationNote =>
      'Eleme sırasına göre sıralanır: daha sonra çıkan oyuncu, toplamdan bağımsız olarak öne geçer.';

  @override
  String get endGame => 'Oyunu Bitir';

  @override
  String get reopenGame => 'Oyunu tekrar aç';

  @override
  String get gameFinished => 'Tamamlandı';

  @override
  String get undo => 'Geri al';

  @override
  String get gameReopened => 'Oyun tekrar açıldı';

  @override
  String get comment => 'Yorum';

  @override
  String get enterComment => 'Bir yorum girin';

  @override
  String get analyzeGame => 'Oyunu analiz et';

  @override
  String get analysisTitle => 'Oyun analizi';

  @override
  String get analysisStyle => 'Analiz stili';

  @override
  String get analysisStyleProfessor => 'Profesör';

  @override
  String get analysisStyleCommentator => 'Spor spikeri';

  @override
  String get analysisStyleDocumentary => 'Vahşi yaşam belgeseli';

  @override
  String get analysisStyleNoir => 'Dedektif';

  @override
  String get analysisStyleBard => 'Ozanlar';

  @override
  String get analysisStyleCoach => 'Antrenör';

  @override
  String get analysisStyleConsultant => 'Danışman';

  @override
  String get analysisStyleAstrologer => 'Astroloji uzmanı';

  @override
  String get analysisStyleRealityTv => 'Gerçeklik şovu';

  @override
  String get generatingAnalysis => 'Analiz oluşturuluyor…';

  @override
  String get generateAnalysis => 'Analiz oluştur';

  @override
  String get regenerateAnalysis => 'Analizi yeniden oluştur';

  @override
  String get deleteAnalysis => 'Analizi sil';

  @override
  String get confirmRegenerateAnalysis =>
      'Yeniden oluştur? Mevcut analiz değiştirilecektir.';

  @override
  String get confirmDeleteAnalysis => 'Bu oyunun analizi silinsin mi?';

  @override
  String get analysisError => 'Analiz oluşturma başarısız';

  @override
  String get analysisErrorUnavailable =>
      'Analiz sunucusu geçici olarak kullanılamıyor. Daha sonra tekrar deneyin.';

  @override
  String get analysisErrorGroupBudget =>
      'Grubunuz bu ay için analiz bütçesini tüketmiştir. Gelecek ayın başında yenilenir.';

  @override
  String get analysisStyleGroupDefault =>
      'Stil seçilmedi: bu paylaşılan oyun grubun stili ve diliyle analiz edilecek.';

  @override
  String analysisErrorStatus(int status) {
    return 'Analiz oluşturma başarısız (HTTP $status)';
  }

  @override
  String get retry => 'Tekrar dene';

  @override
  String analysisGeneratedAt(String date) {
    return '$date tarihinde oluşturuldu';
  }

  @override
  String get serverSection => 'Sunucu';

  @override
  String get backendUrlLabel => 'Sunucu URL\'si';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Bağlantılı özellikler bir CountScore sunucusu gerektirir. Backend/ klasöründen birisini kurun ve adresini buraya girin. Sunucu olmadığında, hiçbir veri bu cihazdan çıkmaz.';

  @override
  String get backendNotConfigured => 'Sunucu yapılandırılmadı';

  @override
  String get backendUrlInvalid =>
      'Geçersiz adres. Tam bir URL girin, örneğin https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// sadece yerel ağda kabul edilir. Genel bir sunucu için https:// kullanın.';

  @override
  String get testConnection => 'Bağlantıyı test et';

  @override
  String get connectionOk => 'Sunucu yanıt veriyor';

  @override
  String get connectionFailed => 'Sunucu yanıt vermiyor';

  @override
  String get serverUrlSaved => 'Sunucu kaydedildi';

  @override
  String get analysisRequiresBackend =>
      'Bu analiz bir sunucu gerektirir. Ayarlarda birini yapılandırın.';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get serverUrlCleared => 'Sunucu temizlendi';

  @override
  String get groupSection => 'Grup';

  @override
  String get groupDescription =>
      'Grubunuzdaki diğer cihazlarla oyunları paylaşın. Paylaşılan oyunlar, oyuncuları, puanları, yorumları ve analizleri sunucunuza gönderilir; diğer oyunlar bu cihazda kalır.';

  @override
  String get groupNeedsServer => 'Önce yukarıya bir sunucu kurun.';

  @override
  String get groupCreate => 'Grup oluştur';

  @override
  String get groupJoin => 'Gruba katıl';

  @override
  String get groupNameLabel => 'Grup adı';

  @override
  String get groupNicknameLabel => 'Sizin takma adınız';

  @override
  String get groupNicknameHint => 'Gruptaki diğerleri bunu görecek';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Sizin takma adınız: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Takma adınızı değiştirin';

  @override
  String get shareTokenLabel => 'Davet kodu';

  @override
  String get shareTokenHint => 'Bir grup üyesinin gönderdiği kodu yapıştırın';

  @override
  String groupCurrent(String name) {
    return 'Grup: $name';
  }

  @override
  String get shareTokenExplain =>
      'Bu kodu gruba katılması gereken cihazlara gönderin. Onu alan herkes katılabilir.';

  @override
  String get shareTokenCopy => 'Kodu kopyala';

  @override
  String get shareTokenCopied => 'Kod kopyalandı';

  @override
  String get shareTokenRotate => 'Yeni kod';

  @override
  String get shareTokenRotateConfirm =>
      'Eski kod artık kimsenin gruba katılmasına izin vermez. Zaten üye olan cihazlar etkilenmez.';

  @override
  String get groupLeave => 'Grubu terk et';

  @override
  String get groupLeaveConfirm =>
      'Bu cihaz grubu terk edecek. Paylaşılan oyunlar bu cihazda kalacak ancak artık eşitlenmeyecek.';

  @override
  String get groupLeft => 'Grup terk edildi';

  @override
  String get groupJoined => 'Gruba katıldı';

  @override
  String get clearServerLeavesGroup =>
      'Sunucuyu silmek grubu terk ettirir. Paylaşılan oyunlar bu cihazda kalır.';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String syncStatusIdle(String time) {
    return '$time tarihinde eşitlendi';
  }

  @override
  String get syncStatusSyncing => 'Eşitleniyor…';

  @override
  String get syncStatusOffline =>
      'Sunucuya ulaşılamıyor — değişiklikler daha sonra gönderilecek';

  @override
  String get syncStatusUnauthorized =>
      'Sunucu artık bu cihazı kabul etmiyor. Grubu terk edin, sonra tekrar katılın.';

  @override
  String get syncStatusError => 'Eşitleme sırasında sunucu hatası';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik bekleniyor',
      one: '1 değişiklik bekleniyor',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik sunucu tarafından reddedildi',
      one: '1 değişiklik sunucu tarafından reddedildi',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Bilinmeyen veya değiştirilen davet kodu';

  @override
  String get groupErrorRateLimited =>
      'Çok fazla deneme. Bir dakika sonra tekrar deneyin.';

  @override
  String get groupErrorUnreachable => 'Sunucuya ulaşılamıyor';

  @override
  String get groupErrorServer => 'Sunucu hatası';

  @override
  String get shareWithGroup => 'Grupla paylaş';

  @override
  String shareWithGroupSubtitle(String name) {
    return '$name grubundaki cihazlar bu oyunu görecek ve düzenleyecek';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Oyun, oyuncuları, puanları ve yorumları $name adlı gruba gönderilecek. Paylaşım geri alınamaz.';
  }

  @override
  String get gameSharedDone => 'Oyun grupla paylaşıldı';

  @override
  String get gameSharedBadge => 'Paylaşılan oyun';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Bu adlar paylaşılamaz: $names. Harfler, rakamlar, boşluklar, tipler, kesmeleri veya noktaları kullanın (en fazla 32 karakter).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Bu tur başka bir cihazda zaten girilmişti, bu nedenle $number turu oldu.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" başka bir cihazda silindi';
  }

  @override
  String get groupDevices => 'Cihazlar';

  @override
  String get groupDevicesExplain =>
      'Kaybolan veya satılan bir telefon burada gruptan kaldırılabilir.';

  @override
  String get groupDeviceThisOne => 'Bu cihaz';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Son olarak $date tarihinde görüldü';
  }

  @override
  String get groupDeviceRevoke => 'Kaldır';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '\"$label\" öğesini gruptan kaldırsın mı? Artık eşitlenmeyecek. Davet kodu da değişir: üyeler erişimlerini tutar, ancak herhangi birini davet etmek için yeni kodu paylaşmanız gerekir.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" kaldırıldı. Davet kodu değişti.';
  }

  @override
  String get reportCommentary => 'Bu yorumu bildir';

  @override
  String get reportCommentarySubject => 'CountScore — Yapay zeka yorum raporu';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Bu yapay zeka tarafından üretilen yorumda sorun nedir?\n\n\n---\nReferans: $reference\nYorum:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'E-posta uygulaması bulunamadı. Bu yorumu bildirmek için $email adresine yazın.';
  }

  @override
  String get gameRulesTitle => 'Oyun kuralları';

  @override
  String get gameRulesInApp => 'CountScore\'da';

  @override
  String get gameRulesSection => 'Kurallar';

  @override
  String get gameRulesNoElimination => 'Oyun sırasında eleme yok';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Bir oyuncu $threshold puanın üzerinde elenir';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Bir oyuncu $threshold puanın altında elenir';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Bir oyuncu $threshold puana ulaştığında oyun biter';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Bir oyuncu $threshold puanın altına düştüğünde oyun biter';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Birden fazla oyuncu $threshold puanı aştığında oyun biter';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Birden fazla oyuncu $threshold puanın altında olduğunda oyun biter';
  }

  @override
  String get gameRulesNoEnd =>
      'Otomatik sonlanma yok: oyun ne zaman bittiğine siz karar verirsiniz';

  @override
  String get gameRulesEmptyTitle => 'Henüz kural yok';

  @override
  String get gameRulesEmptyHint =>
      'Tablonuzun puanları nasıl saydığını yazın — herkes aynı sürüme sahip olacak.';

  @override
  String get gameRulesWrite => 'Kuralları yazın';

  @override
  String get gameRulesEditTitle => 'Kuralları düzenle';

  @override
  String get gameRulesEditorHint =>
      'Tablonuzun kuralları. Markdown desteklenir.';

  @override
  String get gameRulesFromGroup => 'Grubunuzun kuralları';

  @override
  String get gameRulesRestoreDefault => 'Orijinal kuralları geri yükle';

  @override
  String get gameRulesSaved => 'Kurallar kaydedildi';

  @override
  String get gameRulesRestored => 'Orijinal kurallar geri yüklendi';

  @override
  String get gameRulesDisclaimer =>
      'CountScore için yazılan özet, genel olarak oynanan kurallardan. Oyun adları sahibine aittir ve sadece açıklayıcı olarak kullanılır.';

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
  String get gameTypeNameOther => 'Diğer';

  @override
  String get gameTypeNameOtherSortKey => 'Diğer';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNameSkyjoSortKey => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'Başkan';

  @override
  String get gameTypeNamePresidentSortKey => 'Başkan';

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
  String get gameTypeNameSixNimmt => '6\'yı Al';

  @override
  String get gameTypeNameSixNimmtSortKey => '6\'yı Al';

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
  String get groupDeviceOwner => 'Sahibi';

  @override
  String get groupDeviceMakeOwner => 'Sahibi yap';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Grubu \"$label\" adlı kişiye teslim eder misiniz? Bu cihaz artık cihazları kaldıramayacak veya davet kodunu değiştiremeyecek.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" şimdi grubun sahibi.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Sadece grubun sahibi bir cihazı kaldırabilir veya davet kodunu değiştirebilir.';

  @override
  String get groupErrorNotOwner => 'Sadece grubun sahibi bunu yapabilir';

  @override
  String get whoStarts => 'Kim başlar?';

  @override
  String get whoStartsAgain => 'Tekrar çek';

  @override
  String get diceRoller => 'Zar at';

  @override
  String get diceCount => 'Zar sayısı';

  @override
  String get diceRollAgain => 'Tekrar at';

  @override
  String diceTotal(int total) {
    return 'Toplam: $total';
  }

  @override
  String get resumeGame => 'Devam et';

  @override
  String get recentGames => 'Son oyunlar';

  @override
  String get gameInProgress => 'Devam ediyor';

  @override
  String roundNumber(int number) {
    return 'tur $number';
  }

  @override
  String gameLeader(String name, String score) {
    return '$name öncü · $score';
  }

  @override
  String gameWonBy(String name) {
    return '$name tarafından kazanıldı';
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
  String get boardViewRows => 'Oyuncu başına bir satır';

  @override
  String get boardViewLanes => 'Oyuncu başına bir sütun';

  @override
  String get boardSeatOrder => 'Oturma sırası';

  @override
  String boardRoundShort(int number) {
    return 'T$number';
  }

  @override
  String get boardPlayer => 'Oyuncu';

  @override
  String get boardTotal => 'Toplam';

  @override
  String get boardLeader => 'Öncü';

  @override
  String get groupSettingsTitle => 'Yorumlar ve kullanım';

  @override
  String get groupSettingsDescription =>
      'Sunucunun grup oyunları için yazdığı yorumların stili ve dili. Herhangi bir üye bunları değiştirebilir.';

  @override
  String get groupCommentStyle => 'Yorum stili';

  @override
  String get groupCommentStyleNarrative => 'Anlatı';

  @override
  String get groupCommentStyleHumorous => 'Mizahi';

  @override
  String get groupCommentStyleAnalytical => 'Analitik';

  @override
  String get groupCommentLanguage => 'Yorum dili';

  @override
  String get groupSettingsSaved => 'Grup ayarları kaydedildi';

  @override
  String get groupUsageTitle => 'Bu ay yapay zeka kullanımı';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used ($budget dışı harcandı)';
  }

  @override
  String groupUsageResets(String date) {
    return '$date tarihinde sıfırlanır';
  }

  @override
  String get statsBestWinRate => 'En iyi zafer yüzdesi';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$games oyundan $wins zafer',
      one: '$games oyundan $wins zafer',
      zero: '$games oyundan hiç zafer',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Oyuncu';

  @override
  String get statsColumnGames => 'Oyunlar';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyun · henüz sıralanmamış',
      one: '$count oyun · henüz sıralanmamış',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bitmiş oyundan sıralandı. Oyuncunun kartını görmek için dokunun.',
      one:
          '$count bitmiş oyundan sıralandı. Oyuncunun kartını görmek için dokunun.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'oyun',
      one: 'oyun',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zafer',
      one: 'zafer',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'ortalama sıra';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sıra, son $count oyun',
      one: 'Sıra, son oyun',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'iyileşiyor';

  @override
  String get statsTrendDeclining => 'kötüleşiyor';

  @override
  String get statsTrendSteady => 'sabit';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1.',
      '2': '2.',
      '3': '3.',
      'other': '$rank.',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seri: $count zafer',
      one: 'Seri: $count zafer',
      zero: 'Zafer serisi yok',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(String total) {
    return 'En iyi: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return '$gameType oyununda';
  }

  @override
  String get statsAverageTotal => 'Ortalama final toplamı';

  @override
  String get statsBestTotal => 'En iyi final toplamı';

  @override
  String get statsMostBeaten => 'En çok mağlup edilen rakip';

  @override
  String get statsOpenPlayerCard => 'oyuncu kartını aç';

  @override
  String get shareResult => 'Sonucu paylaş';

  @override
  String get shareAnalysis => 'Analizi paylaş';

  @override
  String shareResultSubject(String gameName) {
    return 'Sonuç: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return '$date oyunu';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points puan',
      one: '$points puan',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return '$appName ile sayılan puanlar: $url';
  }

  @override
  String get shareFailed => 'Paylaşım açılamadı';

  @override
  String get newGameNameLabel => 'Ad';

  @override
  String get newGameGameLabel => 'Oyun';

  @override
  String newGameAllGames(int count) {
    return 'Tüm oyunlar ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Oyuncular · oturma sırası';

  @override
  String get newGameDragToReorder => 'yeniden sıralamak için sürükleyin';

  @override
  String get newGameDealer => 'dağıtır';

  @override
  String get newGameAddPlayer => 'Oyuncu ekle';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Başla · $count oyuncu',
      one: 'Başla · 1 oyuncu',
      zero: 'Başla',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Kim oynuyor?';

  @override
  String get whoIsPlayingSearchHint => 'Ad, veya yeni oyuncu';

  @override
  String get whoIsPlayingFrequent => 'Sık sık sizinle oynuyor';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return '\"$gameName\" ile aynı oyuncular';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return '\"$name\" oluştur';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyuncu ekle',
      one: '1 oyuncu ekle',
      zero: 'Bitti',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Oyun $number';
  }

  @override
  String get pwaUpdateReady => 'CountScore\'un yeni sürümü hazır';

  @override
  String get pwaUpdateReload => 'Yeniden yükle';

  @override
  String get thresholdIsRequired => 'Bu koşul için eşik değeri gereklidir';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Eşik değeri $maxString değerini aşamaz';
  }

  @override
  String get deletionImpossible => 'Silme imkansız';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyun bu türü kullanır: silinemez.',
      one: '1 oyun bu türü kullanır: silinemez.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return '\"$name\" oyun türünü silmek istediğinizden emin misiniz?';
  }

  @override
  String get winDirectionChangeTitle => 'Kim kazanır tersine mi çevirelim?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu türün $count bitmiş oyunu sıralandı tersine çevrilecek: kazananları sonuncu olacak.',
      one: 'Bu türün 1 bitmiş oyunu sıralandı tersine çevrilecek: kazananı sonuncu olacak.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'Oyun bitme koşulu seçilen kazananın tersi yönü ödüllendirir. Bir ev kuralı tam olarak bunu isteyebilir.';

  @override
  String get rulesOutOfDateTitle => 'Kuralları güncellemek ister misiniz?';

  @override
  String get rulesOutOfDateMessage =>
      'Bu türün kuralları yine de eski koşulu tanımlıyor.';

  @override
  String get later => 'Sonra';

  @override
  String get currentIcon => 'Mevcut ikon';

  @override
  String get currentColor => 'Mevcut renk';

  @override
  String get groupDeviceClaimOwner => 'Sahipliği talep et';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" grubu elinde tutuyor ancak uzun süredir görülmüyor. Bu cihazda sahipliği devralmak ister misiniz?';
  }

  @override
  String get groupDeviceOwnerClaimed => 'Bu cihaz şimdi grubun sahibi.';

  @override
  String get groupErrorOwnerActive =>
      'Grubun sahibi yakında görüldü: sahiplik talep edilemez.';

  @override
  String get groupCreatedOwnerExplain =>
      'Grup oluşturuldu. Bu cihaz sahibi; rol Cihazlarda başka birine verilebilir.';

  @override
  String get boardEliminated => 'Elendi';

  @override
  String get soundsSection => 'Sesler';

  @override
  String get gameSounds => 'Oyun sesleri';

  @override
  String get gameSoundsDescription =>
      'Bir oyuncu elendiğinde, oyun kazanıldığında ve zaman bittiğinde ses';

  @override
  String get turnTimer => 'Tur zamanlayıcısı';

  @override
  String get turnTimerLess => 'Daha az zaman';

  @override
  String get turnTimerMore => 'Daha fazla zaman';

  @override
  String get turnTimerStart => 'Başla';

  @override
  String get turnTimerPause => 'Durakla';

  @override
  String get turnTimerReset => 'Sıfırla';

  @override
  String get turnTimerTimeUp => 'Zaman bitti!';

  @override
  String get configShareOpen => 'QR kod ile paylaş';

  @override
  String get configShareTitle => 'Bu yapılandırmayı paylaş';

  @override
  String get configShareExplainServer =>
      'Bu kodu başka bir telefonla tarayarak aynı sunucuyla kurun.';

  @override
  String configShareExplainGroup(String name) {
    return 'Bu kodu başka bir telefonla tarayarak aynı sunucuyla kurun ve $name grubuna katılın. Grubun davet kodunu tutar: sadece grupta olmak istediğiniz kişilere gösterin.';
  }

  @override
  String get configShareWebAppLabel => 'Web uygulaması adresi';

  @override
  String get configShareWebAppHelper =>
      'Sunucunuzun CountScore web uygulamasını hizmet verdiği yer, örneğin https://countscore.example.com/countscore. Kod bu sayfayı açar.';

  @override
  String get configShareWebAppNeeded =>
      'Kodu göstermek için web uygulaması adresini girin.';

  @override
  String get configShareQrLabel => 'Yapılandırma bağlantısının QR kodu';

  @override
  String get configShareCopyLink => 'Bağlantıyı kopyala';

  @override
  String get configShareLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get configShareTooLong =>
      'Bu bağlantı bir QR koduna sığmak için çok uzun. \"Bağlantıyı kopyala\" ı kullanın.';

  @override
  String get replaceConfigTitle => 'Yapılandırma değiştirilsin mi?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Şu an: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Yeni: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'davet kodu $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'Bu cihaz $name grubunu terk edecek. Oyunları bu cihazda kalır.';
  }

  @override
  String get replaceConfigConfirm => 'Değiştir';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihazın $count değişikliği henüz gruba ulaşmadı. Şimdi ayrılırsanız, grup onları asla almayacak.',
      one: 'Bu cihazın 1 değişikliği henüz gruba ulaşmadı. Şimdi ayrılırsanız, grup onu asla almayacak.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Yine de ayrıl';

  @override
  String get replaceConfigDone => 'Yapılandırma değiştirildi';

  @override
  String get replaceConfigUnchanged =>
      'Bu cihaz zaten bu yapılandırmayı kullanıyor';

  @override
  String get joinLinkHandOverMessage =>
      'Bu bağlantı CountScore Android uygulamasında açılabilir. Uygulama kurulu değilse, Play Store bunun yerine açılır.';

  @override
  String get joinLinkOpenInApp => 'Uygulamada aç';

  @override
  String get joinLinkContinueHere => 'Tarayıcıda devam et';
}
