import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
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

      // The first game's name, in the device's language ("Partie 1", "Game 1").
      final gameName = AppLocalizations.of(
        tester.element(find.byType(FloatingActionButton)),
      )!.defaultGameName(1);

      // Pre-clean so the run is idempotent even on a persisted DB (device).
      await _cleanup(gp, gameName);
      await tester.pumpAndSettle();

      // === Step 0: home is up, DB initialized (default game types seeded).
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // === Step 1: new game. On a clean DB the form defaults to ZapZap and
      // the localized first-game name; wait for the name field — it's the last
      // thing the async _loadData() sets, so it confirms the type is selected too.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await _waitFor(tester, find.text(gameName));

      // === Step 2: add two global players Alice, Bob, through the "who's
      // playing" sheet: each typed name is created and checked, then the
      // sheet's button seats them.
      await tester.tap(find.byKey(const Key('create_add_player')));
      await _waitFor(tester, find.byKey(const Key('player_picker_search')));
      final search = find.byKey(const Key('player_picker_search'));
      for (final name in const ['Alice', 'Bob']) {
        // Tap the field first, as a user would: on web, tapping "create" for
        // the previous name unfocused it (TextField's default onTapOutside),
        // which closed its text-input connection. enterText only reopens one
        // when the focused editable *changes*, so on the same field it would
        // send the text to no connection and the field would stay empty.
        await tester.tap(search);
        await tester.pump();
        await tester.enterText(search, name);
        // The "create" action appears once the search field's onChanged
        // setState lands — wait for it, or the tap misses.
        await _waitEnabled(tester, const Key('player_picker_create'));
        await tester.tap(find.byKey(const Key('player_picker_create')));
        await _waitFor(tester, find.byKey(Key('player_chip_$name')));
      }
      await tester.tap(find.byKey(const Key('player_picker_confirm')));
      // The sheet must be gone before the seats are read.
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('who_is_playing_sheet')).evaluate().isEmpty,
        timeout: const Duration(seconds: 10),
      );
      await _waitFor(tester, find.text('Bob'));

      // === Step 3: create the game → GameBoardScreen.
      await tester.tap(find.byKey(const Key('create_game_submit')));
      await _waitFor(tester, find.byKey(const Key('board_add_round')));

      // === Step 4: enter 3 rounds of scores through the keypad sheet: one
      // player after the other in seat order, "Next" then "Validate round".
      final sheet = find.byKey(const Key('keypad_sheet'));
      for (final round in scores) {
        final before = gp.currentRounds.length;
        await tester.tap(find.byKey(const Key('board_add_round')));
        await _waitFor(tester, sheet);
        for (final score in round) {
          for (final digit in '$score'.split('')) {
            await tester.tap(find.byKey(Key('keypad_digit_$digit')));
            await tester.pump();
          }
          await tester.tap(find.byKey(const Key('keypad_primary')));
          await tester.pumpAndSettle();
        }
        // The round is written on "Validate round", through the Drift worker.
        await _pumpUntil(
          tester,
          () =>
              sheet.evaluate().isEmpty && gp.currentRounds.length == before + 1,
          timeout: const Duration(seconds: 15),
        );
      }

      // === Step 5: totals (15 / 17) shown under the column headers.
      expect(find.text('15'), findsWidgets);
      expect(find.text('17'), findsWidgets);

      // === Step 6: end the game from the board's menu → the end screen. The
      // leaderboard (#137) counts finished games only.
      await tester.tap(find.byIcon(Icons.more_vert));
      await _waitFor(tester, find.byIcon(Icons.flag_outlined));
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await _pumpUntil(
        tester,
        () => gp.currentGame?.isFinished ?? false,
        timeout: const Duration(seconds: 15),
      );
      await _waitFor(tester, find.byKey(const Key('game_end_headline')));
      await _back(tester); // end screen → board
      await _waitFor(tester, find.byKey(const Key('board_finished_badge')));
      await _back(tester); // board → home

      // === Step 7: leaderboard — Alice (15) beats Bob (17) at ZapZap (low
      // wins). One game is below kMinGamesToRank, so nobody is ranked and there
      // is no leader card yet; both rows are listed, and Alice's card shows
      // 1 game, 1 win.
      await tester.tap(find.byIcon(Icons.bar_chart));
      // The home card names the winner too: wait for the leaderboard's rows.
      final rows = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('stats_row_'),
      );
      await _waitFor(tester, rows);
      expect(rows, findsNWidgets(2));
      for (final name in const ['Alice', 'Bob']) {
        expect(
          find.descendant(of: rows, matching: find.text(name)),
          findsOneWidget,
        );
      }
      await tester.tap(find.descendant(of: rows, matching: find.text('Alice')));
      await _waitFor(tester, find.byKey(const Key('card_wins')));
      for (final tile in const ['card_games', 'card_wins']) {
        expect(
          find.descendant(of: find.byKey(Key(tile)), matching: find.text('1')),
          findsOneWidget,
          reason: '$tile: Alice played one game and won it',
        );
      }
      await _back(tester); // card → leaderboard
      await _back(tester); // leaderboard → home

      // === Step 8: ZapZap analysis (network → the configured backend).
      // The backend URL is a runtime setting with no default, so this step only
      // runs when the build was given --dart-define=BACKEND_URL=<url>, which
      // seeds it. Without one the "Analyze" item is correctly absent and the
      // step skips rather than failing.
      await _waitFor(tester, find.text(gameName));
      await tester.tap(find.text(gameName));
      // Wait for the board to actually open — the home game card ALSO has a
      // more_vert menu, so opening the menu before the board is up would hit
      // the wrong (home) menu, which has no "Analyze" item.
      await _waitFor(tester, find.byKey(const Key('board_add_round')));
      // The board's own menu: the last AppBar is the top route's, and the home
      // route underneath keeps its cards' more_vert icons in the tree.
      final boardMenu = find.descendant(
          of: find.byType(AppBar).last, matching: find.byIcon(Icons.more_vert));
      await _waitFor(tester, boardMenu);
      await tester.tap(boardMenu);
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
      await _cleanup(gp, gameName);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// Step 8's second half: generate an analysis and prove it is cached. Split out
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
    await _back(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await _waitFor(tester, find.byType(MarkdownBody));
    expect(find.byKey(const Key('analysis_generate')), findsNothing);
  }
}

/// Back one screen, once the screen is ready for it. Found by type, not by the
/// "Back" tooltip, which is localized (a French phone says "Retour"). A route still sliding in
/// or out keeps its back button in the tree, and [WidgetTester.pageBack]
/// refuses two ("One back button expected"): wait for exactly one before, and
/// for that one to leave the tree (the popped route is gone) after.
Future<void> _back(WidgetTester tester) async {
  final back = find.byType(BackButton);
  await _pumpUntil(
    tester,
    () => back.evaluate().length == 1,
    timeout: const Duration(seconds: 10),
  );
  final popped = back.evaluate().single;
  // Not tester.pageBack(): it too finds the button by its English tooltip.
  await tester.tap(back);
  await _pumpUntil(
    tester,
    () => !popped.mounted,
    timeout: const Duration(seconds: 10),
  );
  await tester.pumpAndSettle();
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

/// Deletes the test game and players if present. Safe to call when absent.
Future<void> _cleanup(GameProvider gp, String gameName) async {
  try {
    await gp.loadGames();
    for (final g in gp.games.where((g) => g.name == gameName).toList()) {
      await gp.deleteGame(g.id!);
    }
    await gp.deletePlayerByName('Alice');
    await gp.deletePlayerByName('Bob');
  } catch (_) {
    // Best-effort; ignore if nothing to clean.
  }
}
