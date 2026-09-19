# The analysis screen offers Report, Regenerate and Delete before any analysis exists

**Status:** done (2026-09-19) — closed by fix/app-bar-actions-and-labels. Report, Regenerate and Delete moved into one overflow menu (`Key('analysis_menu')`) that exists only once there is an analysis; Share sits beside it. `test/screens/game_analysis_screen_test.dart` pins both acceptance lines, the title measured in Nunito at 400 dp in `fr`.

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** ai-report
- **Area:** app
- **Blocks release:** no

Opening "Analyser la partie" on a game with no analysis shows the style picker and
"Générer l'analyse". The app bar already carries "Signaler ce commentaire", "Régénérer
l'analyse" and "Supprimer l'analyse", which act on nothing. Once generated (15 s,
gemini-2.5-flash, fine), the title is cut to "Analyse de la …" at 412 px
([capture](../assets/2026-09-19-analysis-screen-offers-actions-on-nothing/title-truncated.png)), because three actions share the bar.

**Changed (2026-09-19, refinement):** #139 (8e972a9) added a fourth action, `ShareResultButton`
(`game_analysis_screen.dart:376`), once content exists; the other three are still always
rendered, only disabled with no analysis (:381-398).

**Fix:** show Report, Regenerate and Delete only when an analysis exists, and move Report,
Regenerate and Delete into an overflow menu so Share and the title fit.

**Acceptance:**
- A widget test: with no cached analysis, the app bar has none of the three actions.
- A widget test at 400 dp: with an analysis, the title is not ellipsized in `fr`.
