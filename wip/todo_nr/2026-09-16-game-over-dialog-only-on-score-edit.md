# The game-over dialog is forgotten as soon as the board is closed

**Status:** partly done (2026-09-16) — fix/end-of-game-polish gave the check every trigger
it was missing. `_checkGameOverCondition` now runs from `_maybeShowGameOver` after a score
edit, after `addRound` and after `deleteRound`, so a threshold crossed by any path raises the
dialog, and `_gameOverDismissed` in `_GameBoardScreenState` keeps it to one question per
crossing, re-arming as soon as the condition is false again.

- **Noted:** 2026-09-16 — while adding the explicit end of a game (feat/explicit-end-of-game)
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

What is left is the part the original entry called out as unrecorded: **the user's "Continue
playing" lives only in `_gameOverDismissed`, a field of the board's `State`.** Leaving the
board and coming back re-arms it, so the next round raises the dialog again on a game the
user already said to keep playing.

The original fix proposed a check "on the board's first build for a game that already has
rounds". It was **deliberately not implemented** (decided with the user, 2026-09-16): with
nothing persisted, that check reopens the dialog on every single opening of a game past its
threshold — worse than the bug. The order matters: persist the refusal first, then a
first-build check becomes possible.

**Fix:** persist the answer. A `gameOverDismissedAt` (or a flag) on `games`, cleared whenever
the condition goes false, would survive the board closing — and, being on a synced table,
would need a schema bump, the `sync_store` contract and LWW like `finishedAt` got in v12
(`db-migration` skill, [[Sync]]). Only then is a check on the board's first build worth
adding.

**Decided (2026-09-18, refinement):** keep the refusal on the device —
SharedPreferences keyed by the game's uuid, no schema change, not synced. Then add the
first-build check.

**Acceptance:**
- "Continue playing", leaving the board, coming back and adding a round does not raise the dialog (widget test).
- The stored refusal is cleared when the condition goes false, and a new crossing raises the dialog once.
- Opening a game past its threshold that was never dismissed raises the dialog once on the board's first build.
- The schema version is unchanged.
