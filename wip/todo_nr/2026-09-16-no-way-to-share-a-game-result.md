# A finished game cannot be shared anywhere, so the app never advertises itself

- **Noted:** 2026-09-16 — while looking for why 10 installs have produced 0 reviews
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

28 days in the Console: 133 impressions, 6 listing visitors, 2 installs, ~10 installs in
total, **0 ratings**. Paid acquisition is not an option here, so the only growth lever left is
the players sitting around the table with the phone — and the app gives them nothing to pass
around.

There is no share path at all: `pubspec.yaml` has no `share_plus` (only `file_picker`,
`url_launcher`, `path_provider`), and `grep -rn "Share\.\|SharePlus" lib/` returns nothing.
The one export route is the file picker, which produces a JSON file for re-import — not
something anyone posts in a family group chat. `lib/screens/ranking_screen.dart` already
computes exactly the content worth sharing (final standings) and `lib/screens/game_analysis_screen.dart`
produces a written commentary, both of which die on the screen they are drawn on.

**Fix:** add `share_plus` and a share action on the end-of-game ranking and on the ZapZap
analysis, producing a short localized text (game type, date, standings, and a single
plain-language mention of the app, no URL shortener and no tracking parameter) plus, ideally,
a rendered image of the standings. Every string through `AppLocalizations`
(`i18n-add-string`). Sharing is user-initiated and goes through the system share sheet, so
nothing leaves the device on its own and the Data Safety declaration does not move — confirm
that reasoning against `.llmwiki/Documentation.md` before shipping.
