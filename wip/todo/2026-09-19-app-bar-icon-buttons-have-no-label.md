# Two app-bar icon buttons have no label, so a screen reader announces nothing

- **Noted:** 2026-09-19 — smoke-testing the production PWA after the ship-parallel loop (Playwright accessibility snapshot)
- **Theme:** accessibility
- **Area:** app
- **Blocks release:** no

The accessibility tree shows a bare `button` with no name for:
- the statistics icon on the home app bar (`lib/screens/home_screen.dart:105-106`, `Icons.bar_chart`);
- the leaderboard icon on the board app bar (`lib/screens/game_board_screen.dart:244`, `Icons.leaderboard`), which opens the Ranking screen.

Neither `IconButton` has a `tooltip`, so TalkBack and browser screen readers read "button", and
automated tests have to click them by position. The neighbouring icons ("Filter games",
"Show menu", "Share the result") all have one.

The same two buttons were also listed in
[[2026-09-19-pwa-shell-still-says-flutter-template-and-offline]], which now leaves them here (2026-09-19, refinement).

**Fix:** give both a `tooltip` from `AppLocalizations` (the existing keys `playerStatistics`
and `ranking` fit), and look for other `IconButton`s without one while there.

**Acceptance:**
- A widget test finds both buttons by `find.byTooltip`, in English and French.
- No `IconButton` in `lib/` lacks a `tooltip:` without a written reason.
