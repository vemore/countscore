# TODO

Open work only. A finished item moves to `DONE.md` — see the workflow section of
`CLAUDE.md`.

## `_snack` hardcodes `Colors.green` / `Colors.red`

**Status:** open — noted 2026-09-11, while fixing the section-header colours in the same file.

`lib/screens/settings_screen.dart:28-33` picks its snackbar background from
`ok ? Colors.green : Colors.red` — the same theme-blindness just fixed four lines below, in the
section headers. Saturated red and green sit badly on the dark theme's surfaces and ignore the
scheme entirely.

The analysis screen's new failure snackbar uses `Theme.of(context).colorScheme.error`, so the
two now disagree about what a failure looks like. The fix is `colorScheme.error` /
`onError` for the failure case and `colorScheme.primary` (or a tertiary) for the success one,
across the six `_snack` call sites. Not folded into the header fix because it changes the look
of every settings confirmation, not just a label colour.

## Group management beyond joining and leaving

**Status:** open — noted 2026-09-13, deliberately out of scope for the sync client (decided
with the user).

The server has endpoints the app does not use: `GET/PATCH /groups/me` (comment style,
language, LLM budget), `GET /groups/me/usage`, the group-scoped comments, and revoking
*another* device (`POST /groups/me/devices/{id}/revoke`). The last one has no way to list
devices first, so a lost phone can only be shut out by rotating the invite code and — once
the backend review's MEDIUM *Revocation is reversible* item lands — by revoking it. Proposed,
in order of value: a `GET /groups/me/devices` endpoint (id, label, joined, last seen) and a
device list in Settings → Group with a revoke action; then group settings. Per-field LWW
(`field_versions`, see `.llmwiki/Sync.md`) belongs to the same "v2 of groups" conversation.

## The two-device sync test does not run in CI

**Status:** open — noted 2026-09-13, while writing `test/sync/sync_two_devices_test.dart`.

That test is the only one that exercises the client against the real server contract, and it
is skipped unless `SYNC_BACKEND_URL` is set, so CI never runs it. The `backend` job already
starts a Postgres through testcontainers. Proposal: a CI job with a `postgres:17` service,
`alembic upgrade head`, uvicorn in the background with a raised group rate limit, then
`SYNC_BACKEND_URL=… flutter test test/sync/sync_two_devices_test.dart` — the recipe in
`.llmwiki/Testing.md`, *Group sync against a local backend*.

## Backend security review — 2026-09-13

**Status:** open — noted 2026-09-13, during a cyber-security review of `backend/` requested
by the user. The two HIGH items on sync scoping and the argon2 scan, and the `server_seq`
race, were closed the same day by `fix/sync-contract` and moved to `DONE.md`; the
`X-Forwarded-For` spoof and the open ZapZap proxy by `fix/ip-spoofing-zapzap-payload`; the
revocation, WebSocket-connection and budget items by `fix/budget-ws-revocation`. Nothing else
below was fixed; the items are ordered by severity, each with the evidence and the
proposed fix. The three HIGH items were **confirmed by running
proof-of-concept tests** against the project's own SQLite fixtures (`tests/conftest.py`);
the PoC file is not committed because it asserts the *presence* of the flaws — the results
quoted below are the acceptance criteria to invert when each fix lands. Everything the
2026-09-09 audit closed (`DONE.md`) was re-checked and holds; the debt it left open is
still in `.llmwiki/Security.md` and is not repeated here.

Checked and found fine, so nobody re-audits them: SQL parameterised throughout; CORS is an
explicit list with credentials off; body cap with 411 on chunked; security headers and CSP;
secrets in env only, and none in git history (grepped for `sk-ant-`, `AKIA`, `AIza`); the
database not published; the API bound to `127.0.0.1`; the WS ticket redeemed before
`accept()`; the PWA mount refusing traversal; argon2 on device tokens; `share_token` kept out
of routine reads.


### LOW — No rate limit on authenticated writes; the raw payload is persisted and replayed

> **Partly done** (2026-09-13, `fix/sync-contract`) — `change_log.payload` now holds only the
> payload's known client columns (`_logged_payload` in `sync.py`), never unknown keys nor
> `id`/`group_id`/timestamps. The per-device limiter on `/sync/push` and the `list_comments`
> bound are still open.

`/sync/push` stores `delta.payload` verbatim in `change_log` (`sync.py:291`), unknown keys
included, up to 256 KiB per request and 500 deltas, and `/sync/pull` serves it back to every
member. A member can bloat the NAS disk and every sibling device. Proposed: persist only the
coerced, known columns; a per-device limiter on `/sync/push` (reuse `check_and_increment`
with a scope of its own). Also `list_comments` (`backend/app/routes/comments.py:349`) takes
`limit: int = 10` unbounded — a negative value is a Postgres error and a 500:
`Query(ge=1, le=100)`.

### LOW — Hardening bundle

None of these is exploitable on its own; together they are the usual production checklist.

- `/docs`, `/redoc` and `/openapi.json` are public in production, under a CSP that allows
  `'unsafe-inline'`: `docs_url=None` unless an `EXPOSE_DOCS` setting is true.
