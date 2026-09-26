// The shared "replace configuration?" dialog
// (wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md): it shows
// the current and the new values and changes nothing unless confirmed. A group is
// joined before anything is left, so a refused join loses nothing; the same group
// behind a newer code is kept; and leaving a group that holds unsynced changes,
// counted when the question is asked, warns first (leaving empties the outbox).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/utils/config_link.dart';
import 'package:countscore/widgets/replace_config_dialog.dart';

import '../support/fake_group_provider.dart';
import '../support/group_servers.dart' as real;

const _oldServer = 'https://old.example.com';
const _newServer = 'https://new.example.com';
const _invite = '22222222-2222-4222-8222-222222222222';

class _Harness {
  _Harness(this.backend, this.group);
  final BackendProvider backend;
  final GroupProvider group;
  ReplaceConfigResult? result;

  List<String> get calls => (group as FakeGroupProvider).calls;
}

/// Pumps a page whose button opens the dialog for [config].
Future<_Harness> _pump(
  WidgetTester tester,
  ConfigLink config, {
  String? server = _oldServer,
  GroupProvider? group,
}) async {
  SharedPreferences.setMockInitialValues({'backendUrl': ?server});
  final h = _Harness(BackendProvider(server), group ?? FakeGroupProvider());
  if (h.group is FakeGroupProvider) addTearDown(h.group.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: h.backend),
      ChangeNotifierProvider<GroupProvider>.value(value: h.group),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => h.result = await showReplaceConfigDialog(context, config),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return h;
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

Future<void> _confirm(WidgetTester tester, {String? nickname}) async {
  if (nickname != null) {
    await tester.enterText(find.byKey(const Key('replace_config_nickname')), nickname);
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('replace_config_confirm')));
  await tester.pumpAndSettle();
}

final _leaveQuestion = find.byKey(const Key('replace_config_leave_question'));

