# The Play listing title carries no word anyone searches for

**Status:** done (2026-09-16) — closed by docs/store-listing-aso. The head keyword now opens
the title in both locales (`Compteur de points: CountScore`, 30 chars; `Score Keeper -
CountScore`, 25), the short descriptions name the games, and both full descriptions were
rewritten to 3 936 / 3 779 of the 4 000 characters available, leading with the score sheet and
moving group sharing and the ZapZap analysis into an "advanced, needs your own server"
section. No third-party game name in either title. Whether it moves the 133 impressions is a
Console measurement to make in a few weeks against the baseline in `.llmwiki/StoreListing.md`.

- **Noted:** 2026-09-16 — while reading the Play Console acquisition report and searching the store as a user would
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

28-day funnel in the Console: **133 impressions → 6 store-listing visitors → 2 installs**.
Visitor→install is 50 %, which is excellent; the app is simply never shown. `title.txt` was
`CountScore - Score Tracker` (en-US) and `CountScore - Suivi de Score` (fr-FR), and Play
ranks heavily on the title.

Measured in the FR store on 2026-09-16:

| Query | Result |
|---|---|
| « compteur de points » | 30 results, **CountScore absent**; all 30 have the keyword in their *title* |
| « suivi de score » | CountScore 9th — a near-zero-volume query |
| « skyjo » | 10+ dedicated Skyjo counters; the per-game long tail is untouched |

`store_listing/en-US/full_description.txt` also used only 2 781 of the 4 000 characters Play
allows, so ~1 200 characters of free keyword surface went unused, and both descriptions led
with the two features that need a self-hosted server — the ones a user searching for a
scorecard cannot use.

**Fix:** put the market's own head term first in the title (`Compteur de points: CountScore`,
`Score Keeper - CountScore`), name the games the app is actually used for in the short and
full descriptions as sentences rather than a comma list (Play's Metadata policy forbids
keyword stuffing), and move group sharing and the ZapZap analysis down the page as advanced
options. No third-party game name in `title.txt` — Uno, Skyjo, Scrabble, Phase 10 and Yahtzee
are trademarks and the title is where Play enforces it.
