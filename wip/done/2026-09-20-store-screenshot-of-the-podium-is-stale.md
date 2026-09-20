# The store's `04_podium` screenshot shows a standings screen that no longer exists

**Status:** done (2026-09-20) — closed by chore/store-screenshots. `04_podium` is retaken in
the ten locales against `origin/main` at 2f4c37b: the *Results* title, the winner's headline,
the podium and the ranked rows **starting at place 1**, first place on the primary container.
The game captured is **Kyoto (Tarot, score-ranked)**, deliberately: a score-ranked game draws
no `ranking_elimination_note` (#191), so the picture stays the plain podium the caption
promises, and it is the same game the published shot used, which keeps the only visible change
the one this entry asks for.

Checking the whole set, as the entry suggested, found **two more stale screens**, retaken in
the same ten locales:
- `03_game_types` — the rule line under the game tiles is two lines now ("Lowest score wins ·
  The game ends when every player but one is above 100 points"), because ZapZap gained a
  `lastPlayerOver` game-over condition (#176). It was one short line in the published shot.
- `06_customization` — the *Edit type* dialog's name field gained a `4/64` character counter
  (`maxLength: 64`, #179), which also widened the dialog.

Left alone, verified screen by screen on the device against the current build: `01_main_screen`
(identical but for the demo database's dates, which follow the day it is generated),
`02_player_management`, `05_game_board`, `07_score_entry`, `08_statistics` (#194 changes
elimination-game places, and no demo game's statistics move). The new app icon (#195) appears
only in the drawer header and the About screen, neither of which is in the set.

`scripts/compose_screenshots.py --check` exits 0 for all ten locales. Not published: the set
ships with the next Android release (the user's call, asked and answered 2026-09-20).

- **Noted:** 2026-09-20 — while merging the two standings screens (`refactor/standings-screen`)
- **Theme:** store-listing
- **Area:** android
- **Blocks release:** no

The ten composed `04_podium` screenshots published with 1.3.0 ([[StoreListing]]) show the old
`GameEndScreen`: a podium with the list under it starting at place 4. Since 2026-09-20 the
standings list every player under the podium, the first place on the primary container, and
the screen's title is *Results* rather than the game's name. The published picture and the
app no longer match.

**Fix:** retake `04_podium` in the ten locales with the existing tooling
(`release-android`, the `adb`-driven session described in [[StoreListing]]) and publish with
`play_publish.py listing --graphics`. Worth batching with the rest of the visual-refresh
wave rather than doing alone — other screens in the set may move too.

**Acceptance:**
- `04_podium` in the ten locales shows the list starting at place 1.
- `--check` exits 0 and the set is published with the next release.
