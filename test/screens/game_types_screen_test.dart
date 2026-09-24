// The game-types list scrolls its last row clear of the "New type" button, and
// the editor: what it carries over, what it validates, what it warns about and
// what it refuses.
// wip/done/2026-09-19-game-types-list-last-row-under-the-button.md
// wip/done/2026-09-20-editing-a-game-type-erases-its-rules.md
// wip/done/2026-09-20-the-game-type-editor-leaks-its-controllers-and-validates-nothing.md
// wip/done/2026-09-20-a-condition-saves-without-a-threshold-and-does-nothing.md
// wip/done/2026-09-20-deleting-a-used-game-type-reports-an-export-error-in-english.md
// wip/done/2026-09-20-the-win-direction-can-be-flipped-under-finished-games.md
// wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/game_type_repository.dart';
import 'package:countscore/screens/game_types_screen.dart';
import 'package:countscore/utils/game_type_appearance.dart';

class _FakeGameTypeRepository implements GameTypeRepository {
  _FakeGameTypeRepository(this._types);

  final List<GameType> _types;

  final List<GameType> updates = [];
  final List<GameType> creations = [];
  final List<int> deletions = [];

  /// What [countGames] / [countFinishedGames] answer, whatever the id.
  int games = 0;
  int finishedGames = 0;

  @override
  Future<List<GameType>> getAll() async => _types;
  @override
  Future<int> create(GameType gameType) async {
    creations.add(gameType);
    return 1;
  }

  @override
  Future<GameType?> getById(int id) async {
    for (final type in _types) {
      if (type.id == id) return type;
    }
    return null;
  }

  @override
  Future<int> update(GameType gameType) async {
    updates.add(gameType);
    return 1;
  }

  @override
  Future<int> countGames(int id) async => games;
  @override
  Future<int> countFinishedGames(int id) async => finishedGames;
  @override
  Future<int> delete(int id) async {
    deletions.add(id);
    return 1;
  }
}

/// A surface wide enough that the test font — a full em per glyph — leaves the
/// dialog's dropdowns and buttons where a tap can reach them.
const _editorSurface = Size(1000, 1400);

Future<_FakeGameTypeRepository> _pump(
  WidgetTester tester, {
  int count = 20,
  Size size = const Size(412, 860), // the report's capture, in fr
  List<GameType>? types,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = _FakeGameTypeRepository(types ??
      [
        for (var i = 1; i <= count; i++)
          GameType(
            id: i,
            name: 'Type ${i.toString().padLeft(2, '0')}',
            iconCodePoint: Icons.casino.codePoint,
            cardColorValue: 0xFF2196F3,
            isLowestScoreWins: true,
          ),
      ]);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => GameTypeProvider(repo: repo),
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
  return repo;
}

Finder _menuOf(WidgetTester tester) =>
    find.byWidgetPredicate((w) => w is PopupMenuButton).first;

Future<void> _pickMenu(WidgetTester tester, String action) async {
  await tester.tap(_menuOf(tester));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await tester.pumpAndSettle();
}

Future<void> _openEditor(WidgetTester tester) =>
    _pickMenu(tester, 'Modifier');

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('game_type_save_button')));
  await tester.pumpAndSettle();
}

/// Chooses [label] in the dropdown [dropdown] resolves to.
Future<void> _choose(
    WidgetTester tester, Finder dropdown, String label) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder get _playerDeadDropdown =>
    find.byType(DropdownButtonFormField<PlayerDeadConditionType?>);
Finder get _gameOverDropdown =>
    find.byType(DropdownButtonFormField<GameOverConditionType?>);
Finder get _shortcutDropdown =>
    find.byKey(const Key('game_type_shortcut_kind'));

/// Scrolls the keypad-shortcut section into view, then chooses [label].
Future<void> _chooseShortcut(WidgetTester tester, String label) async {
  await tester.ensureVisible(_shortcutDropdown);
  await tester.pumpAndSettle();
  await _choose(tester, _shortcutDropdown, label);
}

