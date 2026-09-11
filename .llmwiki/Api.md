# API

> Scope: the HTTP and WebSocket surface. Source of truth is `backend/app/routes/`.
> Related: [[Backend]] · [[Sync]] · [[LlmProviders]] · [[Security]]
> Updated: 2026-09-11

## Facts

`/docs` serves the generated OpenAPI when the server is running.

### `app/routes/groups.py` — prefix `/groups`, tag `groups`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `` | none | Create a group + its first device. 201. IP rate limited. |
| POST | `/join` | none | Join via `share_token`. 201. IP rate limited. |
| GET | `/me` | device | Returns the group. **No `share_token`** — see below. |
| PATCH | `/me/settings` | device | |
| GET | `/me/usage` | device | Budget consumption. |
| POST | `/me/devices/{device_id}/revoke` | device | 204. |
| POST | `/me/rotate-share-token` | device | Invalidates the old share link. Returns `share_token`. |

### `app/routes/sync.py` — prefix `/sync`, tag `sync`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/push` | device | Max **500 deltas** per request. Values bounded per entity. |
| GET | `/pull?since_seq=N` | device | |
| POST | `/ws-ticket` | device | Mints a single-use ticket, 60 s TTL, for the stream below. |
| WS | `/stream?ticket=…` | ticket | Signal only — see [[Sync]]. |

Internals: `_next_server_seq`, `_apply_delta`, `_apply_game_player`, `_coerce_payload`.

### `app/routes/comments.py` — no prefix, tag `comments`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/comments/mvp` | **none** | Stateless. Anthropic path. IP rate limited. |
| POST | `/comments/zapzap-analysis` | **none** | Stateless. Pluggable provider. IP rate limited. 503 if the provider is unavailable, 422 on an invalid payload, 502 on an upstream error. |
| POST | `/groups/me/games/{game_id}/comments` | device | Group-scoped, budgeted. |
| GET | `/groups/me/games/{game_id}/comments` | device | |

Both stateless endpoints pass through `_enforce_ip_rate_limit`.

### `app/main.py`

`GET /health` → `{"status": "ok", "version": …, "llm": {"provider": …, "model": … | null,
"credentials": bool}}` (`HealthResponse` in `app/main.py`). The `llm` block is the ZapZap
provider as the process resolved it, built without calling the provider — `credentials` means
a key is set, never that the model can be called. Polled by the compose healthcheck every 30 s
and asserted by §4 of the `backend-deploy` skill; `deploy_nas.sh` only prints the URL
(`scripts/deploy_nas.sh:71`), it never requests it.

It answers **200 even when the LLM is misconfigured** — an unknown `LLM_PROVIDER` yields
`"model": null` rather than a 5xx. Failing the probe would restart-loop a container whose
group and sync routes are healthy. See [[LlmProviders]].

## Decisions & History

- **The two stateless comment endpoints have no auth on purpose** — they predate groups and
  let the mobile app call the analysis without an account. The cost control is IP rate
  limiting alone (5/min, 30/h), which is process-local memory and therefore **requires a
  single uvicorn worker in production**. See [[Deployment]].
- **`share_token` ships only from create, join and rotate.** `GET /groups/me` and
  `PATCH /groups/me/settings` return `GroupPayload`; the three endpoints where the caller
  is explicitly asking for a share link return `GroupWithShareToken`. Re-sharing a group is
  therefore a deliberate act, not a side effect of a routine read.

  > **Status: Outdated** (2026-09-09) — `GET /groups/me` used to return `share_token`.
- **`POST /groups` and `/groups/join` are IP rate limited** (`GROUP_RL_PER_MINUTE` 3,
  `GROUP_RL_PER_HOUR` 10) in a bucket of their own, so group spam cannot consume the LLM
  quota. On `/join` the same limit is what caps `share_token` guessing: a 201 and a 404
  tell a valid token from an invalid one.
- **The stream is authenticated by ticket, not by the device token.** The ticket is
  redeemed before `websocket.accept()`, so an unauthenticated peer cannot make the server
  do work. See [[Sync]] and [[Security]].
- **`/push` caps at 500 deltas** while the client design drains the outbox in batches of
  100, leaving headroom without letting one request become unbounded.
