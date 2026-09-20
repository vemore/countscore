import 'package:flutter/material.dart';

/// What the game-type editor lets a user pick for a type: its icon and its
/// colour. Both lists are closed sets — the editor offers nothing else — so
/// they live here, where a test can read them.

/// The icons the icon picker offers.
///
/// **Every icon `GameType.defaultGameTypes()` seeds must be in here**, or
/// changing a seeded type's icon is a one-way door: the picker could not put
/// the original back. `test/utils/game_type_appearance_test.dart` fails when a
/// seed introduces an icon this list lacks.
///
/// The glyphs carry no tooltip: they have no names in the ARB files and naming
/// 34 of them is a translation task of its own. Only the *current* one is
/// labelled, because that label is about state, not about the glyph.
const List<IconData> kGameTypeIcons = <IconData>[
  Icons.sports_esports,
  Icons.casino,
  Icons.style,
  Icons.games,
  Icons.sports,
  Icons.flash_on,
  Icons.grid_on,
  Icons.stars,
  Icons.favorite,
  Icons.emoji_events,
  Icons.psychology,
  Icons.rocket_launch,
  Icons.sports_soccer,
  Icons.sports_basketball,
  Icons.deck,
  Icons.celebration,
  Icons.casino_outlined,
  Icons.sports_tennis,
  Icons.sports_baseball,
  Icons.diamond,
  Icons.workspace_premium,
  Icons.auto_awesome,
  Icons.account_tree,
  Icons.extension,
  Icons.local_fire_department,
  Icons.offline_bolt,
  Icons.shield,
  Icons.emoji_objects,
  Icons.music_note,
  Icons.palette,
  Icons.school,
  Icons.sports_kabaddi,
  // Seeded by Rami and Triomino. They were missing until 2026-09-20, so
  // opening either type and changing its icon could not be undone.
  Icons.style_outlined,
  Icons.change_history,
];

/// The colours the colour picker offers.
///
/// A game type's colour is drawn at full opacity as its icon over a card that
/// is white in the light theme and near-black in the dark one, so a free ARGB
/// wheel could pick a colour that vanishes in one theme or the other. These
/// swatches all keep a contrast ratio of at least [kGameTypeColorMinContrast]
/// against both themes' surfaces *and* against the 10 % / 15 % tinted cards the
/// icon actually sits on — `test/utils/game_type_appearance_test.dart` checks
/// every one of them.
///
/// The seeded `cardColorValue`s are deliberately **not** aligned on this list:
/// rewriting them would recolour types a user already has. A current colour
/// that is not in here is shown by the picker as an extra swatch instead.
const List<Color> kGameTypePalette = <Color>[
  Color(0xFFE53935), // red
  Color(0xFFDC4A18), // deep orange
  Color(0xFFB96C0E), // orange
  Color(0xFF6B8A16), // lime
  Color(0xFF388E3C), // green
  Color(0xFF0F8F45), // emerald
  Color(0xFF00897B), // teal
  Color(0xFF0E8F88), // brand teal
  Color(0xFF0A87AE), // cyan
  Color(0xFF2B7BC9), // blue
  Color(0xFF5A6FD6), // indigo
  Color(0xFF8464DD), // violet
  Color(0xFFA94FC6), // purple
  Color(0xFFD51FB0), // magenta
  Color(0xFFE91E63), // pink
  Color(0xFF92715F), // brown
  Color(0xFF607D8B), // blue grey
  Color(0xFF7B7B7B), // grey
];

/// The contrast ratio every [kGameTypePalette] entry clears against both
/// themes' backgrounds — WCAG 2.1's threshold for a non-text graphic (1.4.11).
const double kGameTypeColorMinContrast = 3.0;

/// The backgrounds a game-type colour is drawn over, both themes: the two
/// surfaces of `buildAppTheme` and the two card colours.
/// `lib/screens/game_types_screen.dart` and
/// `lib/widgets/game_type_tile_grid.dart` tint them with the colour itself,
/// which the contrast test composites in.
const List<Color> kGameTypeColorBackgrounds = <Color>[
  Color(0xFFFFFFFF), // light card
  Color(0xFFF3F8F7), // light surface
  Color(0xFF172221), // dark card
  Color(0xFF0E1716), // dark surface
];
