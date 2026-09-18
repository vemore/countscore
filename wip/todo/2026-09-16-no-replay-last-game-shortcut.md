# Starting the next game of the evening repeats the whole creation flow

- **Noted:** 2026-09-16 — while working out why 6 monthly active devices keep so little of the funnel
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

Game nights are played in rounds of *games*: the same four people play Skyjo three times in a
row. Today each of those three starts at `lib/screens/create_game_screen.dart` and walks the
full flow — pick the game type, pick every player again, name the game — even though the
previous game holds all of it. `lib/screens/home_screen.dart` offers a single
`FloatingActionButton.extended` to *create* a game and nothing to repeat one, and
`lib/screens/ranking_screen.dart`, the screen shown the moment a game ends, offers no way
forward at all: the user's only move is back.

Retention for a score counter is measured in *evenings*, and the friction is concentrated in
the exact seconds when the table is waiting for the phone.

**Fix:** a "play again" action on the end-of-game ranking and on a finished game in the
history, creating a new game with the same game type and the same players, straight on the
board screen. It reuses the existing repository calls — no schema change — and adds one
localized string (`i18n-add-string`). Worth pairing with the share action of
`2026-09-16-no-way-to-share-a-game-result.md`, since both live on the ranking screen.

**Acceptance:**
- The end-of-game ranking offers "Play again": a new game with the same type and the same players in the same order, opened on its board.
- A finished game's menu on the home screen offers the same action.
- The source game is unchanged.
- The new string exists in all 10 ARB files.
