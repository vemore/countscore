# DONE

Closed items, newest first. Moved out of `TODO.md` when they were finished, so that file
holds only open work. Nothing here is deleted — the reasoning behind a decision stays
readable after the fact.

---

## `.llmwiki/Testing.md` is missing a test file

**Status:** done (2026-09-11) — closed on `feat/configurable-backend-url`, which added two
more test files and would otherwise have widened the gap.

Its table listed four files totalling 30 tests while `flutter test` ran 37 across six:
`test/providers/theme_provider_test.dart` (added by `ccc3640`) was never added to the page.
The table now lists all seven files and 50 tests, the suite's current shape.

---

## Release builds declare no `INTERNET` permission, so the analysis cannot work

**Status:** done (2026-09-09) — closed on `fix/release-internet-permission`.

`android/app/src/main/AndroidManifest.xml` declared **no permissions at all**. `INTERNET`
appeared only in `android/app/src/debug/AndroidManifest.xml` and the profile manifest, where
Flutter's template puts it for hot reload. Confirmed against a merged release manifest: it
contained one `uses-permission`, the generated `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`,
and no `INTERNET`.

So **the ZapZap analysis could not work in a signed release build** — the HTTP POST in
`lib/screens/game_analysis_screen.dart` would fail with a `SocketException`. It worked in
debug and profile, which is why it went unnoticed: the e2e device run drives a debug build,
and CI builds a debug APK.

**What closed it.** The permission is now in the main manifest, with a comment saying what
needs it and why the debug manifest does not cover it. Verified the way the bug demanded —
against the *merged* manifest of a real signed build, not the source:

```
$ grep uses-permission build/app/intermediates/merged_manifests/release/*/AndroidManifest.xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.vemore.countscore.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />
```

It shipped with the data safety declaration it depends on, in the same commit, because the
two are only correct together: the permission without the declaration transmits data the
form denies, and the declaration without the permission declares a flow the binary cannot
perform.

The entry left two questions open. Both are answered:

- **Should the release build reach the network at all before the sync client exists?** Yes.
  The ZapZap analysis is a shipped, user-facing 1.1.0 feature and is the only flow the
  permission enables; groups and sync have no client, so they add nothing to the surface.
- **Should the e2e suite run against a release build so this is caught mechanically?** No —
  it calls the production endpoint and needs the keystore, which is why it is already out of
  CI. Instead the `android` CI job now asserts that the main manifest declares `INTERNET`.
  That is a weaker check than a real release build, and deliberately so: it needs no
  keystore, no network and no minutes, and it catches the exact regression that happened.
  What it cannot catch — a permission present in source but lost in the merge — is covered
  by the `release-android` checklist, which now greps the merged manifest every release.

---

## `PUBLISHING.md` predates the backend

**Status:** done (2026-09-09) — closed on `fix/release-internet-permission`.

It described a purely local, offline app. Any release shipping group sharing or LLM
commentary needed the Play Data Safety declaration rewritten first, to disclose the network
calls and what game data leaves the device. **This blocked the next store release.**

`PLAY_STORE_DATA_SAFETY.md` and `privacy_policy.md` had already had that pass on
2026-09-09; `PUBLISHING.md` was the one document still contradicting them, telling the
reader to answer *"Does your app collect or share user data? **No**"* and carrying an
embedded privacy-policy template that said *"No data is transmitted to external servers"*.

**What closed it.** The file was cut from 867 lines to 184 rather than corrected, because
correcting it would have preserved the cause. It had duplicated the keystore and build
procedure from the `release-android` skill and the form answers from
`PLAY_STORE_DATA_SAFETY.md`; the duplicates are what drifted. What remains is
Console-specific only — listing, App Content answers, tracks, rollout, post-launch — with a
table at the top routing everything else to its single source. Stale facts disappeared with
the sections carrying them: Flutter 3.9.2, version 1.0.0+1, the policy template, both "no
data collected" answers, "Shares user data: No", and "verify ProGuard/R8 is enabled".

**Three things the pass turned up that the entry did not predict:**

