import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The rulesets shipped with the app, one Markdown asset per locale.
///
/// Long-form localised content lives in `assets/rules/` rather than in the ARB
/// files. Four thousand words across ten languages would be unreviewable as
/// escaped JSON one-liners, and it would double again in the generated
/// `app_localizations_*.dart`, which this project commits. ICU escaping is the
/// other reason: `flutter gen-l10n` treats the apostrophe as an escape
/// character, which French prose is full of. See `.llmwiki/I18n.md`.
///
/// The synchrony the ARB files give for free is kept by
/// `test/game_rules_catalog_test.dart`, which fails when a locale is missing a
/// ruleset.
class GameRulesCatalog {
  GameRulesCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// The locales that have a `rules_<locale>.md` asset — the app's ten, which
  /// `main.dart` lists as `supportedLocales`.
  static const locales = <String>[
    'ar', 'de', 'en', 'es', 'fr', 'hi', 'ja', 'pt', 'ru', 'zh',
  ];

  /// Every slug a shipped asset must define. `Autre` is a catch-all with no
  /// rules of its own and is deliberately absent.
  static const slugs = <String>[
    'zapzap', 'uno', 'scrabble', 'skyjo', 'president', 'belote', 'tarot',
    'bridge', 'rami',
  ];

  /// The locale the app falls back to, matching `main.dart`'s
  /// `localeResolutionCallback`. French is the ARB template, English is the
  /// runtime fallback — see `.llmwiki/I18n.md`.
  static const fallbackLocale = 'en';

  static final _sectionMarker = RegExp(r'^<!--@([a-z0-9_]+)-->$');

  final Map<String, Map<String, String>> _cache = {};

  /// The Markdown ruleset for [slug] in [languageCode], or null when the game
  /// type carries no slug or the asset has no such section.
  Future<String?> rules(String? slug, String languageCode) async {
    if (slug == null || slug.isEmpty) return null;
    final byLocale = await _load(
      locales.contains(languageCode) ? languageCode : fallbackLocale,
    );
    return byLocale[slug];
  }

  Future<Map<String, String>> _load(String languageCode) async {
    final cached = _cache[languageCode];
    if (cached != null) return cached;
    String source;
    try {
      source = await _bundle.loadString('assets/rules/rules_$languageCode.md');
    } on FlutterError {
      // A missing asset must not take the page down: fall back, and if even
      // that is gone, show the empty state rather than throwing.
      if (languageCode == fallbackLocale) return _cache[languageCode] = const {};
      return _cache[languageCode] = await _load(fallbackLocale);
    }
    return _cache[languageCode] = parse(source);
  }

  /// Splits a shipped asset into `slug -> Markdown`. Public so the catalogue
  /// test can check every asset without touching an `AssetBundle`.
  @visibleForTesting
  static Map<String, String> parse(String source) {
    final sections = <String, String>{};
    String? slug;
    final buffer = StringBuffer();
    void flush() {
      final current = slug;
      if (current != null) sections[current] = buffer.toString().trim();
      buffer.clear();
    }

    for (final line in const LineSplitter().convert(source)) {
      final match = _sectionMarker.firstMatch(line.trimRight());
      if (match != null) {
        flush();
        slug = match.group(1);
        continue;
      }
      if (slug != null) buffer.writeln(line);
    }
    flush();
    sections.removeWhere((_, value) => value.isEmpty);
    return sections;
  }
}
