import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'player_avatars.dart';
import 'player_picker_sheet.dart';

/// The New game screen's players, one row per seat, in seat order: the seat
/// number, the two-letter avatar in the player's display colour, the name, and
/// a handle that drags the row to another seat. The first seat deals. A row
/// swiped away leaves the game.
class SeatOrderList extends StatelessWidget {
  const SeatOrderList({
    super.key,
    required this.players,
    required this.colours,
    required this.onReorder,
    required this.onRemove,
  });

  /// The players, in seat order.
  final List<PlayerSelection> players;

  /// Each seat's display colour (`assignPlayerColors`), same length and order.
  final List<Color> colours;

  /// A row moved from [oldIndex] to [newIndex], already adjusted for the
  /// removal (the index it ends up at).
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: const Key('seat_order_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: players.length,
      onReorderItem: (oldIndex, newIndex) {
        if (newIndex != oldIndex) onReorder(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _SeatRow(
          index: index,
          name: players[index].name,
          colour: colours[index],
          lifted: true,
        ),
      ),
      itemBuilder: (context, index) {
        final player = players[index];
        return Padding(
          key: ValueKey('seat_${player.name}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey('dismiss_${player.name}'),
            direction: DismissDirection.endToStart,
            background: const _RemoveBackground(),
            onDismissed: (_) => onRemove(index),
            child: _SeatRow(
              index: index,
              name: player.name,
              colour: colours[index],
            ),
          ),
        );
      },
    );
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.index,
    required this.name,
    required this.colour,
    this.lifted = false,
  });

  final int index;
  final String name;
  final Color colour;

  /// Drawn under the finger while being dragged: outlined in the primary
  /// colour and raised.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(16);

    return Material(
      key: Key('seat_row_$index'),
      color: theme.cardTheme.color,
      elevation: lifted ? 6 : 0,
      shadowColor: scheme.primary.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: lifted
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: lifted ? scheme.primary : scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            PlayerAvatar(name: name, color: colour, size: 34, letters: 2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
            ),
            if (index == 0)
              Container(
                key: const Key('seat_dealer'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.newGameDealer,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                key: Key('seat_handle_$index'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Icon(
                  Icons.drag_handle,
                  color: lifted ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.remove,
              style: TextStyle(
                  color: scheme.onErrorContainer, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ],
      ),
    );
  }
}
