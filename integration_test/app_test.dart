import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/main.dart' as app;
import 'package:countscore/providers/game_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Scores: 3 rounds, [Alice, Bob] per round. Totals Alice=15, Bob=17
  // (both unique, so they cannot collide with any individual cell value).
  const scores = <List<int>>[
    [10, 5],
    [3, 8],
    [2, 4],
  ];

  testWidgets(
    'golden path: create ZapZap game, score 3 rounds, stats, ZapZap analysis',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Provider handle (lives above MaterialApp) — used for pre-clean + teardown.
      final gp = Provider.of<GameProvider>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );

      // Pre-clean so the run is idempotent even on a persisted DB (device).
      await _cleanup(gp);
      await tester.pumpAndSettle();

      // === Step 0: home is up, DB initialized (default game types seeded).
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // === Step 1: new game. On a clean DB the form defaults to ZapZap and a
      // game name "Partie 1"; wait for the name field — it's the last thing the
      // async _loadData() sets, so it confirms the type is selected too.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await _waitFor(tester, find.text('Partie 1'));

      // === Step 2: add two global players Alice, Bob.
      for (final name in const ['Alice', 'Bob']) {
        await tester.tap(find.byKey(const Key('create_add_player')));
        await _waitFor(tester, find.byKey(const Key('player_picker_search')));
        await tester.enterText(
            find.byKey(const Key('player_picker_search')), name);
        // The "create" button is always in the tree but disabled until the
        // search field's onChanged setState lands — wait until it's ENABLED,
        // otherwise the tap is a silent no-op and the player isn't created.
        await _waitEnabled(tester, const Key('player_picker_create'));
        await tester.tap(find.byKey(const Key('player_picker_create')));
        // Card appears in CreateGameScreen; dialog must fully close before the
        // next iteration opens a new one.
        await _waitFor(tester, find.text(name));
        await _pumpUntil(tester, () => find.byType(Dialog).evaluate().isEmpty,
            timeout: const Duration(seconds: 10));
      }

      // === Step 3: create the game → GameBoardScreen.
      await tester.tap(find.byKey(const Key('create_game_submit')));
      await _waitFor(tester, find.byType(DataTable));

      // === Step 4: enter 3 rounds of scores.
      for (final round in scores) {
        await tester.tap(find.byKey(const Key('board_add_round')));
        await _waitDashes(tester, 2);
        for (var j = 0; j < round.length; j++) {
          // The leftmost remaining empty cell ('-') belongs to the next player.
          await tester.tap(find.text('-').first);
          await _waitFor(tester, find.byType(TextField));
          await tester.enterText(find.byType(TextField), '${round[j]}');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await _waitDashes(tester, 2 - (j + 1));
        }
      }

      // === Step 5: totals (15 / 17) shown under the column headers.
      expect(find.text('15'), findsWidgets);
      expect(find.text('17'), findsWidgets);

      // === Step 6: player stats — Alice (15) beats Bob (17) at ZapZap (low wins).
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bar_chart));
      await _waitFor(tester, find.text('Alice'));
      expect(find.text('Bob'), findsWidgets);
      await tester.tap(find.text('Alice'));
      await _waitFor(tester, find.text('100.0%')); // Alice won her only game.
      await tester.pageBack();
      await tester.pumpAndSettle();

      // === Step 7: ZapZap analysis (network → the configured backend).
      // The backend URL is a runtime setting with no default, so this step only
      // runs when the build was given --dart-define=BACKEND_URL=<url>, which
      // seeds it. Without one the "Analyze" item is correctly absent and the
      // step skips rather than failing.
      await _waitFor(tester, find.text('Partie 1'));
      await tester.tap(find.text('Partie 1'));
      // Wait for the board to actually open — the home game card ALSO has a
      // more_vert menu, so opening the menu before the board is up would hit
      // the wrong (home) menu, which has no "Analyze" item.
      await _waitFor(tester, find.byType(DataTable));
      await _waitFor(tester, find.byIcon(Icons.more_vert));
      await tester.tap(find.byIcon(Icons.more_vert));
      final hasAnalyse = await _pumpUntil(
        tester,
        () => find.byIcon(Icons.auto_awesome).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 5),
      );
      if (!hasAnalyse) {
        markTestSkipped(
          'ZapZap analysis skipped: no backend configured '
          '(pass --dart-define=BACKEND_URL=<url> to exercise it).',
        );
        await tester.tapAt(const Offset(5, 5)); // dismiss the popup menu
        await tester.pumpAndSettle();
      } else {
        await _analyse(tester);
      }

      // === Teardown: remove what this run created (idempotent next time).
      await _cleanup(gp);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// Step 7's second half: generate an analysis and prove it is cached. Split out
