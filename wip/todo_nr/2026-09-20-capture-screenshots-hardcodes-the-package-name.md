# `capture_screenshots.sh` hardcodes the package, so it cannot drive a build installed beside the real app

- **Noted:** 2026-09-20 — while retaking the store screenshots (`chore/store-screenshots`)
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

`scripts/capture_screenshots.sh:22` sets `PACKAGE="com.vemore.countscore"` as a constant, and
uses it for `cmd locale set-app-locales`, `am force-stop`, `monkey` and `pm path`. That is the
only package it can drive.

The only Android device available is **the owner's own phone**, and it carries production
data: 172 real games, real first names, and the `shared_prefs` holding the backend URL, the
device token and the membership of a live four-device group. The installed build is
release-signed, so `adb install -r` of the profile APK the screenshots need is refused
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), and the procedure [[StoreListing]] documents —
"the Play-installed app must be **uninstalled** first (its data goes: ask)" — trades that data
for a screenshot set. `wip/done/2026-09-20-store-screenshot-of-the-podium-is-stale.md` was
delivered instead with a temporary, uncommitted `applicationIdSuffix = ".shots"` on the
`profile` build type, so the screenshot build installed **beside** the real app and nothing was
at risk — but `capture_screenshots.sh` could then not be used at all, and its navigation
contract (the eight stems, the output directory) had to be re-implemented in a throwaway
script.

**Fix:** take the package from the environment —
`PACKAGE="${COUNTSCORE_PACKAGE:-com.vemore.countscore}"` — and add the `applicationIdSuffix`
to `android/app/build.gradle.kts`'s `profile` build type permanently, so a screenshot build
never collides with the installed app. Then say in [[StoreListing]] and the `release-android`
skill that the screenshot build installs alongside, and delete the "uninstall first, its data
goes" paragraph rather than keeping a procedure whose recovery path (export, uninstall,
re-import) is only ever tested at the moment it fails.

Worth pairing with the fact that the script is **interactive** (it blocks on `read -p` between
captures), which no agent can drive without a FIFO: a `--non-interactive` mode that captures
each stem on a signal, or a documented driver, would make the retake repeatable instead of
re-invented each time.

**Acceptance:**
- `COUNTSCORE_PACKAGE=com.vemore.countscore.shots scripts/capture_screenshots.sh en-US` drives
  the suffixed build and writes `store_listing/en-US/raw/`.
- A `flutter build apk --profile --no-tree-shake-icons` installs without uninstalling
  `com.vemore.countscore`.
- [[StoreListing]] and `release-android` no longer tell the reader to uninstall the app.
