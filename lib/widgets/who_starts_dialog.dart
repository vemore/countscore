import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "Who starts?": draws one of the game's players at random and shows the
/// name, with a button to draw again. Entirely local — no state is stored.
class WhoStartsDialog extends StatefulWidget {
  const WhoStartsDialog({super.key, required this.playerNames, this.random});

  /// The game's players, in board order. Never empty: the board only offers
  /// the entry when the game has players.
  final List<String> playerNames;

  /// Injected by tests only.
  final Random? random;

  static Future<void> show(
    BuildContext context,
    List<String> playerNames, {
    Random? random,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => WhoStartsDialog(playerNames: playerNames, random: random),
    );
  }

  @override
  State<WhoStartsDialog> createState() => _WhoStartsDialogState();
}

class _WhoStartsDialogState extends State<WhoStartsDialog> {
  late final Random _random = widget.random ?? Random();
  late String _chosen = _draw();

  String _draw() =>
      widget.playerNames[_random.nextInt(widget.playerNames.length)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.whoStarts),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.casino_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            _chosen,
            key: const Key('who_starts_name'),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (widget.playerNames.length > 1)
          TextButton(
            key: const Key('who_starts_again'),
            onPressed: () => setState(() => _chosen = _draw()),
            child: Text(l10n.whoStartsAgain),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
