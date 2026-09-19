// A shared game's analysis goes through the group's comment endpoint, so the
// group's budget, style and language apply; an unshared game keeps the
// stateless endpoint (wip/done/2026-09-19-group-comment-settings-shape-nothing-the-app-shows.md).

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_analysis_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';

const _url = 'https://countscore.example.com';
const _groupId = '11111111-1111-4111-8111-111111111111';
const _deviceToken = '33333333333343338333333333333333.secret';
const _gameUuid = '44444444-4444-4444-8444-444444444444';
const _groupPath = '/groups/me/games/$_gameUuid/comments';

class _FakeAnalysisRepository implements GameAnalysisRepository {
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

class _GameProviderWith extends GameProvider {
  _GameProviderWith(this._game);
  final Game _game;

  @override
  Game? get currentGame => _game;
}

Game _game({String? groupId, String? uuid}) => Game(
      id: 1,
      name: 'Partie 1',
      isLowestScoreWins: true,
      groupId: groupId,
      uuid: uuid,
    );

/// A backend with one group, whose comment endpoint answers [groupStatus]
/// (201: an analysis in the group's style) and whose stateless endpoint
/// answers an analysis of its own.
class _Server {
  _Server({this.groupStatus = 201});

  final int groupStatus;
  final seen = <http.Request>[];

  Iterable<http.Request> at(String path) => seen.where((r) => r.url.path == path);

  late final client = MockClient((request) async {
    seen.add(request);
    final (int status, Object body) = switch (request.url.path) {
      '/groups' => (
          200,
          {
            'group': {'id': _groupId, 'name': 'Famille', 'share_token': 'x'},
            'device': {'id': 'd', 'token': _deviceToken, 'label': 'd'},
          }
        ),
      '/sync/pull' => (200, {'deltas': [], 'server_seq_max': 0, 'has_more': false}),
      '/sync/push' => (200, {'results': []}),
      _groupPath => groupStatus == 201
          ? (201, {'content': 'Analyse du groupe.', 'model': 'gemini-2.5-flash'})
          : (groupStatus, {'detail': 'monthly budget exhausted (100/100¢)'}),
      '/comments/game-analysis' => (200, {'content': 'Analyse sans groupe.', 'model': 'm'}),
      _ => (200, <String, dynamic>{}),
    };
    return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
  });
}

Future<GroupProvider> _joined(_Server server) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final group = GroupProvider(
    db: db,
    credentials: MemorySyncCredentials(),
    httpClient: server.client,
    enableStream: false,
    pollInterval: const Duration(hours: 1),
  );
  await group.updateBackend(_url);
  await group.createGroup('Famille', 'd');
  return group;
}

Future<void> _pump(WidgetTester tester, _Server server, GroupProvider group, Game game) {
  return tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<GameProvider>(create: (_) => _GameProviderWith(game)),
      ChangeNotifierProvider(create: (_) => GameTypeProvider()),
      ChangeNotifierProvider(create: (_) => BackendProvider(_url)),
      ChangeNotifierProvider.value(value: group),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: GameAnalysisScreen(
        repository: _FakeAnalysisRepository(),
        httpClient: server.client,
      ),
    ),
  ));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
  await tester.pump();
}

Future<void> _generate(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('analysis_generate')));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester, GroupProvider group) async {
  await tester.pumpWidget(const SizedBox());
  group.dispose();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a shared game with no voice picked is analysed in the group style', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _joined(server)))!;
    await _pump(tester, server, group, _game(groupId: _groupId, uuid: _gameUuid));
    await _settle(tester);

    // No chip selected: the group's style applies, and the screen says so.
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.selected, isFalse);
    }
    expect(find.byKey(const Key('analysis_style_group_default')), findsOneWidget);

    await _generate(tester);

    expect(find.text('Analyse du groupe.'), findsOneWidget);
    expect(server.at('/comments/game-analysis'), isEmpty);
    final request = server.at(_groupPath).single;
    expect(request.headers['Authorization'], 'Bearer $_deviceToken');
    final analysis = (jsonDecode(request.body) as Map<String, dynamic>)['analysis']
        as Map<String, dynamic>;
    // No `style`: the server falls back on the group's.
    expect(analysis.containsKey('style'), isFalse);
    expect((analysis['game'] as Map<String, dynamic>)['name'], 'Partie 1');

    await _dispose(tester, group);
  });

  testWidgets('a voice picked on the device travels with a shared game', (tester) async {
    SharedPreferences.setMockInitialValues({'analysisStyle': 'bard'});
    final server = _Server();
    final group = (await tester.runAsync(() => _joined(server)))!;
    await _pump(tester, server, group, _game(groupId: _groupId, uuid: _gameUuid));
    await _settle(tester);

    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('analysis_style_bard'))).selected,
      isTrue,
    );
    expect(find.byKey(const Key('analysis_style_group_default')), findsNothing);

    await _generate(tester);

    final analysis = (jsonDecode(server.at(_groupPath).single.body)
        as Map<String, dynamic>)['analysis'] as Map<String, dynamic>;
    expect(analysis['style'], 'bard');

    await _dispose(tester, group);
  });

  testWidgets('an unshared game keeps the stateless endpoint', (tester) async {
    final server = _Server();
    final group = (await tester.runAsync(() => _joined(server)))!;
    await _pump(tester, server, group, _game());
    await _settle(tester);

    expect(find.byKey(const Key('analysis_style_group_default')), findsNothing);
    await _generate(tester);

    expect(find.text('Analyse sans groupe.'), findsOneWidget);
    expect(server.at(_groupPath), isEmpty);
    final request = server.at('/comments/game-analysis').single;
    expect(request.headers.containsKey('Authorization'), isFalse);
    expect((jsonDecode(request.body) as Map<String, dynamic>)['style'], 'professor');

    await _dispose(tester, group);
  });

  testWidgets('a group over its budget gets a message, not a raw error', (tester) async {
    final server = _Server(groupStatus: 409);
    final group = (await tester.runAsync(() => _joined(server)))!;
    await _pump(tester, server, group, _game(groupId: _groupId, uuid: _gameUuid));
    await _settle(tester);

    await _generate(tester);

    expect(
      find.text(
          'Your group has used up its analysis budget for this month. It renews at the start of next month.'),
      findsOneWidget,
    );
    expect(find.textContaining('HTTP'), findsNothing);
    expect(find.textContaining('budget exhausted'), findsNothing);
    // Not quietly sent to the unbudgeted endpoint instead.
    expect(server.at('/comments/game-analysis'), isEmpty);

    await _dispose(tester, group);
  });

  testWidgets('a shared game the server does not hold gets the stateless analysis',
      (tester) async {
    final server = _Server(groupStatus: 404);
    final group = (await tester.runAsync(() => _joined(server)))!;
    await _pump(tester, server, group, _game(groupId: _groupId, uuid: _gameUuid));
    await _settle(tester);

    await _generate(tester);

    // One try, one sync, one retry — then the analysis every unshared game gets.
    expect(server.at(_groupPath), hasLength(2));
    expect(find.text('Analyse sans groupe.'), findsOneWidget);

    await _dispose(tester, group);
  });
}
