/// Schema v20, shared by both engines: the last-player-standing end on the
/// built-in types that play to a last survivor.
///
/// Kept out of `lib/services/sync/sync_schema.dart`, where v12 to v19 live,
/// only so that this step does not touch the sync layer; it follows the same
/// contract ([SqlExecutor], idempotent, called from `DatabaseService._upgradeDB`
/// and `AppDatabase.onUpgrade`). See .llmwiki/SchemaV10.md.
library;

import '../../models/game_type.dart';
import '../sync/sync_schema.dart' show SqlExecutor;

/// The built-in types seeded with `lastPlayerOver`, keyed on `builtin_key`, and
/// the threshold they are seeded with: ZapZap and Rami at 100, 6 qui prend at
/// 65 (`GameType.zapzap`, `rami`, `sixNimmt`).
Map<String, int> lastPlayerStandingSeeds() => {
      for (final type in GameType.defaultGameTypes())
        if (type.gameOverConditionType == GameOverConditionType.lastPlayerOver)
          type.builtinKey!: type.gameOverThreshold!,
    };

/// Sets `lastPlayerOver` on the live rows of [lastPlayerStandingSeeds] that
/// have no game-over condition at all.
///
/// feat/last-player-standing (2026-09-20) seeded that condition for a new
/// database only, so every install and group created before it kept a ZapZap
/// that never ends by itself
/// (`wip/done/2026-09-23-a-game-with-one-player-left-does-not-reliably-end-itself.md`).
///
/// - A row whose condition is set is left alone: that is the user's choice,
///   whatever it is. A NULL end the user chose on purpose — "None" (*Aucune*)
///   in the game-type editor — cannot be told apart from one that was never
///   set, so it is overwritten; the user can pick "None" again.
/// - Only a row that still puts a player out on an `over` threshold is
///   touched. A row with no elimination, or one the user turned into an
///   `under` elimination, is left alone: a last-player-over end would have
///   nothing to count, or would contradict it.
/// - The threshold is the row's own `playerDeadThreshold` when it has one, the
///   seeded value otherwise: the game ends when all but one player are out,
///   and "out" is what that row says. An older 6 qui prend puts a player out
///   past 66, not 65, and must end on the same number.
/// - `updated_at` moves, as for any edit. The UPDATE fires the `game_types`
///   capture trigger, so a row linked into a group is pushed on the next sync
///   and the server needs no change.
/// - **Games already finished are re-ranked.** `GameStanding.ranksByEliminationOrder`
///   is true for a `lastPlayerOver` type, so the final standings of every
///   finished ZapZap, Rami and 6 qui prend game — and the places the
///   statistics count — follow the elimination order from now on, not the
///   totals; when everyone went out, the winner can change. The user accepted
///   this on 2026-09-24: elimination order is the right rule for these games.
///
/// Idempotent: a replay finds the condition set and matches nothing. It never
/// inserts, so a type the user deleted stays deleted.
Future<void> applyV20(SqlExecutor execute) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final entry in lastPlayerStandingSeeds().entries) {
    await execute(
      'UPDATE game_types SET gameOverConditionType = ?, '
      'gameOverThreshold = COALESCE(playerDeadThreshold, ?), updated_at = ? '
      'WHERE builtin_key = ? AND deleted_at IS NULL '
      'AND gameOverConditionType IS NULL '
      "AND playerDeadConditionType = 'over'",
      [
        GameOverConditionType.lastPlayerOver.toDbString(),
        entry.value,
        now,
        entry.key,
      ],
    );
  }
}
