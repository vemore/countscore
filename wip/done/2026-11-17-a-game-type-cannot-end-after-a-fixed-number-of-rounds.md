# A game type cannot end after a fixed number of rounds

**Status:** done (2026-11-17) — closed by feat/max-rounds-chouineurs. `GameType.maxRounds`
(schema v22, `game_types.max_rounds`, Alembic `0007_game_type_max_rounds`) is OR-ed with the
total condition in `isGameOver`; the editor has a "Maximum rounds" field, the rule lines and
the analysis payload carry it, it syncs with a null as a clear and an absent key as no
change, and the board shows "Round n of N" for a type with a limit.

- **Noted:** 2026-11-17 — the user asked for a "maximum rounds" end condition in the game-type editor, for games such as Chouineurs (4 rounds)
- **Theme:** game-types
- **Area:** app | backend
- **Blocks release:** no

The only end rule a type can carry is one `(gameOverConditionType, gameOverThreshold)` pair
on a **total** (`lib/models/game_type.dart`, `GameOverConditionType`, `isGameOver`). A game
played over a fixed number of rounds — Chouineurs (4), and any house rule "on fait 5 manches"
— never offers its end screen, and the board keeps proposing another round.

The board reads the rule in one place: `_checkGameOverCondition` in
`lib/screens/game_board_screen.dart:578`, which returns false straight away when the type has
no threshold — so a round limit has to be tested before that early return, not inside it.

**Fix:** a separate, optional field, combined with the total condition by **OR** — not a fifth
`GameOverConditionType`, because a type may need both ("first to 500, or 10 rounds at most")
and the dropdown can hold only one.

1. **Model.** `GameType.maxRounds` (`int?`, null = no limit), in `toMap`/`fromMap`/`copyWith`
   (with a `clearMaxRounds` flag, like `clearGameOverCondition`). `isGameOver(totals, {int
   roundCount = 0})` returns true when `maxRounds != null && roundCount >= maxRounds`, else
   applies the total condition as today.
2. **Schema v22** (`db-migration` skill): `game_types.max_rounds INTEGER` nullable, in
   `lib/services/drift/tables.dart`, `database_service.dart` (fresh create + upgrade) and an
   `applyV22` in `lib/services/schema_steps.dart` run by both engines; both `schemaVersion`s
   to 22; `test/migration_v21_to_v22_test.dart`. No back-fill of existing built-ins.
3. **Sync.** Push and pull `max_rounds` in `lib/services/sync/sync_store.dart` (same three
   places as `game_over_threshold`, lines ~503, ~823, ~894). Server: column on `GameType` in
   `backend/app/models/game.py`, Alembic `0007_game_type_max_rounds`, bound `max_rounds:
   (1, 999)` in `backend/app/services/delta_bounds.py`. Touches sync paths: lane C
   (`.llmwiki/ParallelDelivery.md`), and the backend must be deployed before the app ships.
4. **Board.** `_checkGameOverCondition` passes the number of rounds of the current game; the
   existing "once per crossing" dismissal logic is unchanged. Deleting the last round brings
   the game back under the limit and drops the stored "Continue playing", as for a total.
5. **Editor** (`lib/screens/game_types_screen.dart`, "End of game" section): a numeric field
   "Maximum rounds" under the condition dropdown, always visible, empty = no limit, validated
   1–999 (`_ThresholdField` pattern, key `game_type_max_rounds`). Saved through `copyWith`.
6. **Where the rule is read back.** `game_rules_screen.dart` (`_gameOver`) and
   `create_game_screen.dart` (`_gameOver`, the rule line) show "Ends after N rounds" — alone,
   or joined to the total condition. Analysis payload (`game_analysis_screen.dart:200`) sends
   `max_rounds`; `backend/app/services/analysis/{builder,game_rules}.py` read it and add one
   line to the prompt.
7. **Strings** (`i18n-add-string`, 20 languages, ICU plural for the count): the field label,
   its helper ("Leave empty for no limit"), the error, and the rule sentence.
8. **Docs, same PR:** `.llmwiki/Schema.md` (v22, the column), `Sync.md`, `MobileApp.md`
   (`isGameOver`), `LlmProviders.md`, `Testing.md`; `README.md` if it lists the end conditions.

**Acceptance:**
- `GameType(maxRounds: 4).isGameOver([], roundCount: 4)` is true, `roundCount: 3` false; with
  a threshold too, either condition alone ends the game.
- A widget test sets "Maximum rounds" to 4 in the editor, saves, reopens: the field reads 4;
  clearing it saves null.
- `test/migration_v21_to_v22_test.dart`: both engines upgrade a v21 file, the column exists,
  every row reads null, a replay is a no-op.
- A sync round-trip test pushes and pulls `max_rounds`; the server refuses 0 and 1000.
- The board shows the round progress ("Round 3 of 4", `boardRoundProgress`, ICU-correct in
  all 20 languages) in its header for a type with `maxRounds`, and nothing for a type
  without — a widget test covers both.
- `flutter analyze`, `flutter test`, backend `pytest` and the ARB checks are green.

**Decision (user, 2026-11-17):** yes — the game board shows the round progress ("Manche
3/4" / "Round 3 of 4") in its header or an equally visible place, only for a type with
`maxRounds` set.
