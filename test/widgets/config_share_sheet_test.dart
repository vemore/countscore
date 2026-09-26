// Settings → Share by QR code
// (wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md): the
// QR shown carries a link that parses back to this device's server and, when it
// is in a group, the group's invite code.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/providers/settings_provider.dart';
import 'package:countscore/providers/theme_provider.dart';
import 'package:countscore/screens/settings_screen.dart';
import 'package:countscore/utils/config_link.dart';
import 'package:countscore/widgets/config_share_sheet.dart';

import '../support/fake_group_provider.dart';

const _server = 'https://scores.example.com';
const _base = 'https://scores.example.com/countscore';
const _invite = '22222222-2222-4222-8222-222222222222';

Widget _app(BackendProvider backend, GroupProvider group, Widget home,
        {SettingsProvider? settings}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: backend),
        ChangeNotifierProvider<GroupProvider>.value(value: group),
        if (settings != null) ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => ThemeProvider(ThemeMode.system)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: home,
      ),
    );

/// Opens Settings on [group], then its *Share by QR code* button [opener].
Future<void> _openFromSettings(
  WidgetTester tester,
  FakeGroupProvider group, {
  String opener = 'config_share_open',
}) async {
  tester.view.physicalSize = const Size(412, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(group.dispose);
  final settings = SettingsProvider();
  await tester.runAsync(() => settings.ready);

  await tester.pumpWidget(
    _app(BackendProvider(_server), group, const SettingsScreen(), settings: settings),
  );
  await tester.pumpAndSettle();
  final button = find.byKey(Key(opener));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// The link the QR on screen carries.
String _qrData(WidgetTester tester) =>
    tester.widget<ConfigQrCode>(find.byKey(const Key('config_share_qr'))).data;

void main() {
  group('Settings shows a QR that round-trips', () {
    testWidgets('with a group: the server and the invite code', (tester) async {
      SharedPreferences.setMockInitialValues({ConfigShareSheet.prefsKey: _base});
      await _openFromSettings(tester, FakeGroupProvider(joined: true, token: _invite));

      final link = _qrData(tester);
      expect(link, startsWith('$_base/#/join?'));
      expect(parseConfigLink(link), const ConfigLink(server: _server, invite: _invite));
      expect(find.textContaining('join the group Famille'), findsOneWidget);
    });

    testWidgets('with no group: the server alone', (tester) async {
      SharedPreferences.setMockInitialValues({ConfigShareSheet.prefsKey: _base});
      await _openFromSettings(tester, FakeGroupProvider());

      expect(parseConfigLink(_qrData(tester)), const ConfigLink(server: _server));
      expect(find.text('Scan this code with another phone to set it up with the same server.'),
          findsOneWidget);
    });

    testWidgets('from the Group section too', (tester) async {
      SharedPreferences.setMockInitialValues({ConfigShareSheet.prefsKey: _base});
      await _openFromSettings(tester, FakeGroupProvider(joined: true, token: _invite),
          opener: 'group_share_qr');

      expect(parseConfigLink(_qrData(tester)),
          const ConfigLink(server: _server, invite: _invite));
    });
  });

  testWidgets('with no web app address, asks for one, then shows the QR and keeps it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _openFromSettings(tester, FakeGroupProvider());

    expect(find.byKey(const Key('config_share_qr')), findsNothing);
    expect(find.byKey(const Key('config_share_needs_base')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('config_share_base')), 'http://example.com/app');
    await tester.tap(find.byKey(const Key('config_share_base_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('config_share_qr')), findsNothing,
        reason: 'cleartext on a public host is refused, as for a server');
    expect(find.textContaining('http:// is only accepted on a local network'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('config_share_base')), '$_base/');
    await tester.tap(find.byKey(const Key('config_share_base_save')));
    await tester.pumpAndSettle();

    expect(parseConfigLink(_qrData(tester)), const ConfigLink(server: _server));
    expect(_qrData(tester), startsWith('$_base/#/join?'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ConfigShareSheet.prefsKey), _base);
  });

  testWidgets('in the PWA, starts from the app\'s own address', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final group = FakeGroupProvider();
    addTearDown(group.dispose);
    await tester.pumpWidget(_app(
      BackendProvider(_server),
      group,
      const Scaffold(body: ConfigShareSheet(runningPwaBase: 'https://owner.github.io/countscore')),
    ));
    await tester.pumpAndSettle();

    expect(_qrData(tester), startsWith('https://owner.github.io/countscore/#/join?'));
  });

  testWidgets('the share button is off while no server is set', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final group = FakeGroupProvider();
    addTearDown(group.dispose);
    final settings = SettingsProvider();
    await tester.runAsync(() => settings.ready);
    await tester.pumpWidget(
        _app(BackendProvider(null), group, const SettingsScreen(), settings: settings));
    await tester.pumpAndSettle();

    final button = find.ancestor(
      of: find.text('Share by QR code'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
  });

  testWidgets('"Copy link" says it is done on the sheet itself, not under it', (tester) async {
    SharedPreferences.setMockInitialValues({ConfigShareSheet.prefsKey: _base});
    await _openFromSettings(tester, FakeGroupProvider(joined: true, token: _invite));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.tap(find.byKey(const Key('config_share_copy')));
    await tester.pumpAndSettle();

    expect(copied, _qrData(tester));
    expect(
      find.descendant(
        of: find.byKey(const Key('config_share_copy')),
        matching: find.text('Link copied'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing, reason: 'it would sit under the sheet');
  });

  testWidgets('a link too long for any QR code shows a message instead of throwing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ConfigQrCode(data: '', tooLongText: 'too long')),
    ));
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ConfigQrCode(data: 'x' * 4000, tooLongText: 'too long')),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('config_share_too_long')), findsOneWidget);
    expect(find.text('too long'), findsOneWidget);
  });

  testWidgets('Settings shows a server replaced from elsewhere', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final group = FakeGroupProvider();
    addTearDown(group.dispose);
    final backend = BackendProvider(_server);
    final settings = SettingsProvider();
    await tester.runAsync(() => settings.ready);
    await tester.pumpWidget(_app(backend, group, const SettingsScreen(), settings: settings));
    await tester.pumpAndSettle();

    await tester.runAsync(() => backend.setBaseUrl('https://other.example.com'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, 'https://other.example.com');
  });
}
