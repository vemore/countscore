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

**Acceptance:**
- `evals/` holds at least five cases from `wip/done/`, each a prompt and a check script.
- One local command runs them all and prints pass or fail per case; no secret and no workflow is added.
- `.llmwiki/` says when to run them, and `release-android` §3b runs them.
