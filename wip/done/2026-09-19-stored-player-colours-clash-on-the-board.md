# Player colours picked at random on creation can be near-twins or unreadable on the board

**Status:** done (2026-09-19) — closed by fix/player-avatars-colours-keypad. Two colours clash when closer than 12 in CIEDE2000 (`playerColorsClash`; a hue threshold alone would have made palette colours clash with each other), and `onPlayerColor` picks white or `black87` by WCAG contrast. One reading of the first acceptance line: of `green` and `lightGreen`, the first seat keeps its own Material green and the second takes a palette colour — the two are distinct, but not both palette colours, since a stored colour is still honoured when it clashes with nothing. Tests: `test/utils/player_colors_test.dart`.

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`player_colors.dart` lets a player's stored `colorValue` win, unless another player of the
same game has **exactly** that value. The create screen gives new players random Material
colours. So a 4-player game got Lionel `green` and Thibaut `lightGreen`: two lanes that read
as the same colour ([capture](../assets/2026-09-19-stored-player-colours-clash-on-the-board/two-greens.png)). Another run gave Laurent a yellow disc
with a white "La" that can barely be read ([capture](../assets/2026-09-19-stored-player-colours-clash-on-the-board/yellow-avatar.png)). Exact
equality is the only clash detected.

**Changed (2026-09-19, refinement):** the creation half is done — #138 (e53442f) replaced the
player dialog, and `player_picker_sheet.dart:131` adds new players with no colour, so they
take `kPlayerPalette`. Players stored before it keep their Material colours, and
`player_colors.dart:45-49` still treats only exact equality as a clash; `onPlayerColor`
(:88-91) uses `estimateBrightnessForColor`, with no contrast check.

**Fix:** at display time, treat colours closer than a hue threshold as a
clash too, and pick the avatar text colour from the disc's luminance.

**Acceptance:**
- A unit test: `green` and `lightGreen` in one game resolve to two distinct palette colours.
- A unit test: every palette colour gets avatar text with a WCAG contrast of at least 4.5:1.
