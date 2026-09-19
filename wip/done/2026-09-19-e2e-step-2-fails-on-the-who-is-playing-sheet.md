# The web e2e golden path fails in step 2, on the who's-playing sheet

**Status:** done (2026-09-19) — closed by fix/e2e-who-is-playing-step. The test was wrong,
not the app: on web, tapping "create" for Alice unfocused the search field (`TextField`'s
default `onTapOutside`), which closed its text-input connection, and `enterText` on the same
field reopens none, so "Bob" went nowhere. The test now taps the field before each name. The
same run also exposed that #137's leaderboard counts finished games only: the test now ends
the game from the board's menu, checks the leaderboard rows and Alice's player card, and goes
back through a `_back` helper that waits out route transitions.

- **Noted:** 2026-09-19 — running the web e2e on main after #138 and #129
- **Theme:** testing
- **Area:** app
- **Blocks release:** no

`flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
-d web-server --browser-name=chrome --headless` (chromedriver 153.0.8010.36, Chrome 153) fails
at `integration_test/app_test.dart:63-64`: `_waitEnabled(tester, const Key('player_picker_create'))`
times out with "Found 0 widgets with key [<'player_picker_create'>]". In
`lib/widgets/player_picker_sheet.dart` the create button renders only while `_newName != null`,
i.e. while the typed name matches no player in `_all`.

**Fix:** find out why the typed name produces no create button, and fix the test if the test is
wrong or the widget if the app is. Then run the whole web e2e until it passes end to end.

**Acceptance:** the web e2e command above prints `All tests passed.` on a fresh headless Chrome
profile, with no `--dart-define=BACKEND_URL` (step 8 then skips itself, as designed).
