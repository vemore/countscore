# The app looks like the default Material template, and hides who is winning

- **Noted:** 2026-09-18 — during a visual review against competing score apps, with mock-ups
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The theme is `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` with the default Roboto
(`lib/main.dart:102-127`). The violet has nothing to do with the teal, green and blue podium
of the icon (`store_listing/assets/icon_512.png`). Home cards are tinted to 10 % of the game
colour (`lib/screens/home_screen.dart:373`), which makes ZapZap amber turn a dull beige. On the
board every cell is the same game-coloured pill (`game_board_screen.dart:471`). Totals are
small grey numbers under the names, and nothing marks the leader. `Player.colorValue` exists
but the board does not use it. Entering one score takes a dialog plus the system keyboard,
so 4 players cost 16 gestures per round. Finishing a game shows only a snackbar.
Competitors (Keep Score, redesigned in 2026; Scory; Skeep) all give each player a colour,
keep the ranking visible and enter scores without the system keyboard.

**Direction chosen: A, "Material soigné".** Its mock-ups are the implementation target:

- **In the repository** (light, and `dark-` prefixed):
  [`wip/assets/2026-09-18-app-looks-like-a-default-material-template/`](../assets/2026-09-18-app-looks-like-a-default-material-template/)
  — [home](../assets/2026-09-18-app-looks-like-a-default-material-template/home.png),
  [board, 4 players](../assets/2026-09-18-app-looks-like-a-default-material-template/board-4-players.png),
  [6](../assets/2026-09-18-app-looks-like-a-default-material-template/board-6-players.png),
  [8](../assets/2026-09-18-app-looks-like-a-default-material-template/board-8-players.png),
  [10, scrolled](../assets/2026-09-18-app-looks-like-a-default-material-template/board-10-players-scrolling.png),
  [one row per player](../assets/2026-09-18-app-looks-like-a-default-material-template/board-one-row-per-player.png),
  [entry, 4 players](../assets/2026-09-18-app-looks-like-a-default-material-template/entry-4-players.png),
  [entry, 8 players](../assets/2026-09-18-app-looks-like-a-default-material-template/entry-8-players.png),
  [end of game](../assets/2026-09-18-app-looks-like-a-default-material-template/end-of-game.png).
- **Interactive page** (private artifact, colours and fonts inspectable):
  https://claude.ai/artifact/D3ycxcgzPxHezRrSrmuxiw — section `#A` for home, entry and end of
  game, `#A8` for the board from 4 to 10 players. It also holds the rejected directions B to D
  and the competitor survey.

The board in the images supersedes the first-draft board of section `#A` (header cards above
an unaligned grid): lanes are the target.

**Fix:** direction A, plus the shared base shown in the mock-ups:
- **Theme:** seed teal `#0E8F88` (dark `#5ED8CF`), gold `#F2B705` for the leader. Nunito is
  **bundled as an asset**, not `google_fonts`, which would fetch from Google at runtime and
  add an outbound data flow. Nunito covers Latin and Cyrillic; ar, hi, ja and zh fall back to
  the system font. Use tabular figures for scores. Plain white cards with a 1 px outline, no
  tint and no elevation 2.
- **Board: one lane per player.** Each player's column is a vertical band tinted with
  `Player.colorValue`. It runs from the player's header (two-letter avatar, name, large total,
  rank) down to the last row. The header and the cells sit in the same grid, so they cannot
  drift apart. The leader's lane is outlined and crowned, following `isLowestScoreWins`. A
  total within 20 points of the elimination threshold turns orange. Zeros are shown in amber.
  - **Up to 8 players**, the lanes tighten to fit the width. From 6 players the header
    switches to the compact form: avatar, vertical name, total.
  - **Beyond 8 players**, lanes keep their minimum width and the grid scrolls horizontally.
    The round column stays pinned, and a ranking ribbon of all players stays on top.
  - **An app-bar button switches to "one row per player"**: players as rows (sorted by rank
    or seat order), the last 4 rounds as columns plus the total, and older rounds reached by
    swiping. The choice is remembered on the device (`SettingsProvider`).
- **Score entry:** a bottom sheet with a built-in keypad, "next player" and a "validate round"
  button, replacing the per-cell `AlertDialog`. Editing a single past cell reuses the same
  sheet.
- **Home:** a "Resume" hero for the latest open game, showing its leader and round. Cards
  show their status (in progress, or the winner) before the date, plus player avatars.
- **End of game:** a podium and ranking screen with "Play again" (`utils/play_again.dart`)
  and "Analysis" (the existing AI commentary).
- New strings go through `i18n-add-string`. Store screenshots are retaken afterwards
  (`2026-09-16-screenshots-are-raw-captures.md`).

**Acceptance:**
- `lib/main.dart` no longer references `Colors.deepPurple`, and Nunito is declared under
  `flutter: fonts:` in `pubspec.yaml` with no `google_fonts` dependency.
- A widget test on the board shows the crown on the lowest total for a lowest-wins type and
  on the highest total otherwise.
- At 400 dp wide, the board shows 8 players without horizontal scrolling and 10 players with
  it. The toggle shows one row per player, and the choice survives a restart (widget tests).
- A widget test enters a full 4-player round through the keypad sheet without opening a
  `TextField` dialog.
- Finishing a game opens the end screen, and "Play again" from it creates the next game.

**Open question:** one pull request, or two (theme and home first, then board, keypad and
end screen)?
