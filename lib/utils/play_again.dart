import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../providers/game_provider.dart';
import '../providers/group_provider.dart';

/// Starts the next game of the evening from [source] and opens it on [board].
///
/// The one path behind "Play again" on the end-of-game ranking and on a game's
/// menu in the home list: same type, same win rule, same players in the same
/// order (`GameProvider.playAgain`). [source] is not modified. A rematch of a
/// shared game is shared too — its players already are.
///
/// The new board replaces everything above the home screen, so back from it
/// returns to the game list rather than to the previous game's ranking.
Future<void> playAgain(
  BuildContext context,
  Game source, {
  required WidgetBuilder board,
}) async {
  final gameProvider = context.read<GameProvider>();
  final group = context.read<GroupProvider>();
  final navigator = Navigator.of(context);

  final newGameId =
      await gameProvider.playAgain(source, nextGameName(source.name));
  if (source.isShared && group.isJoined) {
    try {
      await group.shareGame(newGameId);
    } on GroupActionException {
      // Names the server refuses: the new game stays local.
    }
  }
  await gameProvider.loadGame(newGameId);

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: board),
    (route) => route.isFirst,
  );
}

/// The name of the game after [name]: its trailing number plus one
/// (`Skyjo 3` → `Skyjo 4`), or ` 2` appended when it has none — the one just
/// played was the first.
String nextGameName(String name) {
  final match = RegExp(r'(\d+)$').firstMatch(name);
  // tryParse: a run of digits too long for an int is a name, not a counter.
  final number = match == null ? null : int.tryParse(match.group(1)!);
  if (match == null || number == null) return '$name 2';
  return '${name.substring(0, match.start)}${number + 1}';
}
