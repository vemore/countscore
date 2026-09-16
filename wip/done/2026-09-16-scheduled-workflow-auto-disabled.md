# The weekly CI run, now the only thing auditing uv.lock on a quiet week, can be disabled silently

**Status:** done (2026-09-16) — closed by `chore/scheduled-run-freshness`.
`scripts/check_scheduled_runs.sh` asks GitHub for the state of `ci.yml` and `deps.yml`
(`disabled_inactivity` is GitHub's own name for the 60-day rule) and for the age of each
one's newest `schedule`-event run, against a threshold per workflow — 10 days for the
weekly, 40 for the monthly, since one window would cry wolf at `deps.yml` every month.
`.claude/hooks/session-start.sh` runs it at most once a day, because the moment the cron is
found off is the moment the repository comes back to life; it is silent when healthy and
silent when it cannot ask (no `gh`, unauthenticated, origin not GitHub, no answer under
`timeout`), and banks no day in that case. Its answers are pinned offline in
`scripts/hooks_selftest.sh` against a stubbed `gh`.

**The "cheaper alternative" below was not taken.** GitHub's documentation says a scheduled
workflow is disabled when no **repository activity** has occurred in 60 days, and says
nowhere that a scheduled run is itself such activity. Moving the cron to daily therefore
rests on an unverified premise, and would have replaced a gap that can be detected with one
that cannot.

- **Noted:** 2026-09-16 — adding the `scope` job to `.github/workflows/ci.yml`
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

`pip-audit` is a step of the `backend` CI job and the only dependency scan that *fails a
build* in this project — Dependabot alerts, on since 2026-09-16, notify but gate nothing
(`2026-09-16-dependabot-alerts-disabled.md`). It used to re-run on every
pull request, documentation included, purely because every job ran on every pull request.
Since the `scope` job it runs only when a change touches `backend/`, and the weekly
`schedule:` trigger (`cron: "17 6 * * 1"`) is what caps the exposure window at seven days.

That trigger is fragile in a way nothing here notices:

- GitHub **disables a scheduled workflow after 60 days with no repository activity**, and
  re-enabling it is a manual click. This repository goes quiet between releases.
- A scheduled run's failure is an email to the owner and a red run in the Actions tab. There
  is no pull request in front of it, so no hook and no check blocks on it.

So the audit can stop running without anything going red.

(2026-09-16) **A second workflow is now exposed to the same thing.**
`.github/workflows/deps.yml` — the monthly `flutter pub upgrade` that also refreshes the
committed `web/` binaries (`chore/web-binaries-and-lock-freshness`) — is scheduled and
nothing else triggers it, so the 60-day clock silently stops it too, and its own
`schedule:` activity is the only thing resetting it. Whatever check this entry grows has to
cover both workflows, not just `ci.yml`.

**Fix:** make the absence detectable rather than trusting the trigger. Either a `Stop`-hook
or `release-android` §3 check that the newest `schedule`-event run of `ci.yml` is younger
than ~10 days (`gh run list --workflow=ci.yml --event schedule --limit 1 --json createdAt`),
or a `workflow_dispatch` of the full matrix as a step of the release procedure. Cheaper
alternative if the cron is kept as the only line of defence: move it to daily
(`"17 6 * * *"`) — still free on a public repository — so the 60-day clock is reset by the
workflow's own activity.