void main() {
  testWidgets('shows the current and the new server and group', (tester) async {
    await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: _invite),
      group: FakeGroupProvider(joined: true, name: 'Famille'),
    );

    expect(_text(tester, 'replace_config_server_current'), 'Now: $_oldServer');
    expect(_text(tester, 'replace_config_server_new'), 'New: $_newServer');
    expect(_text(tester, 'replace_config_group_current'), 'Now: Famille');
    expect(_text(tester, 'replace_config_group_new'), 'New: invite code $_invite');
    expect(find.byKey(const Key('replace_config_leaves_group')), findsOneWidget);
    expect(find.byKey(const Key('replace_config_nickname')), findsOneWidget);
  });

  testWidgets('with no server and no group yet, the current values read None', (tester) async {
    await _pump(tester, const ConfigLink(server: _newServer), server: null);

    expect(_text(tester, 'replace_config_server_current'), 'Now: None');
    expect(_text(tester, 'replace_config_group_current'), 'Now: None');
    expect(_text(tester, 'replace_config_group_new'), 'New: None');
    expect(find.byKey(const Key('replace_config_nickname')), findsNothing);
    expect(find.byKey(const Key('replace_config_leaves_group')), findsNothing);
  });

  testWidgets('a group whose name is not known is shown by its invite code', (tester) async {
    await _pump(
      tester,
      const ConfigLink(server: _newServer),
      group: FakeGroupProvider(joined: true, name: '', token: 'old-invite'),
    );

    expect(_text(tester, 'replace_config_group_current'), 'Now: invite code old-invite');
  });

  testWidgets('cancelling leaves the settings untouched', (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: _invite),
      group: FakeGroupProvider(joined: true, pending: 2),
    );
    await tester.enterText(find.byKey(const Key('replace_config_nickname')), 'Tablet');
    await tester.tap(find.byKey(const Key('replace_config_cancel')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(h.result, ReplaceConfigResult.cancelled);
    expect(h.backend.baseUrl, _oldServer);
    expect((await SharedPreferences.getInstance()).getString('backendUrl'), _oldServer);
    expect(h.calls, isEmpty, reason: 'no join, no leave, no server hand-over');
    expect(h.group.isJoined, isTrue);
    expect(h.group.shareToken, 'old-invite');
  });

  testWidgets('Replace stays disabled until a nickname is typed', (tester) async {
    await _pump(tester, const ConfigLink(server: _newServer, invite: _invite));
    FilledButton confirm() =>
        tester.widget<FilledButton>(find.byKey(const Key('replace_config_confirm')));

    expect(confirm().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('replace_config_nickname')), '   ');
    await tester.pump();
    expect(confirm().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('replace_config_nickname')), 'Tablet');
    await tester.pump();
    expect(confirm().onPressed, isNotNull);
  });

  testWidgets('confirming joins the new group first, then leaves the old one',
      (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: _invite),
      group: FakeGroupProvider(joined: true),
    );
    await _confirm(tester, nickname: '  Tablet ');

    expect(h.result, ReplaceConfigResult.applied);
    expect(h.calls, [
      'prepare $_invite on $_newServer as Tablet',
      'leave',
      'adopt group-new on $_newServer',
    ]);
    expect(_leaveQuestion, findsNothing, reason: 'announced in the first question, all synced');
    expect(h.backend.baseUrl, _newServer);
    expect((await SharedPreferences.getInstance()).getString('backendUrl'), _newServer);
    expect(find.text('Configuration replaced'), findsOneWidget);
  });

  testWidgets('a server alone replaces the server and leaves the group', (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer),
      group: FakeGroupProvider(joined: true),
    );
    expect(_text(tester, 'replace_config_group_new'), 'New: None');
    await _confirm(tester);

    expect(h.calls, ['leave', 'backend $_newServer']);
    expect(h.backend.baseUrl, _newServer);
  });

  group('a join the server refuses', () {
    testWidgets('changes nothing and says why', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer, invite: _invite),
        group: FakeGroupProvider(
          joined: true,
          pending: 3,
          joinError: GroupActionException(GroupActionError.unknownShareToken),
        ),
      );
      await _confirm(tester, nickname: 'Tablet');

      expect(h.result, ReplaceConfigResult.joinFailed);
      expect(h.calls, ['prepare $_invite on $_newServer as Tablet'],
          reason: 'no leave, no server change');
      expect(h.group.isJoined, isTrue);
      expect(h.backend.baseUrl, _oldServer);
      expect((await SharedPreferences.getInstance()).getString('backendUrl'), _oldServer);
      expect(find.text('Configuration replaced'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('with the real GroupProvider: still in the old group, outbox untouched',
        (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final credentials = MemorySyncCredentials();
      final servers = real.GroupServers();
      final group = GroupProvider(
        db: db,
        credentials: credentials,
        httpClient: servers.client,
        enableStream: false,
        pollInterval: const Duration(hours: 1),
      );
      addTearDown(() async {
        group.dispose();
        await db.close();
      });
      await tester.runAsync(() async {
        await group.updateBackend(real.oldServer);
        await group.joinGroup(real.oldInvite, 'Phone');
        await real.idle(group);
        await real.addUnsyncedChange(db);
      });
      servers
        ..seen.clear()
        ..joinStatus = 404;

      final h = await _pump(
        tester,
        const ConfigLink(server: real.newServer, invite: 'stale-code'),
        server: real.oldServer,
        group: group,
      );
      await tester.enterText(find.byKey(const Key('replace_config_nickname')), 'Tablet');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('replace_config_confirm')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(h.result, ReplaceConfigResult.joinFailed);
      expect(find.text('Unknown or replaced invite code'), findsOneWidget);
      expect(group.groupId, real.oldGroupId);
      expect(group.shareToken, real.oldInvite);
      expect(await tester.runAsync(credentials.deviceToken), real.oldDeviceToken);
      expect(await tester.runAsync(() => real.outboxCount(db)), 1);
      expect(servers.seen.map((r) => '${r.method} ${r.url.host}${r.url.path}'),
          ['POST new.example.com/groups/join'],
          reason: 'the join was tried, and nothing on the old server was touched');
      expect(h.backend.baseUrl, real.oldServer);
      expect((await SharedPreferences.getInstance()).getString('backendUrl'), real.oldServer);
    });
  });

  testWidgets('the same group behind a newer code is kept, not left', (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _oldServer, invite: 'rotated-code'),
      group: FakeGroupProvider(joined: true, pending: 4, joinGroupId: 'group-old'),
    );
    await _confirm(tester, nickname: 'Tablet');

    expect(_leaveQuestion, findsNothing, reason: 'nothing is left: no warning');
    expect(h.calls, ['prepare rotated-code on $_oldServer as Tablet', 'keep']);
    expect(h.result, ReplaceConfigResult.unchanged);
    expect(h.group.isJoined, isTrue);
    expect(h.group.shareToken, 'rotated-code');
    expect(find.text('This device already uses this configuration'), findsOneWidget);
  });

  testWidgets('the same group under another server URL says the configuration changed',
      (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: 'rotated-code'),
      group: FakeGroupProvider(joined: true, pending: 4, joinGroupId: 'group-old'),
    );
    await _confirm(tester, nickname: 'Tablet');

    expect(_leaveQuestion, findsNothing);
    expect(h.calls, ['prepare rotated-code on $_newServer as Tablet', 'keep']);
    expect(h.result, ReplaceConfigResult.applied);
    expect(h.backend.baseUrl, _newServer);
    expect(find.text('Configuration replaced'), findsOneWidget);
    expect(find.text('This device already uses this configuration'), findsNothing);
  });

  group('leaving a group with unsynced rows', () {
    testWidgets('warns first, with the count read now; cancelling changes nothing',
        (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer, invite: _invite),
        // The cached count says 0 (no sync pass yet, as on a cold start from a
        // link); the outbox holds 3.
        group: FakeGroupProvider(joined: true, pending: 0, storedPending: 3),
      );
      await _confirm(tester, nickname: 'Tablet');

      expect(_leaveQuestion, findsOneWidget);
      expect(find.textContaining('3 changes on this device have not reached the group'),
          findsOneWidget);
      expect(h.calls, ['prepare $_invite on $_newServer as Tablet'],
          reason: 'joined, nothing left yet');

      await tester.tap(find.byKey(const Key('replace_config_leave_cancel')));
      await tester.pumpAndSettle();

      expect(h.result, ReplaceConfigResult.cancelled);
      expect(h.calls.last, 'cancel', reason: 'the new registration is withdrawn');
      expect(h.calls, isNot(contains('leave')));
      expect(h.group.isJoined, isTrue);
      expect(h.backend.baseUrl, _oldServer);
    });

    testWidgets('"Leave anyway" goes on', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _oldServer, invite: _invite),
        group: FakeGroupProvider(joined: true, pending: 1),
      );
      await _confirm(tester, nickname: 'Tablet');
      expect(find.textContaining('1 change on this device has not reached the group'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('replace_config_leave_anyway')));
      await tester.pumpAndSettle();

      expect(h.result, ReplaceConfigResult.applied);
      expect(h.calls, [
        'prepare $_invite on $_oldServer as Tablet',
        'leave',
        'adopt group-new on $_oldServer',
      ]);
    });

    testWidgets('a server alone, unsynced: warns before leaving', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer),
        group: FakeGroupProvider(joined: true, pending: 0, storedPending: 2),
      );
      await _confirm(tester);

      expect(_leaveQuestion, findsOneWidget);
      await tester.tap(find.byKey(const Key('replace_config_leave_cancel')));
      await tester.pumpAndSettle();
      expect(h.calls, isEmpty);
      expect(h.backend.baseUrl, _oldServer);
    });

    testWidgets('no warning when everything is synced and the leave was announced',
        (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer),
        group: FakeGroupProvider(joined: true, pending: 0),
      );
      await _confirm(tester);

      expect(_leaveQuestion, findsNothing);
      expect(h.calls.first, 'leave');
    });

    testWidgets('same server, another group: says the group is left before leaving it',
        (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _oldServer, invite: _invite),
        group: FakeGroupProvider(joined: true, pending: 0),
      );
      expect(find.byKey(const Key('replace_config_leaves_group')), findsNothing,
          reason: 'may be the same group: only the server can tell');
      await _confirm(tester, nickname: 'Tablet');

      expect(_text(tester, 'replace_config_leave_question'),
          'This device will leave the group Famille. Its games stay on this device.');
      await tester.tap(find.byKey(const Key('replace_config_leave_anyway')));
      await tester.pumpAndSettle();
      expect(h.calls.skip(1), ['leave', 'adopt group-new on $_oldServer']);
    });

    testWidgets('no warning when no group is left', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer, invite: _invite),
        group: FakeGroupProvider(joined: false, pending: 5),
      );
      await _confirm(tester, nickname: 'Tablet');

      expect(_leaveQuestion, findsNothing);
      expect(h.calls, [
        'prepare $_invite on $_newServer as Tablet',
        'adopt group-new on $_newServer',
      ]);
    });
  });

  testWidgets('the configuration already in use asks nothing', (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _oldServer, invite: 'old-invite'),
      group: FakeGroupProvider(joined: true, pending: 4),
    );

    expect(find.byType(AlertDialog), findsNothing);
    expect(h.result, ReplaceConfigResult.unchanged);
    expect(find.text('This device already uses this configuration'), findsOneWidget);
    expect(h.calls, isEmpty);
  });
}
