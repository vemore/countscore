import 'package:flutter/rendering.dart';

/// The line tops (rounded) the characters in [start, end) of [paragraph] sit
/// on.
Set<int> _lineTops(RenderParagraph paragraph, int start, int end) => {
      for (final box in paragraph.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end)))
        box.top.round(),
    };

/// How many lines [paragraph] is laid out on.
int lineCount(RenderParagraph paragraph) =>
    _lineTops(paragraph, 0, paragraph.text.toPlainText().length).length;

/// The words of [paragraph] — runs of non-space characters, punctuation
/// included — laid out across more than one line: "Enregist / rer",
/// "Siguiente / : Sofia". Empty when every line breaks between words.
List<String> wordsBrokenAcrossLines(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  return [
    for (final word in RegExp(r'\S+').allMatches(text))
      if (_lineTops(paragraph, word.start, word.end).length > 1) word[0]!,
  ];
}
