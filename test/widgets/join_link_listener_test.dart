// A scanned configuration QR reaching the app
// (wip/done/2026-09-24-the-app-opens-no-countscore-join-link.md and
// wip/done/2026-09-24-the-pwa-has-no-join-route.md): the Android app's
// `countscore://join?…` intent and the PWA's `#/join?…` route both open the replace
// dialog, once, after the group provider has read the stored membership; a link that
// does not parse opens nothing; and the PWA in an Android browser offers the app
// first, through the `intent://` hand-over.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/join_link_inbox.dart';
import 'package:countscore/services/sync/sync_credentials.dart';
import 'package:countscore/utils/config_link.dart';
import 'package:countscore/utils/game_result_share.dart' show kPlayStoreUrl;
import 'package:countscore/widgets/join_link_listener.dart';
import 'package:countscore/widgets/replace_config_dialog.dart';

import '../support/fake_group_provider.dart';

const _oldServer = 'https://old.example.com';
const _newServer = 'https://new.example.com';
const _invite = '22222222-2222-4222-8222-222222222222';
const _config = ConfigLink(server: _newServer, invite: _invite);

/// What follows `#` in the QR's link: the route the PWA opens on.
final _route = Uri.parse(encodeConfigLink('https://scores.example.com/cs', _config)).fragment;

class _Harness {
  _Harness(this.backend, this.group);
  final BackendProvider backend;
  final FakeGroupProvider group;
  final opened = <String>[];
}

