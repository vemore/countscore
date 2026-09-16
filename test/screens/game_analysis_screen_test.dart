// With no server configured it
// must not be offerable at all — and a previously cached analysis must still
// be readable, because that text is local data.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/analysis_style.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_analysis_screen.dart';
import 'package:countscore/services/commentary_report.dart';

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

/// A backend that always refuses. `Response.bytes` keeps the fixture out of
/// http's latin-1 fallback.
MockClient _failing(int status, String detail) => MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'detail': detail})),
        status,
      ),
    );

MockClient _failing502() => _failing(502, 'upstream LLM error: RuntimeError');

/// Drives the screen from tapped button to settled failure.
///
/// `pumpAndSettle` cannot be used while loading: the CircularProgressIndicator
/// animates forever and would time it out. And settling afterwards would wait
/// out the snackbar's own auto-dismiss, so the assertions would find nothing.
Future<void> _pumpFailure(WidgetTester tester) async {
  await tester.pump(); // start the request
  await tester.pump(const Duration(milliseconds: 100)); // MockClient resolves
  await tester.pump(); // let the SnackBar enter
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('a failed regeneration keeps the cached analysis and warns',
      (tester) async {
    // The defect this pins: the error state used to win over the content, so a
    // failed refresh looked like it had destroyed an analysis that was never
    // touched — the repository is only written on success.
    final cached = GameAnalysis(
      gameId: 1,
      content: 'Le professeur a parlé.',
      modelId: 'test-model',
      generatedAt: DateTime(2026, 9, 11, 14, 30),
    );
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(cached),
        httpClient: _failing502(),
      ),
      backendUrl: 'https://countscore.example.com',
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Le professeur a parlé.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    // By position, not by label: regenerateAnalysis is also the IconButton's
    // tooltip, so a text finder can match twice.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    ).last);
    await _pumpFailure(tester);

    expect(find.text('Le professeur a parlé.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Failed to generate analysis (HTTP 502)'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('with nothing cached, a failure shows the error without the raw exception',
      (tester) async {
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(),
        httpClient: _failing502(),
      ),
      backendUrl: 'https://countscore.example.com',
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analysis_generate')));
    await _pumpFailure(tester);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Failed to generate analysis (HTTP 502)'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // The leak: the screen used to append the Dart exception verbatim.
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('upstream LLM error'), findsNothing);
  });

  testWidgets('a shown commentary can be reported by email', (tester) async {
    // Play's AI-Generated Content policy: the report control must be there
    // whenever generated text is on screen.
    final cached = GameAnalysis(
      id: 7,
      gameId: 1,
      content: 'Le professeur a parlé & bien parlé.',
      modelId: 'test-model',
      generatedAt: DateTime(2026, 9, 11, 14, 30),
    );
    final launched = <Uri>[];
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(cached),
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    final report = find.byKey(const Key('analysis_report'));
    expect(report, findsOneWidget);
    expect(tester.widget<IconButton>(report).tooltip, 'Report this commentary');

    await tester.tap(report);
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    final context = tester.element(find.byType(GameAnalysisScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(
      launched.single,
      buildCommentaryReportUri(
        subject: l10n.reportCommentarySubject,
        body: l10n.reportCommentaryBody(
          '#7 · test-model · 2026-09-11T14:30:00.000',
          'Le professeur a parlé & bien parlé.',
        ),
      ),
    );
    expect(launched.single.toString(),
        startsWith('mailto:$commentaryReportEmail?subject='));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('with nothing to report, the control is disabled',
      (tester) async {
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository()),
      backendUrl: 'https://countscore.example.com',
    ));
    await tester.pump();

    final report = find.byKey(const Key('analysis_report'));
    expect(tester.widget<IconButton>(report).onPressed, isNull);
  });

  testWidgets('with no mail app, reporting explains where to write',
      (tester) async {
    final cached = GameAnalysis(
      gameId: 1,
      content: 'Le professeur a parlé.',
      generatedAt: DateTime(2026, 9, 11, 14, 30),
    );
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(cached),
        launcher: (_) async => throw Exception('no activity for mailto'),
      ),
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analysis_report')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('No email app found. Write to $commentaryReportEmail '
          'to report this commentary.'),
      findsOneWidget,
    );
  });

  testWidgets('a 503 tells the user to retry later instead of showing a code',
      (tester) async {
    // The server answers 503 when its LLM provider is out of quota — the
    // 2026-09-11 Mistral outage showed users a bare "HTTP 502" for that.
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(),
        httpClient: _failing(503, 'upstream LLM rate-limited'),
      ),
      backendUrl: 'https://countscore.example.com',
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analysis_generate')));
    await _pumpFailure(tester);

    expect(
      find.text(
          'The analysis server is temporarily unavailable. Try again later.'),
      findsOneWidget,
    );
    expect(find.textContaining('HTTP'), findsNothing);
    expect(find.textContaining('rate-limited'), findsNothing);
  });

  testWidgets('the style picker offers every voice and remembers the last pick',
      (tester) async {
    SharedPreferences.setMockInitialValues({'analysisStyle': 'bard'});
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository()),
      backendUrl: 'https://countscore.example.com',
    ));
    await tester.pumpAndSettle();

    for (final style in AnalysisStyle.values) {
      expect(find.byKey(Key('analysis_style_${style.id}')), findsOneWidget);
    }
    ChoiceChip chip(AnalysisStyle style) =>
        tester.widget<ChoiceChip>(find.byKey(Key('analysis_style_${style.id}')));
    expect(chip(AnalysisStyle.bard).selected, isTrue);

    await tester.tap(find.byKey(const Key('analysis_style_coach')));
    await tester.pumpAndSettle();

    expect(chip(AnalysisStyle.coach).selected, isTrue);
    expect(chip(AnalysisStyle.bard).selected, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('analysisStyle'), 'coach');
  });

  testWidgets('an unreadable stored style falls back to the professor',
      (tester) async {
    SharedPreferences.setMockInitialValues({'analysisStyle': 'town-crier'});
    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(repository: _FakeAnalysisRepository()),
      backendUrl: 'https://countscore.example.com',
    ));
    await tester.pumpAndSettle();

    final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('analysis_style_professor')));
    expect(chip.selected, isTrue);
  });

  testWidgets('the request carries the style, the app language and the rules',
      (tester) async {
    SharedPreferences.setMockInitialValues({'analysisStyle': 'noir'});
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response.bytes(
        utf8.encode(jsonEncode({'content': 'Il pleuvait.', 'model': 'm'})),
        200,
      );
    });

    await tester.pumpWidget(_wrap(
      GameAnalysisScreen(
        repository: _FakeAnalysisRepository(),
        httpClient: client,
      ),
      backendUrl: 'https://countscore.example.com',
      gameProvider: _GameProviderWithCurrentGame(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analysis_generate')));
    await tester.pumpAndSettle();

    expect(find.text('Il pleuvait.'), findsOneWidget);
    expect(sent!['style'], 'noir');
    // The analysis answers in the language the app is displayed in — this
    // MaterialApp is pinned to English.
    expect(sent!['language'], 'en');
    expect(
      (sent!['game_type_rules'] as Map<String, dynamic>)['is_lowest_score_wins'],
      isTrue,
    );
  });
}
