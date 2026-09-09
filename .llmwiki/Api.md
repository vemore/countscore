# API

> Scope: the HTTP and WebSocket surface. Source of truth is `backend/app/routes/`.
> Related: [[Backend]] · [[Sync]] · [[LlmProviders]] · [[Security]]
> Updated: 2026-09-09

## Facts

`/docs` serves the generated OpenAPI when the server is running.

### `app/routes/groups.py` — prefix `/groups`, tag `groups`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `` | none | Create a group + its first device. 201. |
| POST | `/join` | none | Join via `share_token`. 201. |
| GET | `/me` | device | Returns the group, including `share_token`. |
| PATCH | `/me/settings` | device | |
| GET | `/me/usage` | device | Budget consumption. |
| POST | `/me/devices/{device_id}/revoke` | device | 204. |
| POST | `/me/rotate-share-token` | device | Invalidates the old share link. |

### `app/routes/sync.py` — prefix `/sync`, tag `sync`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/push` | device | Max **500 deltas** per request. |
| GET | `/pull?since_seq=N` | device | |
| WS | `/stream?token=…` | device | Signal only — see [[Sync]]. |

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

`GET /health` → `{"status": "ok", "version": …}`. This is what `deploy_nas.sh` checks.

## Decisions & History

- **The two stateless comment endpoints have no auth on purpose** — they predate groups and
  let the mobile app call the analysis without an account. The cost control is IP rate
  limiting alone (5/min, 30/h), which is process-local memory and therefore **requires a
  single uvicorn worker in production**. See [[Deployment]].
- **`GET /groups/me` returns `share_token`.** Convenient for showing a share link, but it
  means any device in the group can re-share it. Logged as known debt in [[Security]].
- **`POST /groups` and `/groups/join` are not rate limited at all.** Open debt — see
  [[Security]].
- **`/push` caps at 500 deltas** while the client design drains the outbox in batches of
  100, leaving headroom without letting one request become unbounded.
