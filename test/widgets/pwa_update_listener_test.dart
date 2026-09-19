// The PWA's "new version, reload" prompt. The service worker installs a deploy's build
// beside the running one; the app offers a reload and applies it only when asked, so a
// screen never runs on files from two builds. The JS side is web/flutter_bootstrap.js.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/widgets/pwa_update_listener.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Widget app({
    required void Function(VoidCallback) listen,
    required VoidCallback apply,
  }) {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      locale: const Locale('en', ''),
      builder: (context, child) => PwaUpdateListener(
        messengerKey: messengerKey,
        listen: listen,
        apply: apply,
        child: child!,
      ),
      home: const Scaffold(body: Text('home')),
    );
  }

  testWidgets('nothing is shown while no update is waiting', (tester) async {
    await tester.pumpWidget(app(listen: (_) {}, apply: () {}));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a waiting update is offered, and applied only on Reload',
      (tester) async {
    VoidCallback? onReady;
    var applied = 0;
    await tester.pumpWidget(
      app(listen: (cb) => onReady = cb, apply: () => applied++),
    );
    await tester.pump(); // the listener registers after the first frame
    expect(onReady, isNotNull);

    onReady!();
    await tester.pumpAndSettle();

    expect(find.text(l10n.pwaUpdateReady), findsOneWidget);
    expect(applied, 0);

    // It persists: an update is not something to miss because the snackbar timed out.
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text(l10n.pwaUpdateReady), findsOneWidget);

    await tester.tap(find.text(l10n.pwaUpdateReload));
    await tester.pumpAndSettle();
    expect(applied, 1);
  });

  testWidgets('an update reported twice is offered once', (tester) async {
    VoidCallback? onReady;
    await tester.pumpWidget(app(listen: (cb) => onReady = cb, apply: () {}));
    await tester.pump();

    onReady!();
    onReady!();
    await tester.pumpAndSettle();

    expect(find.text(l10n.pwaUpdateReady), findsOneWidget);
  });
}
