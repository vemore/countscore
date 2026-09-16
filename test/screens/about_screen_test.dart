// The About screen reads the version from the platform (pubspec at build
// time) instead of a string frozen in the ARB files, and lists the connected
// features next to the local ones.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/screens/about_screen.dart';

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
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
      'without overflowing a narrow screen in a long language', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsNothing);
    expect(find.text('Group sharing'), findsOneWidget);
    expect(find.text('AI game analysis'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Locale('ru')));
    await tester.pumpAndSettle();

    expect(find.text('Версия 1.1.0'), findsOneWidget);
    expect(find.text('Совместный доступ в группах'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
