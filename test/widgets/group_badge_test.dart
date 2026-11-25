// A shared game's group as a badge with its name, where a cloud icon said only
// "shared" (wip/done/2026-11-25-multi-group-ui.md, decision 6 of the
// multi-group plan): on the home screen's cards, one badge per game, each
// naming its own group.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/widgets/group_badge.dart';

import '../support/fake_group_provider.dart';

Widget _app(Widget home, {GroupProvider? group, List<ChangeNotifierProvider> more = const []}) {
  final child = MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: home,
  );
  final providers = [
    ...more,
    if (group != null) ChangeNotifierProvider<GroupProvider>.value(value: group),
  ];
  return providers.isEmpty ? child : MultiProvider(providers: providers, child: child);
}

FakeGroupProvider _groups() {
  final group = FakeGroupProvider()
    ..addGroup('group-1', 'Famille', 'invite-1')
    ..addGroup('group-2', 'Amis', 'invite-2');
  addTearDown(group.dispose);
  return group;
}

void main() {
  group('GroupBadge', () {
    testWidgets("names the game's group, with a tooltip saying it is shared with it",
        (tester) async {
      await tester.pumpWidget(_app(
        const Scaffold(body: Center(child: GroupBadge(groupId: 'group-2'))),
        group: _groups(),
      ));

      expect(find.byKey(const Key('group_badge_group-2')), findsOneWidget);
      expect(find.textContaining('Amis'), findsOneWidget);
      expect(find.byTooltip('Shared with Amis'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    });

    testWidgets('a group not known by name shows the cloud icon alone', (tester) async {
      await tester.pumpWidget(_app(
        const Scaffold(body: Center(child: GroupBadge(groupId: 'group-unknown'))),
        group: _groups(),
      ));

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byTooltip('Shared game'), findsOneWidget);
    });

    testWidgets('with no GroupProvider above, the cloud icon, and no error', (tester) async {
      await tester.pumpWidget(_app(
        const Scaffold(body: Center(child: GroupBadge(groupId: 'group-1'))),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('a long name is cut short, not overflowing', (tester) async {
      final group = _groups()..addGroup('group-3', 'Les amis du jeudi soir au club', 'i');
      await tester.pumpWidget(_app(
        const Scaffold(body: Center(child: GroupBadge(groupId: 'group-3', maxWidth: 80))),
        group: group,
      ));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const Key('group_badge_group-3'))).width,
          lessThanOrEqualTo(80));
    });
  });

  testWidgets("the home screen's cards: a badge per shared game, naming its group",
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final games = GameProvider(
      gameRepo: DriftGameRepository(db),
      playerRepo: DriftPlayerRepository(db),
      roundRepo: DriftRoundRepository(db),
      scoreRepo: DriftScoreRepository(db),
      gameTypeRepo: DriftGameTypeRepository(db),
      statsRepo: DriftPlayerStatsRepository(db),
    );
    final gameTypes = GameTypeProvider(repo: DriftGameTypeRepository(db));
    await tester.runAsync(() async {
      for (final (name, groupId) in [
        ('Partie famille', 'group-1'),
        ('Partie amis', 'group-2'),
        ('Partie locale', null),
      ]) {
        final id = await games.createGame(name, null, true, ['Ana', 'Ben'], null);
        if (groupId != null) {
          await db.customStatement('UPDATE games SET group_id = ? WHERE id = ?', [groupId, id]);
        }
        // Finished, so each is a card rather than the Resume card.
        await db.customStatement(
            'UPDATE games SET finishedAt = ? WHERE id = ?', ['2026-11-20T10:00:00.000', id]);
      }
    });
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
      const HomeScreen(),
      group: _groups(),
      more: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    Finder cardOf(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(Card));
    expect(
      find.descendant(of: cardOf('Partie famille'), matching: find.textContaining('Famille')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cardOf('Partie amis'), matching: find.textContaining('Amis')),
      findsOneWidget,
    );
    expect(find.descendant(of: cardOf('Partie locale'), matching: find.byType(GroupBadge)),
        findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing,
        reason: 'the badge replaces the cloud icon');
  });
}
