# The New game screen is a bare form that the refreshed theme does not reach

**Status:** done (2026-09-19) — closed by feat/new-game-screen. The screen is redrawn in direction A: six game-type tiles (most recent first) and *All games (N)*, a light title field, seat-ordered rows coloured through `assignPlayerColors` and reorderable by their handle, the "who's playing" sheet with *Same players as*, and *Start · N players*; `test/screens/create_game_screen_test.dart` checks the 412 dp layout, the colour against the real board and the seat order after a drag.

- **Noted:** 2026-09-19 — reported by the user after the theme (#118), board (#119) and end screen (#123) landed
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

After the refresh, every screen from home to the end of a game carries the "Material soigné"
look, except the one in between. `lib/screens/create_game_screen.dart` is still a stock form
([capture](../assets/2026-09-19-new-game-screen-is-a-bare-form/today.png)):
- a text field;
- a `DropdownMenu` of game types (`:230`), whose colour and icon appear only once the menu is
  open;
- an outlined "Add" button;
- players as `ListTile`s with a `CircleAvatar` (`:345-353`) coloured by the stored
  `colorValue`, not by `lib/utils/player_colors.dart`. A player may therefore show one colour
  here and another on the board.

It is also the screen that fixes the **seat order**, which the board lanes, the
one-row-per-player view and the keypad now all follow. Nothing on it says that the order
matters, or lets you change it.

**Fix:** redraw the screen in direction A, **mock-up first** (added to the page linked from
`wip/done/2026-09-18-app-looks-like-a-default-material-template.md`, then saved as target
images in `wip/assets/2026-09-19-new-game-screen-is-a-bare-form/`):
- the game type as a grid of colour-and-icon tiles, with the most recent types first;
- players as seat-ordered chips using the display-time palette and the two-letter avatars of
  `lib/widgets/player_avatars.dart`, reorderable by drag, with the order labelled as the seat
  order;
- the game name as a light title field;
- a primary "Start" button.

**Acceptance:**
- `create_game_screen.dart` draws player colours through `player_colors.dart`, and a widget
  test shows the same colour for a player here and on the board.
- A widget test reorders two players and the created game's seat order follows.
- The screen matches the target images at 412 dp wide (layout, not exact pixels).

**Decided (2026-09-19):** the user approved direction A as drawn. Target images:
[the screen](../assets/2026-09-19-new-game-screen-is-a-bare-form/target.png) and
[the "who's playing" sheet](../assets/2026-09-19-new-game-screen-is-a-bare-form/target-add-players.png)
(canvas: https://claude.ai/artifact/MWw9hSctjPCW6XwXKrvJXd, boards "New game").
- Six game tiles, most recently used types first, the selected one outlined and ticked;
  "All games (N)" opens the full list. The win rule and end condition show as one line
  under the grid.
- Seat-ordered player rows (seat number, two-letter avatar, name, drag handle); the first
  seat is labelled as the dealer; a dashed "Add a player" row opens the sheet.
- The sheet: a search field that also creates a new player, known players as chips
  (most frequent co-players first) and "Same players as <last game>".
- A full-width primary "Start · N players" button at the bottom.
