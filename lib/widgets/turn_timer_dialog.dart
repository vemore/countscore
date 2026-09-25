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
    final clockStyle = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: _timeUp ? theme.colorScheme.error : null,
    );
    // One layout for every state, so no button moves under the finger
    // between two taps (wip/done/2026-09-25-the-turn-timer-dialog-changes-
    // shape-while-it-runs.md): the dialog takes its full width, every label
    // stays on one line (scaled down when too long), the clock is scaled as
    // its widest value, and "Time's up!" has a slot of its own, empty until
    // zero. Start / pause is one full-width button; Reset and Close share
    // the row under it instead of AlertDialog's actions, which stack in a
    // column the moment one label no longer fits.
    return AlertDialog(
      title: Text(l10n.turnTimer),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('turn_timer_less'),
                    tooltip: l10n.turnTimerLess,
                    icon: const Icon(Icons.remove),
                    onPressed: editable && _duration > step
                        ? () => _setDuration(_duration - step)
                        : null,
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The widest value, invisible: it sets the scale.
                          Visibility(
                            visible: false,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: Text(_clock(TurnTimerDialog.maxSeconds),
                                style: clockStyle),
                          ),
                          Text(
                            _clock(_remaining),
                            key: const Key('turn_timer_value'),
                            style: clockStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('turn_timer_more'),
                    tooltip: l10n.turnTimerMore,
                    icon: const Icon(Icons.add),
                    onPressed:
                        editable && _duration < TurnTimerDialog.maxSeconds
                            ? () => _setDuration(_duration + step)
                            : null,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 28,
              child: _timeUp
                  ? Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.turnTimerTimeUp,
                          key: const Key('turn_timer_time_up'),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('turn_timer_start'),
              onPressed: _running ? _pause : _start,
              child: _oneLine(
                  _running ? l10n.turnTimerPause : l10n.turnTimerStart),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('turn_timer_reset'),
                    onPressed:
                        _remaining == _duration && !_running ? null : _reset,
                    child: _oneLine(l10n.turnTimerReset),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    key: const Key('turn_timer_close'),
                    onPressed: () => Navigator.pop(context),
                    child: _oneLine(l10n.close),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A button label kept on one line, scaled down rather than wrapped, so a
  /// long translation never changes the button's height.
  static Widget _oneLine(String label) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, softWrap: false),
      );
}