- `backend/Dockerfile` runs as root, keeps `build-essential` in the final image, and
  installs from `pyproject.toml` — not from `uv.lock`, which only CI honours
  (`uv sync --locked`), so production resolves its own dependency set. Multi-stage build,
  a `USER`, and `uv sync --locked --no-dev`.
- No dependency vulnerability scan anywhere: a `pip-audit` (or `uv` equivalent) step in
  `.github/workflows/ci.yml` and a `.github/dependabot.yml`.
- `AsyncOpenAI` and `AsyncAnthropic` are built without a timeout (600 s by default) while
  the app gives up after 90 s: pass `timeout=90`, as `bedrock.py` already does.
- `f"invalid payload: {e}"` (`comments.py:141`) echoes internal key names to the client, and
  `logger.warning("... %s", e.orig)` in `sync.py:181` writes driver error text containing
  user data — newlines included — to the log. Generic detail out; sanitise before logging.
- The daily backups (`./backups`, plain gzip) hold every live `share_token`: say so in
  `.llmwiki/Deployment.md`, or encrypt them.

## The commit hook ignores git worktrees

**Status:** open — noted 2026-09-13, while committing `fix/sync-contract`.

`.claude/hooks/guard-bash.sh:16` resolves the repository as `$CLAUDE_PROJECT_DIR` first,
then `cd "$ROOT"` (`:41`) for every check and every gate. `CLAUDE_PROJECT_DIR` is the
directory the session was launched in and stays so after `EnterWorktree`. So a `git commit`
run inside a worktree is judged on the **main checkout's** branch — here another session's
merged, remote-deleted branch, so the commit was refused as "stale" — and, had it passed,
`flutter test` / `pytest` would have run against the main checkout's files, not the ones
being committed. Two sessions on one repository therefore cannot use worktrees to stay out
of each other's way, which is exactly what worktrees are for; the work had to wait for the
other session and then move back into the main checkout.

Proposal: resolve `ROOT` from the command's own working directory — `git -C "<cwd of the
command>" rev-parse --show-toplevel`, taking the cwd from the hook payload (or from a
leading `cd <dir> &&` that `parse_command.py` already tokenises) — and fall back to
`CLAUDE_PROJECT_DIR` only when that fails. Add a case to `scripts/hooks_selftest.sh` that
commits from a worktree whose branch differs from the main checkout's.

## `alembic check` reports drift that predates the sync contract

**Status:** open — noted 2026-09-13, while validating `0002_sync_contract` on Postgres.

After `alembic upgrade head` on a fresh Postgres 17, `alembic check` still reports four type
differences between the models and the DDL, none of them from `0002`: `change_log.id`,
`change_log.client_lamport` and `change_log.server_seq` are `BIGINT` in
`alembic/versions/0001_initial.py` but plain `int` fields in `app/models/change_log.py`, and
`comments.content` is `TEXT` in the DDL but an `AutoString` in `app/models/comment.py`. The
database is the wider type in every case, so nothing is lost today — but `alembic revision
--autogenerate` will propose narrowing them, and the test suite (which builds the schema
from the models) runs on the narrower types. Fix: give those four fields an explicit
`sa_column` matching the DDL, then make `alembic check` a CI step on the Postgres job so
drift fails the build instead of surfacing in a hand check.

## `shared_preferences_android` still applies the Kotlin Gradle Plugin

**Status:** open — noted 2026-09-09, during the Flutter 3.47 upgrade.

Every Android build now prints:

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
shared_preferences_android
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

Nothing to do on our side — it needs an upstream release that migrates to AGP's built-in
Kotlin. Watch the `shared_preferences` changelog; this becomes a hard build failure on some
future Flutter, not on 3.47.2.

## The web e2e recipe assumes a matching `chromedriver` on the PATH

**Status:** open — noted 2026-09-13, while running the web e2e for the drift worker refresh.

`.llmwiki/Testing.md` says "`chromedriver --port=4444 &`" and that its major version must
match Chrome. On the development machine there is no `chromedriver` on the PATH; the copy
under `~/cft/` is 145 while Chrome is 153, so the recipe fails as written. It took a manual
lookup in the Chrome for Testing `known-good-versions-with-downloads.json` and a download of
the matching `chromedriver-linux64.zip` into the session scratchpad to run the suite.

Proposal: a small `scripts/chromedriver.sh` that reads `google-chrome --version`, fetches
the matching Chrome for Testing driver into a cache directory if absent, and starts it on
4444 — and point the Testing recipe (and `.claude/rules/web.md`) at it instead of a bare
`chromedriver`.

---

## Surfaced during the LLM-wiki migration

**Status:** open — noted 2026-09-09, while decomposing `CLAUDE.md` and `ARCHITECTURE.md`
into `.llmwiki/`. None of these were introduced by that change; they were found by reading
the whole tree at once. Background for each lives in the wiki page named alongside it.

### Smaller, self-contained

- **`test/widget_test.dart` pumps no widgets.** Its 8 tests are model serialisation. The
  name implies widget coverage that does not exist anywhere in the repo — rename it, or
  give it real widget tests.
- **The Drift repositories are raw SQL.** `drift_repositories.dart` uses `customSelect` /
  `customInsert` throughout, a faithful port of the sqflite queries. That was the right
  call for a safe migration, but the type-safe-query argument for adopting Drift is still
  unbanked. Converting the simplest repositories first would prove the pattern.
