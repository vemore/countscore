// The game-types list scrolls its last row clear of the "New type" button, and
// the new-type dialog names its icon and colour buttons.
// wip/done/2026-09-19-game-types-list-last-row-under-the-button.md

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/game_type_repository.dart';
import 'package:countscore/screens/game_types_screen.dart';

class _FakeGameTypeRepository implements GameTypeRepository {
  _FakeGameTypeRepository(this._types);

  final List<GameType> _types;

  @override
  Future<List<GameType>> getAll() async => _types;
  @override
  Future<int> create(GameType gameType) async => 1;
  @override
  Future<GameType?> getById(int id) async => null;
  @override
  Future<int> update(GameType gameType) async => 1;
  @override
  Future<int> delete(int id) async => 1;
}

Future<void> _pump(
  WidgetTester tester, {
  int count = 20,
  Size size = const Size(412, 860), // the report's capture, in fr
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final types = [
    for (var i = 1; i <= count; i++)
      GameType(
        id: i,
        name: 'Type ${i.toString().padLeft(2, '0')}',
        iconCodePoint: Icons.casino.codePoint,
        cardColorValue: 0xFF2196F3,
        isLowestScoreWins: true,
      ),
  ];
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => GameTypeProvider(repo: _FakeGameTypeRepository(types)),
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('fr')],
        home: GameTypesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scrolled to the end, the last type\'s menu clears the button',
      (tester) async {
    await _pump(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final lastCard = find.ancestor(
      of: find.text('Type 20'),
      matching: find.byType(Card),
    );
    final menu = find.descendant(
      of: lastCard,
      matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
    );
    expect(menu, findsOneWidget);

    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(tester.getRect(menu).overlaps(fab), isFalse);
    expect(menu.hitTestable(), findsOneWidget);

    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('Modifier'), findsOneWidget);
  });

  testWidgets('the new-type dialog names its icon and colour buttons',
      (tester) async {
    final semantics = tester.ensureSemantics();
    // Wide enough that the test font, a full em per glyph, fits the dialog's
    // dropdowns; the labels are what this test is about.
    await _pump(tester, count: 1, size: const Size(1000, 1400));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Choisir une icône'), findsOneWidget);
    expect(find.byTooltip('Choisir une couleur'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('game_type_icon_button'))),
      isSemantics(
        tooltip: 'Choisir une icône',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('game_type_color_button'))),
      isSemantics(
        tooltip: 'Choisir une couleur',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
