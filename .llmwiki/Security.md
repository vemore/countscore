# Security

> Scope: what is defended, and what is knowingly open.
> Related: [[Backend]] · [[Api]] · [[LlmProviders]] · [[Deployment]] · [[KnownLimits]]
> Updated: 2026-09-19

## Facts

### Defended surfaces

| Surface | Measure |
|---|---|
| Device token on the client | `flutter_secure_storage`: Android Keystore; on web, encrypted in localStorage. Never in the database, SharedPreferences or an export (`lib/services/sync/sync_credentials.dart`). |
| `device_token` | `<device id hex>.<secret>`, 128 bits of secret. Stored argon2-hashed server-side; one verify per request, failures capped per IP. |
| `share_token` | uuid4, rotatable. Unused once a device has joined. Shown in Settings → Group so it can be passed on; kept in secure storage on the device. |
| `ANTHROPIC_API_KEY`, AWS keys | Environment only, never logged, never bundled in the APK. |
| TLS | Synology Web Station, integrated Let's Encrypt. |
| Prompt injection | 5 layers — see [[LlmProviders]]. |
| SQL injection | SQLModel/asyncpg parameterised throughout; no string concatenation. |
| CSRF | Stateless API with a bearer token, so not applicable. |
| CORS | Explicit origin whitelist in `config.py`; `*` is rejected at startup. |
| Rate limiting | Per device, per group budget, and per IP — including group create/join. `/sync/push` has its own per-device limit (`SYNC_PUSH_RL_*`, in-memory bucket `sync_push`). The IP is `request.client.host`, which `TrustedProxyMiddleware` (`app/services/trusted_proxy.py`) sets from `X-Real-IP` only when the peer is in `TRUSTED_PROXY_IPS` (the pinned compose gateway, see [[Deployment]]). `X-Forwarded-For` is read by nothing: Web Station passes it through as the client wrote it. `backend/tests/test_ip_rate_limit.py`. |
| Analysis payload | `GameAnalysisPayload` (`app/schemas/comments.py`): 422 on a wrong shape or a count out of bounds (12 players, 200 rounds, 10 history entries, thresholds ±1 000 000); text clipped, player names filtered through the sync allow-list. `style`, `language` and the two condition enums are normalised to a known value instead of refused — see [[Api]]. The **game-type name** now drives a section of the prompt rather than one data line, so it is escaped, wrapped in `<game_type>`, stripped of newlines and of a leading `#`, and named by the anti-injection rule alongside `<player_name>`. |
| Body size | `limit_body_size` middleware, 413 above `MAX_BODY_BYTES` (262144); 411 when `Content-Length` is absent on a write. |
| WebSocket auth | Single-use ticket from `POST /sync/ws-ticket`, 60 s TTL. `app/services/ws_ticket.py`. |
| WebSocket cost | One shared LISTEN connection for all streams (`app/services/notify.py`), at most `MAX_STREAMS_PER_DEVICE` (3) streams per device — a member can no longer exhaust Postgres connections. See [[Sync]]. |
| LLM budget | Only the group owner sets `monthly_budget_cents` (403 for any other member), and only up to the operator's `MAX_BUDGET_CENTS` (unset: `DEFAULT_BUDGET_CENTS`). `backend/tests/test_groups.py`. |
| Group owner | `groups.owner_device_id`: the creator, until it hands over (`PUT /groups/me/owner`) or leaves (the earliest-joined live device inherits). Only the owner may revoke another device, rotate `share_token` or hand over — 403 for any other member, checked under the group's row lock. `backend/tests/test_groups.py`. See [[Api]]. |
| Revocation | Only the owner revokes another device ([[Api]]). Revoking another device rotates `share_token`, so the revoked device cannot rejoin with the token it learnt when joining. Its open `/sync/stream` is closed (1008) before the next frame it would receive — a push signal or the idle heartbeat (`app/routes/sync.py:_serve_stream`, `tests/test_sync_stream_cap.py`, `tests/test_sync_ws_integration.py`). |
| Sync payload values | Per-entity bounds in `app/services/delta_bounds.py`, enforced before write. |
| Security headers | `security_headers` middleware in `app/main.py:main`; HSTS behind `HSTS_ENABLED`. API responses get `default-src 'none'`; `/docs` a Swagger CSP, and only exists with `EXPOSE_DOCS=true`; paths under `PWA_BASE_PATH` get `_PWA_CSP` (`'self'` for scripts, fonts and everything else — no third-party host, CanvasKit and the fallback fonts being served from the build — plus `'wasm-unsafe-eval'` and `connect-src 'self' https: wss:`) plus `Cache-Control: no-cache`. |
| Container | `backend/Dockerfile`: multi-stage, `USER app` (uid 10001), code and venv owned by root, no compiler, dependencies exactly `uv.lock` (`--locked --no-dev`). Checked by the `image` CI job. See [[Deployment]]. |
| PWA static files | Read-only bind mount; Starlette `StaticFiles` rejects traversal out of `PWA_DIR`; `deploy_web.sh` refuses a build containing any `.md`. |
| Backups | Daily `pg_dump`, 7-day rotation, encrypted with `age` to a public key whose private half is kept off the server (`backend/backup/countscore-backup.sh`). The sidecar refuses to dump without `BACKUP_AGE_RECIPIENT`. See [[Deployment]] *Backups*. |

