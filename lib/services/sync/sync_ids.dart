import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Normalises a name the way the server's `name_normalized` column expects:
/// trimmed and lower-cased. Two devices that type "Alice" and "alice " mean one
/// player, and must compute the same server identity for her.
String normalizeName(String name) => name.trim().toLowerCase();

/// RFC 4122 name-based UUID, version 5 (SHA-1).
String uuid5(String namespace, String name) {
  final ns = _uuidBytes(namespace);
  final digest = sha1.convert([...ns, ...utf8.encode(name)]).bytes;
  final bytes = digest.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// The server uuid a player or game type takes when it is first linked into a
/// group: derived from the group and the normalised name, so every device that
/// shares an "Alice" computes the same one and the server sees one player rather
/// than a name clash.
String linkedRemoteUuid(String groupId, String entityType, String name) =>
    uuid5(groupId, '$entityType:${normalizeName(name)}');

/// The server uuid a game type takes when it is first linked into a group.
///
/// A built-in type derives it from its stable key rather than from its name:
/// its name is localized, so two devices in different locales hold different
/// names for the same type and would otherwise mint two server rows for it. A
/// user's own type has no key and falls back to the name, as before.
///
/// The namespace is `game_type_builtin:` rather than `game_type:builtin:`, so a
/// user type someone names "builtin:zapzap" cannot collide with the key
/// `zapzap`: a name always lands under `game_type:`.
String linkedGameTypeRemoteUuid(String groupId, String? builtinKey, String name) =>
    builtinKey == null || builtinKey.isEmpty
        ? linkedRemoteUuid(groupId, 'game_type', name)
        : uuid5(groupId, 'game_type_builtin:$builtinKey');

List<int> _uuidBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('not a uuid', uuid);
  }
  return [
    for (var i = 0; i < 32; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

/// Player names the server accepts: 1–32 characters, each a letter (with any
/// combining marks that follow it — the vowel signs of "रवि", Arabic harakat), a
/// digit, a space, `-`, `'` or `.` (`backend/app/models/player.py`,
/// `is_valid_player_name`). A mark with no letter to combine with is refused.
/// Checked before a game is shared, so the user hears it from the app rather than
/// as a rejected delta.
bool isSyncablePlayerName(String name) =>
    name.isNotEmpty && name.length <= 32 && _playerName.hasMatch(name);

final _playerName = RegExp(r"^(?:\p{L}\p{M}*|\p{N}|[ \-'.])+$", unicode: true);
