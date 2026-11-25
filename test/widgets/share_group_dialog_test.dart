// Sharing a local game from its board (wip/done/2026-11-25-multi-group-ui.md):
// one group is today's confirmation naming it; several ask which, with none
// preselected, since a share cannot be undone.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/widgets/share_group_dialog.dart';

import '../support/fake_group_provider.dart';

/// Opens the dialog for [group]'s memberships; what it returned lands in
/// [results].
Future<void> _open(WidgetTester tester, FakeGroupProvider group, List<String?> results) async {
  await tester.pumpWidget(MaterialApp(
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
          onPressed: () async => results.add(await showShareGroupDialog(context, group.memberships)),
          child: const Text('share'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('share'));
  await tester.pumpAndSettle();
}

TextButton _confirm(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(const Key('share_group_confirm')));

void main() {
  late FakeGroupProvider group;
  late List<String?> results;

  setUp(() {
    group = FakeGroupProvider()..addGroup('group-1', 'Famille', 'invite-1');
    results = [];
  });
  tearDown(() => group.dispose());

  testWidgets('one group: the confirmation names it, and Share returns it', (tester) async {
    await _open(tester, group, results);

    expect(find.textContaining('will be sent to Famille'), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.tap(find.byKey(const Key('share_group_confirm')));
    await tester.pumpAndSettle();
    expect(results, ['group-1']);
  });

  testWidgets('two groups: none preselected, Share returns the one picked', (tester) async {
    group.addGroup('group-2', 'Amis', 'invite-2');
    await _open(tester, group, results);

    expect(find.textContaining('Which group should this game be shared with?'), findsOneWidget);
    expect(_confirm(tester).onPressed, isNull, reason: 'a group is picked, never assumed');
    await tester.tap(find.byKey(const Key('share_group_group-2')));
    await tester.pumpAndSettle();
    expect(_confirm(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('share_group_confirm')));
    await tester.pumpAndSettle();
    expect(results, ['group-2']);
  });

  testWidgets('cancelled: no group', (tester) async {
    group.addGroup('group-2', 'Amis', 'invite-2');
    await _open(tester, group, results);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
