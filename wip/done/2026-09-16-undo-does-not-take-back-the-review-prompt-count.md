# Undoing a finish leaves the review-prompt count incremented

**Status:** done (2026-09-18) — closed by feat/board-growth. `reviewPromptGamesFinished`
is gone (and removed from existing installs by `recordFirstLaunch`); `ReviewPromptService`
reads `GameRepository.countFinished()` — live games with `finishedAt` set — once the cheap
guards pass. `test/services/review_prompt_test.dart` checks finish then Undo leaves the count
unchanged and finish, reopen, finish counts one.

- **Noted:** 2026-09-16 — adding the undo snackbar (fix/end-of-game-polish)
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

`ReviewPromptService.onGameFinished()` bumps `reviewPromptGamesFinished` — and may hand the
Play sheet over — the moment a game is finished, on both triggers
(`lib/screens/home_screen.dart`, `lib/screens/game_board_screen.dart`). Nothing ever puts the
count back: `setGameFinished(id, false)` writes `finishedAt` away and returns false, which
only means "do not count this one".

That was already true of **Reopen**, which is a deliberate part of the design —
`GameProvider.setGameFinished`'s doc says a finish → reopen → finish evening must count once,
not zero. The new **Undo** action makes the same path one tap away and immediate, so a
mis-tap on "Finish" now costs a permanent +1 towards `minGamesFinished = 3`
(`lib/services/review_prompt.dart`). The empty-game route is closed, so this is no longer a
way to reach the sheet without playing — it just makes the count slightly generous.

**Fix:** decide whether the count follows the state or the act. Either
`ReviewPromptService.onGameUnfinished()` decrements when a finish is reversed **within the
snackbar's lifetime** (the undo, not a considered reopen days later), or the counter is
dropped for a `COUNT(*)` over `games WHERE finishedAt IS NOT NULL` read at prompt time, which
cannot drift from the truth at all. The second is fewer moving parts and survives a restore
from backup; it needs `GameRepository` to expose the count.

**Decided (2026-09-18, refinement):** the count follows the state: a `COUNT(*)` of games
with `finishedAt IS NOT NULL`, read through `GameRepository` when the prompt is due. The
`reviewPromptGamesFinished` counter goes.

**Acceptance:**
- `ReviewPromptService` reads the finished-game count from `GameRepository`; no stored counter remains.
- Finish then Undo leaves the count where it was (unit test).
- Finish, reopen, finish counts one game.
