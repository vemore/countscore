# The board and the home card still crown the earlier seat on a tie

- **Noted:** 2026-09-19 — fixing the Ranking crown in fix/elimination-and-crown
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The Ranking and end screens now crown `GameStanding.soleLeader`, which is null on a tie for
the lead. Two other readers still use `GameStanding.leader`, which breaks a tie by seat
(`lib/models/game_standing.dart`): the board's crown and outlined lane
(`lib/widgets/board_lanes.dart`, `board_rows.dart`, the ranking ribbon), so a round of all
zeros crowns seat 1 on the board; and the home screen's finished-game pill, which shows
"won by" the earlier seat of a tied game (`lib/screens/home_screen.dart`, `_buildStatusPill`)
while the end screen names every tied player. They were left alone because other pull
requests were editing those files, and because the board also uses `leader != null` to
decide whether to sort by rank and show places.

**Fix:** the board crowns `standing.soleLeader` and keys its rank sort and place labels on
`standing.hasScores`; the home pill shows the tie (or no single name) when `soleLeader` is
null and scores exist.

**Acceptance:**
- A board test with one round of equal scores shows no `board_leader_crown`, and the places
  still read `#1` for every player.
- A home test on a finished tied game does not name a single winner.
