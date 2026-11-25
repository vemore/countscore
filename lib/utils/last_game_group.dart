import 'package:shared_preferences/shared_preferences.dart';

/// The group the last game was created in, so the create screen's group
/// selector starts there (decision 5 of the multi-group plan). A game created
/// local leaves it as it was: the selector's default stays a group, as the
/// single-group switch was on by default. Kept on the device only.
class LastGameGroup {
  LastGameGroup._();

  static const prefsKey = 'lastGameGroupId';

  /// The stored group id; null when none is, or storage cannot be read.
  static Future<String?> read() async {
    try {
      return (await SharedPreferences.getInstance()).getString(prefsKey);
    } catch (_) {
      return null;
    }
  }

  /// Remembers [groupId]. Best effort: a failed write keeps the old default.
  static Future<void> write(String groupId) async {
    try {
      await (await SharedPreferences.getInstance()).setString(prefsKey, groupId);
    } catch (_) {
      // Storage unavailable: the next screen starts on the first group.
    }
  }

  /// The group a new game starts in: [stored] while this device is still in
  /// it, else the first of [groupIds] (the order they were joined); null in
  /// none.
  static String? pick(String? stored, List<String> groupIds) {
    if (groupIds.isEmpty) return null;
    return groupIds.contains(stored) ? stored : groupIds.first;
  }
}
