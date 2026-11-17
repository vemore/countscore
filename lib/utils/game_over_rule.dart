import '../l10n/app_localizations.dart';
import '../models/game_type.dart';

/// The end rule of [type] as one sentence, or null when the type has none.
///
/// The total condition alone ("The game ends as soon as a player reaches 500
/// points"), the round limit alone ("The game ends after 4 rounds"), or both
/// joined — either ends the game, as `GameType.isGameOver` reads them.
///
/// Read by the rules screen's *In CountScore* summary and by the create-game
/// screen's rule line, so the two never describe the same type differently.
String? gameOverRuleLine(AppLocalizations l10n, GameType type) {
  final threshold = type.gameOverThreshold;
  final condition = type.gameOverConditionType;
  final total = threshold == null || condition == null
      ? null
      : switch (condition) {
          GameOverConditionType.firstPlayerOver =>
            l10n.gameRulesEndFirstOver(threshold),
          GameOverConditionType.firstPlayerUnder =>
            l10n.gameRulesEndFirstUnder(threshold),
          GameOverConditionType.lastPlayerOver =>
            l10n.gameRulesEndLastOver(threshold),
          GameOverConditionType.lastPlayerUnder =>
            l10n.gameRulesEndLastUnder(threshold),
        };
  final rounds = type.maxRounds;
  if (rounds == null) return total;
  if (total == null) return l10n.gameRulesEndMaxRounds(rounds);
  return l10n.gameRulesEndOrMaxRounds(total, rounds);
}
