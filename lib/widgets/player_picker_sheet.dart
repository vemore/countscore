import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/player_colors.dart';
import 'player_avatars.dart';

/// A player seated at a new game: a name, and the colour value it brings (null
/// for none — the display-time palette then decides, see `player_colors.dart`).
class PlayerSelection {
  final String name;
  final int? colorValue;

  PlayerSelection(this.name, this.colorValue);
}

/// The last game's players, offered as one tap: "Same players as" the last game.
class LastGamePlayers {
  const LastGamePlayers(this.gameName, this.players);

  final String gameName;

  /// In that game's seat order.
  final List<PlayerSelection> players;
}

/// "Who's playing?": picks the players of a new game.
///
/// Resolves to the new seat list, or null when dismissed. Players already
/// seated keep their order; players checked here are seated after them, in the
/// order they were checked. "Same players as" replaces the whole list with the
/// last game's, in its order.
Future<List<PlayerSelection>?> showPlayerPickerSheet(
  BuildContext context, {
  required List<String> knownPlayers,
  required Map<String, int?> colorValues,
  required List<PlayerSelection> seated,
  LastGamePlayers? lastGame,
}) {
  return showModalBottomSheet<List<PlayerSelection>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    showDragHandle: true,
    builder: (context) => PlayerPickerSheet(
      knownPlayers: knownPlayers,
      colorValues: colorValues,
      seated: seated,
      lastGame: lastGame,
    ),
  );
}

class PlayerPickerSheet extends StatefulWidget {
  const PlayerPickerSheet({
    super.key,
    required this.knownPlayers,
    required this.colorValues,
    required this.seated,
    this.lastGame,
  });

  /// Every known player, most frequent co-player first.
  final List<String> knownPlayers;

  /// Each known player's own colour value, by name.
  final Map<String, int?> colorValues;

  /// The players already seated, in seat order.
  final List<PlayerSelection> seated;
  final LastGamePlayers? lastGame;

  @override
  State<PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<PlayerPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  /// The checked players, in seat order.
  late final List<PlayerSelection> _checked = [...widget.seated];

  /// Players named here and not stored yet, in the order they were named.
  final List<String> _created = [];

  /// Their colour values, by name (known players' own, then any seated one's).
  late final Map<String, int?> _colours = {
    ...widget.colorValues,
    for (final p in widget.seated) p.name: p.colorValue,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _all {
    final seen = <String>{};
    return [
      for (final name in [
        ..._created,
        ...widget.seated.map((p) => p.name),
        ...widget.knownPlayers,
      ])
        if (seen.add(name.toLowerCase())) name,
    ];
  }

  List<String> get _shown {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((n) => n.toLowerCase().contains(q)).toList();
  }

  /// The name typed, when it is nobody's yet.
  String? get _newName {
    final name = _query.trim();
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();
    return _all.any((n) => n.toLowerCase() == lower) ? null : name;
  }

  bool _isChecked(String name) => _checked.any((p) => p.name == name);

  void _toggle(String name) {
    setState(() {
      if (_isChecked(name)) {
        _checked.removeWhere((p) => p.name == name);
      } else {
        _checked.add(PlayerSelection(name, _colours[name]));
      }
    });
  }

  void _create() {
    final name = _newName;
    if (name == null) return;
    setState(() {
      _created.add(name);
      _colours[name] = null;
      _checked.add(PlayerSelection(name, null));
      _search.clear();
      _query = '';
    });
  }

  /// Enter in the search field: a new name is created, an exact match checked.
  void _submit(String value) {
    if (_newName != null) {
      _create();
      return;
    }
    final lower = value.trim().toLowerCase();
    final match = _all.where((n) => n.toLowerCase() == lower);
    if (match.isNotEmpty && !_isChecked(match.first)) _toggle(match.first);
    setState(() {
      _search.clear();
      _query = '';
    });
  }

  void _sameAsLastGame() {
    final last = widget.lastGame!;
    setState(() {
      _checked
        ..clear()
        ..addAll([
          for (final p in last.players)
            PlayerSelection(p.name, _colours[p.name] ?? p.colorValue),
        ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = _shown;
    final newName = _newName;

    // Checked players in their seat colours — the ones the screen will show;
    // the others in the colour they would take after them.
    final seatColours =
        assignPlayerColors([for (final p in _checked) p.colorValue]);
    final unchecked = [for (final n in shown) if (!_isChecked(n)) n];
    final otherColours = assignPlayerColors([
      for (final p in _checked) p.colorValue,
      for (final n in unchecked) _colours[n],
    ]).skip(_checked.length).toList();
    Color colourOf(String name) {
      final seat = _checked.indexWhere((p) => p.name == name);
      if (seat >= 0) return seatColours[seat];
      final i = unchecked.indexOf(name);
      return i >= 0 ? otherColours[i] : kPlayerPalette.first;
    }

    final last = widget.lastGame;
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Padding(
      key: const Key('who_is_playing_sheet'),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.whoIsPlayingTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              key: const Key('player_picker_search'),
              controller: _search,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.whoIsPlayingSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
              // Enter seats the name and keeps the field for the next one.
              onEditingComplete: () {},
              onSubmitted: _submit,
            ),
            if (newName != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('player_picker_create'),
                  onPressed: _create,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.whoIsPlayingCreate(newName)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_all.isNotEmpty)
              Text(
                l10n.whoIsPlayingFrequent.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: shown.isEmpty
                    ? (_query.trim().isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(l10n.noPlayersFound,
                                style: TextStyle(color: scheme.outline)),
                          ))
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final name in shown)
                            _PlayerChip(
                              key: Key('player_chip_$name'),
                              name: name,
                              colour: colourOf(name),
                              checked: _isChecked(name),
                              onTap: () => _toggle(name),
                            ),
                        ],
                      ),
              ),
            ),
            if (last != null && last.players.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('player_picker_same_as'),
                  onPressed: _sameAsLastGame,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.whoIsPlayingSameAs(last.gameName)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: FilledButton(
                key: const Key('player_picker_confirm'),
                onPressed: () => Navigator.pop(context, _checked),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(l10n.whoIsPlayingConfirm(_checked.length),
                    style: const TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    super.key,
    required this.name,
    required this.colour,
    required this.checked,
    required this.onTap,
  });

  final String name;
  final Color colour;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: true,
      selected: checked,
      child: Material(
        color: checked
            ? Color.alphaBlend(colour.withValues(alpha: 0.12),
                theme.cardTheme.color ?? scheme.surface)
            : theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: checked
              ? BorderSide(color: colour, width: 2)
              : BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 14, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatar(name: name, color: colour, size: 32, letters: 2),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: checked ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (checked) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 18, color: colour),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
