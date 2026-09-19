// The rules page picks between three layers: what the user wrote, the ruleset
// the app ships for the type, and nothing at all. Getting that precedence wrong
// is the defect that matters — a group's own rules must never be shadowed by
// the shipped text, and "restore" must put the shipped text back.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/game_type_repository.dart';
import 'package:countscore/screens/game_rules_screen.dart';
import 'package:countscore/services/game_rules_catalog.dart';

/// Serves one ruleset from memory, so the test never touches the asset bundle.
class _FakeCatalog implements GameRulesCatalog {
  _FakeCatalog(this._shipped);

  final String? _shipped;

  @override
  Future<String?> rules(String? slug, String languageCode) async =>
      slug == null ? null : _shipped;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGameTypeRepository implements GameTypeRepository {
  GameType? updated;

  @override
  Future<int> update(GameType gameType) async {
    updated = gameType;
    return 1;
  }

  @override
  Future<int> create(GameType gameType) async => 1;
  @override
  Future<GameType?> getById(int id) async => null;
  @override
  Future<List<GameType>> getAll() async => const [];
  @override
  Future<int> delete(int id) async => 1;
}

GameType _type({String? rules, String? rulesSlug = 'skyjo'}) => GameType(
      id: 1,
      name: 'Skyjo',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: 0xFF2196F3,
      isLowestScoreWins: true,
      isDefault: true,
      gameOverConditionType: GameOverConditionType.firstPlayerOver,
      gameOverThreshold: 100,
      rules: rules,
      rulesSlug: rulesSlug,
    );

Future<_FakeGameTypeRepository> _pump(
  WidgetTester tester,
  GameType gameType, {
  String? shipped = '## Mise en place\nDouze cartes.',
}) async {
  final repo = _FakeGameTypeRepository();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => GameTypeProvider(repo: repo),
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameRulesScreen(
          gameType: gameType,
          catalog: _FakeCatalog(shipped),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows the shipped ruleset when the user wrote none',
      (tester) async {
    await _pump(tester, _type());
    expect(find.textContaining('Douze cartes'), findsOneWidget);
    // The shipped text carries the trademark note; the group's own does not.
    expect(find.textContaining('à titre descriptif'), findsOneWidget);
  });

  testWidgets("the user's own rules win over the shipped ones", (tester) async {
    await _pump(tester, _type(rules: 'Chez nous on joue à 150.'));
    expect(find.textContaining('Chez nous on joue à 150.'), findsOneWidget);
    expect(find.textContaining('Douze cartes'), findsNothing);
    expect(find.text('Règles de votre groupe'), findsOneWidget);
  });

  testWidgets('derives the scoring summary from the type, not from the text',
      (tester) async {
    await _pump(tester, _type());
    // Twice on purpose: the header card names the direction, the summary
    // repeats it as the first derived line.
    expect(find.text('Plus petit score gagne'), findsNWidgets(2));
    expect(
      find.text("La partie s'arrête dès qu'un joueur atteint 100 points"),
      findsOneWidget,
    );
    expect(find.text("Pas d'élimination en cours de partie"), findsOneWidget);
  });

  testWidgets('a type with no slug and no text gets the empty state',
      (tester) async {
    await _pump(tester, _type(rulesSlug: null), shipped: null);
    expect(find.text('Pas encore de règles'), findsOneWidget);
    expect(find.text('Écrire les règles'), findsOneWidget);
    // Nothing to edit from the app bar while the page is empty.
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('restoring the default clears the stored rules', (tester) async {
    final repo = await _pump(tester, _type(rules: 'Chez nous on joue à 150.'));
    await tester.tap(find.text("Rétablir les règles d'origine"));
    await tester.pumpAndSettle();
    expect(repo.updated, isNotNull);
    expect(repo.updated!.rules, isNull,
        reason: 'copyWith must be able to put rules back to null');
    expect(find.textContaining('Douze cartes'), findsOneWidget);
  });

  testWidgets('restore is not offered for a type with no shipped ruleset',
      (tester) async {
    await _pump(tester, _type(rulesSlug: null, rules: 'Mes règles.'),
        shipped: null);
    expect(find.text("Rétablir les règles d'origine"), findsNothing);
    expect(find.text('Règles de votre groupe'), findsOneWidget);
  });

  testWidgets('the editor opens on what is displayed and saves it', (tester) async {
    final repo = await _pump(tester, _type());
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    // Pre-filled with the shipped text, so a correction starts from it.
    expect(find.text('## Mise en place\nDouze cartes.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nos règles.');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repo.updated!.rules, 'Nos règles.');
  });

  testWidgets('emptying the editor means "no rules of mine", not an empty string',
      (tester) async {
    final repo = await _pump(tester, _type(rules: 'Mes règles.'));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repo.updated!.rules, isNull);
  });
}
