# `proguard-rules.pro` header contradicts itself

**Status:** done (2026-09-14) — closed by chore/release-housekeeping. The header now says only
what `android/app/build.gradle.kts:54-61` does: R8 on for release, for size, with these rules on
top of `proguard-android-optimize.txt`; the "keep it disabled" and "enable in the future"
sections are gone. The file's TESTING footer is a separate entry,
`wip/todo_nr/2026-09-14-proguard-testing-footer.md`.

- **Noted:** 2026-09-13
- **Theme:** release-housekeeping
- **Area:** android
- **Blocks release:** no

`android/app/proguard-rules.pro:3-22` says R8 is ENABLED, then lists "Benefits of keeping it
disabled" and "To enable ProGuard/R8 in the future" — the drift `.llmwiki/Release.md` fixed
for the docs on 2026-09-09.

**Fix:** cut the header to what is true: enabled, for size, rules below.
