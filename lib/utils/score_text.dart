/// A score as text that survives a right-to-left paragraph.
///
/// Under the bidirectional algorithm the "-" of a negative number sitting in
/// an Arabic or Urdu line lands after the digits, so -25 reads "25-". A
/// left-to-right isolate keeps the sign in front without touching the
/// surrounding text. A non-negative number has no sign to lose and stays as
/// it is.
final String _lri = String.fromCharCode(0x2066); // LEFT-TO-RIGHT ISOLATE
final String _pdi = String.fromCharCode(0x2069); // POP DIRECTIONAL ISOLATE

String scoreText(int value) => value < 0 ? '$_lri$value$_pdi' : '$value';

/// The keypad's own spelling of a negative: a true minus sign, isolated the
/// same way.
String keypadScoreText({required bool negative, required String digits}) {
  final shown = digits.isEmpty ? '0' : digits;
  return negative ? '$_lri${String.fromCharCode(0x2212)}$shown$_pdi' : shown;
}
