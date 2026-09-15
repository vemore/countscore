# The About screen shows a hardcoded "Version 1.0.0" and omits the connected features

**Status:** done (2026-09-15) — closed by feat/about-version. The version is now read at runtime through `package_info_plus` (`"Version {version}"` ICU placeholder in all 10 ARB files), and the feature list gained group sharing and the ZapZap analysis.

- **Noted:** 2026-09-15 — while preparing the 1.1.0 release
- **Theme:** about-screen
- **Area:** app
- **Blocks release:** yes — the About screen of 1.1.0 says 1.0.0

`lib/screens/about_screen.dart` rendered `l10n.version`, whose value was the literal
`"Version 1.0.0"` (translated) in every `lib/l10n/app_*.arb`, while `pubspec.yaml` is at
`1.1.0+4`. Its feature card listed only local features (game types, players, statistics,
customization, theme) — nothing about group sharing or the LLM analysis that 1.1.0 adds.

**Fix:** read the version from `PackageInfo.fromPlatform()` (a static future, `FutureBuilder`),
make `version` a `{version}` placeholder, add `featureGroupSharing` and
`featureZapZapAnalysis` rows, and make the screen scroll so the longer list fits a small
phone. Covered by `test/screens/about_screen_test.dart`.
