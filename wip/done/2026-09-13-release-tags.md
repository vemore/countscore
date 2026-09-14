# Release tags are inconsistent, and 1.1.0 has none

**Status:** done (2026-09-14) — closed by chore/release-housekeeping. Annotated tags
`1.0.0+1` → `4e52a54` and `1.0.1+2` → `1614707` pushed (each checked against `version:` in
that commit's `pubspec.yaml`); the scheme is recorded in `.llmwiki/Release.md` → Tags, and the
`release-android` skill §10 now creates annotated tags. `1.1.0+4` is deliberately not tagged
here: `release-android` §10 tags it once the Play rollout is live. Correction to the evidence
below: `1.0.1` is annotated, not lightweight, and exists only locally — it was never pushed.

- **Noted:** 2026-09-13
- **Theme:** release-housekeeping
- **Area:** tooling
- **Blocks release:** no

`git tag`: `1.0.1` (on `1614707`) and `1.0.1+3` (on `ee3ff1b`), two schemes, both
lightweight; `1.0.0+1` and `1.1.0+4` untagged. The `release-android` skill (§10) tags
`<x.y.z+n>` after a rollout.

**Fix:** tag `1.0.0+1` on `4e52a54` and `1.0.1+2` beside `1.0.1`; tag `1.1.0+4` once live.
