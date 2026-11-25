// One device in two groups, end to end through the UI against a real backend
// (wip/done/2026-11-25-multi-group-ui.md, and the acceptance of
// wip/done/2026-11-17-belong-to-several-groups.md): join two groups from
// Settings → Groups, create one game in each through the create screen's
// selector, see both badges, check each game reached its own group only, leave
// one group, and check the other's game still syncs.
//
// Needs a backend whose CORS_ORIGINS lists the origin the test is served from
// (recipe: .llmwiki/Testing.md, "Several groups, end to end"); skipped without
// --dart-define=BACKEND_URL.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/main.dart' as app;
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/backend_client.dart';

const _backend = String.fromEnvironment('BACKEND_URL');

/// Screenshots of the three screens the change draws, kept by
/// `test_driver/integration_test_screenshots.dart`.
const _screenshots = bool.fromEnvironment('SCREENSHOTS');

late IntegrationTestWidgetsFlutterBinding _binding;

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_screenshots) return;
  await tester.pumpAndSettle();
  await _binding.takeScreenshot(name);
}

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'two groups: one game in each, each reaches its own group only, leaving one keeps the other',
    (tester) async {
      if (_backend.isEmpty) {
        markTestSkipped('No backend: pass --dart-define=BACKEND_URL=<url>.');
        return;
      }
      final server = BackendClient(_backend);
      final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
      // Another device in each group, which reads what reaches its group.
      final famille = await server.createGroup('Famille $stamp', 'Tablette famille');
      final amis = await server.createGroup('Amis $stamp', 'Tablette amis');

      app.main();
      await tester.pumpAndSettle();
      await _waitFor(tester, find.byType(FloatingActionButton));
      final context = tester.element(find.byType(MaterialApp));
      final gp = Provider.of<GameProvider>(context, listen: false);
      final group = Provider.of<GroupProvider>(context, listen: false);

      // === Settings → Groups: join both, one nickname.
      await _openSettings(tester);
      await _join(tester, famille.shareToken, nickname: 'Téléphone e2e');
      await _pumpUntil(tester, () => group.memberships.length == 1,
          timeout: const Duration(seconds: 15));
      await _join(tester, amis.shareToken);
      await _pumpUntil(tester, () => group.memberships.length == 2,
          timeout: const Duration(seconds: 15));
      expect([for (final s in group.memberships) s.groupId], [famille.groupId, amis.groupId]);
      expect(group.nickname, 'Téléphone e2e');
      await _waitFor(tester, find.byKey(Key('group_card_${famille.groupId}')));
      await _waitFor(tester, find.byKey(Key('group_card_${amis.groupId}')));
      await tester.ensureVisible(find.byKey(Key('group_card_${famille.groupId}')));
      await _shot(tester, 'groups');
      await _back(tester);

      // === One game in each group, through the selector.
      await _createGame(tester, 'Partie famille $stamp', famille.groupId, newPlayers: true);
      await _createGame(tester, 'Partie amis $stamp', amis.groupId, shot: 'create_selector');
      await gp.loadGames();
      final inFamille = gp.games.singleWhere((g) => g.name == 'Partie famille $stamp');
      final inAmis = gp.games.singleWhere((g) => g.name == 'Partie amis $stamp');
      expect(inFamille.groupId, famille.groupId);
      expect(inAmis.groupId, amis.groupId);

      // === Both badges, each naming its group.
      await _waitFor(tester, find.byKey(Key('group_badge_${famille.groupId}')));
      await _waitFor(tester, find.byKey(Key('group_badge_${amis.groupId}')));
      expect(find.textContaining('Famille $stamp'), findsWidgets);
      expect(find.textContaining('Amis $stamp'), findsWidgets);
      await _shot(tester, 'games_badges');

      // === Each game reached its own group, and only that one.
      Future<Set<String>> gamesSeenBy(String token) async =>
          {for (final d in await _pullAll(server, token)) if (d.entityType == 'game') d.entityUuid};
      expect(
        await _eventually(() async => (await gamesSeenBy(famille.deviceToken)).contains(inFamille.uuid)),
        isTrue,
        reason: "the family's game reaches the family's other device",
      );
      expect(
        await _eventually(() async => (await gamesSeenBy(amis.deviceToken)).contains(inAmis.uuid)),
        isTrue,
        reason: "the friends' game reaches the friends' other device",
      );
      expect(await gamesSeenBy(famille.deviceToken), isNot(contains(inAmis.uuid)));
      expect(await gamesSeenBy(amis.deviceToken), isNot(contains(inFamille.uuid)));

      // === Leave the family group from its card.
      await _openSettings(tester);
      final card = find.byKey(Key('group_card_${famille.groupId}'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: card, matching: find.text('Famille $stamp')));
      await tester.pumpAndSettle();
      final leave = find.descendant(of: card, matching: find.byKey(const Key('group_leave')));
      await tester.ensureVisible(leave);
      await tester.pumpAndSettle();
      await tester.tap(leave);
      await _waitFor(tester, find.byType(AlertDialog));
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton)).last);
      await _pumpUntil(tester, () => group.memberships.length == 1,
          timeout: const Duration(seconds: 15));
      expect([for (final s in group.memberships) s.groupId], [amis.groupId]);
      await _back(tester);
      await gp.loadGames();
      expect(gp.games.singleWhere((g) => g.id == inFamille.id).groupId, isNull,
          reason: 'the left group\'s game is a local one now');
      expect(gp.games.singleWhere((g) => g.id == inAmis.id).groupId, amis.groupId);

      // === The friends' game still syncs: a round entered now reaches them.
      final amisRoundsBefore = await _rounds(server, amis.deviceToken);
      final familleRoundsBefore = await _rounds(server, famille.deviceToken);
      await tester.tap(find.text('Partie amis $stamp').first);
      await _waitFor(tester, find.byKey(const Key('board_add_round')));
      final before = gp.currentRounds.length;
      // The "left the group" snackbar sits over the round button until it goes.
      await _pumpUntil(tester, () => find.byType(SnackBar).evaluate().isEmpty,
          timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const Key('board_add_round')));
      await _waitFor(tester, find.byKey(const Key('keypad_sheet')));
      for (final score in const [7, 4]) {
        await tester.tap(find.byKey(Key('keypad_digit_$score')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('keypad_primary')));
        await tester.pumpAndSettle();
      }
      await _pumpUntil(tester, () => gp.currentRounds.length == before + 1,
          timeout: const Duration(seconds: 15));
      expect(
        await _eventually(() async => await _rounds(server, amis.deviceToken) > amisRoundsBefore),
        isTrue,
        reason: 'the round reached the group still joined',
      );
      expect(await _rounds(server, famille.deviceToken), familleRoundsBefore,
          reason: 'nothing more reaches the group left');
      await _back(tester);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _openSettings(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.settings));
  await _waitFor(tester, find.byKey(const Key('backend_url_save')));
}

