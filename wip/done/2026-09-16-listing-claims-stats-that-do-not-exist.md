# The store listing claims a best score and an average the app never computes

- **Noted:** 2026-09-16 — while re-reading the rewritten listing before publishing it
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no
- **Status:** done (2026-09-16) — closed by fix/listing-stats-claim. The sentence now names the statistics the screen actually shows, in all ten languages.

The "Players and statistics" paragraph of `store_listing/<locale>/full_description.txt` promised
"best and average score" in all ten locales — `meilleur score et moyenne`, `bestes und
durchschnittliches Ergebnis`, `最高点、平均点`, and so on.

Neither exists. `lib/screens/player_stats_screen.dart` renders exactly four things:
`l10n.gamesPlayed`, `l10n.wins`, `l10n.winRate` and `l10n.byGameType` — games played, wins, win
rate, and the same three broken down per game type. `DriftPlayerStatsRepository.getStatsByName`
computes nothing else; there is no best-score and no average anywhere in `lib/`, and no `bestScore`
or `averageScore` key in the ARB files.

Promising a feature the app does not have is a Play metadata accuracy problem, and the kind of gap
that earns a one-star review from the first user who goes looking for it. It was introduced by
`docs/store-listing-aso` (#61) and caught before the listing was ever published, so nothing
inaccurate reached the store.

**Fix:** replace the claim with the statistics the screen really shows — games played, games won,
win rate, and the per-game-type breakdown — in all ten locales.
