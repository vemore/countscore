import 'package:flutter_test/flutter_test.dart';
import 'package:countscore/services/commentary_report.dart';

void main() {
  group('buildCommentaryReportUri', () {
    test('addresses the listing contact with an encoded subject and body', () {
      final uri = buildCommentaryReportUri(
        subject: 'Report & review',
        body: 'Line one\nLigne deux é',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, commentaryReportEmail);
      final s = uri.toString();
      expect(s, startsWith('mailto:scribio.ai@gmail.com?subject='));
      // Spaces must be %20, never '+': mail apps show '+' verbatim.
      expect(s, isNot(contains('+')));
      expect(s, contains('subject=Report%20%26%20review'));
      expect(s, contains('&body=Line%20one%0ALigne%20deux%20%C3%A9'));
    });

    test('an ampersand in the body cannot start a new parameter', () {
      final uri = buildCommentaryReportUri(subject: 's', body: 'a&cc=x@y.z');
      expect(uri.toString(), isNot(contains('&cc=')));
    });
  });

  group('truncateForReport', () {
    test('leaves short text alone', () {
      expect(truncateForReport('short', maxChars: 10), 'short');
    });

    test('cuts long text and marks the cut', () {
      expect(truncateForReport('abcdefghij', maxChars: 4), 'abcd…');
    });

    test('counts code points, so an emoji is never split', () {
      expect(truncateForReport('🃏🃏🃏', maxChars: 2), '🃏🃏…');
    });
  });

  test('reference joins what is known and skips what is not', () {
    expect(
      commentaryReportReference(
        analysisId: 7,
        modelId: 'gemini-2.5-flash',
        generatedAt: DateTime(2026, 9, 11, 14, 30),
      ),
      '#7 · gemini-2.5-flash · 2026-09-11T14:30:00.000',
    );
    expect(commentaryReportReference(modelId: 'm'), 'm');
  });
}
