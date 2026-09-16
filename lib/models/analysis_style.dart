import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The voice an AI analysis is written in.
///
/// [id] is what travels to the backend and what is stored in preferences, so it
/// is an ASCII string that never changes; only [label] is translated. The set
/// mirrors `PERSONAS` in `backend/app/services/analysis/personas.py` — adding a
/// voice means adding it in both places, plus a string in the ten ARB files.
enum AnalysisStyle {
  professor('professor', Icons.school_outlined),
  commentator('commentator', Icons.sports_soccer_outlined),
  documentary('documentary', Icons.pets_outlined),
  noir('noir', Icons.search_outlined),
  bard('bard', Icons.auto_stories_outlined),
  coach('coach', Icons.sports_outlined),
  consultant('consultant', Icons.insights_outlined),
  astrologer('astrologer', Icons.auto_awesome_outlined),
  realityTv('reality_tv', Icons.tv_outlined);

  const AnalysisStyle(this.id, this.icon);

  final String id;
  final IconData icon;

  /// The style the app has always used, and what an unreadable stored value
  /// decodes to — same rule as [ThemeMode] in `theme_provider.dart`.
  static const fallback = AnalysisStyle.professor;

  static AnalysisStyle fromId(String? id) {
    for (final style in AnalysisStyle.values) {
      if (style.id == id) return style;
    }
    return fallback;
  }

  String label(AppLocalizations l10n) => switch (this) {
    AnalysisStyle.professor => l10n.analysisStyleProfessor,
    AnalysisStyle.commentator => l10n.analysisStyleCommentator,
    AnalysisStyle.documentary => l10n.analysisStyleDocumentary,
    AnalysisStyle.noir => l10n.analysisStyleNoir,
    AnalysisStyle.bard => l10n.analysisStyleBard,
    AnalysisStyle.coach => l10n.analysisStyleCoach,
    AnalysisStyle.consultant => l10n.analysisStyleConsultant,
    AnalysisStyle.astrologer => l10n.analysisStyleAstrologer,
    AnalysisStyle.realityTv => l10n.analysisStyleRealityTv,
  };
}
