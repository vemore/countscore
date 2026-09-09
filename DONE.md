# DONE

Closed items, newest first. Moved out of `TODO.md` when they were finished, so that file
holds only open work. Nothing here is deleted — the reasoning behind a decision stays
readable after the fact.

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
