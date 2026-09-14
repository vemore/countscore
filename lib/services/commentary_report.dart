/// Reporting an AI-generated commentary, as Play's AI-Generated Content policy
/// requires: a `mailto:` the user sends from their own mail app. The app itself
/// sends nothing, so this is not an outbound data flow.
library;

/// The public contact of the store listing (`PUBLISHING.md`).
const String commentaryReportEmail = 'scribio.ai@gmail.com';

/// Commentary characters kept in the prefilled body. Percent-encoding can
/// multiply a character's length by up to nine, and some mail handlers refuse
/// very long URIs; the reporter can still paste more by hand.
const int commentaryReportMaxChars = 1500;

/// Cuts [text] to at most [maxChars] Unicode code points, never splitting a
/// surrogate pair, and marks the cut with an ellipsis.
String truncateForReport(
  String text, {
  int maxChars = commentaryReportMaxChars,
}) {
  final runes = text.runes;
  if (runes.length <= maxChars) return text;
  return '${String.fromCharCodes(runes.take(maxChars))}…';
}

/// Identifies the commentary for whoever reads the report: the local analysis
/// id when there is one, the model that wrote it and when. The server keeps no
/// copy of an analysis, so there is no server-side id to quote.
String commentaryReportReference({
  int? analysisId,
  String? modelId,
  DateTime? generatedAt,
}) {
  return [
    if (analysisId != null) '#$analysisId',
    ?modelId,
    if (generatedAt != null) generatedAt.toIso8601String(),
  ].join(' · ');
}

/// Builds the `mailto:` URI. Encoded by hand with [Uri.encodeComponent]:
/// `Uri(queryParameters:)` encodes spaces as `+`, which mail apps show verbatim.
Uri buildCommentaryReportUri({
  required String subject,
  required String body,
  String email = commentaryReportEmail,
}) {
  return Uri.parse(
    'mailto:$email'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );
}
