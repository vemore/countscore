// The analysis is the app's only network call. With no server configured it
// must not be offerable at all — and a previously cached analysis must still
// be readable, because that text is local data.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_analysis_screen.dart';

/// In-memory stand-in: the screen is the subject here, not persistence.
class _FakeAnalysisRepository implements GameAnalysisRepository {
  _FakeAnalysisRepository([this._stored]);

  GameAnalysis? _stored;

  @override
  Future<GameAnalysis?> getByGame(int gameId) async => _stored;

  @override
  Future<int> upsert(GameAnalysis analysis) async {
    _stored = analysis;
    return 1;
  }

  @override
  Future<int> deleteByGame(int gameId) async {
    _stored = null;
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit = 10,
    int? excludeGameId,
  }) async =>
      const [];
}

/// The screen only reads `currentGame` to know which analysis to load; nothing
/// else on the provider is touched, so overriding the getter is enough to avoid
/// standing up a database.
class _GameProviderWithCurrentGame extends GameProvider {
  @override
  Game? get currentGame =>
      Game(id: 1, name: 'Partie 1', gameTypeId: null, isLowestScoreWins: true);
}

Widget _wrap(Widget child, {String? backendUrl, GameProvider? gameProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => gameProvider ?? GameProvider()),
      ChangeNotifierProvider(create: (_) => GameTypeProvider()),
      ChangeNotifierProvider(create: (_) => BackendProvider(backendUrl)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('en', ''),
      home: child,
    ),
  );
}

void main() {
  testWidgets('with no server configured, generation is not offered',
      (tester) async {
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository()),
    ));
    await tester.pump();

    expect(find.byKey(const Key('analysis_no_server')), findsOneWidget);
    expect(find.byKey(const Key('analysis_generate')), findsNothing);
  });

  testWidgets('a cached analysis stays readable with no server configured',
      (tester) async {
    final cached = GameAnalysis(
      gameId: 1,
      content: 'Le professeur a parlé.',
      modelId: 'test-model',
      generatedAt: DateTime(2026, 9, 11, 14, 30),
    );
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository(cached)),
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    // Generated text is local data: clearing the server must not take it away.
    expect(find.text('Le professeur a parlé.'), findsOneWidget);
    expect(find.byKey(const Key('analysis_no_server')), findsNothing);
  });

  testWidgets('configuring a server brings the generate button back',
      (tester) async {
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository()),
      backendUrl: 'https://countscore.example.com',
    ));
    await tester.pump();

    expect(find.byKey(const Key('analysis_generate')), findsOneWidget);
    expect(find.byKey(const Key('analysis_no_server')), findsNothing);
  });
}
