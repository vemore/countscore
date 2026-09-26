# Nothing measures the tokens and the time each workflow costs

**Status:** done (2026-09-26) — closed by feat/delivery-and-agent-metrics. `scripts/agent_metrics.py` reads the local transcripts (stdlib, one streamed pass, about 8 s for 638 MB) and prints the ten biggest consumers in tokens, raw and price-weighted, and in active time, per session, branch, skill, agent, tool, file and hook; the baseline is in `.llmwiki/ParallelDelivery.md` § Measuring delivery, and `release-android` §3b reads it. The CI job durations went to [[2026-09-26-ci-job-durations-are-not-measured]].

- **Noted:** 2026-09-26 — comparing `.llmwiki/` with Karpathy's LLM Wiki pattern; the user
  asked for a way to find the big consumers and the bottlenecks of the system
- **Theme:** process-evals
- **Area:** tooling
- **Blocks release:** no

Every session re-reads `CLAUDE.md`, `INDEX.md` and wiki pages of up to 1060 lines
(`.llmwiki/MobileApp.md`), agents fan out through `ship-parallel`, and the pre-commit gates
run inside `guard-bash.sh` (timeout 300 s) — yet no figure says which of these dominates. The
data is already on disk, outside the repository: `~/.claude/projects/-home-vemore-workspace-countscore/`
(102 sessions, 45 with `subagents/`, 611 MB on 2026-09-26). Each assistant record carries
`message.usage` (`input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`,
`output_tokens`, thinking tokens), a `timestamp`, `gitBranch` and `sessionId`; `tool_use` and
`tool_result` blocks name the tool, the skill, the agent and the file read; hook attachments
carry `hookEvent` and `durationMs`.

**Fix:** `scripts/agent_metrics.py [--since DATE] [--by session|branch|skill|agent|tool|file|hook]`,
local only — it reads the transcripts, prints aggregates, and never writes transcript content
into the repository. Two measures:
- **Tokens**, raw and weighted by price class (cache read, cache write, uncached input, output),
  attributed to the session, the branch (→ pull request through `gh`), the skill or subagent
  that ran, and the files whose content entered the context (top files by bytes read).
- **Time**, active wall-clock only (the waits on the user excluded): per tool call
  (`tool_use` → `tool_result`), per hook (`durationMs`), per skill and per subagent; plus the CI
  job durations from `gh run list` / `gh run view --json jobs`.

Considered: OpenTelemetry export (`CLAUDE_CODE_ENABLE_TELEMETRY`) needs a collector running;
`ccusage` totals per session but attributes nothing to a skill or a file. Complements
[[2026-09-18-no-measure-of-whether-process-changes-help]], which measures the outcome — this
measures the cost; the pruning pass reads both.

**State of the art** (web search, 2026-09-26): two routes. Claude Code exports OpenTelemetry
metrics, events and — in beta — traces covering subagent dispatch
(`CLAUDE_CODE_ENABLE_TELEMETRY=1`, `OTEL_*`), to a collector such as SigNoz or Dash0: the
richest data, but a service to run. `ccusage` reads the same local transcripts as proposed
here, and gives per-day, per-session and per-model totals, without attribution to a skill, a
file or a hook. Reading the transcripts keeps us at no new service; if the attribution proves
too coarse, OTel traces are the next step. `/cost` gives one session's figure by hand.
Sources: [Claude Code docs, costs](https://code.claude.com/docs/en/costs),
[SigNoz, Claude Code monitoring](https://signoz.io/docs/claude-code-monitoring/),
[Bindplane, per-session cost](https://bindplane.com/blog/claude-code-opentelemetry-per-session-cost-and-token-tracking).

**Acceptance:**
- `scripts/agent_metrics.py --since 2026-09-01 --by <axis>` prints the ten biggest consumers in tokens and in active time, for each axis.
- A first baseline and its top findings are recorded in `.llmwiki/ParallelDelivery.md`.
- `release-android` §3b reads the report next to the rule-by-rule evidence.
- `git grep` finds no transcript content and no `.jsonl` in the repository.
