import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/keypad_shortcut.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import 'fit_words_text.dart';
import 'player_avatars.dart';

/// Past this many players the caption also says where in the round the entry
/// is ("4/8"): the chips no longer fit on one screen width.
const int kKeypadPositionFrom = 5;

/// The longest score the keypad takes, in digits.
const int kKeypadMaxDigits = 6;

/// A score being typed: its digits and its sign, kept apart so that "−" can be
/// pressed before the first digit.
class _Entry {
  _Entry({this.digits = '', this.negative = false, this.prefilled = false});

  factory _Entry.of(int? score) => score == null
      ? _Entry()
      : _Entry(
          digits: '${score.abs()}',
          negative: score < 0,
          prefilled: true,
        );

  String digits;
  bool negative;

  /// The value was already there when the sheet opened, or when the entry came
  /// back to it: the first digit typed replaces it instead of appending.
  bool prefilled;

  int get value =>
      digits.isEmpty ? 0 : int.parse(digits) * (negative ? -1 : 1);
}

/// The keypad bottom sheet the board enters scores through: one sheet for a
/// whole round, or for one score already on the board.
///
/// **A round** ([ScoreKeypadSheet.round]) walks [players] in seat order —
/// "Next" moves on, and on the last one the key becomes "Validate round". The
/// sheet returns every player's score at once, and the board writes the round
/// only then: closing the sheet halfway leaves nothing behind.
///
/// **One score** ([ScoreKeypadSheet.single]) opens on the tapped player with its
/// current value, and the key reads "Save".
///
/// A game type with a [KeypadShortcut] gets it as the bottom-left key, the 0
/// moving to the bottom of the third column: a value ("0 ZapZap", "162")
/// enters that score and moves on to the next player; an operation ("×2",
/// "+50") applies to the score on display and stays on the player. Every other
/// type has the plain digit 0 bottom-left
/// (wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md).
class ScoreKeypadSheet extends StatefulWidget {
  const ScoreKeypadSheet._({
    required this.players,
    required this.colors,
    required this.totalsBefore,
    required this.roundNumber,
    required this.shortcut,
    required this.initialScores,
    required this.singlePlayerId,
  });

  /// The players whose score is entered, in seat order.
  final List<Player> players;

  /// Each player's display colour, keyed by player id.
  final Map<int, Color> colors;

  /// Each player's total without the score(s) being entered, keyed by id.
  final Map<int, int> totalsBefore;

  final int roundNumber;

  /// The game type's extra key, or null for a plain 0.
  final KeypadShortcut? shortcut;

  /// The scores already there, keyed by id (one score only).
  final Map<int, int?> initialScores;

  /// The one player being edited; null while a round is entered.
  final int? singlePlayerId;

  bool get isRound => singlePlayerId == null;

  /// Opens the sheet on a new round. Returns each player's score keyed by
  /// player id on "Validate round", or null when the sheet was closed.
  static Future<Map<int, int>?> round(
    BuildContext context, {
    required List<Player> players,
    required Map<int, Color> colors,
    required Map<int, int> totalsBefore,
    required int roundNumber,
    KeypadShortcut? shortcut,
  }) =>
      _show(
        context,
        ScoreKeypadSheet._(
          players: players,
          colors: colors,
          totalsBefore: totalsBefore,
          roundNumber: roundNumber,
          shortcut: shortcut,
          initialScores: const {},
          singlePlayerId: null,
        ),
      );

  /// Opens the sheet on one existing score. [players] and [roundScores] are
  /// the round's, shown for context; only [playerId]'s score is edited.
  /// Returns `{playerId: score}` on "Save", or null when the sheet was closed.
  static Future<Map<int, int>?> single(
    BuildContext context, {
    required List<Player> players,
    required Map<int, Color> colors,
    required Map<int, int> totalsBefore,
    required int roundNumber,
    KeypadShortcut? shortcut,
    required Map<int, int?> roundScores,
    required int playerId,
  }) =>
      _show(
        context,
        ScoreKeypadSheet._(
          players: players,
          colors: colors,
          totalsBefore: totalsBefore,
          roundNumber: roundNumber,
          shortcut: shortcut,
          initialScores: roundScores,
          singlePlayerId: playerId,
        ),
      );

  static Future<Map<int, int>?> _show(
          BuildContext context, ScoreKeypadSheet sheet) =>
      showModalBottomSheet<Map<int, int>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).cardTheme.color,
        builder: (_) => sheet,
      );

  @override
  State<ScoreKeypadSheet> createState() => _ScoreKeypadSheetState();
}

class _ScoreKeypadSheetState extends State<ScoreKeypadSheet> {
  late final Map<int, _Entry> _entries = {
    for (final p in widget.players) p.id!: _Entry.of(widget.initialScores[p.id]),
  };