### Disclosure — what the app admits to sending, and to whom

[[Release]] and `wip/done/ARCHIVE-2026-09.md` point here for "what those declarations would have to disclose",
so it is stated once, here, and the compliance documents are written from it.

| Question | Answer, and where it is verified |
|---|---|
| What leaves the device | One request, `POST /comments/game-analysis`, built in `lib/screens/game_analysis_screen.dart` `_generate`: game name and date, player **names**, every round's scores and free-text **comment**, per-player history of up to 10 *other* games (`drift_repositories.dart`), and three fields that are app configuration rather than user content — the chosen `style`, the display `language`, and the game type's scoring rules. |
| When | Only once the user has configured a backend in Settings → Server **and** taps Generate. There is no default URL, so an install that has never been configured makes no network request at all. Nothing is sent on launch, on a timer, or in the background; `initState` only reads the local cache. |
| To whom | The backend whose URL the user entered — usually one they run themselves from `backend/` — and then the provider that backend's `LLM_PROVIDER` selects: AWS Bedrock, Google Gemini or Mistral (`backend/app/services/llm/factory.py`). The provider sees essentially the whole payload, rendered by `app/services/analysis/`. The recipient is the operator's choice, not ours. |
| Kept where | Nowhere on the backend's side: the route takes no `session` and writes no row. The per-IP counter is process memory only. The device keeps its own copy in `game_analyses` until the user deletes it. At the provider, whatever that provider's retention policy says — which we do not control, and which is why the Play declaration does not claim the ephemeral-processing exemption. |
| Declared as | Personal info → Name, and App activity → Other user-generated content. Both optional, App functionality, not linked to identity, not used for tracking. `PLAY_STORE_DATA_SAFETY.md`. |
| Permission it needs | `INTERNET`, and only that, in `android/app/src/main/AndroidManifest.xml`. That manifest also points at `res/xml/network_security_config.xml`. |

The rule that keeps this true is in [[Documentation]]: a new outbound flow — a new field in this
payload included — changes `README.md`, `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md`
in the same commit, or it is not finished.

### Cleartext, and where the rule actually lives

`android/app/src/main/res/xml/network_security_config.xml` sets
`cleartextTrafficPermitted="true"`, which reads alarming and is not what it looks like.
Android's network security config matches **host names**, not address ranges, so the rule
that was wanted — `http://` on a LAN, `https://` everywhere else — cannot be written in that
file at all. `BackendProvider.check` (`lib/providers/backend_provider.dart`) enforces it
instead: an `http://` URL whose host is not private or loopback is refused before it can be
stored, so no cleartext request is ever issued even though the platform would permit one.
Covered by `test/providers/backend_provider_test.dart`.

A user-entered URL is a user-controlled request destination, which is normally an SSRF
concern. It is not one here: the request originates on the user's own device, targets the
server they chose, and carries no credential of ours.

### Known debt — open, and deliberate for now

The four items found by the 2026-09-13 review are **not** deliberate; they are open
because they were found after the 2026-09-09 hardening. Proposed fixes, evidence and the
proof-of-concept results are in `wip/done/2026-09-13-backend-security-review.md`; what is still open is in `wip/todo/` (`scripts/wip.sh list`, theme `backend-hardening`).

- **`POST /sync/push` is not group-scoped.** `app/routes/sync.py:152` finds an entity by
  UUID alone and then overwrites it and reassigns its `group_id` to the caller's group;
  `round` and `score` have no `group_id` and their parent ids are written unchecked. A
  revoked device knows every UUID of its former group, so revocation protects nothing.
  Confirmed by a proof of concept: rename, steal, attach a round, tombstone — all `applied`.

  > **Status: Outdated** (2026-09-13) — fixed by `fix/sync-contract`. Entities are refused
  > with `not in group` unless owned by the caller's group (rounds and analyses through the
  > game, scores through round and game), and every parent a payload names must be in the
  > group (`parent_missing`). Regression tests: `backend/tests/test_sync_contract.py`.
