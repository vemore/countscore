# Hooks

> Scope: the Claude Code hooks that enforce project rules mechanically, and the reasoning
> that used to live in `CLAUDE.md`.
> Related: [[Web]] · [[I18n]] · [[Testing]] · [[Backend]] · [[KnownLimits]]
> Updated: 2026-09-13

## Facts

### What is configured

`.claude/settings.json` declares four handlers. The scripts are in `.claude/hooks/`; the
`hooks` key merges across settings levels, so `.claude/settings.local.json` (permissions)
is untouched by it.

| Event | Matcher | Script | What it does |
|---|---|---|---|
| `PreToolUse` | `Bash` | `guard-bash.sh` | Refuses three commands outright; runs the gates before a commit |
| `PostToolUse` | `Edit\|Write` | `guard-gitignore.sh` | Refuses a `.gitignore` that starts ignoring the two web binaries |
| `PostToolUse` | `Edit\|Write` | `check-arb-sync.sh` | Reports ARB key drift as context — never blocks |
| `SessionStart` | — | `session-start.sh` | Says whether the clone needs codegen and whether the branch is safe |
| `Stop` | — | `require-pull-request.sh` | Refuses to end the turn while finished commits have no pull request, or while that pull request is red |

`session-start.sh` also reports any pull request merged in the last 14 days whose base was
not `main` and whose commits are not on `main` — work that merged into a dead-end branch.
Acknowledge one that reached `main` another way with
`git config --add countscore.deliveryAcknowledged <number>`.

`parse_command.py` and `arb_keys.py` are helpers, not handlers.
`scripts/hooks_selftest.sh` exercises all of them from a table of ~57 cases and runs as the
first step of the `app` job in `.github/workflows/ci.yml`.

### What is refused, and on what evidence

| Rule | Evidence used |
|---|---|
| `flutter build <target>` without `--no-tree-shake-icons` | tokenised command; `--help` and a bare `flutter build` produce no artifact and pass |
| Deleting or moving `web/sqlite3.wasm`, `web/drift_worker.js`, or `web/` itself | each argument resolved against a notional cwd that follows `cd`; copies under `build/` pass |
| A `.gitignore` matching either binary | `git check-ignore --no-index`, one path per call |
| Committing a keystore, `key.properties` or a `.env` | staged path list; `*.template` and `.env.example` pass |
| Committing on `main`, on a detached HEAD, or on a stale branch | `%(upstream:track)` = `[gone]`, then `git cherry origin/main HEAD` |
| Committing with red gates | `flutter analyze`, `flutter test` if app paths are involved; `ruff check`/`ruff format --check`/`mypy`/`pytest -m 'not integration'` if `backend/` is |
| Committing divergent ARB files, or a stale `app_localizations*.dart` | key sets against the template from `l10n.yaml`, then `flutter gen-l10n` |
| Ending a turn with commits that no pull request covers, whose pull request was closed unmerged, or whose checks are failing | `gh pr list --head <branch> --state all`, then `gh pr checks` |
| `gh pr create --base <anything but main>` | the parsed `--base` argument; unlocked per repository by `countscore.allowStackedPr` |

The path set that decides which gates run is a union, not `git diff --cached` alone:
`git commit -a` stages tracked changes *after* the hook has read the index, so `--cached`
would report nothing and the filter would conclude "documentation only". `--amend` adds
`HEAD`'s files, and trailing pathspecs are added too. The gates are project-wide anyway, so
a superset costs seconds and never blocks wrongly.

### What the hooks do not cover

- **Anything a `Bash` command writes.** `PostToolUse` does not fire when a shell command
  rewrites a file, so the two post-edit handlers are a convenience. The guarantee is the
  commit-time check in `guard-bash.sh`.
- **`git merge`, `git rebase --continue`, `git revert`, `git cherry-pick`,** and any commit
  made inside a script invoked as `bash scripts/foo.sh`: the hook only sees the command
  string it was given.
- **`git checkout` / `git restore` / a `Write` overwriting the web binaries** — only
  removal and gitignoring are guarded. `web/CLAUDE.md` still states the rule.
- **A stale `*.g.dart`.** `session-start.sh` only notices when *no* generated file exists.
  This is why the codegen rule stays in `CLAUDE.md`.
- **Freshness of `origin/main`.** The hooks never fetch: no network in a hook. Everything
  they know about a branch is as old as the last `git fetch --prune`, so they err towards
  letting a stale branch through — which is why that command stays in `CLAUDE.md`.
- **Pushing and opening.** `require-pull-request.sh` reads GitHub, never writes to it: it
  asks for the pull request, it does not create one. Publishing is an outward-facing act
  and stays deliberate. It also stays silent when `gh` is absent or unauthenticated, when
  the origin remote is not GitHub, and on a branch carrying
  `git config branch.<name>.noPullRequest true` — the escape hatch for work deliberately
  held back.
- **Hard enforcement generally.** A hook whose script is missing or non-executable exits
  127, which does not block; a hook that times out does not block either. They reduce a
  class of mistake, they do not make it impossible.

## Decisions & History

