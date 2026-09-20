# The rank-then-seat sort is written twice, in the ranking and on the board

- **Noted:** 2026-09-20 — while merging the two standings screens (`refactor/standings-screen`)
- **Theme:** code-health
- **Area:** app
- **Blocks release:** no

`GameRanking.fromStanding` (`lib/widgets/game_ranking.dart:51-69`) and `BoardData.byRank`
(`lib/widgets/board_lanes.dart:89-95`) sort the same players the same way — by
`GameStanding.ranks`, the seat breaking a tie because `List.sort` is not stable — in two
copies, each with its own comment saying it matches the other. The standings screen and the
board can therefore drift apart silently: a change to one order is a change to nothing else.

**Fix:** one function over a `GameStanding` — `GameStanding.rankedBySeat` or a
`rankedPlayers(standing)` in `lib/models/game_standing.dart` — that both call.
`board_lanes.dart` keys its seat map on the `Player` object and `game_ranking.dart` on
`player.id`; the shared one keys on `id`, as the rest of the app does since v9.

**Note:** `lib/models/game_standing.dart` is owned by the ranking-rule entry
(`2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`), which changes how the order is
computed. Do this one after it, or as part of it — the rule decides *what* the order is, this
entry only decides where it is written.

**Acceptance:**
- One sort in `lib/`, called by both `GameRanking` and `BoardData`.
- The board and the standings show the same order on a tie, covered by a test that would fail
  if only one of them changed.
