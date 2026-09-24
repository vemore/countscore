# API

> Scope: the HTTP and WebSocket surface. Source of truth is `backend/app/routes/`.
> Related: [[Backend]] · [[Sync]] · [[LlmProviders]] · [[Security]]
> Updated: 2026-09-24

## Facts

`/docs`, `/redoc` and `/openapi.json` serve the generated OpenAPI only with `EXPOSE_DOCS=true`
(off by default, so off in production); otherwise they are 404.

### `app/routes/groups.py` — prefix `/groups`, tag `groups`

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `` | none | Create a group + its first device. 201. IP rate limited. |
| POST | `/join` | none | Join via `share_token`. 201. IP rate limited. |
| GET | `/me` | device | Returns the group. **No `share_token`** — see below. Carries `owner_device_id` (null only when no device of the group is live): how the app learns whether it is the owner. |
| PATCH | `/me/settings` | device | `comment_style` and `comment_language`: every member. `monthly_budget_cents`: **owner only** (403 otherwise, whatever else the body carries — a refused request changes nothing), and 422 when it exceeds the operator's `MAX_BUDGET_CENTS` (unset: `DEFAULT_BUDGET_CENTS`) — the owner may lower the budget, not raise it past that. |
| GET | `/me/usage` | device | Budget consumption: `{current_month_used_cents, budget_cents, resets_at}`, US cents. `resets_at` is always in the future — the next month start, UTC: once the stored reset has passed, the read reports 0 spent and the next month start without waiting for a charge to roll it over (`budget.current_period`; `GET /me`'s `current_month_used_cents` too). Feeds Settings → Group → Comments and usage, with `GET /me` for the style and language. |
| GET | `/me/devices` | device | The group's **active** devices, oldest first: `{"devices": [{id, label, joined_at, last_seen_at, is_owner, dormant}]}`. `dormant` is `last_seen_at` older than `GROUP_OWNER_DORMANT_DAYS` (30) — stated per device because it is meaningful on any row, read by the app on the owner's, where it opens *Claim ownership*. Revoked devices are left out; no token or hash. Feeds Settings → Group → Devices. |
| PATCH | `/devices/me` | device | `{"label": …}`: **renames the calling device**, and nothing else: `devices.label`, trimmed, 1 to 64 characters (**422** otherwise, blank included). No device id in the path, so a device can only ever rename itself. Returns `{id, label}`. Not a synced row: no delta, the siblings see it on their next `GET /me/devices`. **429** + `Retry-After` past `DEVICE_RENAME_RL_PER_MINUTE` / `_PER_HOUR` (5 / 30) calls per device, in-memory bucket `device_rename`. `rename_my_device`, `tests/test_groups.py`. |
| POST | `/me/devices/{device_id}/revoke` | device | Another device: **owner only** (403 otherwise); revokes it **and rotates `share_token`**, 200 with `GroupWithShareToken` — the revoked device learnt the old token when it joined. Again on a revoked device: the current token, no new one. The caller's own id: leaving (`GroupProvider.leave`), open to every member, 204, no rotation; an owner that leaves hands the role to the earliest-joined live device (none left: `owner_device_id` null). |
| POST | `/me/rotate-share-token` | device | **Owner only** (403 otherwise). Invalidates the old share link. Returns `share_token`. |
| PUT | `/me/owner` | device | `{"device_id": …}`. **Owner only** (403 otherwise). Hands the owner role to a live device of the group — 404 for a revoked device or one of another group; naming itself is a no-op. Returns the group (`GroupPayload`), no `share_token`, no rotation. |
| POST | `/me/owner/claim` | device | **Any member.** Takes the owner role when the current owner has not been seen for `GROUP_OWNER_DORMANT_DAYS` (30) — **409** while it has, so the refusal is never confused with the 403 of an owner-only route. No owner, or a revoked one, counts as dormant. Claiming what one already owns is a no-op. Returns the group (`GroupPayload`), no `share_token`, no rotation. |

**The owner.** `groups.owner_device_id` (revision `0005_group_owner`) names the device that
created the group, until it hands over or leaves. The check and the change run under the
group's row lock (`_locked_group` in `app/routes/groups.py`), so two concurrent hand-overs or
a hand-over racing a revoke cannot both pass. `PATCH /me/settings` stays open to every
member for the comment style and language; its budget is the owner's, checked under the same
lock.

**An owner that goes dormant.** An uninstall sends no request, so neither the hand-over nor
the leave fires and the role would sit for ever on a device that never comes back.
`Device.last_seen_at`, refreshed on every authenticated request (`app/auth.py`), is the
signal: past `GROUP_OWNER_DORMANT_DAYS` unseen, any member may take the role with
`POST /me/owner/claim`, and a group down to a **single** live device is given to it on read
(`_heal_sole_device_owner`, applied by `GET /me` and `GET /me/devices`) — with one device
left there is nothing to decide. Both run under the same row lock. No schema change:
`devices.last_seen_at` has existed since `0001_initial`.

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
| POST | `/comments/game-analysis` | **none** | Stateless. Any game type, nine voices, ten languages. Pluggable provider. IP rate limited (429). 503 if the provider is unavailable **or rate-limited or overloaded upstream** — an OpenAI-compatible 429 or 5xx, a Bedrock throttling, quota, `ServiceUnavailableException` or `ModelNotReadyException` (the latter with `Retry-After: 60` and the detail `upstream LLM rate-limited`, `app/routes/comments.py`), 422 on a wrong shape or a count out of bounds (`GameAnalysisPayload`: 1–12 players, ≤ 200 rounds, ≤ 10 history entries per player, thresholds within ±1 000 000; long text is clipped, player names filtered, and an unknown `style`, `language` or condition enum is corrected — never refused), 502 on any other upstream error. |
| POST | `/comments/zapzap-analysis` | **none** | The same handler under its former name, `include_in_schema=False`, sharing one IP-rate-limit bucket. Kept for a published app talking to a backend its owner has not upgraded. |
| POST | `/groups/me/games/{game_id}/comments` | device | Group-scoped, budgeted: per-device rate limit (429), then the group's budget (**409** `monthly budget exhausted (…)`), then the game must be the group's and live (404). Two bodies (`GenerateCommentRequest`). **Without `analysis`**: the original comment — Anthropic path, prompt from the server's copy of the game, `style_override` (one of the three group styles) or the group's style; 503 when no Anthropic key. **With `analysis`** (since 2026-09-19): the analysis of a *shared* game — the very `GameAnalysisPayload` of `/comments/game-analysis`, through the pluggable provider, with the group's `comment_language` in place of the payload's and, when the payload has no `style`, the voice the group's style maps to (`persona_for_group_style`: narrative → documentary, humorous → professor, analytical → coach). Charged at `calculate_cost_cents` of the provider's tokens, ≥ 1¢ a call; stored as a `comments` row. 503 (+ `Retry-After: 60` when rate-limited upstream) and 502 as on `/comments/game-analysis`; nothing is charged on a failure. `backend/app/routes/comments.py` `_generate_group_analysis`, `tests/test_group_analysis.py`. 201 either way, `CommentPayload` (`style` is a group style or a voice key). |
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

- **A device names itself, and can rename itself (2026-09-24).** `feat/group-nickname-and-rename`:
  production held two live devices both called "Mon appareil", because the join and create
  dialogs pre-filled the name and everyone left it. The dialogs now ask for a nickname first,
  empty and required, and `PATCH /groups/devices/me` lets a device change it afterwards. The
  path names no device on purpose: there is nothing to authorise and no way to rename a
  sibling. It sits under `/groups/devices/me` as the wip entry specified it, beside the
  `/me/...` routes of the caller's group. Its own per-device bucket, like `sync_push`, so a
  rename loop cannot eat another route's quota. The `devices.label` column already existed:
  no migration.

- **A dormant owner can be replaced, by a deliberate claim (2026-09-20).** `feat/group-owner-claim`
  closed the one group failure with no way out: an owner that uninstalls sends no request, so
  the role never moves and the share token it left behind can never be rotated — a token that
  leaked stayed valid for ever. Three shapes were weighed (wip entry
  `2026-09-20-a-group-whose-owner-uninstalls-can-never-get-one-back.md`): automatic
  succession, a deliberate claim, a recovery code handed out at creation. The user chose the
  **claim**: automatic succession would take the role from a member merely on holiday, and a
  recovery code would add a secret to keep and to phish — the only one of the app's secrets
  that would ever leave a device. So the group decides rather than the clock, and the former
  owner's reinstall is just one more device that may claim it back. The window is a setting
  (`GROUP_OWNER_DORMANT_DAYS`, 30 days) because the right value is a guess: long enough that a
  holiday does not open a claim, short enough that a group is not stuck for a season. The
  degenerate case needs no claim at all — a group with a single live device is given to it on
  read. `Device.last_seen_at` already existed, so there is no migration.

- **A shared game's analysis is the group's (2026-09-19).** The group's comment style and
  language, editable in Settings → Group → Comments and usage, shaped nothing the app showed:
  only the group comment endpoint read them, and the app never called it, so usage stayed at
  zero whatever a member did. Refinement 6 decided the analysis of a shared game goes through
  that endpoint (`feat/group-comment-analysis`). The endpoint kept its path and gained an
  optional `analysis` body rather than a new route, so the old body still works; the
  analysis prompt stays the one `/comments/game-analysis` builds from the device's payload,
  because the device holds what the server's copy lacks (the players' history, the round
  comments as typed). The three group styles predate the nine voices, so they map to a voice
  instead of widening `PATCH /groups/me/settings`. The provider reports tokens, not money, so
  the charge uses the Anthropic path's rates as a notional price — a free-tier Gemini call
  costs the operator nothing, but the budget still meters use.

