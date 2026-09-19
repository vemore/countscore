# The group's comment style and language shape nothing the app shows

**Status:** done (2026-09-19) — closed by feat/group-comment-analysis. A shared game's analysis now posts its payload under `analysis` to `POST /groups/me/games/{id}/comments` (device token): billed to the group's budget, in the group's language, and in the voice the group's style maps to when no voice was ever picked; a 409 shows `analysisErrorGroupBudget`. An unshared game keeps `/comments/game-analysis`.

- **Noted:** 2026-09-19 — while building Settings → Group → Comments and usage (feat/group-settings-screen)
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

The group's `comment_style` and `comment_language` are read only by the group-scoped comment
endpoint, `POST /groups/me/games/{game_id}/comments` (`backend/app/routes/comments.py:306`),
which is also the one the usage and budget count. The app never calls it: the analysis goes to
`POST /comments/game-analysis`, anonymous and unbudgeted, with the voice picked on the analysis
screen and the display language (`lib/services/backend_client.dart`, `gameAnalysis`). So a
member can now change the group's style and language, and watch a usage that stays at zero,
without either changing anything they see.

**Fix:** decide with the user which way to close the gap: have a shared game's analysis go
through the group endpoint (budgeted, the group style as fallback when no voice is picked, the
group language), or show group comments on the board of a shared game, or drop the comment
settings from the screen and keep only what is used.

**Decided (2026-09-19, refinement 6):** through the group endpoint. The analysis of a shared
game calls `POST /groups/me/games/{game_id}/comments`: billed to the group's budget, the group's
style as the fallback when no voice is picked, the group's language. An unshared game keeps
`/comments/game-analysis`.

**Acceptance:**
- Analysing a shared game raises the group's usage on Settings → Group → Comments and usage.
- With no voice picked, a shared game's analysis uses the group's style and language (client test with a stubbed backend).
- An unshared game's analysis still calls `/comments/game-analysis` and counts nothing.
- A group over its budget gets a clear message, not a raw error.
