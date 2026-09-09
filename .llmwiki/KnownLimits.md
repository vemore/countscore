# Known Limits

> Scope: what is deliberately deferred, and what is simply missing.
> Related: [[Architecture]] · [[Sync]] · [[Security]] · [[Testing]] · [[Web]]
> Updated: 2026-09-09

## Facts

### Deferred on purpose

- **Sync client on mobile.** The schema (`outbox`, `sync_state`) and the whole backend are
  ready; `sync_service.dart`, the outbox drain and the WebSocket client are not written.
  Nothing in `lib/` writes to `outbox` today. See [[Sync]].
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

- **No CI.** Nothing mechanically checks that a fresh clone builds. This matters because
  `*.g.dart` is gitignored, so a clean checkout does not compile until
  `dart run build_runner build` has run.
- **No monitoring or alerting.** `docker logs` only. Prometheus + Grafana in a
  `docker-compose.monitoring.yml` is the intended shape.
- **`PUBLISHING.md` predates the backend.** It must be updated before the first release
  that ships groups or commentary. See [[Release]].
- **Argon2 device-token verification is O(N).** One argon2 verify per device row, on every
  authenticated HTTP request. Fine at current scale; above ~1000 devices, index a short
  token prefix. See `backend/app/auth.py`. The WebSocket handshake used to duplicate this
  scan inline and no longer does — it redeems a ticket instead. See [[Sync]].
- **Flutter SDK upgrade blocked.** Six packages are pinned back, and `dart run drift_dev`
  does not compile at all at drift 2.34.4 / drift_dev 2.34.0. Full analysis and the plan
  live in `TODO.md` at the repo root — that file is the source of truth for this item.

## Decisions & History

- **`web/sqlite3.wasm` and `web/drift_worker.js` are committed** (1.1 MB) despite being
  build outputs. The `drift_dev make-web-worker` CLI that regenerates the worker does not
  build at the pinned drift version, so the repository is the only reliable source for
  them. Reconsider once the CLI works again. (`8a13541`)
- **This page is not a backlog.** It records limits so that a session does not rediscover
  them. Actionable work with a plan attached belongs in `TODO.md`.
