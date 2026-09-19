# The sqlite3 native-asset hash mismatch is back, now in the Sync job

**Status:** done (2026-09-19) — closed by ci/android-scope-and-sqlite-cache. `app`, `sync` and `android` cache `.dart_tool/hooks_runner/shared/sqlite3/build/download-*` with `actions/cache@v6`, keyed per job on the `sqlite3` version in `pubspec.lock`, and run the hook's step through `scripts/retry_sqlite3_hash.sh`, which retries once only on "Hash of downloaded file" and keeps the second status; `scripts/retry_sqlite3_hash_selftest.sh` pins both. The hash check is untouched.

- **Noted:** 2026-09-19 — first CI run of test/e2e-golden-path-keypad (#129)
- **Theme:** ci-scope
- **Area:** tooling
- **Blocks release:** no

`wip/done/2026-09-18-android-ci-sqlite3-native-asset-hash-mismatch.md` was dropped as not
seen again, "reopen with the run id if it comes back". It came back, in another job: run
35429735515, job "Sync — two devices against a real backend", `flutter test
test/sync/sync_two_devices_test.dart` failed in `package:sqlite3` 3.6.0's build hook with
`Bad state: Hash of downloaded file libsqlite3.x64.linux.so is 2514114…f003, expected
4b986901…f9af` — the same wrong hash `2514114…f003` as the Android failure of 2026-09-18,
for a different file. Rerunning the failed job alone passed. The change touched only a test
and docs.

The identical bad hash for two different files suggests the download returns the same wrong
body (an error or rate-limit page) rather than a corrupted library.

**Fix:** the one the dropped entry proposes, applied to every job that runs a sqlite3 build
hook (App, Sync, Android): cache the sqlite3 native libraries keyed on the `sqlite3` version
in `pubspec.lock`; if that is not enough, retry once and only on this message. Do not relax
the hash check.

**Acceptance:**
- A rerun with an unchanged lock hits a native-asset cache in every job that builds sqlite3.
- A job that fails twice with the same message still fails.
