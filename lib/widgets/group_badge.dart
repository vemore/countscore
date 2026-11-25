import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';
import '../utils/group_label.dart';

/// The group a shared game belongs to, as a small rounded label with its name
/// — on the game cards, the Resume card and the board's title, where a cloud
/// icon used to say only "shared". The name comes from the session of
/// [groupId]; a group this device does not know by name (recorded before
/// names were kept, not loaded yet, or no `GroupProvider` above, as in some
/// screen tests) shows the cloud icon alone.
class GroupBadge extends StatelessWidget {
  const GroupBadge({super.key, required this.groupId, this.color, this.maxWidth = 120});

  final String groupId;

  /// The text and outline colour; the scheme's primary when null.
  final Color? color;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.select<GroupProvider?, GroupSession?>((g) => g?.session(groupId));
    final name = session?.groupName.trim();
    final colour = color ?? Theme.of(context).colorScheme.primary;
    if (session == null || name!.isEmpty) {
      // An invite code is no label for a badge; the tooltip still names the
      // group by it ([groupLabel]).
      return Tooltip(
        message: session == null ? l10n.gameSharedBadge : l10n.gameSharedWith(groupLabel(l10n, session)),
        child: Icon(Icons.cloud_done_outlined, size: 16, color: colour),
      );
    }
    return Tooltip(
      message: l10n.gameSharedWith(name),
      child: Container(
        key: Key('group_badge_$groupId'),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          border: Border.all(color: colour.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(999),
        ),
        // One line of text, the icon inside it: squeezed, the label ends in an
        // ellipsis rather than overflowing a row it shares with the game's name.
        child: Text.rich(
          TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 3),
                child: Icon(Icons.group_outlined, size: 12, color: colour),
              ),
            ),
            TextSpan(text: name),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: colour, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
