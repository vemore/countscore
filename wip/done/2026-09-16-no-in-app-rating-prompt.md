# The app never asks for a Play Store rating, and has zero ratings

**Status:** done (2026-09-16) — closed by feat/rating-prompt. `lib/services/review_prompt.dart`
holds the four guards over `SharedPreferences` with `in_app_review` behind `ReviewRequester`;
the request fires from the "Partie terminée" dialog's **End game** button in
`game_board_screen.dart`, and About gained a "Rate CountScore" entry opening the Play listing.
Eight unit tests in `test/services/review_prompt_test.dart`. The coverage limit of that trigger
— only game types that define a game-over condition reach the dialog — is
`wip/todo_nr/2026-09-16-no-explicit-end-of-game.md`.

- **Noted:** 2026-09-16 — while reading the Play Console acquisition figures for the growth plan
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

Play Console, 28 days to 2026-09-16: 133 store-listing impressions, 6 listing visitors, 2
installs, ~10 installs in total, **0 ratings and 0 reviews**. Play uses the rating and the
review count both as a ranking signal and as a conversion signal on the listing itself; the
nearest competitor at 500 K installs shows 4.9 over 4 320 reviews. Nothing in `lib/` ever
asks: `in_app_review` is absent from `pubspec.yaml` and no screen offers a path to the
listing, so a happy user has to go looking for one.

**Fix:** add `in_app_review` and request the native Play review sheet at the moment a game is
declared over, behind guards persisted in `SharedPreferences` — at least 3 finished games, at
least 7 days since the first launch, at most once per app version, never twice in one session
— in a single testable service with the plugin behind an injectable seam. No pre-prompt and no
"do you like the app?" question: Play policy forbids conditioning anything on the rating, and
`requestReview()` neither guarantees the sheet nor reports the outcome. Optionally an About
screen entry that opens the Play listing through `url_launcher`, which is the only honest
"rate this app" button.
