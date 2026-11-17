// The compact landscape layout is chosen on a short height, not on a width
// (wip/done/2026-11-17-landscape-layout.md).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/utils/compact_landscape.dart';

void main() {
  test('the threshold is 500 dp and the toolbar 48 dp', () {
    expect(kCompactLandscapeMaxHeight, 500);
    expect(kCompactLandscapeToolbarHeight, 48);
  });

  test('a phone on its side is compact landscape', () {
    expect(isCompactLandscape(const Size(800, 360)), isTrue);
    expect(isCompactLandscape(const Size(873, 393)), isTrue);
    expect(isCompactLandscape(const Size(997, 448)), isTrue);
    expect(isCompactLandscape(const Size(1000, 499)), isTrue);
  });

  test('a portrait phone, a tablet, a desktop window are not', () {
    expect(isCompactLandscape(const Size(360, 800)), isFalse);
    expect(isCompactLandscape(const Size(412, 915)), isFalse);
    // The default widget-test surface, which every portrait test runs on.
    expect(isCompactLandscape(const Size(800, 600)), isFalse);
    expect(isCompactLandscape(const Size(1000, 500)), isFalse);
    expect(isCompactLandscape(const Size(1280, 800)), isFalse);
    // Short but not wider than tall: a split-screen sliver.
    expect(isCompactLandscape(const Size(300, 400)), isFalse);
    expect(isCompactLandscape(const Size(400, 400)), isFalse);
  });
}
