# The home screen still shows a built-in game type's untranslated name

**Status:** done (2026-09-16) — closed by fix/home-screen-game-type-name. The game-type
filter on the home screen now renders `gameTypeDisplayName(l10n, gameType)` like every other
site. It was left out of #75 only because `fix/end-of-game-polish` owned the file at the
time; both have merged, so it is one line and one import.

- **Noted:** 2026-09-16 — while making built-in game-type names localized (`feat/game-types-long-tail`)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Since `feat/game-types-long-tail`, a built-in game type's displayed name comes from
`game_types.builtin_key` through `gameTypeDisplayName` (`lib/utils/game_type_name.dart`).
Every screen that shows one was converted — the board, the game types list, the create-game
form, the per-type statistics — **except one**: `lib/screens/home_screen.dart:243` still
renders `Text(gameType.name)`, the seeded literal. So a Japanese user sees `その他` on the
board and `Autre` on the game list, for the same game.

It was left out on purpose, not missed: `home_screen.dart` was owned by the parallel branch
`fix/end-of-game-polish` for the duration, and the rule is to stay out of another pull
request's file rather than to take a conflict.

**Fix:** in `lib/screens/home_screen.dart`, import `../utils/game_type_name.dart` and
replace `Text(gameType.name)` with `Text(gameTypeDisplayName(l10n, gameType))` — `l10n` is
already in scope in that build method. One line plus the import; no test exists for that
screen, and adding one is not worth it for this.
