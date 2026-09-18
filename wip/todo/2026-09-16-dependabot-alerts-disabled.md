# `pub` has no vulnerability gate in CI, only Dependabot alerts on the repository

- **Noted:** 2026-09-16 — reviewing what dependency updates were available
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

As first noted, `gh api repos/{owner}/{repo}/dependabot/alerts` answered
`403 Dependabot alerts are disabled for this repository`. `.llmwiki/Testing.md` claimed the
opposite — that alerts covered the Flutter dependencies, which have no scanner of their own.
The alerts have since been turned on; see *Half done* below. What stood at the time:

| Ecosystem | Version updates | Vulnerability scanning |
|---|---|---|
| `uv` (backend) | `.github/dependabot.yml`, weekly | `pip-audit --strict` in the `backend` CI job |
| `pub` (app) | `.github/dependabot.yml`, weekly | **nothing** |
| `github-actions` | `.github/dependabot.yml`, weekly | **nothing** |

So a CVE in a Flutter dependency reaches nobody: Dependabot's *version* updates are not
security updates, they only happen to carry the fix if someone merges the weekly pull request
before it matters — and they never cover a transitive package at all
(`2026-09-16-pubspec-lock-never-refreshed.md`).

## Half done (2026-09-16)

**The alerts are on.** Enabled the same day from GitHub → Settings → Advanced Security,
together with the *Dependency graph* they require — both had been off since the repository
was created. The endpoint that answered `403 Dependabot alerts are disabled for this
repository` now answers `[]`: enabled, no open advisory on any ecosystem. The table above is
therefore out of date in its third column; `pub` and `github-actions` now get advisories,
they still get no gate.

*Dependabot security updates* — the setting that turns an alert into a pull request — was
deliberately left off. A security bump should arrive on the normal weekly schedule, reviewed
like any other, rather than as an extra automated pull request.

**What is left, and why the entry stays open:** an alert notifies, it does not fail a build,
and a repository setting can be switched off again without leaving a trace in git. The
durable half is a CI gate symmetric to the backend's `pip-audit`: an OSV scan of
`pubspec.lock` in the `app` job, failing on any advisory, with the same `--ignore-vuln <ID>`
+ `wip/` entry escape. `osv-scanner` reads `pubspec.lock` natively; `dart pub audit` does not
exist (checked: `Could not find a subcommand named "audit" for "dart pub"`).

**Changed (2026-09-18, refinement):** the repository's Dependabot alerts are on since #62.
What is left is the gate: nothing in CI fails on an advisory against `pubspec.lock`
(`pip-audit` covers the backend only).

**Fix:** an `osv-scanner` step on `pubspec.lock` in the `app` job.

**Acceptance:**
- The `app` CI job runs an OSV scan of `pubspec.lock` and fails on any advisory.
- Ignoring an advisory takes `--ignore-vuln <ID>` plus a `wip/` entry that names it.
- `scripts/ci_scope.sh` runs that job when `pubspec.lock` changes.
- `.llmwiki/Testing.md` shows the `pub` gate next to `pip-audit`.
