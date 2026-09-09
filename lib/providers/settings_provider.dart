import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _keepScreenAwake = false;

  bool get keepScreenAwake => _keepScreenAwake;

  /// Export/import is mobile-only in v1 (dart:io File required).
  bool get supportsDbExportImport => !kIsWeb;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _keepScreenAwake = prefs.getBool('keepScreenAwake') ?? false;
    await _applyWakeLock();
    notifyListeners();
  }

  Future<void> toggleKeepScreenAwake() async {
    _keepScreenAwake = !_keepScreenAwake;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepScreenAwake', _keepScreenAwake);
    await _applyWakeLock();
    notifyListeners();
  }

  Future<void> _applyWakeLock() async {
    if (kIsWeb) return; // WakelockPlus not available on web.
    if (_keepScreenAwake) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
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
