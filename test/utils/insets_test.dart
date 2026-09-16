// `withBottomInset` restores, for a scrollable that passes an explicit
// padding, the bottom compensation `BoxScrollView` only applies when its
// `padding` argument is null. Asserting the resolved padding under a
// `MediaQuery` is what replaces a measurement on hardware: the helper has to
// reproduce what Flutter itself does, and that is checkable here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countscore/utils/insets.dart';

/// Pumps [child] under a `MediaQuery` whose bottom padding is [bottom], and
/// returns what `withBottomInset` resolves to for [base] in that context.
Future<EdgeInsets> _resolve(
  WidgetTester tester, {
  required double bottom,
  required EdgeInsets base,
}) async {
  late EdgeInsets resolved;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: bottom)),
      child: Builder(
        builder: (context) {
          resolved = withBottomInset(context, base);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  testWidgets('adds the system bottom inset to the bottom edge only', (
    tester,
  ) async {
    // 48 dp is the three-button navigation bar, the mode that hides a whole row.
    final resolved = await _resolve(
      tester,
      bottom: 48,
      base: const EdgeInsets.all(8),
    );

    expect(resolved, const EdgeInsets.fromLTRB(8, 8, 8, 56));
  });

  testWidgets('leaves the padding untouched when there is no inset', (
    tester,
  ) async {
    final resolved = await _resolve(
      tester,
      bottom: 0,
      base: const EdgeInsets.all(16),
    );

    expect(resolved, const EdgeInsets.all(16));
  });

  testWidgets('compensates a zero padding too — the drawer case', (
    tester,
  ) async {
    final resolved = await _resolve(
      tester,
      bottom: 24,
      base: EdgeInsets.zero,
    );

    expect(resolved, const EdgeInsets.only(bottom: 24));
  });

  testWidgets('a ListView with an explicit padding loses the compensation '
      'a null padding gets, and the helper puts it back', (tester) async {
    // A list taller than the viewport: what the inset buys is 48 dp more
    // scroll extent, i.e. the last row scrolling clear of the navigation bar.
    Widget app(EdgeInsets? Function(BuildContext)? pad) => MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => ListView(
            padding: pad?.call(context),
            children: List.generate(
              100,
              (i) => const SizedBox(height: 10),
            ),
          ),
        ),
      ),
    );

    double extent() =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position
            .maxScrollExtent;

    // Null: Flutter inserts the inset itself.
    await tester.pumpWidget(app(null));
    final compensated = extent();

    // Explicit: the compensation is gone — this is the bug.
    await tester.pumpWidget(app((_) => EdgeInsets.zero));
    expect(extent(), compensated - 48);

    // Through the helper: back to what Flutter would have done.
    await tester.pumpWidget(app((c) => withBottomInset(c, EdgeInsets.zero)));
    expect(extent(), compensated);
  });
}