1. **The actual published listing text was false too.**
   `store_listing/en-US/full_description.txt` and its `fr-FR` twin — the copy that goes on
   the store page, not a template — said *"no data collection"* and *"Your data stays on
   your device"*. That would have put the store listing in direct contradiction with a Data
   Safety form saying "Yes", which is the pairing reviewers look for. Both locales now
   describe the ZapZap analysis as an optional feature and say plainly that data is sent
   when the user asks.
2. **Both listings claimed "Requires Android 5.0 or higher"** against a `minSdk` of 24,
   which is Android 7.0. Corrected in the same pass.
3. **ProGuard/R8 is enabled, and three documents said it was disabled.**
   `android/app/build.gradle.kts:53-54` has `isMinifyEnabled = true` and
   `isShrinkResources = true` — turned on in `1614707` and never reflected anywhere.
   `.llmwiki/Release.md` and the `release-android` skill are corrected; the wiki keeps the
   old claim in a `Status: Outdated` block.

The privacy policy is also published now. `scripts/build_privacy_page.py` renders
`privacy_policy.md` to `docs/privacy-policy.html` with pandoc, GitHub Pages serves it at
`https://vemore.github.io/countscore/privacy-policy.html`, and that URL replaces the
`[YOUR_PRIVACY_POLICY_URL]` placeholder the Data Safety guide carried. Generating rather
than hand-writing the page is deliberate: a hand-maintained copy is exactly how
`PUBLISHING.md` came to contradict the policy in the first place. **Enabling Pages in the
repository settings is still a manual step**, and the release is not submittable until it is
done.

---

## `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md` deny a data flow that exists

**Status:** done (2026-09-09) — closed by the rewrite of both documents on
`docs/privacy-disclosure`.

Both compliance documents state that CountScore transmits nothing and uses no third-party
service. That stopped being true when the ZapZap analysis moved server-side: requesting one
posts the game's data — game type, player names, round scores and per-player history — from
`lib/screens/game_analysis_screen.dart` to the backend, which forwards it to an LLM provider
(Bedrock / Gemini / Mistral).

The offending claims:

- `privacy_policy.md:88` — "does not integrate with any third-party services for data
  collection, analytics, or advertising" — and the `:235` summary line "No third-party
  services".
- `PLAY_STORE_DATA_SAFETY.md:15` — "No data is transmitted to external servers, and no
  third-party services are used" — plus `:55` and `:308`.

`README.md` was corrected on 2026-09-09; these two were left alone deliberately, because a
Play Store data safety declaration is a legal statement and rewriting it needs a decision
about what is actually declared (data type, purpose, whether it is "collected" or only
"transmitted", retention at the provider), not a copy-edit.

**This blocks the next store submission that ships the analysis feature.** It is the same
class of problem `.llmwiki/Release.md` already records for `PUBLISHING.md`, which likewise
predates the backend. See [[LlmProviders]] for exactly what the payload contains and
[[Security]] for what the declarations would have to disclose.

**What closed it.** `privacy_policy.md` is now v2.0: it describes the ZapZap payload field by
field, names the recipients (the backend, then AWS Bedrock / Google Gemini / Mistral AI),
states that the backend persists nothing, gives consent as the legal basis, and keeps the v1.0
text identified as the policy for the 1.0.x releases still on the store.
`PLAY_STORE_DATA_SAFETY.md` flips Q1 to "Yes" and declares two data types — Personal info →
Name, and App activity → Other user-generated content — both optional, App functionality, not
linked to identity, not used for tracking.

The posture was a deliberate choice: Google's ephemeral-processing exemption would allow "not
collected", and our own backend meets that bar, but the LLM provider is env-configurable and
free-tier Gemini may train on submitted prompts, so the exemption cannot hold for every
supported configuration. Over-declaring is permitted; under-declaring is what removes apps.

Checking the manifests for this also turned up the missing `INTERNET` permission and the
`WAKE_LOCK` claim that was never true — the first is now its own open item, the second is
corrected in both documents.

---

