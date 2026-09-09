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
| Rate limiting | Per device, per group budget, and per IP. |
| Body size | `limit_body_size` middleware, 413 above `MAX_BODY_BYTES` (262144). |
| Backups | Daily `pg_dump`, 7-day rotation. |

### Known debt — open, and deliberate for now

- **`device_token` travels in the WebSocket query string** (`/sync/stream?token=…`), because
  browsers cannot set headers on a WebSocket handshake. It therefore lands in server logs.
- **`POST /groups` and `POST /groups/join` have no rate limit at all** — group creation is
  free to spam.
- **`GET /groups/me` returns `share_token`**, so any member device can re-share the group.
- **No validation bounds on score and round values.** A client can push absurd numbers.
- **No security headers** (HSTS, CSP, X-Content-Type-Options) are set by the app.
- **The two stateless `/comments` endpoints are unauthenticated and unbudgeted**, protected
  only by an in-memory per-IP limit that a single worker makes coherent — see [[Api]].
- **Argon2 verification is O(N) in devices** — one verify per row. See [[KnownLimits]].

## Decisions & History

- **No tool use in any LLM call** is a security control, not a capability decision: if a
  prompt injection gets through the other four layers, the worst outcome is one strange
  comment rather than a database action.
- **Player names are validated at storage, not at prompt time.**
  `length BETWEEN 1 AND 32` and `^[\p{L}\p{N} \-''.]+$` — filtering at the boundary means
  every later consumer, prompt included, gets clean input.
- **No email/password auth.** For family scorekeeping it is attack surface without a
  matching benefit; per-device tokens give revocation and an audit trail, which were the
  actual requirements.
- **This list is published rather than quietly carried.** Each item is a considered
  trade-off at the current scale (a handful of devices, one household). Re-evaluate every
  one of them before any public or multi-tenant launch.
