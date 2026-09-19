// Every `IconButton` in `lib/` names itself: its `tooltip` is what TalkBack and
// browser screen readers announce, and what a test finds it by. A button that
// deliberately has none says why in a comment starting "No tooltip" in the few
// lines above it.
//
// A source scan rather than a widget test, so that a button added on a screen
// no test pumps is caught all the same.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Returns the text from the `(` at [open] to its matching `)`.
String _call(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final c = source[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return source.substring(open, i + 1);
    }
  }
  return source.substring(open);
}

void main() {
  test('no IconButton in lib/ lacks a tooltip without a written reason', () {
    final constructor = RegExp(r'\bIconButton(\.\w+)?\(');
    final missing = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in constructor.allMatches(source)) {
        final args = _call(source, match.end - 1);
        if (RegExp(r'\btooltip\s*:').hasMatch(args)) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        final before = source.substring(0, match.start).split('\n');
        final context = before.skip(before.length > 6 ? before.length - 6 : 0);
        if (context.any((l) => l.trim().startsWith('// No tooltip'))) continue;

        missing.add('${file.path}:$line');
      }
    }

    expect(missing, isEmpty,
        reason: 'IconButtons with no tooltip and no "// No tooltip" reason');
  });
}
