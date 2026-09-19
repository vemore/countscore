# The e2e golden path fails on a device whose language is not English

**Status:** done (2026-09-19) — closed by fix/e2e-device-locale. `_back` finds and taps the `BackButton` by type instead of `pageBack`, and step 8 opens the board's menu inside the last `AppBar`. The full golden path then passed on the Pixel 9 Pro XL (French, `--dart-define=BACKEND_URL=…`, analysis included) and still passes on the web (chromedriver 153, headless).

- **Noted:** 2026-09-19 — running the golden path on the Pixel, the device run #129 owed
- **Theme:** testing
- **Area:** app
- **Blocks release:** no

On the French Pixel, `integration_test/app_test.dart` failed in `_back` (`find.byTooltip('Back')`
found nothing: the tooltip is "Retour"), then in `tester.pageBack()`, which looks for the same
English tooltip. With both fixed, step 8 tapped `find.byIcon(Icons.more_vert)`, which found two
icons: the board's and the home card's, the home route staying mounted underneath. The web run
passed only because its browser is in English.

**Fix:** find the back button by type and tap it; scope the board menu to the top route's
`AppBar`.

**Acceptance:** the golden path passes on the French Pixel and on the web.
