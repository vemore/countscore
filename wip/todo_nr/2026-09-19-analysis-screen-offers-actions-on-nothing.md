# The analysis screen offers Report, Regenerate and Delete before any analysis exists

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** ai-report
- **Area:** app
- **Blocks release:** no

Opening "Analyser la partie" on a game with no analysis shows the style picker and
"Générer l'analyse". The app bar already carries "Signaler ce commentaire", "Régénérer
l'analyse" and "Supprimer l'analyse", which act on nothing. Once generated (15 s,
gemini-2.5-flash, fine), the title is cut to "Analyse de la …" at 412 px
([capture](../assets/2026-09-19-analysis-screen-offers-actions-on-nothing/title-truncated.png)), because three actions share the bar.

**Fix:** show the three actions only when an analysis exists, and move Report and Delete
into an overflow menu so the title fits.

**Acceptance:**
- A widget test: with no cached analysis, the app bar has none of the three actions.
- A widget test at 400 dp: with an analysis, the title is not ellipsized in `fr`.
