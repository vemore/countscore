# The "game reopened / finished — Undo" snackbar never goes away

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Reopening a finished game from the home menu shows "Partie rouverte · Annuler"
(`home_screen.dart`, the `SnackBar` with an `action`). On the PWA it was **still on screen
more than 20 s later**, after renaming a game, opening the filter and deleting another game
([capture](../assets/2026-09-19-undo-snackbar-never-goes-away/snackbar-still-there.png)). An Undo offered that long after the action, with
other changes in between, is misleading.

Recent Flutter keeps a `SnackBar` that has an action on screen until it is dismissed (its
`persist` default).

**Fix:** set `persist: false` and a duration (about 6 s) on the snackbars that carry an
Undo (home and board), and hide them on navigation.

**Acceptance:**
- A widget test: the snackbar with Undo is gone after its duration without any interaction.
