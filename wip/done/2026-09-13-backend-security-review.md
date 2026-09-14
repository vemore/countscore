# Backend security review — 2026-09-13: scope and what was found fine

**Status:** done (2026-09-13) — the review itself. Its findings were filed one by one; the
closed ones are in `wip/done/ARCHIVE-2026-09.md` (sync scoping, the argon2 scan, `server_seq`,
`X-Forwarded-For`, the ZapZap proxy, revocation, WebSocket connections, budget, Dockerfile),
the open ones in `wip/todo/` under theme `backend-hardening`.

- **Noted:** 2026-09-13 — a cyber-security review of `backend/` requested by the user
- **Theme:** backend-hardening
- **Area:** backend

The three HIGH items were confirmed by proof-of-concept tests on the SQLite fixtures
(`backend/tests/conftest.py`); the PoC file was not committed because it asserted the
*presence* of the flaws, and each fix inverted it into a regression test.

Checked and found fine, so nobody re-audits them: SQL parameterised throughout; CORS an
explicit list with credentials off; body cap with 411 on chunked; security headers and CSP;
secrets in env only, none in git history (grepped for `sk-ant-`, `AKIA`, `AIza`); the database
not published; the API bound to `127.0.0.1`; the WS ticket redeemed before `accept()`; the PWA
mount refusing traversal; argon2 on device tokens; `share_token` kept out of routine reads.
Everything the 2026-09-09 audit closed was re-checked and held.
