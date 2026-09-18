# The board does not show who leads, and its columns barely say whose they are

- **Noted:** 2026-09-18 — visual refresh, split into one pull request per screen
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Part of the visual refresh, direction A "Material soigné", chosen from four mock-up directions
(split out of `wip/done/2026-09-18-app-looks-like-a-default-material-template.md`). The images
in [`wip/assets/…material-template/`](../assets/2026-09-18-app-looks-like-a-default-material-template/) are the target (light, and `dark-` prefixed); the
interactive page is https://claude.ai/artifact/D3ycxcgzPxHezRrSrmuxiw (private).

**Target:** [4 players](../assets/2026-09-18-app-looks-like-a-default-material-template/board-4-players.png), [6](../assets/2026-09-18-app-looks-like-a-default-material-template/board-6-players.png), [8](../assets/2026-09-18-app-looks-like-a-default-material-template/board-8-players.png), [10, scrolled](../assets/2026-09-18-app-looks-like-a-default-material-template/board-10-players-scrolling.png), [one row per player](../assets/2026-09-18-app-looks-like-a-default-material-template/board-one-row-per-player.png), and their `dark-` versions.

`lib/screens/game_board_screen.dart:471` paints every cell in the game colour, whoever the
player is. The totals are small grey numbers under the names, and nothing marks the leader.
`Player.colorValue` exists but the board does not use it. With 8 players the header and the
cells are laid out separately, so a column is linked to its player only by position.

Lands after [[2026-09-18-app-theme-is-default-deep-purple]], whose theme and player palette it uses.

**Fix:** the board becomes **one lane per player**. A vertical band tinted with the player's
colour runs from the header (two-letter avatar, name, large total, rank) to the last row.
Header and cells sit in **one grid**, so they cannot drift apart.
- The leader's lane is outlined, with a crown, following `isLowestScoreWins`. A total within 20
  points of `playerDeadThreshold` turns orange. A zero is shown in amber.
- **Up to 8 players** the lanes tighten to fit the width. From 6 players the header switches
  to the compact form: avatar, vertical name, total.
- **Beyond 8 players**, lanes keep a minimum width and the grid scrolls horizontally. The
  round column stays pinned, and a ranking ribbon of every player stays on top.
- **App-bar toggle** to "one row per player": rows in **seat order** by default, with rank
  order as an option; the last 4 rounds as columns plus the total; older rounds reached by
  swiping. The view is remembered **app-wide** in `SettingsProvider` (`SharedPreferences`).
- Unchanged: eliminated players stay visibly out, tapping a round number opens the round
  comment (`game_board_screen.dart:441`), and tapping a cell still edits it (through today's
  dialog until [[2026-09-18-score-entry-takes-a-dialog-per-cell]] lands).

**Acceptance:**
- Widget test: the crown is on the lowest total for a lowest-wins type and on the highest
  total otherwise.
- Widget tests at 400 dp wide: 8 players fit with no horizontal scroll, 10 players scroll and
  keep the round column visible, and each header's left edge equals its column's left edge.
- Widget test: the toggle switches to one row per player in seat order, and the choice
  survives rebuilding the app with the same `SharedPreferences`.
- A PWA screenshot at 4 and 8 players, in light and dark, is attached to the pull request.
