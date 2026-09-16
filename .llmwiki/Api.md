# API

> Scope: the HTTP and WebSocket surface. Source of truth is `backend/app/routes/`.
> Related: [[Backend]] · [[Sync]] · [[LlmProviders]] · [[Security]]
> Updated: 2026-09-16

## Facts

`/docs`, `/redoc` and `/openapi.json` serve the generated OpenAPI only with `EXPOSE_DOCS=true`
(off by default, so off in production); otherwise they are 404.

### `app/routes/groups.py` — prefix `/groups`, tag `groups`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `` | none | Create a group + its first device. 201. IP rate limited. |
| POST | `/join` | none | Join via `share_token`. 201. IP rate limited. |
| GET | `/me` | device | Returns the group. **No `share_token`** — see below. |
| PATCH | `/me/settings` | device | 422 when `monthly_budget_cents` exceeds the operator's `MAX_BUDGET_CENTS` (unset: `DEFAULT_BUDGET_CENTS`) — members may lower their budget, not raise it past that. |
| GET | `/me/usage` | device | Budget consumption. |
| GET | `/me/devices` | device | The group's **active** devices, oldest first: `{"devices": [{id, label, joined_at, last_seen_at}]}`. Revoked devices are left out; no token or hash. Feeds Settings → Group → Devices. |
| POST | `/me/devices/{device_id}/revoke` | device | Another device: revokes it **and rotates `share_token`**, 200 with `GroupWithShareToken` — the revoked device learnt the old token when it joined. Again on a revoked device: the current token, no new one. The caller's own id: leaving (`GroupProvider.leave`), 204, no rotation. |
| POST | `/me/rotate-share-token` | device | Invalidates the old share link. Returns `share_token`. |

### `app/routes/sync.py` — prefix `/sync`, tag `sync`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/push` | device | Max **500 deltas** per request. Values bounded per entity. Serialised per group (row lock); one savepoint per delta. **429** + `Retry-After` past `SYNC_PUSH_RL_PER_MINUTE` / `_PER_HOUR` (60 / 1200) calls per device — in-memory, keyed by device id. |
| GET | `/pull?since_seq=N` | device | |
| POST | `/ws-ticket` | device | Mints a single-use ticket, 60 s TTL, for the stream below. |
| WS | `/stream?ticket=…` | ticket | Signal only — see [[Sync]]. 1008 on a bad ticket or a revoked device; 1013 past `MAX_STREAMS_PER_DEVICE` (3) open streams; 1012 when the shared LISTEN connection drops. |

Internals: `_apply_delta`, `_apply_game_player`, `_owned_by`, `_check_parents`,
`_check_unique`, `_was_deleted`, `_coerce_payload`, `_logged_payload`.

Entity types: `player`, `game_type`, `game`, `game_player`, `round`, `score`,
`game_analysis`. Per-delta status: `applied`, `merged_lww`, `duplicate`, `rejected`. A
rejected delta carries a `reason`; the conflict codes a client branches on are constants at
the top of `app/routes/sync.py`:

| Reason | When |
|---|---|
| `not in group` | The entity uuid exists and belongs to another group |
| `parent_missing` | A named parent (`game_id`, `round_id`, `player_id`, `game_type_id`) is absent or in another group — the two are indistinguishable on purpose |
| `round_number_taken` | Another live round of the game has that number |
| `score_exists` | Another live score exists for that player and round |
| `name_taken` | Another live player (normalised name) or game type (name) of the group |
| `builtin_key_taken` | Another live game type of the group already claims that `builtin_key` |
| `analysis_exists` | The game already has another live analysis |
| `integrity constraint violation` | Anything the pre-checks missed, e.g. a NOT NULL column absent on create |

Bounds failures keep their prose (`value out of bounds (…)`, `comment longer than 500
characters`, …) — see `app/services/delta_bounds.py`.

Device tokens are `<device id hex>.<secret>` (`app/auth.py`). `require_device` runs at most
one argon2 verify; a client address over `AUTH_FAIL_RL_PER_MINUTE` / `_PER_HOUR` failed
checks gets **429** before any hashing.

