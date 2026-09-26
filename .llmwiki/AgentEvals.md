# AgentEvals

> Scope: the local eval harness that checks agents still do the job after the agent
> configuration changes — what a case is, how it runs, when to run it, what it costs.
> Related: [[Hooks]] · [[Documentation]] · [[Release]] · [[ParallelDelivery]] · [[Testing]]
> Updated: 2026-09-26

## Facts

### What it checks, and what it does not

The hooks are tested as scripts (`scripts/hooks_selftest.sh`, [[Hooks]]); that says nothing
about whether an agent given a changed `CLAUDE.md`, skill, hook or wiki page still does the
task right. An eval replays a past task with `claude -p` on a throwaway worktree and judges
the outcome with a deterministic script: a skill reworded until it stops triggering, or a
pruned rule that was carrying weight, shows up as a failing case instead of a later pull
request going wrong. A case judges the *outcome* (files, commits), never the transcript.

### The cases

Two kinds, both listed by `evals/run.sh --list`:

- **Cross-cutting** — `evals/cases/<name>/`: `prompt.md` (the task), `check.sh`,
  `case.env` (the `wip/done/` source, `SETUP=app|none`, and whether an untouched tree should
  pass), an optional `setup.sh` that plants the problem, and `good.sh` / `bad.sh`, hand-made
  right and wrong outcomes. They cover the rules of `CLAUDE.md` and `wip/README.md`:
  `docs-only-wiki-fact` (a stale wiki count: fixed on its page and its `INDEX.md` row,
  both dated, README untouched), `close-wip-entry` (`git mv` to `wip/done/` with its
  `**Status:**` line), `out-of-scope-finding` (a planted hardcoded French label left alone
  and filed under `wip/`), `no-hardcoded-string` (new text only through `AppLocalizations`,
  ten ARB files passing `arb_keys.py --keys` and `--values`), `no-default-backend-url` (asked
  for a default server, the agent declines).
- **Per skill** — `.claude/skills/<skill>/evals/evals.json` in skill-creator's format
  (`skill_name`, `evals[]` with `id`, `prompt`, `expected_output`, `files`, `expectations`),
  so skill-creator's own benchmark and grader can use it; the script form of eval `<id>` is
  `.claude/skills/<skill>/evals/<id>/check.sh` (+ `good.sh`, `bad.sh`), and `run.sh` names
  it `<skill>/<id>`. Today: `i18n-add-string/1` (an ICU plural in ten locales) and
  `db-migration/1` (a nullable column: both schema versions bumped by one, a migration test).

A check is `check.sh <worktree> [<base>]`: read-only, offline, one line per assertion, exit 0
or 1; `<base>` defaults to the `eval fixture:` commit, so it can be rerun by hand on a kept
worktree. Shared helpers: `evals/lib.sh`. The work date is the last commit's, so a rerun on a
later day gives the same verdict.

### How a run is isolated

`evals/run.sh [case...]`, per case: a worktree under `$TMPDIR` off `--ref` (default
`origin/main`) on a branch `eval/<case>-<stamp>` with `noPullRequest` set and no upstream;
`setup.sh` and an `eval fixture:` commit; `scripts/worktree_setup.sh --no-backend` for app
cases; then `claude -p` with `evals/preamble.md` + the prompt, `--permission-mode dontAsk`,
`--setting-sources project` (the project's configuration is what is under test, not the
user's), a closed `--allowedTools` list (read, edit, `git add/mv/rm/commit`, the local
checks, `flutter gen-l10n/analyze/test`) and a `--disallowedTools` list (`git push`, `gh`,
`git remote/config/fetch/switch/worktree`, network tools, sub-agents). As a second fence the
agent's environment has no GitHub credentials and a `remote.origin.pushurl` that points at a
missing directory, and `run.sh` fails a case whose branch gained an upstream. Worktrees and
branches are removed on exit (`--keep` keeps them); logs, the agent's JSON result and the
check output go to the gitignored `evals/runs/`. It runs on the user's own Claude login: no
API key, no secret, no CI workflow (decided 2026-09-18).

Case files are read from the checkout that runs `run.sh`; the tree the agent works in is
`--ref`. To evaluate a branch's own configuration before it merges, commit it and pass
`--ref HEAD`.

### When to run it

- **After changing `CLAUDE.md`, `.claude/**` or `.llmwiki/**`** — the cases that touch
  what changed at least (`run.sh <case>`), from the branch with `--ref HEAD`, before the
  pull request merges.
- **In the pruning pass** before each release (`release-android` §3b): the whole suite on
  `origin/main`, and again with `--ref HEAD` on the pruning branch — a case that passes
  before and fails after is evidence that the removed rule was carrying weight.
- **After editing a check, a fixture or `evals/lib.sh`:** `evals/selftest.sh`, which needs
  no agent and costs nothing — every check must fail the untouched tree (or pass it, for
  `no-default-backend-url`), pass `good.sh` and fail `bad.sh`. About 20 s for the seven cases.

`--dry-run` builds each worktree and fixture and prints the `claude` command without running
it. `--model` picks the model ([[ParallelDelivery]] on routing by task); `--budget` caps
each case (default 3 USD, `--max-budget-usd`) and `--timeout` its wall clock (45 min).

### Adding a case

Every production incident or `wip/done/` entry whose right outcome a script can decide is a
candidate. Name its source in `case.env` (or `expected_output`), plant the problem in
`setup.sh` rather than depending on a state `main` will leave, and write `good.sh` and
`bad.sh` before trusting the check: `selftest.sh` must pass.

## Decisions & History

- **Local, not CI (2026-09-18, refinement).** No API key in the repository secrets and no
  workflow: the suite runs by hand on the user's Claude login. From
  `wip/done/2026-09-18-no-evals-for-the-agent-configuration.md`, prompted by Anthropic's
  "AI-native SDLC playbook" (continuous evals over 20–50 past tasks, `claude -p` with a
  restricted `--allowedTools`).
- **Skill-creator's format for per-skill cases (2026-09-26).** Its `evals.json` is what its
  benchmark, A/B comparison and grader read; a home-made format would have cut the skills
  off from them. `evals/` keeps the cases no single skill owns. The script form sits next
  to the JSON because the grader judges `expectations` with a model, and a check a script
  can decide should not cost one.
- **Planted fixtures (2026-09-26).** Each case plants its problem (`setup.sh`) on the
  throwaway branch instead of pointing at a bug `main` still has: the bugs of `wip/done/`
  are fixed on `main`, and a case that depended on one would stop meaning anything the day
  it was fixed.
- **First real runs (2026-09-26, default model, `origin/main` = 28a5f16).** Four cases
  passed: `docs-only-wiki-fact` (≈ 25 s, $0.25), `close-wip-entry` ($0.26),
  `no-default-backend-url` ($0.31; declined, filed a `wip/todo_nr/` entry instead) and
  `out-of-scope-finding` (79 s, $0.34 plus the app setup; the planted label left alone and
  filed). Allow about $0.3 per docs case. One `docs-only-wiki-fact` run failed because the
  agent chained commands (`cd …; grep …`, `git -C <path> commit`) that the closed tool list
  cannot match, so every Bash call was denied and nothing was committed. Since then
  `evals/preamble.md` states the list and asks for one plain command per call. A case that
  fails is worth a second run before blaming the configuration: the agent is not
  deterministic, even though the check is.
