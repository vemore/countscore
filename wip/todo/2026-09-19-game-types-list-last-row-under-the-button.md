# The last game type is hidden under the "New type" button, and the new-type dialog predates the refresh

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

On "Types de jeux" the list has no bottom padding for the floating "Nouveau type" button.
Scrolled to the very end, the last type (ZapZap) still sits under the button: its row
centre is at y 818 and the button at 816. Its ⋮ menu (edit, delete) cannot be tapped
([capture](../assets/2026-09-19-game-types-list-last-row-under-the-button/last-row-under-fab.png), the same overlap one row higher before
scrolling). The "Nouveau type de jeu" dialog is the pre-refresh style: plain outlined fields,
an icon and a colour button with no label.

**Fix:** bottom padding of the FAB's height plus the inset (`withBottomInset`,
`lib/utils/insets.dart`) on the list. Label the dialog's icon and colour buttons. The dialog's
restyle is out of scope (2026-09-19, refinement): no target design exists, and it is not a bug.

**Acceptance:**
- A widget test: scrolled to the end, the last type's menu button is hit-testable and not
  under the FAB.
- The icon and colour buttons have semantic labels.