## `README.md` advertises a Flutter version four majors out of date

**Status:** done (2026-09-09) — closed by the full README refresh on
`docs/privacy-disclosure`.

It claims `Flutter SDK ^3.9.2` in three places (the badge, the Tech Stack section and the
prerequisites). The project runs 3.47.2 / Dart 3.13.2 — see the toolchain table in
[[MobileApp]]. The Platform badge also reads `Android | iOS`, while everything documented
in [[Release]] and `store_listing/` targets the Play Store and the web PWA; whether iOS is
still an intended target is worth settling in the same pass.

Worth a pass over the whole Tech Stack list rather than a one-line badge fix: the
dependency versions quoted there predate the Flutter 3.47 upgrade too.

**What closed it.** The whole README was rewritten rather than patched: badges (Flutter 3.47.2,
`Android | Web` — iOS settled as not a target), a tech stack split into app and backend with
Drift as the database and sqflite named as the bootstrap migrator only, the mandatory
`dart run build_runner build` step that was missing from Getting Started, the web PWA build,
the 10 languages, a Backend section stating plainly that the sync client does not exist, the
three CI jobs, and a corrected privacy section. Versions were cross-checked against
`pubspec.yaml` rather than carried over.

---

## There is no CI

**Status:** done (2026-09-09) — closed by the `chore/ci` branch. Opened 2026-09-09,
carried over from the Flutter 3.47 entry.

Nothing mechanically checked that a fresh clone builds, which was uncomfortable given
`*.g.dart` is gitignored. The backend already had three green gates (`ruff check`,
`mypy`, `pytest`) and the app had `flutter analyze` + `flutter test`; a workflow running
them costs little and stops lint debt from re-accumulating.

The Flutter 3.47 upgrade made this sharper: it turned out `android/settings.gradle` had
been shadowing `android/settings.gradle.kts` since the first commit, so edits to the `.kts`
file were silently dead. A build in CI would have caught that years earlier.

**Closed by `.github/workflows/ci.yml`** — three parallel jobs on every push to `main` and
every PR:

- `backend` — `uv sync --locked --extra dev`, then `ruff check .`, `mypy`, `pytest -v`.
  The full suite, so the `integration`-marked testcontainers test really starts
  `postgres:17-alpine` and exercises LISTEN/NOTIFY and JSONB — covered nowhere else.
  `uv` rather than `pip install -e ".[dev]"`, which silently misses `testcontainers` and
  `httpx-ws`: they live in `[dependency-groups]`, which pip does not read.
- `app` — `pub get` → `dart run build_runner build` → `analyze` → `test` → web release
  build. The codegen step is what makes this a fresh-clone proof.
- `android` — the same codegen, then `flutter build apk --debug`, plus an assertion that
  the Flutter tool really injected the gitignored `gradlew` / `gradle-wrapper.jar`.

Deliberately **not** covered, so the gap stays honest: the e2e suite
(`integration_test/app_test.dart`) is out, because it calls the real production endpoint;
the signed release APK/AAB is out, because it needs the keystore secrets; and `ruff format`
is not run, as it remains its own open item.

Two traps found while writing it. `gradle/actions/setup-gradle` is the wrong action here —
it expects a wrapper at checkout time, but `android/gradlew` is gitignored until Flutter
injects it, so `actions/setup-java` with `cache: gradle` does the job instead. And
`android/gradle.properties` asks for `-Xmx8G`, more than a runner has; the override goes in
the `GRADLE_USER_HOME` `gradle.properties`, which outranks the project's, so the committed
file stays untouched.

---

## Upgrade Flutter to 3.47 to unblock the held-back dependencies

**Status:** done (2026-09-09) — closed by the `chore/flutter-3-47` branch. Opened
2026-09-09 during the dependency update (`f0a8bd6`).

The trigger was a defect, not version lag: `dart run drift_dev <anything>` failed to
compile at drift 2.34.4 / drift_dev 2.34.0 (`The getter 'allSchemaEntities' isn't defined
for the type 'GeneratedDatabase'`). `drift_dev` 2.34.6 fixes it but needs
`analyzer >=13.0.0 <15.0.0`, and Dart 3.11 capped us at analyzer 10.0.1.

