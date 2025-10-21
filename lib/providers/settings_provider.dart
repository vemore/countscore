import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _keepScreenAwake = false;

  bool get keepScreenAwake => _keepScreenAwake;

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
    if (_keepScreenAwake) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  // Exporter la base de données
  Future<String?> exportDatabase() async {
    try {
      // Demander à l'utilisateur de sélectionner un dossier
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // L'utilisateur a annulé la sélection
        return null;
      }

      // Exporter la base de données
      final exportedPath = await DatabaseService.instance.exportDatabase(selectedDirectory);
      return exportedPath;
    } catch (e) {
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  // Importer une base de données
  Future<bool> importDatabase() async {
    try {
      // Demander à l'utilisateur de sélectionner un fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.single.path == null) {
        // L'utilisateur a annulé la sélection
        return false;
      }

      // Importer la base de données
      await DatabaseService.instance.importDatabase(result.files.single.path!);
      notifyListeners();
      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'import: $e');
    }
  }
}
