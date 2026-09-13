# Testing

> Scope: what is tested, how to run it, and the traps.
> Related: [[MobileApp]] · [[DataLayer]] · [[SchemaV9]] · [[Backend]] · [[Web]] · [[KnownLimits]]
> Updated: 2026-09-13

## Facts

### Mobile unit tests — `flutter test`

| File | Coverage |
|---|---|
| `test/database_service_test.dart` (9) | Fresh v9 schema, CRUD via the singleton, v8→v9 migration, model serialisation. `sqflite_common_ffi` in memory (`sqfliteFfiInit()`), schema built via `DatabaseService.instance.createDB`. |
| `test/migration_v8_to_v9_test.dart` (4) | Hand-written v8 fixture; cross-game dedup and intra-game disambiguation. |
| `test/drift/drift_repositories_test.dart` (9) | Full lifecycle through the Drift repositories over `AppDatabase.forTesting(NativeDatabase.memory())`. |
| `test/widget_test.dart` (8) | Model serialisation only — it pumps no widgets, despite the name. |
| `test/providers/theme_provider_test.dart` (7) | `ThemeMode` decode fallbacks and the SharedPreferences round-trip. |
| `test/providers/backend_provider_test.dart` (10) | Backend URL validation — https anywhere, http only on a private or loopback host — and the persistence round-trip, including that a cleared setting is not re-seeded from `--dart-define`. |
| `test/screens/game_analysis_screen_test.dart` (5) | The only widget-pumping tests: with no backend configured the analysis screen offers no generation, a cached analysis still renders, and configuring one restores the button; plus the two failure paths — a failed regeneration keeps the cached text and warns by snackbar, and with nothing cached the error state carries the HTTP status and no raw exception. |
| `test/services/backend_client_test.dart` (4) | `BackendException` carries the status, keeps the body for logging, and decodes utf8 on both the error and the success path. `MockClient` from `package:http/testing.dart`. |

Neither the `SafeArea` inset nor the scheme-derived header colour has a widget test: both
need golden files this repo does not use, and an assertion that a `SafeArea` exists proves
nothing. They were verified on device on 2026-09-11.

The Analyze menu entry's own gating (`game_board_screen.dart`, `isConfigured ||
_hasCachedAnalysis`) has **no** widget test: pumping the board needs a loaded game and six
repositories. It was verified on device on 2026-09-11 — both directions, and the p171 case
where neither condition holds.

56 tests in eight files.

### End-to-end — `integration_test/app_test.dart`

One golden-path `testWidgets`, shared by web and device: create a ZapZap game → 2 global
players (Alice, Bob) → 3 rounds of scores → check totals → check stats (Alice wins,
lowest-wins) → generate a ZapZap analysis over a real network call → prove the
`game_analyses` cache was used. The analysis half lives in `_analyse`, skipped whole when no
backend is configured, so the teardown always runs.

Finders are locale-proof across all 10 languages: `Key`s (`player_picker_search`,
`player_picker_create`, `create_game_submit`, `board_add_round`, `analysis_generate`), icons,
and the untranslated literal `ZapZap`.

**`pumpAndSettle` cannot be used while the analysis screen is loading.** Its
`CircularProgressIndicator` animates forever, so the call times out; and settling *after* the
failure waits out the snackbar's own auto-dismiss, leaving nothing to assert. The failure
tests hand-pump instead — see `_pumpFailure` in `test/screens/game_analysis_screen_test.dart`.

**`pumpAndSettle` is not sufficient on web.** The Drift web worker resolves asynchronously
without scheduling a frame, so the suite uses hand-rolled waiters `_waitFor`, `_waitEnabled`
and `_waitDashes`. Do not "simplify" them back to `pumpAndSettle`.

**Web run** — `chromedriver` major version must match the installed Chrome:

```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=BACKEND_URL=<your backend URL>
```

The ZapZap network step is **skipped** on web whenever the configured backend's
`CORS_ORIGINS` does not list the serving origin — normally the case for `localhost`. It is
validated separately by `curl` and by the device run.

It is also skipped, on both targets, when **no** `--dart-define=BACKEND_URL` was passed: the
backend URL is a runtime setting with no default, so the Analyze menu entry is legitimately
absent and `_analyse` is not entered. The teardown still runs.

**Device run** — a clean database is required so the defaults are ZapZap and "Partie 1":

```bash
adb shell pm clear com.vemore.countscore
flutter test integration_test/app_test.dart -d <device_id> \
  --dart-define=BACKEND_URL=<your backend URL>
