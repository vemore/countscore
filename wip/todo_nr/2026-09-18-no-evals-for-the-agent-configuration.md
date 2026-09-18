# Nothing checks that agents still work well after CLAUDE.md, a skill or a hook changes

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

**Fix:** start small — five to ten cases taken from `wip/done/`, where the right outcome is
known and checkable by a script: add a string in ten locales (ARB key sets and values pass
`arb_keys.py`), a migration (schema version bumped, migration test added), a problem found
out of scope (a new `wip/todo_nr/` entry, no inline fix), a docs-only change (no gate run,
README untouched when nothing it states changed). An `evals/` folder with the prompts and
check scripts, and a workflow run on pull requests touching `CLAUDE.md`, `.claude/**` or
`.llmwiki/**`, plus a manual trigger. Open questions: the API key as a repository secret and
the cost per run (budget it before enabling on every PR — `workflow_dispatch` first), and
whether a failing eval blocks the merge or only reports.

**Open question:** Put an Anthropic API key in the repository secrets? With what monthly budget per run? Does a failing eval block the merge, or only report?