/// The home screen as `main.dart` builds it: the listener around it, under the
/// providers, with this device on [_oldServer] in the group "Famille".
Future<_Harness> _pump(
  WidgetTester tester,
  JoinLinkInbox inbox, {
  bool offerAppHandOver = false,
  FakeGroupProvider? group,
}) async {
  SharedPreferences.setMockInitialValues({'backendUrl': _oldServer});
  final h = _Harness(BackendProvider(_oldServer), group ?? FakeGroupProvider(joined: true));
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
      home: JoinLinkListener(
        inbox: inbox,
        offerAppHandOver: offerAppHandOver,
        openInApp: h.opened.add,
        child: const Scaffold(body: Text('home')),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return h;
}

final _replaceDialog = find.byType(ReplaceConfigDialog);
final _anyDialog = find.byType(AlertDialog);

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

/// The settings a cancelled link must leave as they were.
Future<void> _expectUntouched(_Harness h) async {
  expect(h.backend.baseUrl, _oldServer);
  expect((await SharedPreferences.getInstance()).getString('backendUrl'), _oldServer);
  expect(h.group.isJoined, isTrue);
  expect(h.group.token, 'old-invite');
  expect(h.group.calls, isEmpty, reason: 'no join, leave or server change');
}

/// A route push as the web engine sends it when the address changes while the
/// PWA runs (`flutter/navigation`, `pushRouteInformation`).
Future<void> _pushRoute(WidgetTester tester, String location) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': location, 'state': null}),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Android: countscore://join', () {
    testWidgets('opens the replace dialog; cancelling leaves the settings untouched',
        (tester) async {
      final inbox = JoinLinkInbox();
      final h = await _pump(tester, inbox);
      expect(_anyDialog, findsNothing);

      inbox.add(encodeAppConfigLink(_config)); // a new intent while the app runs
      await tester.pumpAndSettle();

      expect(_replaceDialog, findsOneWidget);
      expect(_text(tester, 'replace_config_server_current'), 'Now: $_oldServer');
      expect(_text(tester, 'replace_config_server_new'), 'New: $_newServer');
      expect(_text(tester, 'replace_config_group_current'), 'Now: Famille');
      expect(_text(tester, 'replace_config_group_new'), 'New: invite code $_invite');

      await tester.tap(find.byKey(const Key('replace_config_cancel')));
      await tester.pumpAndSettle();

      expect(_anyDialog, findsNothing);
      await _expectUntouched(h);
    });

    testWidgets('a cold start waits for the stored membership, and opens the link once',
        (tester) async {
      // The launch intent arrives before the home screen exists.
      final inbox = JoinLinkInbox()..add(encodeAppConfigLink(_config));
      final group = FakeGroupProvider(joined: true)..holdLoad();
      await _pump(tester, inbox, group: group);

      expect(_anyDialog, findsNothing, reason: 'the membership is still being read');

      group.markLoaded();
      await tester.pumpAndSettle();
      expect(_replaceDialog, findsOneWidget);
      expect(_text(tester, 'replace_config_group_current'), 'Now: Famille');

      await tester.tap(find.byKey(const Key('replace_config_cancel')));
      await tester.pumpAndSettle();

      // A rebuild, or the app coming back to the foreground, replays nothing.
      group.notifyListeners();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(_anyDialog, findsNothing);
    });

    testWidgets('two links in a row open one dialog after the other', (tester) async {
      final inbox = JoinLinkInbox();
      await _pump(tester, inbox);

      inbox
        ..add(encodeAppConfigLink(_config))
        ..add(encodeAppConfigLink(const ConfigLink(server: 'https://third.example.com')));
      await tester.pumpAndSettle();
      expect(_replaceDialog, findsOneWidget);
      expect(_text(tester, 'replace_config_server_new'), 'New: $_newServer');

      await tester.tap(find.byKey(const Key('replace_config_cancel')));
      await tester.pumpAndSettle();
      expect(_replaceDialog, findsOneWidget);
      expect(_text(tester, 'replace_config_server_new'), 'New: https://third.example.com');
    });

    testWidgets('a link that does not parse opens nothing', (tester) async {
      final inbox = JoinLinkInbox();
      final h = await _pump(tester, inbox);

      for (final link in const [
        'countscore://join',
        'countscore://join?s=ftp%3A%2F%2Fexample.com',
        'countscore://other?s=$_newServer',
        'countscore://join?s=$_newServer&g=two%20words',
      ]) {
        inbox.add(link);
        await tester.pumpAndSettle();
        expect(_anyDialog, findsNothing, reason: link);
      }
      expect(find.text('home'), findsOneWidget);
      await _expectUntouched(h);
    });
  });

  group('PWA: #/join', () {
    testWidgets('the route the page opened on shows the replace dialog', (tester) async {
      expect(_route, startsWith('/join?s='));
      final h = await _pump(tester, JoinLinkInbox(initialRoute: _route));

      expect(_replaceDialog, findsOneWidget);
      expect(_text(tester, 'replace_config_server_new'), 'New: $_newServer');
      expect(_text(tester, 'replace_config_group_new'), 'New: invite code $_invite');

      await tester.tap(find.byKey(const Key('replace_config_cancel')));
      await tester.pumpAndSettle();
      await _expectUntouched(h);
    });

    for (final route in const [
      '/join',
      '/join?',
      '/join?g=$_invite',
      '/join?s=ftp%3A%2F%2Fexample.com&g=$_invite',
      '/join?s=%E0%A4%A',
    ]) {
      testWidgets('$route opens the home screen with no dialog', (tester) async {
        final h = await _pump(tester, JoinLinkInbox(initialRoute: route));

        expect(find.text('home'), findsOneWidget);
        expect(_anyDialog, findsNothing);
        await _expectUntouched(h);
      });
    }

    testWidgets('a #/join pushed while the PWA runs is answered before the Navigator',
        (tester) async {
      // main() registers the inbox before runApp, so ahead of WidgetsApp's observer.
      final inbox = JoinLinkInbox();
      tester.binding.addObserver(inbox);
      addTearDown(() => tester.binding.removeObserver(inbox));
      await _pump(tester, inbox);

      // Malformed: consumed, so the Navigator never looks for a `/join` route.
      await _pushRoute(tester, '/join?s=nope');
      expect(tester.takeException(), isNull);
      expect(_anyDialog, findsNothing);
      expect(find.text('home'), findsOneWidget);

      await _pushRoute(tester, _route);
      expect(tester.takeException(), isNull);
      expect(_replaceDialog, findsOneWidget);
    });

    testWidgets('another route pushed is left to the Navigator', (tester) async {
      final inbox = JoinLinkInbox();
      expect(await inbox.didPushRouteInformation(RouteInformation(uri: Uri.parse('/'))), isFalse);
      expect(
        await inbox.didPushRouteInformation(RouteInformation(uri: Uri.parse('/joined'))),
        isFalse,
      );
    });
  });

  group('PWA in an Android browser: the hand-over', () {
    testWidgets('"Open in the app" navigates to the intent:// link and opens no dialog',
        (tester) async {
      final h = await _pump(tester, JoinLinkInbox(initialRoute: _route), offerAppHandOver: true);

      expect(find.byKey(const Key('join_link_hand_over')), findsOneWidget);
      expect(_replaceDialog, findsNothing);

      await tester.tap(find.byKey(const Key('join_link_open_in_app')));
      await tester.pumpAndSettle();

      expect(h.opened, [encodeAndroidIntentLink(_config, fallbackUrl: kPlayStoreUrl)]);
      expect(h.opened.single, startsWith('intent://join?s='));
      expect(_anyDialog, findsNothing);
      await _expectUntouched(h);
    });

    testWidgets('"Continue in the browser" shows the replace dialog here', (tester) async {
      final h = await _pump(tester, JoinLinkInbox(initialRoute: _route), offerAppHandOver: true);

      await tester.tap(find.byKey(const Key('join_link_continue_here')));
      await tester.pumpAndSettle();

      expect(h.opened, isEmpty);
      expect(_replaceDialog, findsOneWidget);
    });

    testWidgets('dismissing the question does nothing', (tester) async {
      final h = await _pump(tester, JoinLinkInbox(initialRoute: _route), offerAppHandOver: true);

      await tester.tapAt(const Offset(5, 5)); // the barrier
      await tester.pumpAndSettle();

      expect(h.opened, isEmpty);
      expect(_anyDialog, findsNothing);
      await _expectUntouched(h);
    });
  });

  test('GroupProvider.loaded completes once the stored membership is read', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final group = GroupProvider(
      db: db,
      credentials: MemorySyncCredentials(),
      enableStream: false,
      pollInterval: const Duration(hours: 1),
    );
    addTearDown(() async {
      group.dispose();
      await db.close();
    });
    var loaded = false;
    group.loaded.then((_) => loaded = true);

    await pumpEventQueue();
    expect(loaded, isFalse);

    await group.updateBackend(null); // what the provider tree does on creation
    await pumpEventQueue();
    expect(loaded, isTrue);
  });
}
