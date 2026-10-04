// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get playersListTitle => 'Daftar Pemain';

  @override
  String get gameTypesTitle => 'Jenis Permainan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String get newGame => 'Permainan Baru';

  @override
  String get noGames => 'Tidak ada permainan';

  @override
  String get noGamesOfThisType => 'Tidak ada permainan jenis ini';

  @override
  String get createFirstGame => 'Buat permainan pertama Anda';

  @override
  String get newWithSamePlayers => 'Baru dengan pemain yang sama';

  @override
  String get playAgain => 'Bermain lagi';

  @override
  String get rename => 'Ubah nama';

  @override
  String get delete => 'Hapus';

  @override
  String get confirmDeletion => 'Konfirmasi penghapusan';

  @override
  String confirmDeleteGame(String name) {
    return 'Apakah Anda ingin menghapus permainan \"$name\"?';
  }

  @override
  String get cancel => 'Batal';

  @override
  String get renameGame => 'Ubah nama permainan';

  @override
  String get gameName => 'Nama permainan';

  @override
  String get save => 'Simpan';

  @override
  String get allGames => 'Semua permainan';

  @override
  String get filterGames => 'Filter permainan';

  @override
  String get applyFilter => 'Terapkan';

  @override
  String get resetFilter => 'Atur Ulang';

  @override
  String get selectGameType => 'Pilih jenis permainan';

  @override
  String get gameType => 'Jenis permainan';

  @override
  String get loadingGameTypes => 'Memuat jenis permainan...';

  @override
  String get lowestScoreWins => 'Skor terendah menang';

  @override
  String get highestScoreWins => 'Skor tertinggi menang';

  @override
  String get players => 'Pemain';

  @override
  String get add => 'Tambah';

  @override
  String get pleaseEnterName => 'Silakan masukkan nama';

  @override
  String get clear => 'Hapus';

  @override
  String get remove => 'Hapus';

  @override
  String get game => 'Permainan';

  @override
  String get editGame => 'Edit permainan';

  @override
  String get editGameDialogTitle => 'Edit permainan';

  @override
  String get removePlayer => 'Hapus pemain';

  @override
  String get addPlayerToGame => 'Tambah pemain';

  @override
  String get warningRemovePlayer =>
      'Peringatan! Menghapus pemain ini akan menghapus semua skor mereka dari permainan ini. Tindakan ini tidak dapat dibatalkan.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Apakah Anda yakin ingin menghapus $playerName dari permainan ini?';
  }

  @override
  String get playerRemoved => 'Pemain dihapus dari permainan';

  @override
  String get deleteLastRound => 'Hapus putaran terakhir';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get confirmDeleteLastRound => 'Hapus putaran terakhir?';

  @override
  String get noPlayersInGame => 'Tidak ada pemain dalam permainan ini';

  @override
  String get round => 'Putaran';

  @override
  String boardRoundButton(int round) {
    return 'Putaran $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · putaran $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · putaran $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'total setelah: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Berikutnya\n$player';
  }

  @override
  String get keypadValidateRound => 'Validasi putaran';

  @override
  String get keypadToggleSign => 'Ubah tanda';

  @override
  String get keypadBackspace => 'Hapus angka';

  @override
  String get keypadShortcutTitle => 'Pintasan papan ketik';

  @override
  String get keypadShortcutKind => 'Jenis tombol';

  @override
  String get keypadShortcutKindValue => 'Masukkan nilai';

  @override
  String get keypadShortcutKindMultiply => 'Kalikan skor (positif saja)';

  @override
  String get keypadShortcutKindAdd => 'Tambah ke skor';

  @override
  String get keypadShortcutAmount => 'Angka';

  @override
  String get keypadShortcutLabel => 'Label tombol (opsional)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'Angka bulat antara $min dan $max, bukan 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'Angka bulat antara $min dan $max';
  }

  @override
  String get appearance => 'Tampilan';

  @override
  String get light => 'Terang';

  @override
  String get dark => 'Gelap';

  @override
  String get system => 'Sistem';

  @override
  String get screen => 'Layar';

  @override
  String get keepScreenAwake => 'Jaga layar tetap aktif';

  @override
  String get keepScreenAwakeDescription =>
      'Mencegah layar tidur selama permainan';

  @override
  String get backup => 'Cadangan';

  @override
  String get exportDatabase => 'Ekspor basis data';

  @override
  String get exportDatabaseDescription => 'Simpan semua permainan Anda ke file';

  @override
  String get databaseExportedTo => 'Basis data diekspor ke:';

  @override
  String get errorDuringExport => 'Kesalahan saat mengekspor:';

  @override
  String get importDatabase => 'Impor basis data';

  @override
  String get importDatabaseDescription =>
      'Pulihkan permainan Anda dari file cadangan';

  @override
  String get confirmation => 'Konfirmasi';

  @override
  String get importWarning =>
      'Mengimpor akan menggantikan semua data Anda saat ini. Cadangan otomatis akan dibuat sebelum impor.\n\nApakah Anda ingin melanjutkan?';

  @override
  String get import => 'Impor';

  @override
  String get databaseImportedSuccessfully => 'Basis data berhasil diimpor';

  @override
  String get importSuccessful => 'Impor berhasil';

  @override
  String get importSuccessMessage =>
      'Basis data telah berhasil diimpor.\n\nAplikasi akan ditutup sekarang. Silakan buka kembali untuk melihat data baru.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Kesalahan saat mengimpor:';

  @override
  String get noPlayers => 'Tidak ada pemain';

  @override
  String get playersAppearMessage =>
      'Pemain akan muncul di sini setelah\nAnda membuat permainan';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permainan',
      one: '1 permainan',
      zero: '0 permainan',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kemenangan',
      one: '1 kemenangan',
      zero: '0 kemenangan',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Ubah warna';

  @override
  String get renamePlayer => 'Ubah nama pemain';

  @override
  String get newName => 'Nama baru';

  @override
  String playerRenamedTo(String name) {
    return 'Pemain diubah nama menjadi \"$name\"';
  }

  @override
  String get deletePlayer => 'Hapus pemain';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Apakah Anda yakin ingin menghapus \"$name\"?\n\nPemain ini akan dihapus dari semua $count permainan.';
  }

  @override
  String playerDeleted(String name) {
    return 'Pemain \"$name\" dihapus';
  }

  @override
  String get chooseColor => 'Pilih warna';

  @override
  String get noGameTypes => 'Tidak ada jenis permainan';

  @override
  String get edit => 'Edit';

  @override
  String get newType => 'Jenis baru';

  @override
  String get editType => 'Edit jenis';

  @override
  String get newGameType => 'Jenis permainan baru';

  @override
  String get gameTypeName => 'Nama jenis permainan';

  @override
  String get icon => 'Ikon:';

  @override
  String get color => 'Warna:';

  @override
  String get chooseIcon => 'Pilih ikon';

  @override
  String get nameIsRequired => 'Nama diperlukan';

  @override
  String get create => 'Buat';

  @override
  String get ranking => 'Peringkat';

  @override
  String get noCurrentGame => 'Tidak ada permainan saat ini';

  @override
  String get noScoresRecorded => 'Tidak ada skor yang dicatat';

  @override
  String get playerStatistics => 'Statistik Pemain';

  @override
  String get noStatisticsAvailable => 'Tidak ada statistik tersedia';

  @override
  String get gamesPlayed => 'Permainan dimainkan';

  @override
  String get wins => 'Kemenangan';

  @override
  String get winRate => 'Tingkat kemenangan';

  @override
  String get byGameType => 'Berdasarkan jenis permainan';

  @override
  String get rate => 'Rating';

  @override
  String version(String version) {
    return 'Versi $version';
  }

  @override
  String get appDescription =>
      'Aplikasi manajemen skor untuk sesi permainan Anda oleh Vincent Moreau';

  @override
  String get features => 'Fitur';

  @override
  String get featureDifferentGameTypes => 'Jenis permainan berbeda';

  @override
  String get featurePlayerManagement => 'Manajemen pemain';

  @override
  String get featureDetailedStatistics => 'Statistik terperinci';

  @override
  String get featureCustomization => 'Kustomisasi';

  @override
  String get featureDarkLightTheme => 'Tema gelap/terang';

  @override
  String get featureGroupSharing => 'Berbagi grup';

  @override
  String get featureGameAnalysis => 'Analisis permainan AI';

  @override
  String get rateApp => 'Rating CountScore';

  @override
  String get search => 'Cari';

  @override
  String get newPlayerName => 'Nama pemain baru';

  @override
  String get noPlayersFound => 'Tidak ada pemain ditemukan';

  @override
  String get close => 'Tutup';

  @override
  String get playerEliminationCondition => 'Kondisi Eliminasi Pemain';

  @override
  String get gameOverCondition => 'Kondisi Game Over';

  @override
  String get none => 'Tidak ada';

  @override
  String get overThreshold => 'Di atas ambang batas';

  @override
  String get underThreshold => 'Di bawah ambang batas';

  @override
  String get firstPlayerOver => 'Pemain pertama untuk mencapai';

  @override
  String get firstPlayerUnder => 'Pemain pertama di bawah';

  @override
  String get lastPlayerOver => 'Pemain terakhir berdiri (yang lain di atas)';

  @override
  String get lastPlayerUnder => 'Pemain terakhir berdiri (yang lain di bawah)';

  @override
  String get threshold => 'Ambang batas';

  @override
  String get conditionType => 'Jenis Kondisi';

  @override
  String get continuePlay => 'Terus Bermain';

  @override
  String gameEndWinner(String name) {
    return '$name menang';
  }

  @override
  String gameEndTie(String names) {
    return 'Seri: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count putaran',
      one: '$count putaran',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'skor terendah menang';

  @override
  String get gameEndHighestWins => 'skor tertinggi menang';

  @override
  String get gameEndAnalysis => 'Analisis';

  @override
  String get gameEndResults => 'Hasil';

  @override
  String get rankingEliminationNote =>
      'Peringkat berdasarkan urutan eliminasi: siapa yang keluar lebih dulu, skor berapa pun.';

  @override
  String get endGame => 'Akhiri Permainan';

  @override
  String get reopenGame => 'Buka Kembali Permainan';

  @override
  String get gameFinished => 'Selesai';

  @override
  String get undo => 'Batalkan';

  @override
  String get gameReopened => 'Permainan dibuka kembali';

  @override
  String get comment => 'Komentar';

  @override
  String get enterComment => 'Masukkan komentar';

  @override
  String get analyzeGame => 'Analisis permainan';

  @override
  String get analysisTitle => 'Analisis permainan';

  @override
  String get analysisStyle => 'Gaya analisis';

  @override
  String get analysisStyleProfessor => 'Profesor';

  @override
  String get analysisStyleCommentator => 'Komentator olahraga';

  @override
  String get analysisStyleDocumentary => 'Dokumenter satwa liar';

  @override
  String get analysisStyleNoir => 'Detektif';

  @override
  String get analysisStyleBard => 'Penyair';

  @override
  String get analysisStyleCoach => 'Pelatih';

  @override
  String get analysisStyleConsultant => 'Konsultan';

  @override
  String get analysisStyleAstrologer => 'Astrolog';

  @override
  String get analysisStyleRealityTv => 'Acara realitas';

  @override
  String get generatingAnalysis => 'Membuat analisis…';

  @override
  String get generateAnalysis => 'Buat analisis';

  @override
  String get regenerateAnalysis => 'Buat ulang analisis';

  @override
  String get deleteAnalysis => 'Hapus analisis';

  @override
  String get confirmRegenerateAnalysis =>
      'Buat ulang? Analisis saat ini akan diganti.';

  @override
  String get confirmDeleteAnalysis => 'Hapus analisis untuk permainan ini?';

  @override
  String get analysisError => 'Gagal membuat analisis';

  @override
  String get analysisErrorUnavailable =>
      'Server analisis tidak tersedia saat ini. Coba lagi nanti.';

  @override
  String get analysisErrorGroupBudget =>
      'Grup Anda telah menghabiskan anggaran analisis bulan ini. Akan diperbaharui di awal bulan depan.';

  @override
  String get analysisStyleGroupDefault =>
      'Tidak ada gaya dipilih: permainan bersama ini dianalisis dalam gaya dan bahasa grup.';

  @override
  String analysisErrorStatus(int status) {
    return 'Gagal membuat analisis (HTTP $status)';
  }

  @override
  String get retry => 'Coba Lagi';

  @override
  String analysisGeneratedAt(String date) {
    return 'Dibuat pada $date';
  }

  @override
  String get serverSection => 'Server';

  @override
  String get backendUrlLabel => 'URL Server';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Fitur terhubung memerlukan server CountScore. Instal satu dari folder backend/ dan masukkan alamatnya di sini. Tanpa server, tidak ada data yang meninggalkan perangkat ini.';

  @override
  String get backendNotConfigured => 'Tidak ada server yang dikonfigurasi';

  @override
  String get backendUrlInvalid =>
      'Alamat tidak valid. Masukkan URL lengkap, misalnya https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// hanya diterima di jaringan lokal. Gunakan https:// untuk server publik.';

  @override
  String get testConnection => 'Uji koneksi';

  @override
  String get connectionOk => 'Server merespons';

  @override
  String get connectionFailed => 'Server tidak merespons';

  @override
  String get serverUrlSaved => 'Server disimpan';

  @override
  String get analysisRequiresBackend =>
      'Analisis ini memerlukan server. Konfigurasikan satu di pengaturan.';

  @override
  String get openSettings => 'Buka pengaturan';

  @override
  String get serverUrlCleared => 'Server dihapus';

  @override
  String get groupSection => 'Grup';

  @override
  String get groupDescription =>
      'Bagikan permainan dengan perangkat lain dalam grup Anda. Permainan bersama, pemain, skor, komentar, dan analisis dikirim ke server Anda; permainan lain tetap di perangkat ini.';

  @override
  String get groupNeedsServer => 'Atur server di atas terlebih dahulu.';

  @override
  String get groupCreate => 'Buat grup';

  @override
  String get groupJoin => 'Bergabung dengan grup';

  @override
  String get groupNameLabel => 'Nama grup';

  @override
  String get groupNicknameLabel => 'Nama panggilan Anda';

  @override
  String get groupNicknameHint => 'Yang lain di grup akan melihatnya';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Nama panggilan Anda: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Ubah nama panggilan Anda';

  @override
  String get shareTokenLabel => 'Kode undangan';

  @override
  String get shareTokenHint =>
      'Tempel kode yang dikirim anggota grup kepada Anda';

  @override
  String groupCurrent(String name) {
    return 'Grup: $name';
  }

  @override
  String get shareTokenExplain =>
      'Kirim kode ini ke perangkat yang harus bergabung dengan grup. Siapa pun yang memilikinya dapat bergabung.';

  @override
  String get shareTokenCopy => 'Salin kode';

  @override
  String get shareTokenCopied => 'Kode disalin';

  @override
  String get shareTokenRotate => 'Kode baru';

  @override
  String get shareTokenRotateConfirm =>
      'Kode lama tidak lagi membiarkan siapa pun bergabung. Perangkat yang sudah ada di grup tidak terpengaruh.';

  @override
  String get groupLeave => 'Tinggalkan grup';

  @override
  String get groupLeaveConfirm =>
      'Perangkat ini meninggalkan grup. Permainan bersama tetap di perangkat ini tetapi tidak akan lagi disinkronkan.';

  @override
  String get groupLeft => 'Meninggalkan grup';

  @override
  String get groupJoined => 'Bergabung dengan grup';

  @override
  String get clearServerLeavesGroup =>
      'Menghapus server meninggalkan grup. Permainan bersama tetap di perangkat ini.';

  @override
  String get syncNow => 'Sinkronkan sekarang';

  @override
  String syncStatusIdle(String time) {
    return 'Disinkronkan pada $time';
  }

  @override
  String get syncStatusSyncing => 'Menyinkronkan…';

  @override
  String get syncStatusOffline =>
      'Server tidak terjangkau — perubahan akan dikirim nanti';

  @override
  String get syncStatusUnauthorized =>
      'Server tidak lagi menerima perangkat ini. Tinggalkan grup, lalu bergabunglah lagi.';

  @override
  String get syncStatusError => 'Kesalahan server saat sinkronisasi';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perubahan menunggu',
      one: '1 perubahan menunggu',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perubahan ditolak oleh server',
      one: '1 perubahan ditolak oleh server',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Kode undangan tidak dikenal atau sudah diganti';

  @override
  String get groupErrorRateLimited =>
      'Terlalu banyak percobaan. Coba lagi dalam semenit.';

  @override
  String get groupErrorUnreachable => 'Server tidak terjangkau';

  @override
  String get groupErrorServer => 'Kesalahan server';

  @override
  String get shareWithGroup => 'Bagikan dengan grup';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Perangkat di $name akan melihat dan mengedit permainan ini';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Permainan, pemain, skor, dan komentar akan dikirim ke $name. Berbagi tidak dapat dibatalkan.';
  }

  @override
  String get gameSharedDone => 'Permainan dibagikan dengan grup';

  @override
  String get gameSharedBadge => 'Permainan bersama';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Nama-nama ini tidak dapat dibagikan: $names. Gunakan huruf, angka, spasi, tanda hubung, apostrof, atau titik (maksimal 32 karakter).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Putaran itu sudah dimasukkan di perangkat lain, jadi menjadi putaran $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return '\"$name\" dihapus di perangkat lain';
  }

  @override
  String get groupDevices => 'Perangkat';

  @override
  String get groupDevicesExplain =>
      'Ponsel yang hilang atau dijual dapat dihapus dari grup di sini.';

  @override
  String get groupDeviceThisOne => 'Perangkat ini';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Terakhir dilihat $date';
  }

  @override
  String get groupDeviceRevoke => 'Hapus';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Hapus \"$label\" dari grup? Itu tidak akan lagi disinkronkan. Kode undangan berubah juga: anggota mempertahankan akses mereka, tetapi Anda perlu berbagi kode baru untuk mengundang siapa pun.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '\"$label\" dihapus. Kode undangan telah berubah.';
  }

  @override
  String get reportCommentary => 'Laporkan komentar ini';

  @override
  String get reportCommentarySubject => 'CountScore — laporan komentar AI';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Apa yang salah dengan komentar yang dihasilkan AI ini?\n\n\n---\nReferensi: $reference\nKomentar:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Tidak ada aplikasi email yang ditemukan. Tulis ke $email untuk melaporkan komentar ini.';
  }

  @override
  String get gameRulesTitle => 'Aturan permainan';

  @override
  String get gameRulesInApp => 'Di CountScore';

  @override
  String get gameRulesSection => 'Aturan-aturannya';

  @override
  String get gameRulesNoElimination => 'Tidak ada eliminasi selama permainan';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Pemain dieliminasi di atas $threshold poin';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Pemain dieliminasi di bawah $threshold poin';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Permainan berakhir segera setelah pemain mencapai $threshold poin';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Permainan berakhir segera setelah pemain turun di bawah $threshold poin';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Permainan berakhir ketika setiap pemain kecuali satu berada di atas $threshold poin';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Permainan berakhir ketika setiap pemain kecuali satu berada di bawah $threshold poin';
  }

  @override
  String get gameRulesNoEnd =>
      'Tidak ada akhir otomatis: Anda memutuskan kapan permainan selesai';

  @override
  String get gameRulesEmptyTitle => 'Belum ada aturan';

  @override
  String get gameRulesEmptyHint =>
      'Tuliskan bagaimana meja Anda menghitung poin — semua orang akan memiliki versi yang sama.';

  @override
  String get gameRulesWrite => 'Tulis aturan';

  @override
  String get gameRulesEditTitle => 'Edit aturan';

  @override
  String get gameRulesEditorHint => 'Aturan meja Anda. Markdown didukung.';

  @override
  String get gameRulesFromGroup => 'Aturan grup Anda';

  @override
  String get gameRulesRestoreDefault => 'Pulihkan aturan asli';

  @override
  String get gameRulesSaved => 'Aturan disimpan';

  @override
  String get gameRulesRestored => 'Aturan asli dipulihkan';

  @override
  String get gameRulesDisclaimer =>
      'Ringkasan ditulis untuk CountScore dari aturan seperti yang biasanya dimainkan. Nama permainan adalah milik pemiliknya masing-masing dan digunakan hanya secara deskriptif.';

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
  String get gameTypeNameOther => 'Lainnya';

  @override
  String get gameTypeNameOtherSortKey => 'Lainnya';

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
  String get groupDeviceOwner => 'Pemilik';

  @override
  String get groupDeviceMakeOwner => 'Jadikan pemilik';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Serahkan grup ke \"$label\"? Perangkat ini tidak akan lagi dapat menghapus perangkat atau mengubah kode undangan.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '\"$label\" sekarang memiliki grup.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Hanya pemilik grup yang dapat menghapus perangkat atau mengubah kode undangan.';

  @override
  String get groupErrorNotOwner =>
      'Hanya pemilik grup yang dapat melakukan ini';

  @override
  String get whoStarts => 'Siapa yang memulai?';

  @override
  String get whoStartsAgain => 'Undian lagi';

  @override
  String get diceRoller => 'Lempar dadu';

  @override
  String get diceCount => 'Jumlah dadu';

  @override
  String get diceRollAgain => 'Lempar lagi';

  @override
  String diceTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get resumeGame => 'Lanjutkan';

  @override
  String get recentGames => 'Terakhir';

  @override
  String get gameInProgress => 'Sedang berlangsung';

  @override
  String roundNumber(int number) {
    return 'putaran $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name memimpin · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Dimenangkan oleh $name';
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
  String get boardViewRows => 'Satu baris per pemain';

  @override
  String get boardViewLanes => 'Satu kolom per pemain';

  @override
  String get boardSeatOrder => 'Urutan tempat duduk';

  @override
  String boardRoundShort(int number) {
    return 'P$number';
  }

  @override
  String get boardPlayer => 'Pemain';

  @override
  String get boardTotal => 'Total';

  @override
  String get boardLeader => 'Memimpin';

  @override
  String get groupSettingsTitle => 'Komentar dan penggunaan';

  @override
  String get groupSettingsDescription =>
      'Gaya dan bahasa komentar yang ditulis server untuk permainan grup. Anggota apa pun dapat mengubahnya.';

  @override
  String get groupCommentStyle => 'Gaya komentar';

  @override
  String get groupCommentStyleNarrative => 'Naratif';

  @override
  String get groupCommentStyleHumorous => 'Lucu';

  @override
  String get groupCommentStyleAnalytical => 'Analitis';

  @override
  String get groupCommentLanguage => 'Bahasa komentar';

  @override
  String get groupSettingsSaved => 'Pengaturan grup disimpan';

  @override
  String get groupUsageTitle => 'Penggunaan LLM bulan ini';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used dihabiskan dari $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Direset pada $date';
  }

  @override
  String get statsBestWinRate => 'Tingkat kemenangan terbaik';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins kemenangan dari $games',
      one: '$wins kemenangan dari $games',
      zero: 'Tidak ada kemenangan dari $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Pemain';

  @override
  String get statsColumnGames => 'Permainan';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permainan · belum peringkat',
      one: '$count permainan · belum peringkat',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Peringkat dari $count permainan selesai. Ketuk pemain untuk melihat kartu mereka.',
      one:
          'Peringkat dari $count permainan selesai. Ketuk pemain untuk melihat kartu mereka.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'permainan',
      one: 'permainan',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kemenangan',
      one: 'kemenangan',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'tempat rata-rata';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tempat, $count permainan terakhir',
      one: 'Tempat, permainan terakhir',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'meningkat';

  @override
  String get statsTrendDeclining => 'menurun';

  @override
  String get statsTrendSteady => 'stabil';

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
      other: 'Garis: $count kemenangan',
      one: 'Garis: $count kemenangan',
      zero: 'Tidak ada garis kemenangan',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Terbaik: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Di $gameType';
  }

  @override
  String get statsAverageTotal => 'Total akhir rata-rata';

  @override
  String get statsBestTotal => 'Total akhir terbaik';

  @override
  String get statsMostBeaten => 'Lawan yang paling sering kalah';

  @override
  String get statsOpenPlayerCard => 'buka kartu pemain';

  @override
  String get shareResult => 'Bagikan hasilnya';

  @override
  String get shareAnalysis => 'Bagikan analisis';

  @override
  String shareResultSubject(String gameName) {
    return 'Hasil: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Permainan $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points poin',
      one: '$points poin',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Skor disimpan dengan $appName: $url';
  }

  @override
  String get shareFailed => 'Berbagi tidak dapat dibuka';

  @override
  String get newGameNameLabel => 'Nama';

  @override
  String get newGameGameLabel => 'Permainan';

  @override
  String newGameAllGames(int count) {
    return 'Semua permainan ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Pemain · urutan tempat duduk';

  @override
  String get newGameDragToReorder => 'seret untuk mengatur ulang';

  @override
  String get newGameDealer => 'membagikan kartu';

  @override
  String get newGameAddPlayer => 'Tambah pemain';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mulai · $count pemain',
      one: 'Mulai · 1 pemain',
      zero: 'Mulai',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Siapa yang bermain?';

  @override
  String get whoIsPlayingSearchHint => 'Nama, atau pemain baru';

  @override
  String get whoIsPlayingFrequent => 'Sering bermain dengan Anda';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Pemain yang sama seperti \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Buat \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tambah $count pemain',
      one: 'Tambah 1 pemain',
      zero: 'Selesai',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Permainan $number';
  }

  @override
  String get pwaUpdateReady => 'Versi baru CountScore siap';

  @override
  String get pwaUpdateReload => 'Muat ulang';

  @override
  String get thresholdIsRequired => 'Ambang batas diperlukan untuk kondisi ini';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Ambang batas tidak dapat melebihi $maxString';
  }

  @override
  String get deletionImpossible => 'Penghapusan tidak mungkin';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permainan menggunakan jenis ini: tidak dapat dihapus.',
      one: '1 permainan menggunakan jenis ini: tidak dapat dihapus.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Apakah Anda yakin ingin menghapus jenis permainan \"$name\"?';
  }

  @override
  String get winDirectionChangeTitle => 'Balik siapa yang menang?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count permainan selesai dari jenis ini akan memiliki peringkat mereka dibalik: pemenang mereka menjadi yang terakhir.',
      one: '1 permainan selesai dari jenis ini akan memiliki peringkatnya dibalik: pemenangnya menjadi yang terakhir.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'Kondisi game-over memberi penghargaan yang berlawanan dengan pemenang yang dipilih. Aturan rumah mungkin menginginkan persis itu.';

  @override
  String get rulesOutOfDateTitle => 'Perbarui aturannya?';

  @override
  String get rulesOutOfDateMessage =>
      'Aturan jenis ini masih menjelaskan kondisi lama.';

  @override
  String get later => 'Nanti';

  @override
  String get currentIcon => 'Ikon saat ini';

  @override
  String get currentColor => 'Warna saat ini';

  @override
  String get groupDeviceClaimOwner => 'Klaim kepemilikan';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return '\"$label\" memiliki grup tetapi belum terlihat dalam waktu lama. Ambil alih kepemilikan di perangkat ini?';
  }

  @override
  String get groupDeviceOwnerClaimed => 'Perangkat ini sekarang memiliki grup.';

  @override
  String get groupErrorOwnerActive =>
      'Pemilik grup telah terlihat baru-baru ini: kepemilikan tidak dapat diklaim.';

  @override
  String get groupCreatedOwnerExplain =>
      'Grup dibuat. Perangkat ini memilikinya; peran dapat diserahkan ke perangkat lain di Perangkat.';

  @override
  String get boardEliminated => 'Dieliminasi';

  @override
  String get soundsSection => 'Suara';

  @override
  String get gameSounds => 'Suara permainan';

  @override
  String get gameSoundsDescription =>
      'Suara ketika pemain dieliminasi, ketika permainan dimenangkan, dan ketika pengatur waktu berakhir';

  @override
  String get turnTimer => 'Pengatur waktu giliran';

  @override
  String get turnTimerLess => 'Waktu lebih sedikit';

  @override
  String get turnTimerMore => 'Lebih banyak waktu';

  @override
  String get turnTimerStart => 'Mulai';

  @override
  String get turnTimerPause => 'Jeda';

  @override
  String get turnTimerReset => 'Atur Ulang';

  @override
  String get turnTimerTimeUp => 'Waktu habis!';

  @override
  String get configShareOpen => 'Bagikan dengan kode QR';

  @override
  String get configShareTitle => 'Bagikan konfigurasi ini';

  @override
  String get configShareExplainServer =>
      'Pindai kode ini dengan ponsel lain untuk menyiapkannya dengan server yang sama.';

  @override
  String configShareExplainGroup(String name) {
    return 'Pindai kode ini dengan ponsel lain untuk menyiapkannya dengan server yang sama dan bergabung dengan grup $name. Itu berisi kode undangan grup: tampilkan hanya kepada orang-orang yang ingin Anda di grup.';
  }

  @override
  String get configShareWebAppLabel => 'Alamat aplikasi web';

  @override
  String get configShareWebAppHelper =>
      'Tempat server menayangkan aplikasi web CountScore, seperti https://countscore.example.com/countscore. Kode membuka halaman ini.';

  @override
  String get configShareWebAppNeeded =>
      'Masukkan alamat aplikasi web untuk menampilkan kode.';

  @override
  String get configShareQrLabel => 'Kode QR tautan konfigurasi';

  @override
  String get configShareCopyLink => 'Salin tautan';

  @override
  String get configShareLinkCopied => 'Tautan disalin';

  @override
  String get configShareTooLong =>
      'Tautan ini terlalu panjang untuk muat dalam kode QR. Gunakan \"Salin tautan\" sebagai gantinya.';

  @override
  String get replaceConfigTitle => 'Ganti konfigurasi?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Sekarang: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Baru: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'kode undangan $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'Perangkat ini akan meninggalkan grup $name. Permainannya tetap di perangkat ini.';
  }

  @override
  String get replaceConfigConfirm => 'Ganti';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count perubahan di perangkat ini belum mencapai grup. Jika Anda pergi sekarang, grup tidak akan pernah menerimanya.',
      one: '1 perubahan di perangkat ini belum mencapai grup. Jika Anda pergi sekarang, grup tidak akan pernah menerimanya.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Pergi saja';

  @override
  String get replaceConfigDone => 'Konfigurasi diganti';

  @override
  String get replaceConfigUnchanged =>
      'Perangkat ini sudah menggunakan konfigurasi ini';

  @override
  String get joinLinkHandOverMessage =>
      'Tautan ini dapat dibuka di aplikasi CountScore Android. Jika aplikasi tidak terinstal, Play Store terbuka sebagai gantinya.';

  @override
  String get joinLinkOpenInApp => 'Buka di aplikasi';

  @override
  String get joinLinkContinueHere => 'Lanjutkan di browser';
}
