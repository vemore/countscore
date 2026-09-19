import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';

/// How the game board lays out its scores: one lane (a column) per player,
/// or one row per player.
enum BoardView { lanes, rows }

class SettingsProvider with ChangeNotifier {
  /// SharedPreferences key of [boardView], stored as the enum's name.
  static const String boardViewKey = 'boardView';

  bool _keepScreenAwake = false;
  BoardView _boardView = BoardView.lanes;

  bool get keepScreenAwake => _keepScreenAwake;

  /// The board's layout, the same for every game: the last one chosen.
  BoardView get boardView => _boardView;

  /// Completes once the stored settings are read.
  late final Future<void> ready;

  /// Export/import is mobile-only in v1 (dart:io File required).
  bool get supportsDbExportImport => !kIsWeb;

  SettingsProvider() {
    ready = _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _keepScreenAwake = prefs.getBool('keepScreenAwake') ?? false;
    final storedView = prefs.getString(boardViewKey);
    _boardView = BoardView.values
            .where((v) => v.name == storedView)
            .firstOrNull ??
        BoardView.lanes;
    notifyListeners();
    // Not awaited by [ready]: the settings are read, whatever the wake lock
    // plugin does.
    unawaited(_applyWakeLock());
  }

  Future<void> toggleKeepScreenAwake() async {
    _keepScreenAwake = !_keepScreenAwake;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepScreenAwake', _keepScreenAwake);
    await _applyWakeLock();
    notifyListeners();
  }

  Future<void> setBoardView(BoardView view) async {
    if (view == _boardView) return;
    _boardView = view;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(boardViewKey, view.name);
  }

  /// On the web, wakelock_plus loads its bundled `no_sleep.js` from the app's own
  /// origin and asks `navigator.wakeLock` for a screen lock, which the PWA's CSP
  /// allows (`script-src 'self'`); a browser without the API, or a page that is
  /// not a secure context, rejects the request and lands in the catch below.
  Future<void> _applyWakeLock() async {
    try {
      if (_keepScreenAwake) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      // A platform without the plugin — a widget test among them — keeps the
      // screen's default. The call is unawaited at load, so an error here would
      // otherwise surface as an uncaught one wherever it lands.
      debugPrint('wake lock unavailable: $e');
    }
  }

  // Exporter la base de données (mobile/desktop only)
  Future<String?> exportDatabase() async {
    if (kIsWeb) throw UnsupportedError('Export not available on web');
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) return null;
      final exportedPath =
          await DatabaseService.instance.exportDatabase(selectedDirectory);
      return exportedPath;
    } catch (e) {
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  // Importer une base de données (mobile/desktop only)
  Future<bool> importDatabase() async {
    if (kIsWeb) throw UnsupportedError('Import not available on web');
    try {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.any,
      );
      if (picked?.path == null) return false;
      await DatabaseService.instance.importDatabase(picked!.path!);
      notifyListeners();
      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'import: $e');
    }
  }
}