  /// Players already moved past with "Next": their chip shows their score even
  /// when nothing was typed (an empty entry is a 0).
  final Set<int> _passed = {};

  /// Keeps the current chip in view when the players do not all fit.
  final ScrollController _chipScroll = ScrollController();

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  late int _index = widget.isRound
      ? 0
      : widget.players.indexWhere((p) => p.id == widget.singlePlayerId);

  Player get _current => widget.players[_index];
  _Entry get _entry => _entries[_current.id!]!;
  bool get _isLast => _index == widget.players.length - 1;

  void _digit(int d) => setState(() {
        final e = _entry;
        if (e.prefilled) {
          e
            ..digits = ''
            ..negative = false
            ..prefilled = false;
        }
        if (e.digits.length >= kKeypadMaxDigits) return;
        e.digits = e.digits == '0' ? '$d' : '${e.digits}$d';
      });

  void _backspace() => setState(() {
        final e = _entry..prefilled = false;
        if (e.digits.isNotEmpty) {
          e.digits = e.digits.substring(0, e.digits.length - 1);
        } else {
          e.negative = false;
        }
      });

  void _toggleSign() => setState(() {
        _entry
          ..negative = !_entry.negative
          ..prefilled = false;
      });

  /// The game type's key. A value replaces the entry and moves on, as the
  /// "0 ZapZap" key always did; an operation rewrites the score on display
  /// (12 then ×2 is 24) and stays. Either way the next digit typed on this
  /// player starts a new number, as on a calculator — a value that cannot move
  /// on (the round's last player, one score) is not appended to: "162" then 8
  /// is 8, not 1628. A key that does not apply — ×2 on a zero or
  /// a negative score, a result past six digits — does nothing.
  void _shortcut() {
    final shortcut = widget.shortcut;
    if (shortcut == null) return;
    final result = shortcut.apply(_entry.value);
    if (result == null) return;
    setState(() {
      _entry
        ..digits = '${result.abs()}'
        ..negative = result < 0
        ..prefilled = true;
    });
    if (shortcut.movesOn && widget.isRound && !_isLast) _next();
  }

  void _goTo(int index) => setState(() {
        _passed.add(_current.id!);
        _index = index;
        final e = _entry;
        if (e.digits.isNotEmpty) e.prefilled = true;
      });

  void _next() => _goTo(_index + 1);

  void _primary() {
    if (widget.isRound && !_isLast) {
      _next();
      return;
    }
    Navigator.of(context).pop(<int, int>{
      if (widget.isRound)
        for (final e in _entries.entries) e.key: e.value.value
      else
        _current.id!: _entry.value,
    });
  }

  String _display(_Entry e) =>
      '${e.negative ? '−' : ''}${e.digits.isEmpty ? '0' : e.digits}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = _entry;
    final total = (widget.totalsBefore[_current.id] ?? 0) + entry.value;
    final caption = widget.isRound &&
            widget.players.length >= kKeypadPositionFrom
        ? l10n.keypadCaptionWithPosition(_current.name, widget.roundNumber,
            _index + 1, widget.players.length)
        : l10n.keypadCaption(_current.name, widget.roundNumber);

    final String primaryLabel;
    if (!widget.isRound) {
      primaryLabel = l10n.save;
    } else if (_isLast) {
      primaryLabel = l10n.keypadValidateRound;
    } else {
      primaryLabel = l10n.keypadNext(widget.players[_index + 1].name);
    }

