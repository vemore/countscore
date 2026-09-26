# Nothing checks that agents still work well after CLAUDE.md, a skill or a hook changes

**Status:** done (2026-09-26) — closed by feat/agent-evals. `evals/run.sh` replays five cross-cutting cases (`evals/cases/`) and two skill cases (skill-creator `evals.json` in `i18n-add-string` and `db-migration`) with `claude -p`, a closed tool list and no push path, each in a throwaway worktree, and prints pass or fail per case; `evals/selftest.sh` proves every check against a right and a wrong hand-made outcome at no cost. When to run them: `.llmwiki/AgentEvals.md`; `release-android` §3b step 5 runs them. Not done: running each case on the model its rating picks waits for [[2026-09-26-agents-run-on-one-model-whatever-the-task]] (`--model` is there for it).

- **Noted:** 2026-09-18 — comparing the project's SDLC with Anthropic's "The AI-native SDLC
  playbook" (claude.com/blog/the-ai-native-sdlc-playbook)
- **Theme:** process-evals
- **Area:** tooling
- **Blocks release:** no

The process changes almost daily: `CLAUDE.md`, the wiki, seven skills, six hook handlers, and
the pruning pass (`release-android` §3b) removes rules on judgement alone. What is tested is
the hook *scripts* (`scripts/hooks_selftest.sh`, 138 cases): deterministic, but silent on
whether an agent given the changed instructions still does the task right. A reworded skill
that stops triggering, or a pruned rule that was carrying weight, shows up only when a later
pull request goes wrong.

The playbook's answer is continuous evals: 20–50 real past tasks, each a prompt plus checks,
replayed non-interactively (`claude -p` with a restricted `--allowedTools`) on every change to
the agent configuration and on a schedule; every production incident becomes a permanent case.

**Decided (2026-09-18, refinement):** no API key in the repository secrets and no CI
workflow. The evals run locally, by hand, from a session, on the user's own Claude login.

**Fix:** start small — five to ten cases taken from `wip/done/`, where the right outcome is
known and checkable by a script: add a string in ten locales (ARB key sets and values pass
`arb_keys.py`), a migration (schema version bumped, migration test added), a problem found
out of scope (a new `wip/todo_nr/` entry, no inline fix), a docs-only change (no gate run,
README untouched when nothing it states changed). An `evals/` folder with the prompts and
check scripts, and a script that replays them with `claude -p` (restricted `--allowedTools`)
in throwaway worktrees and prints pass or fail per case. Run it after changing `CLAUDE.md`,
`.claude/**` or `.llmwiki/**`, and in the pruning pass (`release-android` §3b).

**State of the art** (web search, 2026-09-26): Anthropic's `skill-creator` now writes evals
for a skill — test prompts with expected outcomes — runs benchmarks, blind A/B comparisons
and trigger tuning, in isolated workspaces, and it is installed here. Practice beyond one
skill is the harness proposed above: `claude -p` headless against the project, then a check
script or a judge. Use the `skill-creator` format for the per-skill cases rather than a
home-made one, and keep `evals/` for the cross-cutting cases (`CLAUDE.md`, hooks, the wip
rule). With [[2026-09-26-agents-run-on-one-model-whatever-the-task]], run each case on the
model its rating picks: that is what says a simple task is safe on Sonnet.
Sources: [Anthropic, improving skill-creator](https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills),
[Dik Rana, agent evals for a Claude Code setup](https://dikrana.dev/blog/claude-code-agent-evals/).

**Acceptance:**
- `evals/` holds at least five cases from `wip/done/`, each a prompt and a check script.
- One local command runs them all and prints pass or fail per case; no secret and no workflow is added.
- `.llmwiki/` says when to run them, and `release-android` §3b runs them.
