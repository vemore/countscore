# The group's comment style and language shape nothing the app shows

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

**Open question:** should the analysis of a shared game be billed to the group's budget?
