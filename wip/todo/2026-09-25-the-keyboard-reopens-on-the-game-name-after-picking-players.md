# The keyboard reopens on the game name after closing the "Qui joue ?" sheet

- **Noted:** 2026-09-25 — testing `main` (05894ee) on the Pixel
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

On New game, I edited the name, closed the keyboard, opened "Ajouter un joueur", picked three
players and tapped "Valider". The sheet closed and focus went back to the name field: the
keyboard came up and covered the player list and "Commencer". It takes an extra Back before
the players you just picked are visible.

**Fix:** unfocus the name field before opening the player sheet (or open the sheet with
`FocusScope.of(context).unfocus()`), so focus is not restored when the sheet closes.

**Acceptance:**
- A widget test: with the name field focused, open the player sheet, pick a player, validate,
  and find no focused `EditableText`.

**Promoted (2026-09-25):** by the user, for the next release: it touches what that release
ships (sounds, turn timer, new-game flow, the last-player-standing rule).
