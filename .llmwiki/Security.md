# Security

> Scope: what is defended, and what is knowingly open.
> Related: [[Backend]] · [[Api]] · [[LlmProviders]] · [[Deployment]] · [[KnownLimits]]
> Updated: 2026-09-09

## Facts

### Defended surfaces

| Surface | Measure |
|---|---|
| `device_token` | uuid4, 122 bits of entropy. Stored argon2-hashed server-side. |
| `share_token` | uuid4, rotatable. Unused once a device has joined. |
| `ANTHROPIC_API_KEY`, AWS keys | Environment only, never logged, never bundled in the APK. |
| TLS | Synology Web Station, integrated Let's Encrypt. |
| Prompt injection | 5 layers — see [[LlmProviders]]. |
| SQL injection | SQLModel/asyncpg parameterised throughout; no string concatenation. |
| CSRF | Stateless API with a bearer token, so not applicable. |
| CORS | Explicit origin whitelist in `config.py`; `*` is rejected at startup. |
| Rate limiting | Per device, per group budget, and per IP — including group create/join. |
| Body size | `limit_body_size` middleware, 413 above `MAX_BODY_BYTES` (262144); 411 when `Content-Length` is absent on a write. |
| WebSocket auth | Single-use ticket from `POST /sync/ws-ticket`, 60 s TTL. `app/services/ws_ticket.py`. |
| Sync payload values | Per-entity bounds in `app/services/delta_bounds.py`, enforced before write. |
| Security headers | `security_headers` middleware in `app/main.py:main`; HSTS behind `HSTS_ENABLED`. |
| Backups | Daily `pg_dump`, 7-day rotation. |

### Known debt — open, and deliberate for now

- **The two stateless `/comments` endpoints are unauthenticated and unbudgeted**, protected
  only by an in-memory per-IP limit that a single worker makes coherent — see [[Api]].
- **Argon2 verification is O(N) in devices** — one verify per row on every authenticated
  HTTP request. The WebSocket handshake no longer pays it. See [[KnownLimits]].
- **Every device in a group is equal.** There is no owner role on `Device`, so any member
  can rotate the share token or revoke a sibling device. Full lateral privilege within a
  group, which matches the household model but not a public one.
- **In-memory state ties the service to one worker.** `ip_rate_limiter` and `ws_ticket`
  both live in process memory; horizontal scaling needs them moved to Redis or Postgres
  first. See rule 2 in `backend/CLAUDE.md`.

## Decisions & History

- **No tool use in any LLM call** is a security control, not a capability decision: if a
  prompt injection gets through the other four layers, the worst outcome is one strange
  comment rather than a database action.
- **Player names are validated at storage, not at prompt time.**
  `length BETWEEN 1 AND 32` and `^[\p{L}\p{N} \-''.]+$` — filtering at the boundary means
  every later consumer, prompt included, gets clean input. The allow-list is applied by
  `is_valid_player_name` in `backend/app/models/player.py`, called from the sync apply
  path; `PLAYER_NAME_REGEX` beside it is the written spec, since `\p{L}` needs the
  third-party `regex` module the project does not depend on.

  > **Status: Outdated** (2026-09-09) — until this date the regex was declared but never
  > called anywhere, so only the length constraint was actually enforced. The claim above
  > now holds.
- **No email/password auth.** For family scorekeeping it is attack surface without a
  matching benefit; per-device tokens give revocation and an audit trail, which were the
  actual requirements.
- **This list is published rather than quietly carried.** Each item is a considered
  trade-off at the current scale (a handful of devices, one household). Re-evaluate every
  one of them before any public or multi-tenant launch.
- **The five items closed on 2026-09-09 were closed early, before the mobile sync client
  exists.** Nothing in `lib/` consumes `/groups` or `/sync` yet, so changing the WebSocket
  handshake and dropping `share_token` from `GET /groups/me` broke no shipped client. The
  same changes after the client ships would have needed a migration.
- **The WebSocket ticket also removed a CPU-amplification vector**, not just the token in
  the URL: the old handler called `websocket.accept()` before validating and then ran one
  argon2 verify per device row, so any unauthenticated peer could force that scan at will.
  The ticket is checked before the handshake is accepted.
- **`share_token` is returned only where a share link is being asked for** — create, join
  and rotate. `GET /groups/me` and `PATCH /groups/me/settings` no longer carry it, which
  makes re-sharing a deliberate act rather than a side effect of any routine read.
