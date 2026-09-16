# CI runs all five jobs on every pull request, including one that only touches wip/

- **Noted:** 2026-09-16 — the user asked whether the CI is useful on a documentation-only PR
- **Theme:** ci-scope
- **Area:** tooling
- **Blocks release:** no
- **Status:** done

`.github/workflows/ci.yml` had no filter of any kind, so a pull request touching only
`.llmwiki/`, `wip/` or `README.md` started a `postgres:17-alpine`, compiled a debug APK and
built the release PWA: ~4 min 30 of wall clock and ~13 runner-minutes. Runner minutes are
free on a public repository, so the cost is latency and runner contention — `ship-parallel`
pushes four or five branches at once, and 5 jobs × 5 branches is past the 20-concurrent-job
ceiling of a free public repository. Replaying the last 20 merged pull requests through the
new classifier, **8 would have run nothing at all**.

The reason it had stayed that way was recorded twice — `.llmwiki/Testing.md` (2026-09-09) and
the Required-checks row of `.llmwiki/ParallelDelivery.md`: *"a filtered required check leaves
a doc-only pull request waiting forever"*. That is true of a **workflow-level `paths:`
filter**, and it is still true; it is not true of a **job-level `if:`**, which
[GitHub reports as Success](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/troubleshooting-required-status-checks)
when it skips. Both pages now say which is which.

**Fixed by** a `scope` job that classifies the pull request's changed files through
`scripts/ci_scope.sh` (a pure function, pinned by `scripts/ci_scope_selftest.sh`, 50 cases,
run as that job's first step), and a fail-safe `if:` on each of the five:
`${{ !cancelled() && needs.scope.outputs.<job> != 'false' }}` — a `scope` that fails, is
cancelled or writes nothing leaves the flag empty, and everything runs. An unclassified path
runs everything too. Branch protection is unchanged: the same five contexts, and `scope` is
deliberately not one of them (`.llmwiki/ParallelDelivery.md` says why).

A weekly `schedule:` run with every flag true was added in the same change, because
`pip-audit` — the only dependency scan that fails a build here; Dependabot alerts notify but
gate nothing — lives in the `backend` job and
used to be re-run incidentally by every documentation pull request
(`wip/todo_nr/2026-09-16-scheduled-workflow-auto-disabled.md` covers how that trigger can go
quiet). The `android` job is still triggered by every Dart change, which is why a `lib/`-only
pull request does not get faster (`wip/todo_nr/2026-09-16-android-job-on-every-dart-change.md`).
