# Large pull requests go straight to production, with no staging and gates run twice

**Status:** done (2026-09-14) — closed by chore/merge-safety. Size: `ship-parallel` §3 step 1
counts changed lines outside generated, lock and binary files and needs the user's go-ahead
above 1 500. Staging: not built (user decision — sole production user, daily dumps exist);
instead CI runs upgrade / `downgrade base` / upgrade / `check`, and `deploy_nas.sh` writes an
encrypted `premigration_*` dump before any pending revision, which `backend-deploy` §5
restores to undo a schema change. Gates run twice: implemented by fix/hooks-gates
(`flutter test` and `pytest` leave the commit hook, CI keeps them).

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

Three related gaps in the path from branch to production:

- **Size.** `ship-parallel` §1 caps a pull request at "roughly a day of work", but nothing
  checks it: #21 (+6.9 k lines, 64 files) and #10 (+2 k lines, 56 files) went through, and #21 needed
  six fix pull requests the same day.
- **No staging.** Every merge touching `backend/` is deployed to the NAS production container,
  Alembic migrations included. `backend-deploy` §5 rolls the image back but not the schema: a
  bad migration needs a hand-written `alembic downgrade`, verified on production data.
- **Gates run twice.** `guard-bash.sh` runs `flutter test`, analyze and the backend gates at
  commit time, then CI runs them again on push — which is why the last 80 CI runs have no
  failure. The local run is the slow part of each agent's loop.

**Fix:** have the orchestrator refuse to merge above a threshold (e.g. 1 500 changed lines
outside generated files and `web/` binaries) without the user's go-ahead; run
`alembic upgrade head` then `alembic downgrade -1` then `upgrade` against a copy of the
production database before a migration deploys (a compose service in `backend-deploy`); and
consider scoping the commit-time gates to the fast ones (analyze, ruff, mypy), leaving the full
test suites to CI. UI coverage is a separate entry: `2026-09-09-widget-test-pumps-no-widgets.md`.
