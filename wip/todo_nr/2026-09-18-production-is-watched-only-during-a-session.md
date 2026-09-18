# Production is only watched while a Claude session happens to be open

- **Noted:** 2026-09-18 — comparing the project's SDLC with Anthropic's "The AI-native SDLC
  playbook" (claude.com/blog/the-ai-native-sdlc-playbook)
- **Theme:** process-evals
- **Area:** backend
- **Blocks release:** no

Every check on production runs inside a session: the smoke test after a deploy
(`ship-parallel` §4), and `session-start.sh`, which watches the scheduled CI workflows but not
the service. The compose healthcheck polls `GET /health` every 30 s (`.llmwiki/Api.md`), but
only restarts the container; nobody hears about it. A backend or PWA outage between two
sessions is found by the next person to open the app. Acceptable while the user is prod's
only user (multi-day outages accepted, 2026-09-14), less so once anyone else is.

The playbook closes the loop with a deterministic watcher — no model in the detection — that
turns a breach into an `intent.md` for a human to triage.

**Fix:** a scheduled GitHub workflow (hourly or daily) that requests `/health` and the PWA's
`index.html`, and on failure opens a GitHub issue (or commits a `wip/todo/` entry through a
pull request) with the status code and the time. The production host must come from a
repository secret, never from the repository (`CLAUDE.md`: never commit a real deployment
host). Check first that the host is reachable from GitHub's runners. Add the workflow to
`scripts/check_scheduled_runs.sh`, since a cron GitHub disables goes silent. Later, not now:
a model diagnosing the failure in read-only mode.
