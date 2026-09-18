# `proguard-rules.pro` TESTING footer gives a command that cannot work

- **Noted:** 2026-09-14 — while fixing the file's header (chore/release-housekeeping)
- **Theme:** release-housekeeping
- **Area:** android
- **Blocks release:** no

`android/app/proguard-rules.pro`, the `TESTING` section at the end, still reads "After
enabling these rules" (they have been enabled since `1614707`) and tells the reader to
`adb install build/app/outputs/bundle/release/app-release.aab` — `adb` does not install an
App Bundle; it needs an APK (`flutter build apk --release --no-tree-shake-icons`) or
`bundletool build-apks` + `install-apks`. The `CUSTOM RULES` block also suggests
`-keep class **.g.dart`, which is a Dart file, not a JVM class, and means nothing to R8.

**Fix:** replace the footer with a pointer to the `release-android` skill (which owns release
verification) and drop the `.g.dart` comment.

**Acceptance:**
- The TESTING footer of `android/app/proguard-rules.pro` points at `release-android` and has no `adb install *.aab`.
- The `.g.dart` keep suggestion is gone.
- A release build still succeeds (only comments change).
