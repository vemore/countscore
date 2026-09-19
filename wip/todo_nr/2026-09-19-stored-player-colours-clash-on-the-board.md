# Player colours picked at random on creation can be near-twins or unreadable on the board

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

**Fix:** when colours are assigned at creation, draw from `kPlayerPalette`, not from
arbitrary Material colours. At display time, treat colours closer than a hue threshold as a
clash too, and pick the avatar text colour from the disc's luminance. Overlaps
[[2026-09-19-new-game-screen-is-a-bare-form]], which should reuse this rule.

**Acceptance:**
- A unit test: `green` and `lightGreen` in one game resolve to two distinct palette colours.
- A unit test: every palette colour gets avatar text with a WCAG contrast of at least 4.5:1.