```

This one exercises the real network call, with no CORS in the way. For broader on-device
work, use the `flutter-device-test` skill.

### Backend — `pytest`

`tests/test_groups.py` (create, join, revoke, rotate) · `test_sync.py` (push/pull,
idempotence, round conflicts, payload bounds, player-name allow-list, and row-level LWW
between two devices — SQLite in memory, `pg_notify` stubbed) ·
`test_sync_ws_integration.py` (WS handshake + push → NOTIFY → new_seq → pull on a **real
Postgres** via testcontainers) · `test_comments.py` (mocked Anthropic, rate limit, budget,
prompt injection) · `test_zapzap_analysis.py` · `test_llm_providers.py` ·
`test_ip_rate_limit.py` · `test_health.py` (the `/health` shape, including that the resolved
LLM model is reported and that an unknown `LLM_PROVIDER` still answers 200).

**Tests never read `backend/.env`.** `tests/conftest.py` sets `Settings.model_config["env_file"]`
to `None` before `app.db` builds its settings at import, so a developer's local `.env` cannot
make a code-default assertion pass in CI and fail locally
(`test_settings_ignore_a_local_env_file`). Set per-test values with `monkeypatch.setenv`, then
`get_settings.cache_clear()`.

```bash
cd backend
pytest -m 'not integration' -q   # fast, no Docker
pytest -v                        # everything; the integration marker needs Docker
```

`asyncio_mode = "auto"`, `testpaths = ["tests"]`, marker `integration`.

### CI — `.github/workflows/ci.yml`

Three parallel jobs, on every push to `main`, every pull request, and `workflow_dispatch`.
Flutter is pinned to **3.47.2** by the `FLUTTER_VERSION` env key — that pin and the
toolchain table in [[MobileApp]] must move together.

| Job | Steps |
|---|---|
| `backend` | `uv sync --locked --extra dev` → `ruff check .` → `ruff format --check .` → `mypy` → `pytest -v` |
| `app` | `pub get` → `dart run build_runner build` → `analyze` → `test` → `build web --release` |
| `android` | `pub get` → `dart run build_runner build` → `build apk --debug` |

**Codegen comes before analyze, test and every build.** `*.g.dart` is gitignored, so
`lib/services/drift/database.g.dart` does not exist in a fresh clone; skipping the step
fails with `Target of URI hasn't been generated` and a cascade of undefined `_$AppDatabase`
errors. On the `android` job that cascade appears *after* minutes of Gradle configuration,
so it reads like a Gradle fault when it is not.

`uv`, not `pip install -e ".[dev]"`: `testcontainers` and `httpx-ws` live in
`[dependency-groups]`, which pip does not read, so a pip-based job would silently skip the
integration test. `--locked` additionally fails if `uv.lock` has drifted from
`pyproject.toml`.

The `android` job caps the Gradle heap by appending to `$HOME/.gradle/gradle.properties`,
which outranks the project's `android/gradle.properties` and its `-Xmx8G` request; the
committed file is not touched. It builds **debug** only — release signing reads
`android/key.properties`, absent in CI by design — and asserts afterwards that the Flutter
tool injected the gitignored `gradlew` and `gradle-wrapper.jar`.

Not in CI on purpose: the e2e suite (it calls the real production endpoint) and the signed
release APK/AAB (needs the keystore secrets).

### Gaps

**The e2e suite does not run in CI.** `integration_test/app_test.dart` drives a real
network call against production, so it stays a manual step — on web via chromedriver, on a
device via the `flutter-device-test` skill. Export/import and the wakelock toggle have no
automated coverage at all and must be checked on a device.

**The sync conflict branch is untested.**

> **Status: Outdated** (2026-09-13) — covered now. Three tests in `test_sync.py` drive two
> devices of one group at the same `entity_uuid`: an older lamport answers `merged_lww` and
> contributes nothing, including a field only the loser set (the row-level fact); a newer
> lamport from the other device wins; an equal lamport is broken by the greater
> `origin_device_id`. Each fails when its half of the comparison at
> `backend/app/routes/sync.py` is removed.

## Decisions & History

- **The e2e suite is one golden path, not a matrix.** It is the smallest thing that proves
  the whole stack — UI, Drift, migration defaults, network, cache — is wired together. Its
  value is breadth, not depth; depth belongs in the unit tests.
- **Finders key off `Key`s rather than text** so the suite survives all 10 locales.
  Adding a language must never break the tests.
- **The WS integration test uses testcontainers instead of a stub** because
  `LISTEN/NOTIFY` and JSONB are exactly the Postgres-specific behaviour the rest of the
  suite mocks away. It is marked `integration` so the default run stays Docker-free.
- **`test/widget_test.dart` is misnamed** — it is a model serialisation suite. Left as is to
  avoid churn; do not assume widget coverage exists because of the filename.
- **CI runs the full backend suite, integration tests included** (2026-09-09). The runner
  has Docker, so paying ~40 s to start `postgres:17-alpine` buys mechanical coverage of
  `LISTEN/NOTIFY` and JSONB, which nothing else exercises. `TESTCONTAINERS_RYUK_DISABLED`
  is set because the runner is ephemeral and Ryuk is a known flake source. If it ever turns
  flaky, the fallback is `-m 'not integration'` on PRs and the full run on `main`.
- **The Android CI job builds debug, and there are no path filters** (2026-09-09). Debug
  because release signing needs `android/key.properties`, which is never committed. No
  `paths:` filters because a filtered-out job never reports a status, so branch protection
  with required checks would hang forever on docs-only PRs — and because the bug that
  motivated CI at all (`settings.gradle` shadowing `settings.gradle.kts` for years) was
  precisely a "nobody built it" bug. Narrowing when the build runs would reopen that hole.
