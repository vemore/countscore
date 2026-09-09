# Testing

> Scope: what is tested, how to run it, and the traps.
> Related: [[MobileApp]] · [[DataLayer]] · [[SchemaV9]] · [[Backend]] · [[Web]] · [[KnownLimits]]
> Updated: 2026-09-09

## Facts

### Mobile unit tests — `flutter test`

| File | Coverage |
|---|---|
| `test/database_service_test.dart` (9) | Fresh v9 schema, CRUD via the singleton, v8→v9 migration, model serialisation. `sqflite_common_ffi` in memory (`sqfliteFfiInit()`), schema built via `DatabaseService.instance.createDB`. |
| `test/migration_v8_to_v9_test.dart` (4) | Hand-written v8 fixture; cross-game dedup and intra-game disambiguation. |
| `test/drift/drift_repositories_test.dart` (9) | Full lifecycle through the Drift repositories over `AppDatabase.forTesting(NativeDatabase.memory())`. |
| `test/widget_test.dart` (8) | Model serialisation only — it pumps no widgets, despite the name. |

### End-to-end — `integration_test/app_test.dart`

One golden-path `testWidgets`, shared by web and device: create a ZapZap game → 2 global
players (Alice, Bob) → 3 rounds of scores → check totals → check stats (Alice wins,
lowest-wins) → generate a ZapZap analysis over a real network call → prove the
`game_analyses` cache was used.

Finders are locale-proof across all 10 languages: `Key`s (`player_picker_search`,
`player_picker_create`, `create_game_submit`, `board_add_round`, `analysis_generate`), icons,
and the untranslated literal `ZapZap`.

**`pumpAndSettle` is not sufficient on web.** The Drift web worker resolves asynchronously
without scheduling a frame, so the suite uses hand-rolled waiters `_waitFor`, `_waitEnabled`
and `_waitDashes`. Do not "simplify" them back to `pumpAndSettle`.

**Web run** — `chromedriver` major version must match the installed Chrome:

```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=BACKEND_URL=https://countscore.ombivince.synology.me
```

The ZapZap network step is **skipped** on web: production CORS does not allow a `localhost`
origin. It is validated separately by `curl` and by the device run.

**Device run** — a clean database is required so the defaults are ZapZap and "Partie 1":

```bash
adb shell pm clear com.vemore.countscore
flutter test integration_test/app_test.dart -d <device_id> \
  --dart-define=BACKEND_URL=https://countscore.ombivince.synology.me
```

This one exercises the real network call, with no CORS in the way. For broader on-device
work, use the `flutter-device-test` skill.

### Backend — `pytest`

`tests/test_groups.py` (create, join, revoke, rotate) · `test_sync.py` (push/pull, LWW,
idempotence, round conflicts — SQLite in memory, `pg_notify` stubbed) ·
`test_sync_ws_integration.py` (WS handshake + push → NOTIFY → new_seq → pull on a **real
Postgres** via testcontainers) · `test_comments.py` (mocked Anthropic, rate limit, budget,
prompt injection) · `test_zapzap_analysis.py` · `test_llm_providers.py` ·
`test_ip_rate_limit.py`.

```bash
cd backend
pytest -m 'not integration' -q   # fast, no Docker
pytest -v                        # everything; the integration marker needs Docker
```

`asyncio_mode = "auto"`, `testpaths = ["tests"]`, marker `integration`.

### Gaps

**There is no CI.** Nothing mechanically verifies that a fresh clone builds — which matters
because `*.g.dart` is gitignored. Export/import and the wakelock toggle have no automated
coverage at all and must be checked on a device.

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
