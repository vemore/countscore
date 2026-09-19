# `release-android` §5 asks for a device test that cannot be run

**Status:** done (2026-09-19) — closed by docs/release-device-upgrade-test. Run end to end on the Pixel 9 Pro XL: the phone held the Play build 1.2.0 (not debuggable), so the old database came from Settings → Export (schema v14, integrity ok, 65 games, 24 players, 563 rounds, 2341 scores) rather than `pull`; `adb uninstall`, a clean install of the release APK built at 0a63e06 (schema v15), then `device_db_roundtrip.sh push` and Settings → Import → Downloads → countscore-upgrade-test.db: "Import réussi", and after the reopen the same games show (p165 in progress, p172 won by Vincent, yaniv1 by Lilian), with no crash. `pull` itself was not exercised (needs a debuggable build).

- **Noted:** 2026-09-17 — while releasing 1.2.0+5
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

`release-android` §5 says of the release APK:

> Install it **over the store version**, not over a debug build: the database must survive the
> upgrade.

That cannot be done. An APK built on this machine is signed with the **upload** key; the build
Play serves is re-signed with the **app signing key** Google holds (§Signing). Android refuses
to replace a package with one carrying a different signature, so `adb install -r` on a genuine
store install fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. This is not a misconfiguration —
it is what Play App Signing means, and Play App Signing is on and cannot be turned off.

**What actually happened.** The Pixel held a *debuggable* 1.1.0 build with a real database at
`user_version` 12. The install failed on the signature anyway, because the debug build is
debug-signed. The instruction would have failed just the same against a Play install, for a
different key. The upgrade path was covered instead by `test/migration_v12_to_v13_test.dart`,
`test/migration_v13_to_v14_test.dart` and `test/migration_v2_to_v14_test.dart`, all green, and
the release build was exercised on a fresh install.

**Fix:** replace §5's instruction with one of the two things that do work, and say which.

- **Play internal app sharing** serves an APK signed with the *app signing* key, downloadable
  from a Console link. It upgrades a store install in place, and it is the only faithful test
  of the real upgrade. It costs a Console round trip and is not scriptable through
  androidpublisher.
- **A fresh install plus the app's own import.** Pull the old database out (`run-as`, debug
  builds only), install the release APK clean, push the file to `/sdcard/Download/` and restore
  it through Settings → Import, which `DatabaseService.importDatabase` accepts as a raw `.db`.
  This exercises import *and* the migration inside an R8-shrunk build, and needs no Console.

Worth deciding at the same time: whether the migration-on-device check is owed at all, given
that the version-to-version migration tests already cover the schema path, and what §5 uniquely
buys is the R8-shrunk build running on hardware.

Related: [[2026-09-16-device-test-skill-stale-device-and-locale]].

**Decided (2026-09-18, refinement):** a fresh install plus the app's own import.
Pull the database with `run-as` from a debuggable build, install the release APK clean, push
the file and restore it through Settings → Import. Scriptable, and needs no Console step.

**Acceptance:**
- `release-android` §5 no longer says to install over the store version, and gives the pull → clean install → import steps; the checklist line (`SKILL.md:308`, "over the store version") says the same.
- A script, or one command block, does the pull and the push.
- The steps have been run once end to end on the Pixel, and the pull request records the result.