    return SafeArea(
      top: false,
      child: Padding(
        key: const Key('keypad_sheet'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Chips(state: this),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    _display(entry),
                    key: const Key('keypad_value'),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: entry.digits.isEmpty && !entry.negative
                          ? scheme.outline
                          : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(caption,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 15, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.keypadTotalAfter(total),
                        key: const Key('keypad_total_after'),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 15, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Pad(
              shortcut: widget.shortcut,
              primaryLabel: primaryLabel,
              onDigit: _digit,
              onBackspace: _backspace,
              onToggleSign: _toggleSign,
              onShortcut: _shortcut,
              onPrimary: _primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// The players of the round, the current one outlined in their colour, with
/// the scores already typed under the names.
class _Chips extends StatelessWidget {
  const _Chips({required this.state});

  final _ScoreKeypadSheetState state;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, constraints) {
      final count = widget.players.length;
      // Up to four share the width; more scroll, one peeking past the edge.
      final width = count <= 4
          ? constraints.maxWidth / count
          : constraints.maxWidth / 4.6;
      // Padding, border, avatar and gaps, then the two lines of text as the
      // user's text scale sizes them.
      final scaler = MediaQuery.textScalerOf(context);
      final height = 64 + (scaler.scale(14) + scaler.scale(12)) * 1.25;
      if (count > 4) {
        // The current chip one place in from the left edge, as far as the
        // list goes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final scroll = state._chipScroll;
          if (!scroll.hasClients) return;
          final target = ((state._index - 1) * width)
              .clamp(0.0, scroll.position.maxScrollExtent);
          if ((scroll.offset - target).abs() < 1) return;
          scroll.animateTo(target,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        });
      }
      return SizedBox(
        height: height,
        child: ListView.builder(
          controller: state._chipScroll,
          scrollDirection: Axis.horizontal,
          itemCount: count,
          itemBuilder: (context, i) {
            final p = widget.players[i];
            final colour = widget.colors[p.id] ?? Colors.grey;
            final current = i == state._index;
            final e = state._entries[p.id]!;
            final shown = e.digits.isNotEmpty || state._passed.contains(p.id);
            final upcoming = widget.isRound && i > state._index && !shown;
            final chip = Container(
              key: Key('keypad_chip_${p.id}'),
              width: width,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: current ? colour : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: current ? 1 : (dark ? 0.6 : 0.5),
                    child: PlayerAvatar(
                      name: p.name,
                      color: colour,
                      size: 36,
                      letters: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.25,
                      color:
                          upcoming ? scheme.outline : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shown && !current ? state._display(e) : '',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            );
            if (!widget.isRound) return chip;
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: current ? null : () => state._goTo(i),
              child: chip,
            );
          },
        ),
      );
    });
  }
}

/// 1-9 in three rows, then the bottom row; ⌫ and the primary action on the
/// right — left to right in every locale, Arabic included, as on a phone or a
/// calculator keypad. The labels keep the locale's own direction.
class _Pad extends StatelessWidget {
  const _Pad({
    required this.shortcut,
    required this.primaryLabel,
    required this.onDigit,
    required this.onBackspace,
    required this.onToggleSign,
    required this.onShortcut,
    required this.onPrimary,
  });

  final KeypadShortcut? shortcut;
  final String primaryLabel;
  final void Function(int) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onToggleSign;
  final VoidCallback onShortcut;
  final VoidCallback onPrimary;

  static const double _keyHeight = 64;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textDirection = Directionality.of(context);
    final digitBg = dark ? const Color(0xFF1F2B2A) : const Color(0xFFEDF4F3);
    final toolBg = dark ? const Color(0xFF26403D) : const Color(0xFFDDE9E7);

    Widget key(
      String keyName, {
      required Widget child,
      required VoidCallback onTap,
      Color? background,
      Color? foreground,
      double height = _keyHeight,
      String? tooltip,
    }) {
      final button = SizedBox(
        height: height,
        child: Material(
          color: background ?? digitBg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: Key(keyName),
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: foreground ?? scheme.onSurface,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground ?? scheme.onSurface),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
      return tooltip == null ? button : Tooltip(message: tooltip, child: button);
    }

    Widget digit(int d) =>
        key('keypad_digit_$d', child: Text('$d'), onTap: () => onDigit(d));

    Widget column(List<Widget> keys) => Expanded(
          child: Column(
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                keys[i],
              ],
            ],
          ),
        );

    final sign = key(
      'keypad_sign',
      child: const Text('±'),
      background: toolBg,
      tooltip: l10n.keypadToggleSign,
      onTap: onToggleSign,
    );
    final zero = digit(0);
    final shortcut = this.shortcut;
    final shortcutKey = shortcut == null
        ? null
        : key(
            'keypad_shortcut',
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                // The label is digits, ×, + and — for ZapZap — a game's name,
                // or the user's own text: the locale's direction, never
                // translated.
                child: Text(shortcut.displayLabel, textDirection: textDirection),
              ),
            ),
            background: dark ? kLeaderGold.withValues(alpha: 0.2) : const Color(0xFFFFF0C2),
            foreground: dark ? const Color(0xFFFFD166) : const Color(0xFF8A5A00),
            onTap: onShortcut,
          );
    const hole = SizedBox(height: _keyHeight);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // With a shortcut: the shortcut, ±, 0. Otherwise the 0 itself sits
          // bottom-left, beside ±.
          column([digit(1), digit(4), digit(7), shortcutKey ?? zero]),
          const SizedBox(width: _gap),
          column([digit(2), digit(5), digit(8), sign]),
          const SizedBox(width: _gap),
          column([digit(3), digit(6), digit(9), shortcutKey == null ? hole : zero]),
          const SizedBox(width: _gap),
          column([
            key(
              'keypad_backspace',
              child: const Icon(Icons.backspace_outlined, size: 26),
              background: toolBg,
              tooltip: l10n.keypadBackspace,
              onTap: onBackspace,
            ),
            key(
              'keypad_primary',
              height: _keyHeight * 2 + _gap,
              background: scheme.primary,
              foreground: scheme.onPrimary,
              onTap: onPrimary,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FitWordsText(
                  primaryLabel,
                  key: const Key('keypad_primary_label'),
                  textDirection: textDirection,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