- **Usage reads apply the monthly roll-over (2026-09-19).** A new group's `budget_resets_at`
  was its creation time, and only `check_budget` rolled it to the next month start, when a
  comment was charged — so `GET /me/usage` showed a reset in the past and possibly a past
  month's spending. `fix/usage-resets-at-in-the-past` made `budget.current_period` the one
  rule, applied by the charge (which persists it under the group lock) and by the reads
  (which do not write), and a new group now starts with `budget_resets_at` at the next month
  start (a Python-side default: no migration).

- **The budget is the owner's; style and language are everyone's (2026-09-18).** The budget
  is the one group setting that costs the operator money, so `feat/group-budget-owner-only`
  put `monthly_budget_cents` behind the owner check. The comment style and language only
  change how comments read, so they stay open to every member. A non-owner sending a budget
  gets the 403 even over the cap: the cap is checked only for the owner.

- **Only the owner revokes, rotates or hands over (2026-09-18).** Until `feat/group-owner`
  every device of a group was equal, so any member could shut out any other or rotate the
  invite code — fine in a household, not before opening sharing to the public. The owner is
  the creator because that needs no new input; existing groups were given their
  earliest-joined live device, which is the creator wherever it has not left. Leaving stays
  open to everyone, and an owner that leaves passes the role on automatically, so a group
  with members never ends up with nobody able to revoke.
  > **Status: Incomplete** (2026-09-20) — only an owner that *leaves* passes the role on. An
  > owner that uninstalls never asks anything of the server, so the group did end up with
  > nobody able to revoke; `POST /groups/me/owner/claim` and the single-device heal are the
  > way back (see the 2026-09-20 decision above). No foreign key on
  `owner_device_id`: `devices.group_id` already points the other way, and a device row is
  only ever deleted with its group.

