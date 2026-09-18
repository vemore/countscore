# The Android CI build can fail on a hash mismatch of sqlite3's downloaded native library

- **Noted:** 2026-09-18 — first CI run of feat/play-again-and-type-order (#96), run 35335702639
- **Theme:** ci-scope
- **Area:** tooling
- **Blocks release:** no

The job "Android debug APK — fresh-clone build proof" failed in `flutter build apk --debug`
while `package:sqlite3` 3.6.0's build hook ran:
`Bad state: Hash of downloaded file libsqlite3.arm.android.so is 2514114…f003, expected a42fa9d0…bb49`,
then `Target build_hooks failed`. The change under test touched no dependency and no build
file. Rerunning the failed job alone passed four minutes later, so the download is flaky
(a truncated or substituted file from the hook's release URL), not the lock. A red check
unrelated to the change costs a rerun and a diagnosis each time it happens, and a real
tampering would look exactly the same.

**Fix:** find out where the hook downloads from and whether it retries. Then either cache
the downloaded native libraries in CI (keyed on the `sqlite3` version in `pubspec.lock`),
or retry the build step once and only on this message. Do not relax the hash check.

**Acceptance:**
- The Android job either caches the sqlite3 native assets or retries once on this specific error, and says so in `.llmwiki/Testing.md`.
- A second failure with the same message still fails the job.
