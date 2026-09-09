import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _prefsKey = 'themeMode';

  ThemeMode _themeMode;

  ThemeProvider(this._themeMode);

  /// Falls back to [ThemeMode.system] when nothing is stored, or when the
  /// stored value is not a known [ThemeMode] name (downgrade, corrupt prefs).
  static ThemeMode decode(String? stored) => ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );

  /// Read once before `runApp` so the first frame is already themed.
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(_prefsKey));
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