- **An upstream quota is a 503, not a 429 and not a 502 (2026-09-13).** On 2026-09-11 the
  Mistral account ran out of quota and every client saw "HTTP 502", the code for "something
  broke upstream". Providers now raise `LLMRateLimitedError` (`app/services/llm/base.py`) on an
  OpenAI-compatible `RateLimitError` or a Bedrock `ThrottlingException` /
  `ServiceQuotaExceededException`, and the route answers 503 + `Retry-After`. Not 429: that
  code already means *this client* hit our per-IP limit, and the two call for different
  reactions. The detail stays generic, so no provider name or message reaches the client.
  The app words every 503 as "temporarily unavailable, try again later"
  (`analysisErrorUnavailable`).
- **An upstream 503 "high demand" joins the same family (2026-09-18).** On 2026-09-16
  Gemini's free tier answered `503 UNAVAILABLE — high demand, try again later`; it arrived
  as `openai.InternalServerError`, fell through to the generic branch, and the user saw
  "HTTP 502". `OpenAICompatProvider` now maps `InternalServerError` (any 5xx) to
  `LLMRateLimitedError`, and Bedrock adds `ServiceUnavailableException` and
  `ModelNotReadyException` to its capacity codes; any other `OpenAIError` or `ClientError`
  still answers 502. No backoff was added: the analysis is user-initiated, so the
  Regenerate button is the retry and no connection is held open waiting.

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
