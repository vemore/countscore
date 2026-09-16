# Dependabot alerts are disabled, so no ecosystem gets security advisories pushed to it

- **Noted:** 2026-09-16 — reviewing what dependency updates were available
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

`gh api repos/{owner}/{repo}/dependabot/alerts` answers
`403 Dependabot alerts are disabled for this repository`. `.llmwiki/Testing.md` claimed the
opposite until this entry was written — that alerts covered the Flutter dependencies, which
have no scanner of their own.

What actually stands today:

| Ecosystem | Version updates | Vulnerability scanning |
|---|---|---|
| `uv` (backend) | `.github/dependabot.yml`, weekly | `pip-audit --strict` in the `backend` CI job |
| `pub` (app) | `.github/dependabot.yml`, weekly | **nothing** |
| `github-actions` | `.github/dependabot.yml`, weekly | **nothing** |

So a CVE in a Flutter dependency reaches nobody: Dependabot's *version* updates are not
security updates, they only happen to carry the fix if someone merges the weekly pull request
before it matters — and they never cover a transitive package at all
(`2026-09-16-pubspec-lock-never-refreshed.md`).

**Fix:** turn the alerts on — GitHub → Settings → Advanced Security → Dependabot alerts (and
the dependency graph they need). It is a repository setting, not a file, so no pull request
can do it; reading it back through `gh` needs the `admin:repo_hook` scope, which this
checkout's token does not have.

Because a setting can be switched off again without leaving a trace in the repository, the
durable half is a CI gate symmetric to the backend's: an OSV scan of `pubspec.lock` in the
`app` job, failing on any advisory, with the same `--ignore-vuln` + `wip/` entry escape as
`pip-audit`. `osv-scanner` reads `pubspec.lock` natively; `flutter pub audit` does not exist.