GameType _zapzap({
  String? rules,
  bool isLowestScoreWins = true,
  PlayerDeadConditionType? playerDeadConditionType =
      PlayerDeadConditionType.over,
  int? playerDeadThreshold = 100,
  GameOverConditionType? gameOverConditionType,
  int? gameOverThreshold,
  int cardColorValue = 0xFFFFC107,
}) =>
    GameType(
      id: 1,
      builtinKey: 'zapzap',
      name: 'ZapZap',
      rulesSlug: 'zapzap',
      rules: rules,
      isDefault: true,
      iconCodePoint: Icons.flash_on.codePoint,
      cardColorValue: cardColorValue,
      isLowestScoreWins: isLowestScoreWins,
      playerDeadConditionType: playerDeadConditionType,
      playerDeadThreshold: playerDeadThreshold,
      gameOverConditionType: gameOverConditionType,
      gameOverThreshold: gameOverThreshold,
    );

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
    await _pump(tester, count: 1, size: _editorSurface);

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

  group('editing carries what the form does not show', () {
    testWidgets('a built-in type keeps its rules, rulesSlug, key and isDefault',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(rules: 'On joue à 150.')],
      );

      await _openEditor(tester);
      await tester.enterText(
          find.byKey(const Key('game_type_player_dead_threshold')), '150');
      await _save(tester);

      final saved = repo.updates.single;
      expect(saved.rules, 'On joue à 150.');
      expect(saved.rulesSlug, 'zapzap');
      expect(saved.isDefault, isTrue);
      expect(saved.builtinKey, 'zapzap');
      expect(saved.playerDeadThreshold, 150);
    });

    testWidgets('choosing Aucune clears the condition and its threshold',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap()],
      );

      await _openEditor(tester);
      await _choose(tester, _playerDeadDropdown, 'Aucune');
      await _save(tester);

      final saved = repo.updates.single;
      expect(saved.playerDeadConditionType, isNull);
      expect(saved.playerDeadThreshold, isNull);
      expect(saved.rulesSlug, 'zapzap', reason: 'still carried across');
    });
  });

  group('validation', () {
    testWidgets('an empty name marks the field, with no snackbar',
        (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      await tester.enterText(find.byKey(const Key('game_type_name_field')), '');
      await _save(tester);

      expect(find.text('Le nom est requis'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(repo.updates, isEmpty);
      expect(find.text('Modifier le type'), findsOneWidget,
          reason: 'the dialog stays open');
    });

    testWidgets('the name is trimmed on save, and the field stops at 64',
        (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      final field =
          tester.widget<TextField>(find.byKey(const Key('game_type_name_field')));
      expect(field.maxLength, 64, reason: "the server's max_length=64");

      await tester.enterText(
          find.byKey(const Key('game_type_name_field')), '  Belote  ');
      await _save(tester);

      expect(repo.updates.single.name, 'Belote');
    });

    testWidgets('a condition without a threshold cannot be saved',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(playerDeadConditionType: null, playerDeadThreshold: null)],
      );

      await _openEditor(tester);
      await _choose(tester, _playerDeadDropdown, 'Au-dessus du seuil');
      await _save(tester);

      expect(find.text('Un seuil est obligatoire pour cette condition'),
          findsOneWidget);
      expect(repo.updates, isEmpty);

      // Given one, it saves — and the stored row can never hold a condition
      // without a threshold.
      await tester.enterText(
          find.byKey(const Key('game_type_player_dead_threshold')), '80');
      await _save(tester);
      final saved = repo.updates.single;
      expect(saved.playerDeadConditionType, PlayerDeadConditionType.over);
      expect(saved.playerDeadThreshold, 80);
    });

    testWidgets('the game-over threshold is required too', (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      await _choose(tester, _gameOverDropdown, 'Premier joueur à atteindre');
      await _save(tester);

      expect(find.text('Un seuil est obligatoire pour cette condition'),
          findsOneWidget);
      expect(repo.updates, isEmpty);

      await tester.enterText(
          find.byKey(const Key('game_type_game_over_threshold')), '500');
      await _save(tester);
      expect(repo.updates.single.gameOverThreshold, 500);
    });

    testWidgets('letters typed into a threshold never reach the controller',
        (tester) async {
      await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      final finder = find.byKey(const Key('game_type_player_dead_threshold'));
      await tester.enterText(finder, '1a2b3-');
      await tester.pump();

      expect(tester.widget<TextField>(finder).controller!.text, '123');
    });

    testWidgets('a threshold above the maximum is refused', (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      await tester.enterText(
          find.byKey(const Key('game_type_player_dead_threshold')), '9999999');
      await _save(tester);

      expect(find.textContaining('Le seuil ne peut pas dépasser'), findsOneWidget);
      expect(repo.updates, isEmpty);
    });

    testWidgets('no controller outlives the dialog', (tester) async {
      await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      final controllers = [
        for (final key in const [
          Key('game_type_name_field'),
          Key('game_type_player_dead_threshold'),
        ])
          tester.widget<TextField>(find.byKey(key)).controller!,
      ];
      expect(controllers, hasLength(2));

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      for (final controller in controllers) {
        expect(
          () => controller.addListener(() {}),
          throwsA(isA<FlutterError>()),
          reason: 'a disposed controller refuses a listener',
        );
      }
    });
  });

  group('the pickers', () {
    testWidgets('the icon grid marks the current icon', (tester) async {
      await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _openEditor(tester);
      await tester.tap(find.byKey(const Key('game_type_icon_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('game_type_icon_current')), findsOneWidget);
      expect(find.byTooltip('Icône actuelle'), findsOneWidget);
    });

    testWidgets('a colour outside the palette is offered as the current swatch',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(cardColorValue: 0xFFFFC107)],
      );

      await _openEditor(tester);
      await tester.tap(find.byKey(const Key('game_type_color_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('game_type_color_4294951175')), findsOneWidget,
          reason: 'opening the picker must not recolour a type by itself');
      expect(find.byTooltip('Couleur actuelle'), findsOneWidget);

      final palette = kGameTypePalette.first;
      await tester
          .tap(find.byKey(Key('game_type_color_${palette.toARGB32()}')));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(repo.updates.single.cardColorValue, palette.toARGB32());
    });
  });

  group('deleting a type', () {
    testWidgets('one that games use is refused, in French, with the count',
        (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);
      repo.games = 3;

      await _pickMenu(tester, 'Supprimer');

      expect(find.text('Suppression impossible'), findsOneWidget);
      expect(
        find.text('3 parties utilisent ce type : il ne peut pas être supprimé.'),
        findsOneWidget,
      );
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Erreur lors de'), findsNothing);
      expect(repo.deletions, isEmpty);
    });

    testWidgets('an unused one is confirmed as a type, not as a game',
        (tester) async {
      final repo =
          await _pump(tester, size: _editorSurface, types: [_zapzap()]);

      await _pickMenu(tester, 'Supprimer');
      expect(
        find.text('Voulez-vous vraiment supprimer le type de jeu « ZapZap » ?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();
      expect(repo.deletions, [1]);
    });
  });

  group('the win direction', () {
    testWidgets('flipping it under finished games asks first, and can be refused',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(isLowestScoreWins: true)],
      );
      repo.finishedGames = 3;

      await _openEditor(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(find.byKey(const Key('game_type_direction_warning')), findsOneWidget);
      expect(find.textContaining('3 parties terminées'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byKey(const Key('game_type_direction_warning')),
        matching: find.text('Annuler'),
      ));
      await tester.pumpAndSettle();

      expect(repo.updates, isEmpty, reason: 'the row is left untouched');
      expect(find.text('Modifier le type'), findsOneWidget);
    });

    testWidgets('flipping it with no finished game saves with no interruption',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(isLowestScoreWins: true)],
      );

      await _openEditor(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(find.byKey(const Key('game_type_direction_warning')), findsNothing);
      expect(repo.updates.single.isLowestScoreWins, isFalse);
    });

    testWidgets('confirming the flip saves it', (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(isLowestScoreWins: true)],
      );
      repo.finishedGames = 1;

      await _openEditor(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(find.textContaining('1 partie terminée'), findsOneWidget);
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(repo.updates.single.isLowestScoreWins, isFalse);
    });

    testWidgets('a contradicting game-over condition is flagged, not refused',
        (tester) async {
      final repo = await _pump(
        tester,
        size: _editorSurface,
        types: [
          _zapzap(
            isLowestScoreWins: false,
            gameOverConditionType: GameOverConditionType.firstPlayerOver,
            gameOverThreshold: 500,
          )
        ],
      );

      await _openEditor(tester);
      expect(find.byKey(const Key('game_type_direction_contradiction')),
          findsNothing);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game_type_direction_contradiction')),
          findsOneWidget);

      await _save(tester);
      expect(repo.updates.single.isLowestScoreWins, isTrue,
          reason: 'a house rule may want exactly that');
    });
  });

  group('the rules editor is offered, never rewritten', () {
    testWidgets('a changed condition on a type with rules offers the editor',
        (tester) async {
      await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(rules: 'On joue à 150.')],
      );

      await _openEditor(tester);
      await tester.enterText(
          find.byKey(const Key('game_type_player_dead_threshold')), '150');
      await _save(tester);

      expect(find.byKey(const Key('game_type_rules_outdated')), findsOneWidget);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game_type_rules_outdated')), findsNothing);
    });

    testWidgets('changing only the colour offers nothing', (tester) async {
      await _pump(
        tester,
        size: _editorSurface,
        types: [_zapzap(rules: 'On joue à 150.')],
      );

      await _openEditor(tester);
      await tester.tap(find.byKey(const Key('game_type_color_button')));
      await tester.pumpAndSettle();
      await tester.tap(
          find.byKey(Key('game_type_color_${kGameTypePalette.first.toARGB32()}')));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(find.byKey(const Key('game_type_rules_outdated')), findsNothing);
    });
  });

  testWidgets('a new type is created from the form', (tester) async {
    final repo = await _pump(tester, count: 1, size: _editorSurface);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('game_type_name_field')), ' Triomino ');
    await _save(tester);

    expect(repo.creations.single.name, 'Triomino');
    expect(repo.updates, isEmpty);
  });
  group('the keypad shortcut', () {
    testWidgets('a new type gets the shortcut and label set in the form',
        (tester) async {
      final repo = await _pump(tester, count: 1, size: _editorSurface);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('game_type_name_field')), 'Maison');
      await _chooseShortcut(tester, 'Ajouter au score');
      await tester.enterText(
          find.byKey(const Key('game_type_shortcut_amount')), '-5');
      await tester.enterText(
          find.byKey(const Key('game_type_shortcut_label')), 'Pénalité');
      await _save(tester);

      expect(repo.creations.single.keypadShortcut,
          KeypadShortcut.tryCreate(KeypadShortcutKind.add, -5, label: 'Pénalité'));
    });

    testWidgets('an edit shows the type\'s shortcut and keeps it',
        (tester) async {
      final skyjo = GameType.skyjo();
      final repo = await _pump(tester, size: _editorSurface, types: [
        GameType.fromMap({...skyjo.toMap(), 'id': 1}),
      ]);

      await _openEditor(tester);
      expect(find.text('Multiplier le score (positif seulement)'), findsOneWidget);
      final amount = tester.widget<TextField>(
          find.byKey(const Key('game_type_shortcut_amount')));
      expect(amount.controller!.text, '2');
      await _save(tester);

      expect(repo.updates.single.keypadShortcut, KeypadShortcut.multiply(2));
    });

    testWidgets('choosing Aucune clears it', (tester) async {
      final repo = await _pump(tester, size: _editorSurface, types: [
        GameType.fromMap({...GameType.belote().toMap(), 'id': 1}),
      ]);

      await _openEditor(tester);
      await _chooseShortcut(tester, 'Aucune');
      await _save(tester);

      expect(repo.updates.single.keypadShortcut, isNull);
    });

    testWidgets('a multiplier out of bounds, or none, is refused under its field',
        (tester) async {
      final repo = await _pump(tester, count: 1, size: _editorSurface);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('game_type_name_field')), 'Maison');
      await _chooseShortcut(tester, 'Multiplier le score (positif seulement)');
      await _save(tester);
      expect(find.text('Un nombre entier entre 2 et 10'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('game_type_shortcut_amount')), '11');
      await _save(tester);
      expect(find.text('Un nombre entier entre 2 et 10'), findsOneWidget);
      expect(repo.creations, isEmpty);

      await tester.enterText(
          find.byKey(const Key('game_type_shortcut_amount')), '3');
      await _save(tester);
      expect(repo.creations.single.keypadShortcut, KeypadShortcut.multiply(3));
    });
  });
}
