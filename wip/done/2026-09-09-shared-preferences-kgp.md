# A bundled plugin still applies the Kotlin Gradle Plugin

**Status:** dropped (2026-09-18) — chore/refine-2026-09-18. An upstream watch item with nothing to do on our side (the plugin is now `in_app_review`); the build warning brings it back if it ever becomes an error.

- **Noted:** 2026-09-09 — during the Flutter 3.47 upgrade
- **Theme:** dependencies
- **Area:** android
- **Blocks release:** no — a warning today, a build failure on some future Flutter

Every Android build warns that a plugin applies KGP and that future Flutter versions will
fail to build with it. Nothing to do on our side but watch the changelogs for releases
migrating to AGP's built-in Kotlin.

- 2026-09-09: `shared_preferences_android`.
- 2026-09-16 (measured on `assembleDebug` and `assembleProfile`, main at b82daaf): the
  warning now names **`in_app_review` only** — `shared_preferences` no longer applies KGP,
  and `in_app_review`, added by `feat/rating-prompt` (#59), took its place.
