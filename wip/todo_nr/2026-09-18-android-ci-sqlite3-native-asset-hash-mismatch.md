# The Android CI job fails on flaky downloads that have nothing to do with the change

- **Noted:** 2026-09-18 — the first two CI runs of feat/play-again-and-type-order (#96)
- **Theme:** ci-scope
- **Area:** tooling
- **Blocks release:** no

The job "Android debug APK — fresh-clone build proof" went red twice in half an hour on a
change that touched no dependency and no build file. Each time, rerunning the failed job
alone passed:

- run 35335702639: `package:sqlite3` 3.6.0's build hook, inside `flutter build apk --debug`,
  failed with `Bad state: Hash of downloaded file libsqlite3.arm.android.so is 2514114…f003,
  expected a42fa9d0…bb49`, then `Target build_hooks failed`;
- run 35336544456: Gradle failed with `Could not GET
  'https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/1.9.20/kotlin-stdlib-1.9.20.pom'.
  Received status code 403`, reported as `java.lang.NullPointerException`.

A red check that has nothing to do with the change costs a rerun and a diagnosis every time,
and it teaches people to rerun without reading, when a real tampering would look exactly
like the first failure.

**Fix:** the job already caches `~/.gradle` through `actions/setup-java`'s `cache: gradle`
(`.github/workflows/ci.yml`), yet it still went to Maven Central for a `kotlin-stdlib` pom:
first find out why that cache missed (its key hashes Gradle files, and `android/gradlew`
and the wrapper are only generated at build time). Then cache the sqlite3 native libraries,
keyed on the `sqlite3` version in `pubspec.lock`. If that is not enough, retry the build step
once, and only on these two messages. Do not relax the hash check. Coordinate with whoever
owns `ci.yml` at the time.

**Acceptance:**
- A rerun of the Android job with an unchanged lock hits the Gradle cache and a native-asset cache, and `.llmwiki/Testing.md` says so.
- A job that fails twice with the same message still fails.
