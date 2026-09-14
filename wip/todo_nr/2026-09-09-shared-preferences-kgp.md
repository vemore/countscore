# `shared_preferences_android` still applies the Kotlin Gradle Plugin

- **Noted:** 2026-09-09 — during the Flutter 3.47 upgrade
- **Theme:** dependencies
- **Area:** android
- **Blocks release:** no — a warning today, a build failure on some future Flutter

Every Android build warns that `shared_preferences_android` applies KGP and that future
Flutter versions will fail to build with it. Nothing to do on our side: watch the
`shared_preferences` changelog for a release migrating to AGP's built-in Kotlin.
