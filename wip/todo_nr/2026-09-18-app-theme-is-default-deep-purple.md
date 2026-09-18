# The app theme is the default deep purple, and the home list shows dates before state

- **Noted:** 2026-09-18 — visual refresh, split into one pull request per screen
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Part of the visual refresh, direction A "Material soigné", chosen from four mock-up directions
(split out of `wip/done/2026-09-18-app-looks-like-a-default-material-template.md`). The images
in [`wip/assets/…material-template/`](../assets/2026-09-18-app-looks-like-a-default-material-template/) are the target (light, and `dark-` prefixed); the
interactive page is https://claude.ai/artifact/D3ycxcgzPxHezRrSrmuxiw (private).

**Target:** [home](../assets/2026-09-18-app-looks-like-a-default-material-template/home.png), [dark home](../assets/2026-09-18-app-looks-like-a-default-material-template/dark-home.png); the palette and type of every other image.

`lib/main.dart:102-127` builds both themes from `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`
with Roboto. The violet does not match the icon's teal podium. Home cards are tinted to 10 % of the
game colour (`lib/screens/home_screen.dart:373`), which makes ZapZap amber turn a dull beige. The
subtitle opens with "Created on 18/09/2026" (`home_screen.dart:418`), and whether the game is still
open or who won comes last, or not at all.

This entry goes first: the three board entries build on its theme.

**Fix:**
- **Theme:** seed `#0E8F88` in light and `#5ED8CF` in dark, gold `#F2B705` for the leader,
  defined in one place (a `lib/utils/` theme file or `main.dart`). Nunito is **bundled** under
  `flutter: fonts:`, not `google_fonts`, which fetches from Google at runtime and would add an
  outbound data flow. Add its SIL OFL 1.1 licence to `THIRD_PARTY_LICENSES.md`. ar, hi, ja and
  zh fall back to the system font. Cards are white with a 1 px outline, with no tint and no
  elevation 2.
- **Player colours** (`lib/utils/player_colors.dart`, used by every later entry): a palette of
  10 readable colours, assigned **at display time** by seat order. A player's own `colorValue`
  wins, unless another player of the same game already has it. Nothing is written to the
  database.
- **Home:** a "Resume" hero for the most recently played open game: its name, type, round,
  leader and player avatars. It is hidden when no game is open. Each card shows a game-colour
  icon tile, the name, "type · date", player avatars and a status pill ("In progress", or the
  winner).
- New strings go through `i18n-add-string`.

**Acceptance:**
- `grep -n "deepPurple" lib/` finds nothing, `pubspec.yaml` declares Nunito under
  `flutter: fonts:`, and it has no `google_fonts` dependency.
- A unit test on the palette: 10 players with no colour get 10 distinct colours, and a
  duplicate `colorValue` in one game is reassigned.
- A widget test on home: the hero shows the latest open game and its leader, and is absent
  when every game is finished.
- `flutter analyze` and `flutter test` are green; a PWA screenshot of home in light and dark
  mode is attached to the pull request.