### `app/routes/comments.py` — no prefix, tag `comments`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/comments/mvp` | **none** | Stateless. Anthropic path. IP rate limited. |
| POST | `/comments/game-analysis` | **none** | Stateless. Any game type, nine voices, ten languages. Pluggable provider. IP rate limited (429). 503 if the provider is unavailable **or rate-limited upstream** (the latter with `Retry-After: 60` and the detail `upstream LLM rate-limited`, `app/routes/comments.py`), 422 on a wrong shape or a count out of bounds (`GameAnalysisPayload`: 1–12 players, ≤ 200 rounds, ≤ 10 history entries per player, thresholds within ±1 000 000; long text is clipped, player names filtered, and an unknown `style`, `language` or condition enum is corrected — never refused), 502 on any other upstream error. |
| POST | `/comments/zapzap-analysis` | **none** | The same handler under its former name, `include_in_schema=False`, sharing one IP-rate-limit bucket. Kept for a published app talking to a backend its owner has not upgraded. |
| POST | `/groups/me/games/{game_id}/comments` | device | Group-scoped, budgeted. |
| GET | `/groups/me/games/{game_id}/comments` | device | `limit` 1–100 (default 10), 422 outside. |

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

### The PWA — `GET $PWA_BASE_PATH/…`

When `PWA_BASE_PATH` is set (e.g. `/countscore`), `create_app` mounts the Flutter web build
from `PWA_DIR` there, **after** every API route (`_mount_pwa` in `app/main.py`). GET/HEAD
only (405 otherwise), no auth, `html=True` so `…/` answers `index.html`; the bare prefix
redirects to the trailing slash. A missing build folder is a **404, not a 500** (`_PwaFiles`
skips StaticFiles' one-off directory check), and a folder swapped in by
`scripts/deploy_web.sh` is served without a restart. A prefix whose first segment matches
an API route (`/groups`, `/sync/app`, `/health`, `/docs`…) refuses to start — the docs paths stay reserved
even with `EXPOSE_DOCS` off, so turning them on cannot break a deploy that started. Covered by
`tests/test_pwa.py`.

## Decisions & History

- **An upstream quota is a 503, not a 429 and not a 502 (2026-09-13).** On 2026-09-11 the
  Mistral account ran out of quota and every client saw "HTTP 502", the code for "something
  broke upstream". Providers now raise `LLMRateLimitedError` (`app/services/llm/base.py`) on an
  OpenAI-compatible `RateLimitError` or a Bedrock `ThrottlingException` /
  `ServiceQuotaExceededException`, and the route answers 503 + `Retry-After`. Not 429: that
  code already means *this client* hit our per-IP limit, and the two call for different
  reactions. The detail stays generic, so no provider name or message reaches the client.
  The app words every 503 as "temporarily unavailable, try again later"
  (`analysisErrorUnavailable`).

- **The analysis route was renamed and the old name kept (2026-09-16).** It answers for
  every game type now, in nine voices and ten languages, so `zapzap-analysis` had become
  actively misleading — it will serve Belote in Japanese. Two stacked decorators on one
  handler cost a line and mean a self-hosted backend, upgraded on its owner's schedule,
  never breaks an app that updated first; the app covers the other direction by retrying the
  old path on a 404. See [[LlmProviders]].
- **An unknown `style` or `language` is corrected, not refused (2026-09-16).** They are
  cosmetic fields on a route whose only client is the app. A 422 there would cost a user
  their analysis because their phone and their server disagree about a spelling, which is
  precisely the situation the two paths above exist to survive.
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
  tell a valid token from an invalid one. The IP is the proxy's `X-Real-IP`, believed from the
  trusted proxy, never a header the client wrote — see [[Security]].
- **The stream is authenticated by ticket, not by the device token.** The ticket is
  redeemed before `websocket.accept()`, so an unauthenticated peer cannot make the server
  do work. See [[Sync]] and [[Security]].
- **`/push` caps at 500 deltas** while the client design drains the outbox in batches of
  100, leaving headroom without letting one request become unbounded.
