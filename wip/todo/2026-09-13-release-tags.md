# Release tags are inconsistent, and 1.1.0 has none

- **Noted:** 2026-09-13
- **Theme:** release-housekeeping
- **Area:** tooling
- **Blocks release:** no

`git tag`: `1.0.1` (on `1614707`) and `1.0.1+3` (on `ee3ff1b`), two schemes, both
lightweight; `1.0.0+1` and `1.1.0+4` untagged. The `release-android` skill (§10) tags
`<x.y.z+n>` after a rollout.

**Fix:** tag `1.0.0+1` on `4e52a54` and `1.0.1+2` beside `1.0.1`; tag `1.1.0+4` once live.