- **Why hooks at all (2026-09-09).** Every rule listed above was previously prose in
  `CLAUDE.md`, enforced only by re-reading the file, and `.github/workflows/ci.yml` caught
  the failures after a push. The rules that a script can decide were moved to scripts; the
  rules that need judgement — never hardcode a user-facing string, keep `README.md` true,
  the three privacy documents, `TODO.md` → `DONE.md` — stayed in `CLAUDE.md` because a
  heuristic guard that cries wolf is worse than the prose.
- **Why the tree-shaker flag is not optional.** Game-type icons are `IconData` built from
  codepoints stored in the database (`.llmwiki/MobileApp.md`), so Flutter's icon
  tree-shaker cannot see those references and the build fails. It costs roughly 200 KB.
- **Why a parser rather than a `grep`.** Splitting on `&&` and `;` and matching substrings
  produced a false positive on every quoting case — a `git commit -m "flutter build apk"`,
  an `echo`, and above all a heredoc body documenting a forbidden command, which made the
  guard fire on the file that documents it. `.claude/hooks/parse_command.py` strips heredoc
  bodies, tokenises with `shlex`, segments on operators, and follows `cd`. A command it
  cannot parse yields no refusal (a guard that blocks what it cannot read is worse than the
  risk) but is assumed to be a commit (a skipped gate is a silent regression).
- **Why `[gone]` and not just `git cherry` (2026-09-09).** `CLAUDE.md` described a branch
  whose merged pull request the remote deleted. Under a squash merge, N commits become one
  upstream commit with a different patch-id, so `git cherry` shows no `-` line and would
  have missed exactly the case it was written for. `%(upstream:track)` = `[gone]` survives
  a squash; `git cherry` is kept as a second signal, and catches a deliberate cherry-pick
  from `main` too — the check cannot tell the two apart and says so when it refuses.
- **Why the ARB check does not block on edit.** Adding one string means ten edits, and the
  key sets are legitimately divergent after edits one through nine. A blocking
  `PostToolUse` tells the model its last edit was rejected, and inviting it to undo good
  work would make the `i18n-add-string` skill unusable. It reports progress instead, and
  the refusal happens once, at commit time.
- **Why no `flutter gen-l10n` after each ARB edit.** Ten regenerations for one useful
  result, nine of them writing an `app_localizations_*.dart` that reflects an intermediate
  state — and `generate: true` in `pubspec.yaml` already regenerates on `pub get`, `run`,
  `test` and `build`. The commit-time check runs it once and refuses if the committed
  generated files would be stale.
- **Why the gates are cheap enough to block on.** Measured warm on the development machine:
  `flutter analyze` 3.2 s, `flutter test` 3.6 s, `ruff` 0.1 s, `mypy` 1.6 s,
  `pytest -m 'not integration'` 6.7 s.
- **Why a `Stop` hook for the pull request (2026-09-09).** A commit that never becomes a
  pull request is not delivered: nobody reviewed it, CI never ran on it, and it is
  invisible to everyone but the machine that holds it. `Stop` is the only event that fires
  when the work is plausibly finished. It blocks at most once per turn — `stop_hook_active`
  in the payload marks the retry, and the hook stands down then, so a turn can always end.
  Failing checks block too, on the same reasoning: a red pull request is not a delivered
  change. Both `gh` calls are wrapped in `timeout` so a slow network cannot hang a session.
- **Why stacked pull requests are refused (2026-09-09).** PR #3 was opened with
  `--base docs/privacy-disclosure` while that branch was under review. The parent merged
  first, rebased, so `main` took a snapshot from before the child existed; the child then
  merged into its base — a branch whose content was already on `main` under different
  hashes — and its own work arrived nowhere. Both pull requests read as merged and green.
  It cost a fourth pull request to repair. The guard refuses the shape rather than trying
  to police merge order, which is the user's action and not observable from here. The
  session-start check is the net for the same failure arriving another way; it asks GitHub
  to compare rather than git, because the merge commit of a deleted branch may not exist
  in the clone at all.
- **Why the pull-request check asks for every state (2026-09-09).** The first version
  asked only for *open* pull requests. The moment one was merged, the branch still carried
  commits ahead of a local `origin/main` that had not been fetched since, and no open pull
  request answered for them — so the hook blocked the end of every turn, on work that was
  in fact delivered. It now reads the state: merged is silence, closed-unmerged is a
  refusal of its own, open falls through to the checks. The states are exercised offline
  through a stubbed `gh` in `scripts/hooks_selftest.sh`, which is what the first version
  lacked: its only GitHub-dependent cases were skipped wherever `gh` was unauthenticated,
  so the one answer it had never seen was the one that broke it.
- **Why the self-test is in CI.** The interesting cases are the ones that look like a
  violation and are not. Without a table exercised on every push, the first rule change
  breaks a guard silently — and a broken guard is indistinguishable from a passing one.
- **The `ruff format` refusal was lifted (2026-09-13).** It existed so that formatting 47
  files would not ride along inside a functional diff. The user judged that it did not
  justify refusing the command: it forced a formatter, which is safe to run, to go through a
  manual `!` step, and it would have kept refusing to format new code once the debt was
  paid. Formatting is now enforced the other way round: `ruff format --check .` is a
  commit-time gate and a CI step, so unformatted code is refused rather than the formatter.
