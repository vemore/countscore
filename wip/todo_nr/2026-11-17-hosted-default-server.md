# The app does nothing connected until a user hosts a server

- **Noted:** 2026-11-17 — requested by the user
- **Theme:** hosted-instance
- **Area:** backend
- **Blocks release:** no

The connected features (groups, sync, AI analysis) are off until a user types a server URL in
Settings → Server (`lib/providers/backend_provider.dart`, no default). Few users will run a
backend, so most installs never see them. The request: a **second, public instance** of the
backend, behind Cloudflare, set as the app's default, with a limit on AI analyses.

This reverses a recorded decision — "the backend is the user's, not the developer's"
(2026-09-11, `.llmwiki/LlmProviders.md` and `.llmwiki/Security.md` Decisions & History) — and
the `CLAUDE.md` rule "never reintroduce a default". That decision was about the author's NAS
being compiled in silently; a public instance, disclosed and opt-in, is a different shape.

**Fix:**
- A second deployment, separate from the private NAS one (own database, own secrets, own
  `deploy.env`), reached only through Cloudflare (Tunnel, or a proxied DNS record with the
  origin firewalled to Cloudflare's ranges), with `TRUSTED_PROXY_IPS` and `X-Real-IP` replaced
  by `CF-Connecting-IP` for the IP rate limiter (`backend/app/services/ip_rate_limiter.py`).
- An analysis quota on that instance: per device per day/month, and a global monthly budget
  that switches analysis off when spent, with a localized "quota reached" message in the app.
- The app proposes the public server **on first use of a connected feature**, with an explicit
  consent screen, rather than contacting it silently; Settings → Server still accepts any URL.
- The URL is compiled in through a release-only define, never in the repository
  (`CLAUDE.md`: never commit a real deployment host).
- Documents: `README.md` Privacy, `privacy_policy.md`, `PLAY_STORE_DATA_SAFETY.md`, the wiki
  pages above, and the `CLAUDE.md` rule itself, all in the same change.

**Acceptance:**
- A fresh install with no consent makes no network request (`.llmwiki/Security.md` claim
  kept true until the user accepts).
- The (N+1)-th analysis of a device over its quota gets a 429 and the app shows the quota
  message.
- The public origin refuses a request that does not come through Cloudflare.

**Open question:** default-on or proposed-on-first-use; the quota figures and who pays the
LLM bill; where the second instance runs (the same NAS, or a VPS); whether groups and sync are
offered on it too, or only analysis.
