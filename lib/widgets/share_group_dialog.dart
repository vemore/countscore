import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';

/// Asks which group a local game is shared with, from its board; the chosen
/// group's id, or null when the user backs out. With one group it is today's
/// confirmation naming it; with several, a choice with none preselected —
/// sharing cannot be undone, so the group is picked, never assumed.
Future<String?> showShareGroupDialog(BuildContext context, List<GroupSession> groups) {
  if (groups.isEmpty) return Future.value();
  return showDialog<String>(
    context: context,
    builder: (_) => _ShareGroupDialog(groups: groups),
  );
}

class _ShareGroupDialog extends StatefulWidget {
  const _ShareGroupDialog({required this.groups});

  final List<GroupSession> groups;

  @override
  State<_ShareGroupDialog> createState() => _ShareGroupDialogState();
}

class _ShareGroupDialogState extends State<_ShareGroupDialog> {
  late String? _chosen = widget.groups.length == 1 ? widget.groups.single.groupId : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = widget.groups;
    final Widget content;
    if (groups.length == 1) {
      content = Text(l10n.shareGameConfirm(groups.single.groupName));
    } else {
      content = SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _chosen,
          onChanged: (id) => setState(() => _chosen = id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.shareGameChooseGroup),
              const SizedBox(height: 8),
              for (final g in groups)
                RadioListTile<String>(
                  key: Key('share_group_${g.groupId}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(g.groupName),
                  value: g.groupId,
                ),
            ],
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(l10n.shareWithGroup),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('share_group_confirm'),
          onPressed: _chosen == null ? null : () => Navigator.pop(context, _chosen),
          child: Text(l10n.shareWithGroup),
        ),
      ],
    );
  }
}
