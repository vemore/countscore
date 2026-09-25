// A custom type's keypad shortcut, set in the game-type editor, is written to
// the database file and read back after a restart — a new AppDatabase on the
// same file, as a relaunch opens it
// (wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md). Reaching another
// device is covered by test/sync/sync_store_test.dart (both halves) and
// test/sync/sync_two_devices_test.dart (through a real server).

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/game_types_screen.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  testWidgets('a shortcut set in the editor survives a restart',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('countscore_shortcut_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/countscore.sqlite');

    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase(file));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => GameTypeProvider(repo: DriftGameTypeRepository(db)),
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('fr')],
        home: GameTypesScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('game_type_name_field')), 'Maison');
    final kind = find.byKey(const Key('game_type_shortcut_kind'));
    await tester.ensureVisible(kind);
    await tester.pumpAndSettle();
    await tester.tap(kind);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter a value').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('game_type_shortcut_amount')), '75');
    await tester.enterText(
        find.byKey(const Key('game_type_shortcut_label')), 'Capot');
    await tester.tap(find.byKey(const Key('game_type_save_button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await db.close();

    // The relaunch.
    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(reopened.close);
    final types = await DriftGameTypeRepository(reopened).getAll();
    final maison = types.singleWhere((t) => t.name == 'Maison');
    expect(maison.keypadShortcut,
        KeypadShortcut.value(75, label: 'Capot'));
    expect(maison.keypadShortcut!.displayLabel, 'Capot');
  });
}
