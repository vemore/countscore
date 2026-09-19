{{flutter_js}}
{{flutter_build_config}}

// The stock template, plus one setting: the engine fetches the fonts it falls back to
// (Roboto on every start, then a Noto font for a glyph Nunito lacks — Chinese, Arabic,
// Devanagari, emoji...) from fontFallbackBaseUrl, which defaults to fonts.gstatic.com.
// scripts/build_web.sh mirrors those files into build/web/fallback-fonts/, so they are
// served by whoever serves the PWA and no browser asks Google for them. The path is
// relative, so it follows --base-href. .llmwiki/Web.md, "Self-hosted web resources".
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: "fallback-fonts/",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});
