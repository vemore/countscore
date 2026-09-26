// The shared "replace configuration?" dialog
// (wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md): it shows
// the current and the new values, changes nothing unless confirmed, and warns
// before a group holding unsynced changes is left — leaving empties the outbox.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/utils/config_link.dart';
import 'package:countscore/widgets/replace_config_dialog.dart';

import '../support/fake_group_provider.dart';

const _oldServer = 'https://old.example.com';
const _newServer = 'https://new.example.com';
const _invite = '22222222-2222-4222-8222-222222222222';

class _Harness {
  _Harness(this.backend, this.group);
  final BackendProvider backend;
  final FakeGroupProvider group;
  ReplaceConfigResult? result;
}

/// Pumps a page whose button opens the dialog for [config].
Future<_Harness> _pump(
  WidgetTester tester,
  ConfigLink config, {
  String? server = _oldServer,
  FakeGroupProvider? group,
}) async {
  SharedPreferences.setMockInitialValues({'backendUrl': ?server});
  final h = _Harness(BackendProvider(server), group ?? FakeGroupProvider());
  addTearDown(h.group.dispose);
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
    expect(h.group.calls, isEmpty, reason: 'no leave, no join, no server hand-over');
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

  testWidgets('confirming leaves the old group, then sets the server, then joins',
      (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: _invite),
      group: FakeGroupProvider(joined: true),
    );
    await _confirm(tester, nickname: '  Tablet ');

    expect(h.result, ReplaceConfigResult.applied);
    expect(h.group.calls, ['leave', 'backend $_newServer', 'join $_invite as Tablet']);
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

    expect(h.group.calls, ['leave', 'backend $_newServer']);
    expect(h.backend.baseUrl, _newServer);
  });

  group('leaving a group with unsynced rows', () {
    testWidgets('warns first; cancelling the warning changes nothing', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer, invite: _invite),
        group: FakeGroupProvider(joined: true, pending: 3),
      );
      await _confirm(tester, nickname: 'Tablet');

      expect(find.byKey(const Key('replace_config_unsynced')), findsOneWidget);
      expect(find.textContaining('3 changes on this device have not reached the group'),
          findsOneWidget);
      expect(h.group.calls, isEmpty, reason: 'nothing happens before the answer');

      await tester.tap(find.byKey(const Key('replace_config_unsynced_cancel')));
      await tester.pumpAndSettle();

      expect(h.result, ReplaceConfigResult.cancelled);
      expect(h.group.calls, isEmpty);
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
      expect(h.group.calls, ['leave', 'join $_invite as Tablet'],
          reason: 'same server: no hand-over');
    });

    testWidgets('no warning when everything is synced', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer),
        group: FakeGroupProvider(joined: true, pending: 0),
      );
      await _confirm(tester);

      expect(find.byKey(const Key('replace_config_unsynced')), findsNothing);
      expect(h.group.calls.first, 'leave');
    });

    testWidgets('no warning when no group is left', (tester) async {
      final h = await _pump(
        tester,
        const ConfigLink(server: _newServer, invite: _invite),
        group: FakeGroupProvider(joined: false, pending: 5),
      );
      await _confirm(tester, nickname: 'Tablet');

      expect(find.byKey(const Key('replace_config_unsynced')), findsNothing);
      expect(h.group.calls, ['backend $_newServer', 'join $_invite as Tablet']);
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
    expect(h.group.calls, isEmpty);
  });

  testWidgets('a failed join keeps the new server and says why', (tester) async {
    final h = await _pump(
      tester,
      const ConfigLink(server: _newServer, invite: _invite),
      group: FakeGroupProvider(joinError: GroupActionException(GroupActionError.unknownShareToken)),
    );
    await _confirm(tester, nickname: 'Tablet');

    expect(h.result, ReplaceConfigResult.joinFailed);
    expect(h.backend.baseUrl, _newServer);
    expect(find.text('Configuration replaced'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
