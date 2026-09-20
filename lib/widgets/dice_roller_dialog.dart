import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The board's dice roller: choose 1 to [maxDice] six-sided dice, roll them,
/// and read each face and the total. Entirely local — no state is stored.
class DiceRollerDialog extends StatefulWidget {
  const DiceRollerDialog({super.key, this.initialCount = 2, this.random})
      : assert(initialCount >= 1 && initialCount <= maxDice);

  /// d6 only: the 2026-09-18 refinement decided there is no kind selector.
  static const int faces = 6;
  static const int maxDice = 6;

  /// How many dice are rolled when the dialog opens.
  final int initialCount;

  /// Injected by tests only.
  final Random? random;

  static Future<void> show(BuildContext context, {Random? random}) {
    return showDialog<void>(
      context: context,
      builder: (_) => DiceRollerDialog(random: random),
    );
  }

  @override
  State<DiceRollerDialog> createState() => _DiceRollerDialogState();
}

class _DiceRollerDialogState extends State<DiceRollerDialog> {
  late final Random _random = widget.random ?? Random();
  late int _count = widget.initialCount;
  late List<int> _values = _roll();

  List<int> _roll() => [
        for (var i = 0; i < _count; i++)
          _random.nextInt(DiceRollerDialog.faces) + 1,
      ];

  void _setCount(int count) => setState(() {
        _count = count;
        _values = _roll();
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = _values.fold<int>(0, (sum, v) => sum + v);
    return AlertDialog(
      // Wider than the default 40 dp inset: the six count choices need the room
      // to stay on one row on a 412 dp phone.
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(l10n.diceRoller),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.diceCount, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            // A Row, not a Wrap: AlertDialog sizes its column with
            // IntrinsicWidth, and a Wrap's intrinsic width ignores its own
            // spacing, so the sixth chip wrapped alone however wide the screen
            // was. The Row reports the spacers too, and the FittedBox keeps the
            // six on one line even at a large text scale.
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var n = 1; n <= DiceRollerDialog.maxDice; n++) ...[
                      if (n > 1) const SizedBox(width: 6),
                      ChoiceChip(
                        key: Key('dice_count_$n'),
                        label: Text('$n'),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selected: n == _count,
                        onSelected: (_) => _setCount(n),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _values.length; i++)
                  _Die(key: Key('dice_value_$i'), value: _values[i]),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.diceTotal(total),
              key: const Key('dice_total'),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('dice_roll_again'),
          onPressed: () => setState(() => _values = _roll()),
          child: Text(l10n.diceRollAgain),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// One die: its face value as a numeral in a rounded square.
class _Die extends StatelessWidget {
  const _Die({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
