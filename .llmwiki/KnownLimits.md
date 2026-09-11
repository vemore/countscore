# Known Limits

> Scope: what is deliberately deferred, and what is simply missing.
> Related: [[Architecture]] · [[Sync]] · [[Security]] · [[Testing]] · [[Web]]
> Updated: 2026-09-11

## Facts

### Deferred on purpose

- **Sync client on mobile.** The schema (`outbox`, `sync_state`) and the whole backend are
  ready; `sync_service.dart`, the outbox drain and the WebSocket client are not written.
  Nothing in `lib/` writes to `outbox` today. `lib/services/backend_client.dart` exists but
  covers only the two analysis-related calls. See [[Sync]].
- **No in-app way to discover or install a backend.** Settings takes a URL and tests it;
  finding a server, running `backend/` and getting TLS onto it are left to the user, and
  the app says so in one sentence rather than walking them through it.
- **Database export/import on web.** Hidden behind `kIsWeb` guards. Enabling it means
  extracting a `FileExporter` abstraction (io/web) and serialising the database to JSON for
  browser download/upload. See [[Web]].
- **Real-user snapshot in migration tests.** A production v8 database should be captured to
  `test/fixtures/v8_user_snapshot.db` and exercised. Today the v8 fixture is hand-written.
- **Drift rollout.** Production currently ships sqflite v9; Drift activates on the next
  release. See [[DataLayer]].
- **Multi-group per device.** The schema supports it (`group_id` per row); the UX was not
  designed, so one device maps to one group.

### Missing rather than deferred

- **No e2e or release-artifact coverage in CI.** `.github/workflows/ci.yml` proves a fresh
  clone builds — codegen, analyze, test, the web release and a debug APK — and runs the
  three backend gates. It does not run the e2e suite, which needs a real backend, nor the signed release APK/AAB, which needs the keystore secrets. Both stay
  manual. See [[Testing]].
- **No monitoring or alerting.** `docker logs` only. Prometheus + Grafana in a
  `docker-compose.monitoring.yml` is the intended shape. Since 2026-09-11 `GET /health`
  reports the *resolved* LLM provider and model, so a misconfigured deploy is visible from
  one free request — but nothing watches a 502 rate, and nothing would notice if the provider
  started refusing calls again. That is how the 2026-09-09 outage survived two days.
- **`PUBLISHING.md` predates the backend.** It must be updated before the first release
  that ships groups or commentary. See [[Release]].
- **Argon2 device-token verification is O(N).** One argon2 verify per device row, on every
  authenticated HTTP request. Fine at current scale; above ~1000 devices, index a short
  token prefix. See `backend/app/auth.py`. The WebSocket handshake used to duplicate this
  scan inline and no longer does — it redeems a ticket instead. See [[Sync]].
- **Flutter SDK upgrade blocked.** Six packages are pinned back, and `dart run drift_dev`
  does not compile at all at drift 2.34.4 / drift_dev 2.34.0. Full analysis and the plan
  live in `TODO.md` at the repo root — that file is the source of truth for this item.

  > **Status: Outdated** (2026-09-09) — done. The project is on Flutter 3.47.2 / Dart 3.13.2
  > and all seven held-back packages moved. `drift_dev` 2.34.6 compiles and runs
  > (`dart run drift_dev analyze` → *No errors found*). See `DONE.md`.

## Decisions & History

- **`web/sqlite3.wasm` and `web/drift_worker.js` are committed** (1.1 MB) despite being
  build outputs. The `drift_dev make-web-worker` CLI that regenerates the worker does not
  build at the pinned drift version, so the repository is the only reliable source for
  them. Reconsider once the CLI works again. (`8a13541`)

  > **Status: Outdated** (2026-09-09) — the premise was wrong in two ways. `make-web-worker`
  > is not a `drift_dev` subcommand at all in 2.34.6 (the commands are `analyze`,
  > `identify-databases`, `make-migrations`, `schema`), and the worker never needed the CLI:
  > **drift ships a prebuilt `drift_worker.js` at its package root**,
  > `~/.pub-cache/hosted/pub.dev/drift-<version>/drift_worker.js`. So the repository is *not*
  > the only source. They stay tracked by choice, not by necessity — see [[Web]].
- **This page is not a backlog.** It records limits so that a session does not rediscover
  them. Actionable work with a plan attached belongs in `TODO.md`, and moves to `DONE.md`
  once it is closed.
