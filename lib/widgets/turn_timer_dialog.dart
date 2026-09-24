import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/game_sounds.dart';

/// The board's turn timer: pick a duration, start, pause, reset; at zero it
/// says so, vibrates, and plays the timer sound when "Game sounds" is on.
///
/// The countdown lives in this dialog's own State, so the board's is never
/// involved, and closing the dialog stops it. The last duration chosen is
/// remembered per game type ([prefsKey]); a game with no type shares one.
class TurnTimerDialog extends StatefulWidget {
  const TurnTimerDialog({
    super.key,
    required this.gameTypeId,
    required this.initialSeconds,
    required this.sounds,
  });

  /// The duration a game type starts on before one is chosen.
  static const int defaultSeconds = 60;

  /// The step of the − and + buttons, and the shortest duration.
  static const int stepSeconds = 15;

  /// The longest duration.
  static const int maxSeconds = 600;

  final int? gameTypeId;
  final int initialSeconds;
  final GameSounds sounds;

  /// SharedPreferences key of the last duration chosen for [gameTypeId].
  static String prefsKey(int? gameTypeId) =>
      'turnTimerSeconds.${gameTypeId ?? 'none'}';

  static Future<void> show(
    BuildContext context, {
    required int? gameTypeId,
    GameSounds? sounds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(prefsKey(gameTypeId));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => TurnTimerDialog(
        gameTypeId: gameTypeId,
        initialSeconds: stored ?? defaultSeconds,
        sounds: sounds ?? GameSounds.instance,
      ),
    );
  }

  @override
  State<TurnTimerDialog> createState() => _TurnTimerDialogState();
}

class _TurnTimerDialogState extends State<TurnTimerDialog> {
  late int _duration = widget.initialSeconds
      .clamp(TurnTimerDialog.stepSeconds, TurnTimerDialog.maxSeconds);
  late int _remaining = _duration;
  Timer? _ticker;

  bool get _running => _ticker != null;
  bool get _timeUp => _remaining == 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setDuration(int seconds) {
    setState(() {
      _duration = seconds;
      _remaining = seconds;
    });
    unawaited(SharedPreferences.getInstance().then((prefs) => prefs.setInt(
        TurnTimerDialog.prefsKey(widget.gameTypeId), seconds)));
  }

  void _start() {
    if (_timeUp) _remaining = _duration;
    setState(() {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _ticker = null);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _ticker = null;
      _remaining = _duration;
    });
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _remaining--);
    if (_remaining > 0) return;
    _ticker?.cancel();
    setState(() => _ticker = null);
    unawaited(HapticFeedback.heavyImpact());
    unawaited(widget.sounds.play(GameSound.timerEnd));
  }

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final editable = !_running && _remaining == _duration;
    const step = TurnTimerDialog.stepSeconds;
    return AlertDialog(
      title: Text(l10n.turnTimer),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('turn_timer_less'),
                tooltip: l10n.turnTimerLess,
                icon: const Icon(Icons.remove),
                onPressed: editable && _duration > step
                    ? () => _setDuration(_duration - step)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _clock(_remaining),
                  key: const Key('turn_timer_value'),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _timeUp ? theme.colorScheme.error : null,
                  ),
                ),
              ),
              IconButton(
                key: const Key('turn_timer_more'),
                tooltip: l10n.turnTimerMore,
                icon: const Icon(Icons.add),
                onPressed: editable && _duration < TurnTimerDialog.maxSeconds
                    ? () => _setDuration(_duration + step)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: _timeUp
                ? Text(
                    l10n.turnTimerTimeUp,
                    key: const Key('turn_timer_time_up'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w800),
                  )
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('turn_timer_reset'),
          onPressed: _remaining == _duration && !_running ? null : _reset,
          child: Text(l10n.turnTimerReset),
        ),
        FilledButton(
          key: const Key('turn_timer_start'),
          onPressed: _running ? _pause : _start,
          child: Text(_running ? l10n.turnTimerPause : l10n.turnTimerStart),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
