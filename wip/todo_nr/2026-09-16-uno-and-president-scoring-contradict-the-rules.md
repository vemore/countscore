# The seeded Uno and Président types score the opposite way from the usual rules

- **Noted:** 2026-09-16 — while researching the rules text for the game-rules page
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Writing `assets/rules/rules_fr.md` meant checking, game by game, what each seeded type
actually scores. Two of the ten do not match the way the game is normally counted.

**Uno** — `GameType.uno()` (`lib/models/game_type.dart`) is `isLowestScoreWins: true` with
no threshold. The widespread rule is the opposite: the player who goes out **collects** the
value of everyone else's remaining cards (numbers at face value, action cards 20, wild
cards 50) and the game runs to **500 points**, highest total winning. The app's shape fits
the other common house rule — each player marks what was left in their own hand as a
penalty, lowest wins — which is a legitimate variant, just not the one a new user expects
after reading the box.

**Président** — `GameType.president()` is `isLowestScoreWins: true` with
`gameOverConditionType: firstPlayerOver` and `gameOverThreshold: 11`. The common barème is
the other way round: the Président scores 2 (or 3) points a hand, the Vice-Président 1, and
the highest total wins. A threshold of 11 with lowest-wins reads as a penalty count for the
last player of each hand — again defensible, again not the default reading.

Both are user-editable rows, so nobody is stuck; and both were left untouched by
`feat/game-rules`, which only documents them. The shipped rules text says plainly what the
app expects and how to flip it, so the contradiction is visible rather than silent — see
the closing paragraph of the `uno` and `president` sections in `assets/rules/rules_fr.md`.

**Fix:** decide per game whether the seed follows the box or the house variant. If it
follows the box, change the factory **and** migrate existing rows, which is not free:
flipping `isLowestScoreWins` on a type that already has games would silently reverse their
standings. A safer route is to leave the seeds alone and let the first-run seeding offer
both variants as two types ("Uno (à 500)" / "Uno (pénalités)"), which also feeds the
long-tail work in `2026-09-16-default-game-types-miss-the-long-tail.md`.
