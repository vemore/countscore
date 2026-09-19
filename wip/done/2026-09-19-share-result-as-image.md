# A shared result is text only, while a picture of the podium is what gets posted

**Status:** done (2026-09-19) — closed by feat/share-result-image. `ShareResultButton` draws a `ResultShareCard` (built on `RankedPlayers` from the same `GameRanking`) off-screen to a PNG and shares it next to the text; a browser that cannot share files gets the text alone. The ranking test compares the card's order to the screen's; Chromium under `_PWA_CSP` received the PNG with the activation still live ([[Web]]); no new manifest entry, Data Safety unchanged.

- **Noted:** 2026-09-19 — while adding the text share (feat/share-game-result)
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The share action on the end screen, the ranking and the analysis
(`lib/widgets/share_result_button.dart`) sends a text built by
`buildGameResultShareText` (`lib/utils/game_result_share.dart`). The refinement of
2026-09-18 decided text first and the rendered image in a second pull request
(`wip/done/2026-09-16-no-way-to-share-a-game-result.md`). In a family group chat, an image
of the podium in the players' colours is what stands out; a text line is easy to scroll past.

**Fix:** render the standings — the `RankedPlayers` podium and rows, the summary line, the
app's name — off-screen to a PNG (`RepaintBoundary.toImage`, or a dedicated widget drawn
with the same `GameRanking`), and share it with the existing text through
`ShareParams(files: [XFile.fromData(...)], text: ...)`. On the web, `navigator.canShare`
with files is narrower than for text: check the fallback (share_plus downloads the file when
`downloadFallbackEnabled`) under `_PWA_CSP` — `img-src` already allows `blob:`/`data:`.
Mind the `FileProvider` path share_plus uses on Android (cache directory, no permission).

**Acceptance:**
- The share action attaches a PNG of the standings next to the existing text, on Android and in the PWA.
- The image uses the same ranking as the screen (a widget test compares the order).
- No new permission in the merged release manifest; no change to the Data Safety answers.