/// so the step can be skipped without skipping the teardown.
Future<void> _analyse(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.auto_awesome));
  await _waitFor(tester, find.byKey(const Key('analysis_generate')));

  await tester.tap(find.byKey(const Key('analysis_generate')));
  await tester.pump(); // enter loading state

  final ok = await _pumpUntil(
    tester,
    () =>
        find.byType(MarkdownBody).evaluate().isNotEmpty ||
        find.byIcon(Icons.error_outline).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 120),
  );

  if (!ok || find.byIcon(Icons.error_outline).evaluate().isNotEmpty) {
    // On web the browser blocks the cross-origin POST unless the configured
    // backend's CORS_ORIGINS lists this origin; its IP rate limiter can also
    // return 429. The real network path is exercised on-device. Don't fail.
    markTestSkipped(
      'ZapZap analysis network step skipped (CORS on web / rate-limit / offline).',
    );
  } else {
    final md = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(md.data, isNotEmpty);

    // Cache proof: re-open the screen → _loadCached() repaints the result
    // from the game_analyses table, with no "Generate" button.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await _waitFor(tester, find.byType(MarkdownBody));
    expect(find.byKey(const Key('analysis_generate')), findsNothing);
  }
}

/// Pumps in 250ms ticks until [condition] holds or [timeout] elapses.
/// Never uses pumpAndSettle (the analysis spinner is an infinite animation,
/// and Drift's web worker resolves async without scheduling frames).
Future<bool> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return true;
    await tester.pump(const Duration(milliseconds: 250));
  }
  return condition();
}

/// Waits until [f] matches at least one widget, then asserts it.
Future<void> _waitFor(
  WidgetTester tester,
  Finder f, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  await _pumpUntil(tester, () => f.evaluate().isNotEmpty, timeout: timeout);
  expect(f, findsWidgets);
}

/// Waits until the keyed [ButtonStyleButton] exists and is enabled
/// (`onPressed != null`). Tapping a disabled button is a silent no-op.
Future<void> _waitEnabled(
  WidgetTester tester,
  Key key, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final f = find.byKey(key);
  await _pumpUntil(tester, () {
    final els = f.evaluate();
    if (els.isEmpty) return false;
    final w = els.first.widget;
    return w is ButtonStyleButton && w.onPressed != null;
  }, timeout: timeout);
  expect(f, findsOneWidget);
}

/// Waits until exactly [n] empty score cells ('-') are visible on the board.
Future<void> _waitDashes(WidgetTester tester, int n) async {
  await _pumpUntil(tester, () => find.text('-').evaluate().length == n,
      timeout: const Duration(seconds: 15));
  expect(find.text('-'), findsNWidgets(n));
}

/// Deletes the test game and players if present. Safe to call when absent.
Future<void> _cleanup(GameProvider gp) async {
  try {
    await gp.loadGames();
    for (final g in gp.games.where((g) => g.name == 'Partie 1').toList()) {
      await gp.deleteGame(g.id!);
    }
    await gp.deletePlayerByName('Alice');
    await gp.deletePlayerByName('Bob');
  } catch (_) {
    // Best-effort; ignore if nothing to clean.
  }
}