- **The per-IP limit is spoofable** through `X-Forwarded-For`: `client_ip()` took the
  *first* hop, which the client writes. A rotating header passed 20 group creations
  through a 3-per-minute limit.

  > **Status: Outdated** (2026-09-13) — fixed by `fix/ip-spoofing-zapzap-payload`: the app
  > reads no header, and uvicorn trusts only the pinned gateway `172.28.87.1`, keeping the
  > hop Web Station appended. Regression tests in `backend/tests/test_ip_rate_limit.py`.

  > **Status: Outdated** (2026-09-13) — that fix did not hold in production: Web Station does
  > not set `X-Forwarded-For`, so uvicorn believed the client's. Replaced by
  > `fix/trust-x-real-ip`: `--no-proxy-headers`, and `X-Real-IP` believed from the gateway only.
- **The argon2 scan is a CPU denial of service, not only a scaling limit.** One verify
  (30 ms) per device row for any bearer token, valid or not, with no rate limit on 401s;
  combined with free group creation the single worker can be kept saturated.

  > **Status: Outdated** (2026-09-13) — fixed by `fix/sync-contract`: the token names its
  > device, so a request costs at most one verify, a junk token costs none, and failures
  > are capped per IP (`backend/tests/test_auth.py`), on the unspoofable `client_ip()`.
- **`/comments/zapzap-analysis` takes an unvalidated `dict`.** No field bounds, no name
  allow-list, none of the five injection layers below apply to it — with the per-IP limit
  bypassable it is an open LLM proxy on the operator's key.

  > **Status: Outdated** (2026-09-13) — fixed by `fix/ip-spoofing-zapzap-payload`: a
  > `ZapZapPayload` schema bounds every count and clips every string; names go through the
  > sync allow-list as a filter. The endpoint is still unauthenticated and unbudgeted —
  > the per-IP limit is its only cost control. `backend/tests/test_game_analysis.py`.


- **Backups are plain gzip and hold every `share_token` (2026-09-14).** Anyone who reads a
  daily dump can join every group. Documented for operators, with the recovery step (rotate
  every invite code), in [[Deployment]] *Backups*; encryption is open in `wip/todo/2026-09-13-encrypt-backups.md`.

  > **Status: Outdated** (2026-09-14) — closed by `feat/encrypted-backups`: dumps are
  > `.dump.gz.age`, encrypted to `BACKUP_AGE_RECIPIENT`, and the sidecar refuses to write one
  > without it. The debt that remains is the private key: whoever holds it reads every group.
- **Nothing pins the certificate or the identity of the configured backend.** The user
  types a URL and the app trusts the system trust store for it. Deliberate: a self-hosted
  service cannot be pinned in advance.
- **The two stateless `/comments` endpoints are unauthenticated and unbudgeted**, protected
  only by an in-memory per-IP limit that a single worker makes coherent — see [[Api]].
- **Argon2 verification is O(N) in devices** — one verify per row on every authenticated
  HTTP request. The WebSocket handshake no longer pays it. See [[KnownLimits]].

  > **Status: Outdated** (2026-09-13) — O(1) since `fix/sync-contract`; see above.
- **Every device in a group is equal.** There is no owner role on `Device`, so any member
  can rotate the share token or revoke a sibling device. Full lateral privilege within a
  group, which matches the household model but not a public one. Since a revoke rotates the
  share token, the members who stay hold a stale invite link until they rotate it again
  (`GET /groups/me` never returns the token).
  Since 2026-09-14 the app puts that privilege on screen: Settings → Group → Devices lets any
  member remove any other, and shows every member each device's name and last-seen time.
  Only the member who revoked gets the new code; the others see theirs stop working for
  invitations. An owner role is the change to make before a public launch.

  > **Status: Outdated** (2026-09-18) — closed by `feat/group-owner`: the group has an owner
  > (`groups.owner_device_id`, revision `0005_group_owner`), and only it may revoke a sibling,
  > rotate the share token or hand the role over; every other member gets a 403 and the app
  > hides those actions from it. What stays open to every member: leaving, reading the device
  > list, and the comment style and language through `PATCH /groups/me/settings`. The budget
  > became the owner's too on 2026-09-18 (`feat/group-budget-owner-only`): it is spent on the
  > operator's key.
  > The members who stay after a revoke still hold a stale invite code until the owner shares
  > the new one.
- **In-memory state ties the service to one worker.** `ip_rate_limiter`, `ws_ticket`, the
  per-device stream counter and the LISTEN broker all live in process memory; horizontal scaling needs them moved to Redis or Postgres
  first. See rule 2 in `backend/CLAUDE.md`.

## Decisions & History

- **The device id travels inside the device token (2026-09-13).** The alternative kept the
  opaque format and added an indexed SHA-256 lookup column. Putting the id in the token was
  chosen because no client had ever stored a token, so the format was free to change, and
  it needs no second hash to keep in step with the argon2 one. The id is not a secret —
  every member pulls it as `origin_device_id` — so exposing it costs nothing.

