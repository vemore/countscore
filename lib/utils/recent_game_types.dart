import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_type.dart';
import 'game_type_name.dart';

/// [types] with the ones most recently played first, for the New game screen's
/// tiles.
///
/// [gamesNewestFirst] is the game list as `GameRepository.getAll` returns it,
/// newest first. The types those games used come first, in the order of each
/// type's latest game; every other type follows by display name
/// ([sortGameTypesByDisplayName]). Types without an id are left out.
List<GameType> gameTypesRecentFirst(
  AppLocalizations l10n,
  Iterable<GameType> types,
  Iterable<Game> gamesNewestFirst,
) {
  final byId = {
    for (final t in types)
      if (t.id != null) t.id!: t,
  };
  final recent = <GameType>[];
  for (final game in gamesNewestFirst) {
    final type = byId.remove(game.gameTypeId);
    if (type != null) recent.add(type);
  }
  return [...recent, ...sortGameTypesByDisplayName(l10n, byId.values)];
}

/// The [count] tiles to show out of [recentFirst], always including
/// [selectedId]: a type that is not already among the first [count] — the
/// default ZapZap before any game, or one picked from the full list — takes
/// the first tile, and the last one drops out.
List<GameType> gameTypeTiles(
  List<GameType> recentFirst,
  int? selectedId, {
  int count = 6,
}) {
  final tiles = recentFirst.take(count).toList();
  if (selectedId == null || tiles.any((t) => t.id == selectedId)) return tiles;
  final selected = recentFirst.where((t) => t.id == selectedId);
  if (selected.isEmpty) return tiles;
  if (tiles.length == count) tiles.removeLast();
  return [selected.first, ...tiles];
}
