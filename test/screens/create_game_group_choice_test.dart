// The create screen's group choice (wip/done/2026-11-25-multi-group-ui.md,
// decision 5 of the multi-group plan): nothing in no group, today's switch in
// one, a selector Local / group A / group B in several, starting on the last
// group a game was created in — remembered on the device.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/create_game_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/last_game_group.dart';

import '../support/fake_group_provider.dart';

/// Records the shares instead of writing them: its sessions are the fake's.
class _Groups extends FakeGroupProvider {
  _Groups(int count) {
    for (var i = 1; i <= count; i++) {
      addGroup('group-$i', ['Famille', 'Amis', 'Club'][i - 1], 'invite-$i');
    }
  }

  final shared = <String>[];

  @override
  Future<void> shareGame(int gameId, String groupId) async => shared.add(groupId);
}

void main() {
  late AppDatabase db;
  late GameProvider games;
  late GameTypeProvider gameTypes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    games = GameProvider(
      gameRepo: DriftGameRepository(db),
      playerRepo: DriftPlayerRepository(db),
      roundRepo: DriftRoundRepository(db),
      scoreRepo: DriftScoreRepository(db),
      gameTypeRepo: DriftGameTypeRepository(db),
      statsRepo: DriftPlayerStatsRepository(db),
    );
    gameTypes = GameTypeProvider(repo: DriftGameTypeRepository(db));
  });

  tearDown(() => db.close());

  Future<_Groups> open(WidgetTester tester, int groups) async {
    // Two players to seat with one tap ("same as last game").
    await gameTypes.loadGameTypes();
    await games.createGame('Partie 1', gameTypes.gameTypes.first.id, true, ['Ana', 'Ben'], null);
    final group = _Groups(groups);
    addTearDown(group.dispose);
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ChangeNotifierProvider<BackendProvider>(create: (_) => BackendProvider(null)),
        ChangeNotifierProvider<GroupProvider>.value(value: group),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: CreateGameScreen(boardBuilder: (_) => const Scaffold(body: Text('board'))),
      ),
    ));
    await tester.pumpAndSettle();
    return group;
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('create_add_player')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_same_as')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('create_game_submit')));
    await tester.tap(find.byKey(const Key('create_game_submit')));
    await tester.pumpAndSettle();
    expect(find.text('board'), findsOneWidget);
  }

  bool selected(WidgetTester tester, String key) =>
      tester.widget<ChoiceChip>(find.byKey(Key(key))).selected;

  testWidgets('in no group: no switch, no selector, a local game', (tester) async {
    final group = await open(tester, 0);
    expect(find.byKey(const Key('create_share_with_group')), findsNothing);
    expect(find.byKey(const Key('create_group_choice')), findsNothing);
    await start(tester);
    expect(group.shared, isEmpty);
  });

  testWidgets("in one group: today's switch, on, naming the group", (tester) async {
    final group = await open(tester, 1);
    expect(find.byKey(const Key('create_group_choice')), findsNothing);
    final tile = tester.widget<SwitchListTile>(find.byKey(const Key('create_share_with_group')));
    expect(tile.value, isTrue);
    expect(find.text('Devices in Famille will see and edit this game'), findsOneWidget);
    await start(tester);
    expect(group.shared, ['group-1']);
  });

  testWidgets('in one group, switched off: a local game', (tester) async {
    final group = await open(tester, 1);
    await tester.tap(find.byKey(const Key('create_share_with_group')));
    await tester.pumpAndSettle();
    await start(tester);
    expect(group.shared, isEmpty);
  });

  testWidgets('in two groups: a selector, on the first group with nothing remembered',
      (tester) async {
    final group = await open(tester, 2);
    expect(find.byKey(const Key('create_share_with_group')), findsNothing);
    expect(find.byKey(const Key('create_group_local')), findsOneWidget);
    expect(selected(tester, 'create_group_group-1'), isTrue);
    expect(selected(tester, 'create_group_group-2'), isFalse);
    expect(selected(tester, 'create_group_local'), isFalse);

    await tester.tap(find.byKey(const Key('create_group_group-2')));
    await tester.pumpAndSettle();
    expect(find.text('Devices in Amis will see and edit this game'), findsOneWidget);
    await start(tester);

    expect(group.shared, ['group-2']);
    expect(await LastGameGroup.read(), 'group-2', reason: 'remembered for next time');
  });

  testWidgets('in two groups: starts on the group remembered from the last game',
      (tester) async {
    SharedPreferences.setMockInitialValues({LastGameGroup.prefsKey: 'group-2'});
    final group = await open(tester, 2);
    expect(selected(tester, 'create_group_group-2'), isTrue);
    expect(selected(tester, 'create_group_group-1'), isFalse);
    await start(tester);
    expect(group.shared, ['group-2']);
  });

  testWidgets('a remembered group this device has left falls back on the first',
      (tester) async {
    SharedPreferences.setMockInitialValues({LastGameGroup.prefsKey: 'group-gone'});
    await open(tester, 2);
    expect(selected(tester, 'create_group_group-1'), isTrue);
  });

  testWidgets('in two groups, "This device only": a local game, the default kept',
      (tester) async {
    SharedPreferences.setMockInitialValues({LastGameGroup.prefsKey: 'group-2'});
    final group = await open(tester, 2);
    await tester.tap(find.byKey(const Key('create_group_local')));
    await tester.pumpAndSettle();
    expect(selected(tester, 'create_group_local'), isTrue);
    expect(find.text('The game stays on this device.'), findsOneWidget);
    await start(tester);

    expect(group.shared, isEmpty);
    expect(await LastGameGroup.read(), 'group-2');
  });

  testWidgets('the chosen group left while the screen is open: no group chosen, Start waits',
      (tester) async {
    final group = await open(tester, 3);
    expect(selected(tester, 'create_group_group-1'), isTrue);
    await tester.tap(find.byKey(const Key('create_add_player')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_same_as')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_confirm')));
    await tester.pumpAndSettle();

    group.debugRemoveMembership('group-1');
    await tester.pumpAndSettle();

    expect(selected(tester, 'create_group_local'), isFalse);
    expect(selected(tester, 'create_group_group-2'), isFalse,
        reason: 'never moved silently to another group');
    expect(selected(tester, 'create_group_group-3'), isFalse);
    expect(find.byKey(const Key('create_group_choice_hint')), findsNothing);
    FilledButton start() =>
        tester.widget<FilledButton>(find.byKey(const Key('create_game_submit')));
    expect(start().onPressed, isNull);

    await tester.tap(find.byKey(const Key('create_group_group-3')));
    await tester.pumpAndSettle();
    expect(start().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('create_game_submit')));
    await tester.pumpAndSettle();
    expect(group.shared, ['group-3']);
  });

  testWidgets('a group whose name is not known is offered by its invite code', (tester) async {
    final group = await open(tester, 2);
    group.addGroup('group-2', '', 'invite-2');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: find.byKey(const Key('create_group_group-2')), matching: find.text('invite code invite-2')),
      findsOneWidget,
    );
  });
}