- **Second review, 2026-09-13.** The whole of `backend/` was read again after the PWA
  deploy, this time asking what an attacker holding a former device or no credential at
  all could do. The three HIGH findings were confirmed by proof-of-concept tests run on the
  SQLite fixtures, not committed — a test that asserts a flaw is present would be red the
  day the flaw is fixed. Nothing was changed in the code: the user asked for the findings
  and the proposed fixes in `TODO.md` (now `wip/done/2026-09-13-backend-security-review.md` and the entries it names), and the fixes are each a change of their own.
- **The PWA's CSP allows `connect-src https:` (2026-09-13).** The backend URL is a user
  setting, so a PWA served by one backend may legitimately be pointed at another; pinning
  `connect-src` to `'self'` would break that with nothing but a console line. Scripts stay
  pinned to `'self'` and `www.gstatic.com`, which is what an XSS would need. Measured, not
  guessed: a `--base-href=/countscore/` release build served by uvicorn under this policy
  loaded CanvasKit, the Roboto fallback font and the Drift worker with no violation, and
  persisted a game across a reload.

  > **Status: Outdated** (2026-09-19) — `www.gstatic.com` and `fonts.gstatic.com` left the
  > policy: `scripts/build_web.sh` serves CanvasKit and the fallback fonts from the build, so
  > scripts and fonts are `'self'` alone.
- **No Google host in the PWA's CSP (2026-09-19).** Every visitor's browser used to fetch
  CanvasKit from `www.gstatic.com` and fonts from `fonts.gstatic.com`, a flow no privacy
  document named. Self-hosting them (`--no-web-resources-cdn`, the engine's fallback fonts
  mirrored at build time) made the README's claim true instead of disclosing the flow, and
  narrowed `script-src` to `'self'` — one less origin an XSS could load code from. Verified
  in Chromium under the new policy, fr/zh/ar/hi locales, from load to a game created with a
  CJK-and-emoji player name: every request to the serving host, no CSP violation.
  `wip/done/2026-09-19-pwa-gstatic-undisclosed.md`.

- **Nine voices did not widen the disclosure, and the regression test grew to match
  (2026-09-16).** `style` and `language` are app configuration, not user content and not
  personal data, so the declared Data Safety categories are unchanged — the descriptive
  sentence in all three privacy documents was still rewritten, because the rule in
  [[Documentation]] is about the flow, not about the categories. What did widen is the
  output surface: nine voices, several adversarial by design. The "stay about the game,
  never about a person's attributes" line lives once in the shared contract rather than
  nine times in the persona blocks, and `test_no_prompt_names_a_real_person` now runs over
  the whole nine-by-ten matrix of composed prompts, with the denylist extended to the real
  figures one is tempted to write a commentator or a detective "in the style of".

- **The ZapZap system prompt no longer names anyone (2026-09-13).** It used to hard-code
  eight first names and a reputation for each, so those names reached the third-party
  provider on every request, whoever was playing — undisclosed, because the compliance
  documents describe what leaves the *device* and this text never was on it. The section
  and the "favourite player" line were removed rather than moved to per-group configuration:
  the players and their history already arrive in the payload, which the user chose to send.
  `test_no_prompt_names_a_real_person` keeps it that way. None of the three privacy
  documents described the prompt's content, so none needed a change.

- **The default is no backend at all (2026-09-11).** The URL used to be compiled in, so the
  published app sent every requested analysis to the author's NAS. Making it a setting with
  no default turns the strongest privacy claim — nothing leaves the device — from a
  description of what most users happen to do into the actual shipped default, and it lets
  anyone run the service themselves. See [[LlmProviders]] and [[Deployment]].
- **No tool use in any LLM call** is a security control, not a capability decision: if a
  prompt injection gets through the other four layers, the worst outcome is one strange
  comment rather than a database action.
- **Player names are validated at storage, not at prompt time.**
  `length BETWEEN 1 AND 32` and `^(?:\p{L}\p{M}*|\p{N}|[ \-'.])+$` — filtering at the
  boundary means every later consumer, prompt included, gets clean input. The allow-list is
  applied by `is_valid_player_name` in `backend/app/models/player.py`, called from the sync
  apply path; `PLAYER_NAME_REGEX` beside it is the written spec, since `\p{L}` needs the
  third-party `regex` module the project does not depend on. Combining marks (`\p{M}`) are
  accepted only right after a letter or another accepted mark — they are what "रवि" or
  "محمَّد" are written with, and a mark standing alone carries no injection vector. The app
  mirrors the rule in `isSyncablePlayerName` (`lib/services/sync/sync_ids.dart`).

  > **Status: Outdated** (2026-09-13) — until this date the rule was `^[\p{L}\p{N} \-'.]+$`,
  > which refused every combining mark, so Hindi and Arabic players could not be shared.

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