**Flutter 3.41.9 / Dart 3.11.5 → 3.47.2 / Dart 3.13.2**, and all seven held-back packages
moved: `drift_dev` 2.34.0→2.34.6, `build_runner` 2.15.1→2.16.1, `flex_color_picker`
3.8.0→4.0.0, `wakelock_plus` 1.7.0→1.8.0, `sqflite` 2.4.2+1→2.4.3, `intl` 0.20.2→0.20.3,
`sqflite_common_ffi` 2.4.0+3→2.4.2+1. `analyzer` went 10.0.1→14.3.0. `drift` itself stayed
at 2.34.4 — drift_dev 2.34.6 requires `drift <2.35.0`.

The CLI works again: `dart run drift_dev analyze` returns *No errors found*.

### What the entry got wrong about the web binaries

The old entry, `.llmwiki/Web.md` and `web/CLAUDE.md` all justified tracking
`web/sqlite3.wasm` and `web/drift_worker.js` with "the `make-web-worker` CLI is broken, so
the repo is the only reliable source". Both halves were wrong. `make-web-worker` is not a
`drift_dev` subcommand at all in 2.34.6, and the worker never needed a CLI: **drift ships
it prebuilt at its package root**. The files stay tracked, but now for the honest reason —
a fresh clone should not have to fetch binaries to run the PWA. Refreshing the stale
committed worker is its own `TODO.md` entry.

### `android/settings.gradle` had been shadowing `settings.gradle.kts` since the first commit

The first AGP 9 build failed with *"Your project's Android Gradle Plugin version (8.9.1) is
lower than Flutter's minimum"* — after `settings.gradle.kts` had been edited to 9.1.0. A
Groovy `android/settings.gradle` from `4e52a54` sat next to it pinning AGP 8.9.1 and Kotlin
**2.1.0**, and Gradle prefers the Groovy file when both exist. So every edit to
`settings.gradle.kts` had been dead — including the Kotlin 2.2.20 bump the old TODO
described as already applied. The Groovy file is deleted; the rest of the project is Kotlin
DSL. This is the strongest argument yet for the still-open "no CI" item.

### Android toolchain, aligned to Flutter 3.47.2's own templates

Gradle 8.12→9.3.1, AGP 8.9.1→9.1.0, Kotlin 2.1.0→2.4.0, compileSdk/targetSdk 35→36 (both
follow `flutter.*`), SDK Build-Tools 36.0.0 installed as an AGP 9 prerequisite. Flutter
hard-errors below Gradle 8.14 / AGP 8.11.1 / KGP 2.2.20 / Java 17, so the Android side
could not have been left alone regardless.

The AGP 9 migration itself is the three-line diff Flutter's own template makes:
`id("kotlin-android")` dropped from `android/app/build.gradle.kts` (Flutter's Gradle plugin
applies it), the `kotlinOptions` block replaced by a top-level
`kotlin { compilerOptions { jvmTarget = JVM_17 } }`, and `android.newDsl=false` +
`android.builtInKotlin=false` added to `android/gradle.properties` — AGP 9 defaults both to
`true`, and `org.jetbrains.kotlin.android` is incompatible with the new DSL.
`android.enableJetifier=true` was dropped: no Flutter template has ever set it, it only
rewrites pre-AndroidX artifacts, and it costs build time.

### Verification

`flutter analyze` clean · 37/37 `flutter test` · release apk and appbundle build with R8
enabled · web build serves and drift opens its database in the browser (`drift_worker.js`
fetched, IndexedDB `countscore` created, zero console errors) against the **committed**
worker.

On a Pixel 9 Pro XL (Android 17), because none of this has automated coverage:

- **flex_color_picker 4.0.0** — the one upgrade with real API exposure. Both the Primary/
  Accent/Wheel dialog and the wheel picker render correctly and preselect the current
  colour, matching the `pickersEnabled` map in `players_screen.dart`.
