# `proguard-rules.pro` header contradicts itself

- **Noted:** 2026-09-13
- **Theme:** release-housekeeping
- **Area:** android
- **Blocks release:** no

`android/app/proguard-rules.pro:3-22` says R8 is ENABLED, then lists "Benefits of keeping it
disabled" and "To enable ProGuard/R8 in the future" — the drift `.llmwiki/Release.md` fixed
for the docs on 2026-09-09.

**Fix:** cut the header to what is true: enabled, for size, rules below.
