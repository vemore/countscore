// The About screen reads the version from the platform (pubspec at build
// time) instead of a string frozen in the ARB files, and lists the connected
// features next to the local ones. It credits nobody for the icon: the one it
// ships is the owner's own, and the Credits card named the artist of the icon
// it dropped in #195.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/screens/about_screen.dart';

Widget _app(Locale locale, {double bottomInset = 0}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(padding: EdgeInsets.only(bottom: bottomInset)),
    child: child!,
  ),
  home: const AboutScreen(),
);

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'CountScore',
      packageName: 'com.vemore.countscore',
      version: '1.1.0',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  // One test, not two: AboutScreen caches its PackageInfo future in a static,
  // and a future completed inside one test's fake-async zone never delivers
  // to a FutureBuilder in the next test.
  testWidgets('shows the platform version and the connected features, '
      'credits no icon artist, and does not overflow a narrow screen in a '
      'long language', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsNothing);
    expect(find.text('Group sharing'), findsOneWidget);
    expect(find.text('AI game analysis'), findsOneWidget);
    // No Credits section, and above all not the old icon's artist.
    expect(find.text('Credits'), findsNothing);
    expect(find.textContaining('efendi'), findsNothing);
    expect(find.byIcon(Icons.copyright), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Locale('ru')));
    await tester.pumpAndSettle();

    expect(find.text('Версия 1.1.0'), findsOneWidget);
    expect(find.text('Совместный доступ в группах'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The About screen scrolls in a SingleChildScrollView, which never gets
    // the BoxScrollView bottom compensation: its padding is the child
    // Padding, and that is where the system inset has to land, or the last
    // row is drawn behind the navigation bar.
    tester.view.reset();
    await tester.pumpWidget(_app(const Locale('en'), bottomInset: 48));
    await tester.pumpAndSettle();

    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, const EdgeInsets.fromLTRB(24, 24, 24, 72));
  });
}
