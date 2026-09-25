// A skull above an eliminated player's avatar, in both board layouts, where
// the leader's crown sits
// (wip/done/2026-09-23-eliminated-players-have-no-skull-on-the-board.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/widgets/board_lanes.dart';

import '../support/board_harness.dart';

void main() {
  late BoardHarness board;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    board = BoardHarness();
  });

  tearDown(() => board.close());

  final skull = find.byKey(const Key('board_eliminated_skull'));

  Finder skullIn(Finder scope) =>
      find.descendant(of: scope, matching: skull);

  Future<void> toRows(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('board_view_toggle')));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'in an elimination type, the player past the threshold has the skull in '
      'lanes and in rows, the one below it does not', (tester) async {
    final typeId = await board.aType(eliminatesOver: 100);
    await board.aGame(['Ann', 'Bob'], typeId: typeId, rounds: [
      [120, 20],
    ]);
    await board.open(tester);
    final ann = board.playerNamed('Ann');
    final bob = board.playerNamed('Bob');

    expect(skullIn(find.byKey(Key('board_lane_header_${ann.id}'))),
        findsOneWidget);
    expect(skullIn(find.byKey(Key('board_lane_header_${bob.id}'))),
        findsNothing);
    expect(skull, findsOneWidget);
    expect(find.bySemanticsLabel(l10n.boardEliminated), findsOneWidget);

    await toRows(tester);
    expect(skullIn(find.byKey(Key('board_row_${ann.id}'))), findsOneWidget);
    expect(skullIn(find.byKey(Key('board_row_${bob.id}'))), findsNothing);
    expect(skull, findsOneWidget);
  });

  testWidgets('the skull wins over the crown on a leader who is out',
      (tester) async {
    // Lowest wins, and Ann is at 120 with Bob at 150: Ann leads, both are out.
    final typeId = await board.aType(eliminatesOver: 100);
    await board.aGame(['Ann', 'Bob'], typeId: typeId, rounds: [
      [120, 150],
    ]);
    await board.open(tester);
    final ann = board.playerNamed('Ann');

    final header = find.byKey(Key('board_lane_header_${ann.id}'));
    expect(skullIn(header), findsOneWidget);
    expect(
        find.descendant(
            of: header, matching: find.byKey(const Key('board_leader_crown'))),
        findsNothing);
  });

  testWidgets('a type without elimination never shows the skull',
      (tester) async {
    final typeId = await board.aType();
    await board.aGame(['Ann', 'Bob'], typeId: typeId, rounds: [
      [500, 20],
    ]);
    await board.open(tester);
    expect(skull, findsNothing);
    expect(find.byKey(const Key('board_leader_crown')), findsOneWidget);

    await toRows(tester);
    expect(skull, findsNothing);
  });

  test('boardMark: skull, else crown, else nothing', () {
    expect(boardMark(eliminated: true, isLeader: true), isA<BoardSkull>());
    expect(boardMark(eliminated: true, isLeader: false), isA<BoardSkull>());
    expect(boardMark(eliminated: false, isLeader: true), isA<BoardCrown>());
    expect(boardMark(eliminated: false, isLeader: false), isNull);
  });
}
