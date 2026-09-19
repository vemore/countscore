import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../utils/game_type_name.dart';

/// The New game screen's game types: a grid of colour-and-icon tiles, three a
/// row, the selected one tinted in its colour, outlined and ticked.
class GameTypeTileGrid extends StatelessWidget {
  const GameTypeTileGrid({
    super.key,
    required this.types,
    required this.selectedId,
    required this.onSelected,
  });

  /// The tiles, in order (most recently played first).
  final List<GameType> types;
  final int? selectedId;
  final ValueChanged<GameType> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final width = (constraints.maxWidth - 2 * gap) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final type in types)
            SizedBox(
              width: width,
              height: 84,
              child: GameTypeTile(
                key: Key('game_type_tile_${type.id}'),
                type: type,
                selected: type.id == selectedId,
                onTap: () => onSelected(type),
              ),
            ),
        ],
      );
    });
  }
}

/// One game type: its icon on a tint of its colour, its name under it.
class GameTypeTile extends StatelessWidget {
  const GameTypeTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final GameType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final colour = type.cardColor;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? Color.alphaBlend(colour.withValues(alpha: 0.14),
                theme.cardTheme.color ?? scheme.surface)
            : theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.transparent
                              : colour.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(type.icon, size: 22, color: colour),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        gameTypeDisplayName(l10n, type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full list of game types, as a bottom sheet: resolves to the one picked,
/// or null when dismissed.
Future<GameType?> showAllGameTypesSheet(
  BuildContext context, {
  required List<GameType> types,
  required int? selectedId,
}) {
  final l10n = AppLocalizations.of(context)!;
  final sorted = sortGameTypesByDisplayName(l10n, types);
  return showModalBottomSheet<GameType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.gameType, style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                key: const Key('all_game_types_list'),
                controller: controller,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 8),
                children: [
                  for (final type in sorted)
                    ListTile(
                      key: Key('all_game_types_${type.id}'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: type.cardColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(type.icon, size: 22, color: type.cardColor),
                      ),
                      title: Text(gameTypeDisplayName(l10n, type)),
                      trailing: type.id == selectedId
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      selected: type.id == selectedId,
                      onTap: () => Navigator.pop(context, type),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
