import 'package:flutter/material.dart';

/// A label for a narrow, fixed-size box that never breaks inside a word.
///
/// Flutter wraps a word wider than its box letter by letter ("Enregist / rer",
/// "Siguiente / : Sofia"). This label shrinks its font instead, from
/// [style]'s size down to [minFontSize], until every word fits the width and
/// the whole label fits the height; lines still break between words, and at
/// every `\n` of the text. If even [minFontSize] is too big, each line is kept
/// whole and the label is scaled down to fit.
class FitWordsText extends StatelessWidget {
  const FitWordsText(
    this.text, {
    super.key,
    this.style,
    this.minFontSize = 10,
    this.textAlign = TextAlign.center,
    this.textDirection,
  });

  final String text;
  final TextStyle? style;
  final double minFontSize;
  final TextAlign textAlign;

  /// The direction to lay the text out in, when it differs from the ambient
  /// one (a label inside a left-to-right keypad in an Arabic UI).
  final TextDirection? textDirection;

  static final RegExp _space = RegExp(r'\s+');

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final direction = textDirection ?? Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final words = text.split(_space).where((w) => w.isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool fits(TextStyle style) {
          for (final word in words) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: style),
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();
            if (width > constraints.maxWidth) return false;
          }
          if (!constraints.hasBoundedHeight) return true;
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: constraints.maxWidth);
          final height = painter.height;
          painter.dispose();
          return height <= constraints.maxHeight;
        }

        var size = base.fontSize ?? 14;
        var chosen = base.copyWith(fontSize: size);
        while (!fits(chosen) && size > minFontSize) {
          size = (size - 1).clamp(minFontSize, size);
          chosen = base.copyWith(fontSize: size);
        }
        if (fits(chosen)) {
          return Text(
            text,
            style: chosen,
            textAlign: textAlign,
            textDirection: direction,
          );
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: chosen,
            textAlign: textAlign,
            textDirection: direction,
            softWrap: false,
          ),
        );
      },
    );
  }
}