/// Settings → Groups → Join, with [invite]; the nickname typed only when given
/// (the second join starts from the one the device already goes by).
Future<void> _join(WidgetTester tester, String invite, {String? nickname}) async {
  final join = find.byKey(const Key('group_join'));
  await tester.scrollUntilVisible(join, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(join);
  await _waitFor(tester, find.byKey(const Key('group_invite_field')));
  if (nickname != null) {
    final field = find.byKey(const Key('group_nickname_field'));
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, nickname);
  }
  final code = find.byKey(const Key('group_invite_field'));
  await tester.tap(code);
  await tester.pump();
  await tester.enterText(code, invite);
  await _waitEnabled(tester, const Key('group_dialog_ok'));
  await tester.tap(find.byKey(const Key('group_dialog_ok')));
  await _pumpUntil(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
      timeout: const Duration(seconds: 15));
}

/// A game named [name] in group [groupId], from the home screen's button,
/// with Alice and Bob — created on the first game, the same players after.
Future<void> _createGame(WidgetTester tester, String name, String groupId,
    {bool newPlayers = false, String? shot}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await _waitFor(tester, find.byKey(const Key('create_game_name')));
  final nameField = find.byKey(const Key('create_game_name'));
  // The screen has read the last game (its players, "same as last game") once
  // it has named the new one.
  await _pumpUntil(
    tester,
    () => tester
        .widget<EditableText>(find.descendant(of: nameField, matching: find.byType(EditableText)))
        .controller
        .text
        .isNotEmpty,
    timeout: const Duration(seconds: 15),
  );
  await tester.tap(nameField);
  await tester.pump();
  await tester.enterText(nameField, name);

  await tester.tap(find.byKey(const Key('create_add_player')));
  await _waitFor(tester, find.byKey(const Key('player_picker_search')));
  if (newPlayers) {
    final search = find.byKey(const Key('player_picker_search'));
    for (final player in const ['Alice', 'Bob']) {
      await tester.tap(search);
      await tester.pump();
      await tester.enterText(search, player);
      await _waitEnabled(tester, const Key('player_picker_create'));
      await tester.tap(find.byKey(const Key('player_picker_create')));
      await _waitFor(tester, find.byKey(Key('player_chip_$player')));
    }
  } else {
    await _waitFor(tester, find.byKey(const Key('player_picker_same_as')));
    await tester.tap(find.byKey(const Key('player_picker_same_as')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('player_picker_confirm')));
  await _pumpUntil(
    tester,
    () => find.byKey(const Key('who_is_playing_sheet')).evaluate().isEmpty,
    timeout: const Duration(seconds: 10),
  );

  final chip = find.byKey(Key('create_group_$groupId'));
  await tester.scrollUntilVisible(chip, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
  expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
  if (shot != null) await _shot(tester, shot);

  await tester.tap(find.byKey(const Key('create_game_submit')));
  await _waitFor(tester, find.byKey(const Key('board_add_round')));
  await _back(tester);
  await _waitFor(tester, find.byType(FloatingActionButton));
}

/// Every delta the device of [token] can pull from the start.
Future<List<PulledDelta>> _pullAll(BackendClient server, String token) async {
  final all = <PulledDelta>[];
  var since = 0;
  while (true) {
    final page = await server.pull(token, since);
    all.addAll(page.deltas);
    since = page.serverSeqMax;
    if (!page.hasMore) return all;
  }
}

Future<int> _rounds(BackendClient server, String token) async =>
    (await _pullAll(server, token)).where((d) => d.entityType == 'round').length;

/// Asks [check] every half second for up to 20 seconds.
Future<bool> _eventually(Future<bool> Function() check) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    if (await check()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return check();
}

/// Back one screen ([BackButton] by type, as `app_test.dart` explains).
Future<void> _back(WidgetTester tester) async {
  final back = find.byType(BackButton);
  await _pumpUntil(tester, () => back.evaluate().length == 1,
      timeout: const Duration(seconds: 10));
  final popped = back.evaluate().single;
  await tester.tap(back);
  await _pumpUntil(tester, () => !popped.mounted, timeout: const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

/// Pumps in 250 ms ticks until [condition] holds or [timeout] elapses
/// (`pumpAndSettle` is not enough on the web: `app_test.dart`).
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

Future<void> _waitFor(
  WidgetTester tester,
  Finder f, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  await _pumpUntil(tester, () => f.evaluate().isNotEmpty, timeout: timeout);
  expect(f, findsWidgets);
}

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
