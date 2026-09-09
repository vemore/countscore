# Architecture

> Scope: what CountScore is made of and how far each part has got.
> Related: [[MobileApp]] · [[Backend]] · [[Web]] · [[Sync]] · [[Deployment]] · [[KnownLimits]]
> Updated: 2026-09-09

## Facts

CountScore started as a single-device Flutter/Android score tracker on sqflite. It is being
transformed along three axes, tracked independently:

1. **Web PWA** — full mobile parity plus shared real-time scoring.
2. **Offline-first sharing backend** — groups, delta-log sync, WebSocket.
3. **LLM commentary API** — Claude for short game comments, a separate pluggable provider
   for the long-form "ZapZap" analysis.

### Target topology

```
CountScore Mobile            CountScore Web
(Flutter Android)            (Flutter PWA)
 Drift + SQLite               Drift + sqlite3.wasm
 (native FFI)                 (OPFS)
        \                        /
         HTTPS REST + WebSocket
                   |
        Synology Web Station (TLS)
                   |
          FastAPI (uvicorn, 1 worker)
           /sync/*  /groups/*  /comments/*  /sync/stream
             |                        |
         Postgres 17            Anthropic API / Bedrock / Gemini / Mistral
       (LISTEN/NOTIFY)
```

### Milestone status

| # | Milestone | Status | Notes |
|---|---|---|---|
| 0 | Mobile test safety net | Done | `test/database_service_test.dart`, 9 tests |
| 1 | Mobile repository layer | Done | Interfaces `lib/repositories/`, Drift impls in `drift/` |
| 2 | Schema v6→v9, sync-ready | Done | v6 UUIDs+sync cols · v7 `game_analyses` · v8 cache fix · v9 global players |
| 3 | Drift migration | Done | `lib/services/drift/`; two-release strategy — see [[DataLayer]] |
| 4 | Backend MVP (`/comments/mvp`) | Done | Stateless, 3 tests |
| 5 | Groups + REST sync | Done | Push/pull/dedup/round-conflict tested |
| 6 | Real time (WebSocket) | Done | `/sync/stream` + LISTEN/NOTIFY, testcontainers integration test |
| 7 | Full commentary API | Done | Pluggable LLM providers, IP rate limiting — see [[LlmProviders]] |
| 8 | Web PWA | Done | Drift over `sqlite3.wasm` + OPFS, e2e in headless Chrome — see [[Web]] |
| 9 | Backend production-readiness | Partial | Compose + TLS + daily `pg_dump`; **no monitoring or alerting** |

The server side of milestones 5–7 is complete, but **the Flutter client for sync does not
exist**: `sync_service.dart` and `backend_client.dart` are designed and referenced but are
not on disk. The only live app↔backend call is the ZapZap analysis — see [[LlmProviders]].

## Decisions & History

- **Three independent axes rather than one big rewrite.** Each milestone is a single
  commit, so a broken one is `git reset --hard <sha>` away from a working tree.
- **Postgres `LISTEN/NOTIFY` instead of Redis.** The pub/sub need is one signal per write;
  adding Redis would double the infrastructure for it. Keeps the whole stack around 150 MB
  of RSS, small enough for a Raspberry Pi 4.
- **FastAPI + Postgres over Node/TS or Go.** The Anthropic Python SDK is first-class and
  async-native, SQLModel/SQLAlchemy is the more solid data ecosystem, and FastAPI gives
  type hints, automatic OpenAPI and native WebSockets. Go was rejected as performance
  overkill with a less mature SDK and more boilerplate.
