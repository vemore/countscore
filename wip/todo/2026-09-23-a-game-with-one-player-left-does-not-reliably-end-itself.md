# A game with one player left does not reliably end itself

- **Noted:** 2026-09-23 — user report on ZapZap ("still true of other types, probably"); checked against the production database and `lib/screens/game_board_screen.dart`
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

The rule is that a ZapZap game ends when every player but one is eliminated. The user sees
games where that is already true and yet more rounds can be added, and the end marker
(`games.ended_at`) is not set. [[2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset]]
fixed `isGameOver`, but three gaps remain.

1. **The condition exists only on a new database.** That fix seeded `lastPlayerOver` on
   `zapzap`, `rami` and `six_nimmt` for fresh installs only. Production shows the gap: the
   ZapZap row of group `e802…` (created 2026-09-19) still has
   `game_over_condition_type = NULL`. Group `66ab…` has `lastPlayerOver`/100 only because
   the user set it by hand on 2026-09-20. A device or group created from an older database
   never ends a game on its own.
2. **Nothing stops a round after the end.** `board_add_round` (`game_board_screen.dart:492`)
   is enabled whatever `isFinished` says. The end is only a screen that
   `_maybeShowGameOver` (`:525`) opens once. After "Continue playing", which is stored per
   device in `GameOverDismissals`, or once the game is finished, the board still invites
   round N+1.
3. **The end is a side effect of the board being open on the device that typed.** It is
   checked after `_enterRound`, `_editScore` and the delete-round menu, and when the board
   opens (`_checkGameOverOnOpen`). History shows it: p168–p172 were finished days after
   their last round, when someone happened to reopen them (p172 on 2026-09-22 21:32 UTC,
   last scored on 2026-09-14). A round that arrives by sync on a device whose board is open
   is never checked there.

Last night's p173 and p174 did end on their last round (ended_at within a second of it),
so the check works on the path it covers.

**Fix:**
- A migration (next schema version, `db-migration` skill) that sets the built-in
  last-player-standing condition on rows with `builtin_key` in (`zapzap`, `rami`,
  `six_nimmt`) and a NULL condition. A row the user already set is left alone. The same
  change goes on the server for rows that reach it.
- The board disables or hides "Round N" while the game is finished, and offers "Reopen"
  instead (the app-bar action already exists, `:324`).
- `_maybeShowGameOver` also runs when a sync pull changes the current game's scores.

**Acceptance:**
- Migration test: an existing database with a NULL-condition ZapZap row ends up with `lastPlayerOver`/100, and a user-set condition is unchanged.
- Widget test: entering the round that leaves one ZapZap player standing sets `isFinished` and opens the end screen; the round button is then disabled until "Reopen" or "Continue playing".
- Widget test: a score change delivered through the provider (as sync does) that leaves one player standing ends the game on a board that did not type it.
- `firstPlayerOver` types (e.g. Uno, Président) keep ending as before (regression test).

**Decided (2026-09-24, refinement):** after "Continue playing" the round button comes back, as
today: the player chose to go on. It is disabled only while the game is finished and neither
reopened nor continued. The migration's UPDATE fires the `game_types` capture trigger
(`lib/services/sync/sync_schema.dart:95`), so a linked row reaches the server with no
server-side change.
