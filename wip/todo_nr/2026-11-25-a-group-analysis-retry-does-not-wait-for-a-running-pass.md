# A group analysis retried after a 404 does not wait for a pass already running

- **Noted:** 2026-11-25 — independent review of #292 (feat/multi-group-sync-sessions)
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

`GroupSession.gameAnalysis` (`lib/providers/group_session.dart`) answers a 404 from
`POST /groups/me/games/{uuid}/comments` — the server does not hold the game yet, its share
not pushed — with one `syncNow()` and one retry. When a pass of that group is already
running, `syncNow` only sets `_rerun` and returns at once: the retry goes out before the
share is pushed, gets the same 404, and `GameAnalysisScreen` falls back on the stateless
`/comments/game-analysis`. The analysis is then not billed to the group, not written in its
language or style, and not kept with the group. The window is the first seconds after
sharing a game, exactly when a pass is likely to be running: sharing schedules one.
Older than the multi-group change: the single-group `syncNow` returned the same way.

**Fix:** let `syncNow` hand back a future that completes when the pass that covers the call
ends — the running one plus its rerun — and await that before the retry. The other callers
(the poll, the stream signal, the debounce) do not await it, so nothing else changes.

**Acceptance:**
- A provider test: a pass of the group is held in flight (a gated pull), the analysis answers
  404 once; the retry is sent only after the push of the held pass and its rerun, and it
  goes to the group's endpoint, not the stateless one.
