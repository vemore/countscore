// Tests that the chosen ThemeMode survives a restart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countscore/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider.decode', () {
    test('falls back to system when nothing is stored', () {
      expect(ThemeProvider.decode(null), ThemeMode.system);
    });

    test('falls back to system on an unknown value', () {
      expect(ThemeProvider.decode('nonsense'), ThemeMode.system);
    });

    test('reads a known mode name', () {
      expect(ThemeProvider.decode('dark'), ThemeMode.dark);
      expect(ThemeProvider.decode('light'), ThemeMode.light);
    });
  });

  group('ThemeProvider.load', () {
    test('returns system on empty preferences', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ThemeProvider.load(), ThemeMode.system);
    });

    test('returns the stored mode', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      expect(await ThemeProvider.load(), ThemeMode.dark);
    });
  });

  group('ThemeProvider.setThemeMode', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('notifies listeners and persists the new mode', () async {
      final provider = ThemeProvider(ThemeMode.system);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(notifications, 1);
      // Re-read through the same path the app uses on a cold start.
      expect(await ThemeProvider.load(), ThemeMode.dark);
    });

    test('does nothing when the mode is unchanged', () async {
      final provider = ThemeProvider(ThemeMode.dark);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(notifications, 0);
    });
  });
}