- **wakelock_plus 1.8.0** — toggling it acquires a real `SCREEN_BRIGHT_WAKE_LOCK`
  attributed to `com.vemore.countscore` in `dumpsys power`, and releases it on toggle off.
- **file_picker 12.2.0 + export** — the SAF directory picker opens and a full export
  completes end to end.

Not run: `integration_test/app_test.dart` on device, which needs `adb shell pm clear` and
so would destroy real game data; and the chromedriver web e2e, since chromedriver is not
installed. The Playwright runtime check above covers what the web e2e would have proved
about startup and persistence.

### Smaller consequences

- `build_runner` 2.16 **removed `--delete-conflicting-outputs`** — it now warns and ignores
  the flag. Dropped from `CLAUDE.md`, `.llmwiki/DataLayer.md` and the `db-migration` and
  `release-android` skills.
- Analyzer 14 raised two new findings on pre-existing code. `IconData(iconCodePoint, ...)`
  in `lib/models/game_type.dart` now warns `non_const_argument_for_const_parameter` — that
  warning *is* the dynamic-icon constraint surfacing, so it carries a targeted `// ignore:`
  with the reason rather than a hardcoded codepoint. `GameAnalysisScreen`'s private
  `_repository` field became public `repository`, which satisfies `prefer_initializing_formals`
  properly and keeps the injection seam usable from outside the library.
- Every Android build now warns that `shared_preferences_android` applies KGP. Upstream's
  to fix; tracked in `TODO.md`.
- `flutter analyze` on 3.47 rewrites `analysis_options.yaml` itself, printing *"Upgrading
  analysis_options.yaml to exclude build and platform directories"* and adding an
  `analyzer: exclude:` block for `build/`, `android/`, `ios/` and `web/`. The block is
  committed because reverting it just makes the next `flutter analyze` add it back.
- `android/.kotlin/` is a new Kotlin 2.4 build-artifact directory; added to
  `android/.gitignore`.

---

## `ThemeProvider` never persists

**Status:** done (2026-09-09) — closed by `ccc3640`, *fix: persist the selected theme
across restarts*. Surfaced during the LLM-wiki migration.

`lib/providers/theme_provider.dart` held `ThemeMode` in memory only, so the app reset to
`ThemeMode.system` on every restart. It now stores `ThemeMode.name` under the `themeMode`
key, and `main()` reads it before `runApp` rather than loading async in the constructor
the way `SettingsProvider` does — that pattern would have shown a light flash on every
cold start for a dark-mode user. The unused `toggleTheme()` and `isDarkMode` went with it.

---

## Backend security debt

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*, recorded in `ef57989`. Surfaced during the LLM-wiki migration.

All five catalogued items are closed, plus four found while reading the code:
WebSocket ticket handshake, IP rate limit on group create/join, `share_token`
out of `GET /groups/me`, value bounds on `/sync/push`, security headers; and
the driver error leaked in sync rejections, the `--workers 2` default in the
Dockerfile, the `Content-Length` bypass of the body cap, and the one
string-built SQL statement in `notify.py`.

Details and the reasoning: `.llmwiki/Security.md`. What remains open is listed
there too — the unauthenticated `/comments` endpoints, the O(N) argon2 scan,
and the absence of an owner role on `Device`.

---

## Backend lint debt and type checking

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*. Surfaced during the LLM-wiki migration.

`ruff check .` in `backend/` is clean, and `mypy` is now configured
(`[tool.mypy]` in `backend/pyproject.toml`) and clean over the 36 source files.
The SQLModel query expressions were rewritten with `sqlmodel.col()` rather than
having the error codes silenced, so the checker still reads those lines.

`openai` is unpinned from `>=2,<3` to `>=3,<4` (3.10.0). The only breaking
change in 3.0 was httpx2 as the default client, which `openai_compat.py` never
touched — and `anthropic` 1.4 was already on httpx2, so the tree converged.

Note: `ruff format` has still **never** been run on `backend/` — that stays open in
`TODO.md`.
