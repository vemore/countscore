# The Play Store release falls further behind production with every merge

**Status:** done (2026-09-14) — closed by chore/merge-safety. `ship-parallel` §6 reports an
Android line (last tag, commits since, open `wip/todo/` entries); `.llmwiki/Release.md`
records the cadence: once `wip/todo/` is empty the report proposes `release-android`, still
run only on the user's request.

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** release-housekeeping
- **Area:** android
- **Blocks release:** no

The merge-and-deploy loop ships the backend and the PWA after each pull request, but the
Android app only on request. The last tag is `1.0.1+3`; `pubspec.yaml` has been `1.1.0+4`
since 2026-09-09 and is unreleased, while `wip/todo/` holds 10 open entries — among them
`2026-09-13-store-listing-denies-group-sharing.md`, a listing that contradicts what the
production backend already does. "Merged and deployed" is reported as delivered, yet Android
users have none of the work since June.

**Fix:** make the gap visible and bounded rather than automatic. `ship-parallel` §6 reports,
next to what was deployed, the commits on `main` since the last release tag and the count of
`wip/todo/` entries; and the user picks a cadence (e.g. a release once `wip/todo/` is empty, or
every N merged features) recorded in `.llmwiki/Release.md`.
