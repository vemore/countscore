import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, on this device, the games whose game-over dialog was answered
/// "Continue playing".
///
/// Kept in SharedPreferences, keyed by the game's uuid: no schema change and
/// nothing synced (decided 2026-09-18). Another device sharing the game asks
/// its own user once. The board clears the entry as soon as the game is back
/// under its threshold, so crossing it again is a new question.
class GameOverDismissals {
  const GameOverDismissals._();

  static const _prefix = 'gameOverDismissed.';

  static String key(String gameUuid) => '$_prefix$gameUuid';

  // Every call is best effort: preferences that cannot be read or written
  // cost at most one extra question, which is not worth an error on the board.

  static Future<bool> isDismissed(String gameUuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key(gameUuid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> dismiss(String gameUuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key(gameUuid), true);
    } catch (_) {}
  }

  static Future<void> clear(String gameUuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key(gameUuid))) await prefs.remove(key(gameUuid));
    } catch (_) {}
  }
}
