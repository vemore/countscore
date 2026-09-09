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

### Disclosure — what the app admits to sending, and to whom

[[Release]] and `DONE.md` point here for "what those declarations would have to disclose",
so it is stated once, here, and the compliance documents are written from it.

| Question | Answer, and where it is verified |
|---|---|
| What leaves the device | One request, `POST /comments/zapzap-analysis`, built at `lib/screens/game_analysis_screen.dart:95-122`: game name and date, player **names**, every round's scores and free-text **comment**, and per-player history of up to 10 *other* games (`drift_repositories.dart:698-708`). |
| When | Only when the user taps Generate. Nothing is sent on launch, on a timer, or in the background; `initState` only reads the local cache. |
| To whom | Our backend, then the provider `LLM_PROVIDER` selects — AWS Bedrock, Google Gemini or Mistral (`backend/app/services/llm/factory.py`). The provider sees essentially the whole payload, rendered by `zapzap_prompt.py`. |
| Kept where | Nowhere on our side: the route takes no `session` and writes no row. The per-IP counter is process memory only. The device keeps its own copy in `game_analyses` until the user deletes it. At the provider, whatever that provider's retention policy says — which we do not control, and which is why the Play declaration does not claim the ephemeral-processing exemption. |
| Declared as | Personal info → Name, and App activity → Other user-generated content. Both optional, App functionality, not linked to identity, not used for tracking. `PLAY_STORE_DATA_SAFETY.md`. |
| Permission it needs | `INTERNET`, and only that, in `android/app/src/main/AndroidManifest.xml`. |

The rule that keeps this true is in `CLAUDE.md`: a new outbound flow — a new field in this
payload included — changes `README.md`, `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md`
in the same commit, or it is not finished.

### Known debt — open, and deliberate for now

- **The two stateless `/comments` endpoints are unauthenticated and unbudgeted**, protected
  only by an in-memory per-IP limit that a single worker makes coherent — see [[Api]].
- **Argon2 verification is O(N) in devices** — one verify per row on every authenticated
  HTTP request. The WebSocket handshake no longer pays it. See [[KnownLimits]].
- **Every device in a group is equal.** There is no owner role on `Device`, so any member
  can rotate the share token or revoke a sibling device. Full lateral privilege within a
  group, which matches the household model but not a public one.
- **The ZapZap system prompt names real people.** `backend/app/services/zapzap_prompt.py:52-59`
  hard-codes eight first names and a reputation for each into `ZAPZAP_SYSTEM_PROMPT`, so
  those names reach the third-party provider on **every** request, whoever is playing. The
  compliance documents do not cover it, because they describe what leaves the *device*. See
  `TODO.md`.
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
