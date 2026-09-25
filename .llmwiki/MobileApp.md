# Mobile App

> Scope: the Flutter app's own structure — entry point, state, screens, models.
> Related: [[DataLayer]] · [[SchemaV10]] · [[I18n]] · [[Web]] · [[Testing]]
> Updated: 2026-09-25

## Facts

`lib/` holds `main.dart` and eight directories: `screens/`, `widgets/`, `models/`,
`providers/`, `repositories/` (the interfaces, and their Drift implementations in
`repositories/drift/`), `services/`, `utils/` and `l10n/` (the ARB files and the committed
generated localizations; `*.g.dart` is gitignored). Each is described below, by what it
holds rather than by a file count.

### Entry point

`lib/main.dart` — `MyApp` wraps a `MultiProvider` (6 providers) around a `MaterialApp`.
Material 3, seed colour `Colors.deepPurple`.

> **Status: Outdated** (2026-09-18) — both themes come from `buildAppTheme` in
> `lib/utils/app_theme.dart` (see *Utilities* below): teal seed `#0E8F88` light, `#5ED8CF`
> dark, the bundled Nunito font. `main()` also calls `registerFontLicenses()`.

10 `supportedLocales` with a
`localeResolutionCallback` falling back to `en`. Home is `HomeScreen`.
There is no DI container. `main()` is `async` and calls
`WidgetsFlutterBinding.ensureInitialized()`, then awaits three things before `runApp`, in
this order: `ThemeProvider.load()`, `BackendProvider.load()`, and
`ReviewPromptService.instance.recordFirstLaunch()` (`lib/main.dart:27`). The first two
results are handed to `MyApp`, so the first frame is already themed and already knows
whether the connected features exist; the third starts the review prompt's clock (below).

### Providers — `lib/providers/`, all `ChangeNotifier` (provider ^6.1.2)

| Provider | Responsibility |
|---|---|
| `game_provider.dart` | The substantial one. Repositories are constructor-injectable, defaulting to the six Drift implementations over `AppDatabase.instance`. Owns `_games`, `_currentGame`, `_currentPlayers`, `_currentRounds`, `_scores` (keyed `"playerId_roundId"`) and `_roundCounts` (game id → rounds played, one grouped query in `loadGames`, kept in step by `addRound`/`deleteRound`). Game/round/score CRUD plus stats. |
| `game_type_provider.dart` | Game-type list CRUD, `getGameTypeById`. The 22 built-in types are rows like any other; their *displayed* name comes from `lib/utils/game_type_name.dart`, not from the row. |
| `settings_provider.dart` | Wakelock toggle, *Game sounds* (key `gameSounds`, off by default, the one `GameSounds` reads) and the board's layout, `BoardView` (`lanes` or `rows`, key `boardView`, app-wide) — all SharedPreferences-backed, read by `ready` — and DB export/import. The **only** caller of `DatabaseService` for I/O. Exposes `supportsDbExportImport => !kIsWeb`. |
| `theme_provider.dart` | `ThemeMode` only, persisted to SharedPreferences under `themeMode` as `ThemeMode.name`. `load()` is called from `main()` before `runApp`. |
| `group_provider.dart` | Group membership and the sync loop — create/join/leave/rotate, the device list and `revokeDevice`, `shareGame`, `syncNow`, `SyncStatus`, and a `SyncEvent` stream shown as snackbars by `_SyncEventListener` in `main.dart`. A `ChangeNotifierProxyProvider` over `BackendProvider`: runs only with a URL **and** a device token. Calls `GameProvider.refreshFromSync` after remote changes. See [[Sync]]. |
| `backend_provider.dart` | The self-hosted backend base URL, SharedPreferences key `backendUrl`, **no default**. `check()` validates and canonicalises what the user typed; `isConfigured` gates every connected feature. `load()` is called from `main()` before `runApp`. |

### Screens — `lib/screens/`

`settings_screen` is a `StatefulWidget` since the Server section (it owns the URL
`TextEditingController`).

`home_screen` (the game list, below) · `game_board_screen` (the scoring grid) ·
`game_types_screen` · `create_game_screen` ·
`game_analysis_screen` (the LLM analysis, with its row of voice chips — see
[[LlmProviders]]) ·
`players_screen` (every known player: games and wins as the leaderboard counts them —
`buildLeaderboard` over the finished results — a two-letter `PlayerAvatar` in the
leaderboard's colour that opens the colour picker, rename and delete; the delete
confirmation alone counts every game, open ones too, from `getPlayerGameCounts`) ·
`player_stats_screen` (the leaderboard) and `player_card_screen`, below ·
`settings_screen` ·
`about_screen` · `standings_screen` (where the game stands — its result once it is finished, below) · `game_rules_screen` ·
`group_settings_screen`.

**The game-type editor.** `game_types_screen`'s create/edit form is `_GameTypeDialog`, a
`StatefulWidget` of its own (it owns three `TextEditingController`s and the per-field
errors). What it saves is `existingGameType.copyWith(...)`, never a fresh `GameType`:
`DriftGameTypeRepository.update` writes every column of `toMap()`, so a column the form does
not show — `rules`, `rulesSlug`, `isDefault` — would otherwise be written NULL by an edit of
the colour ([[SchemaV10]]). Clearing a condition back to *None* goes through
`clearPlayerDeadCondition` / `clearGameOverCondition`, since `x ?? this.x` cannot express a
null. Validation is on the fields, never in a snackbar: `ScaffoldMessenger.of` reaches the
app's messenger, which draws *behind* the modal barrier. A threshold is required as soon as
a condition type is chosen, digits only (`keyboardType` is a keyboard hint, not a
constraint), at most `kMaxGameTypeThreshold` (1000000); the name is trimmed and capped at 64,
the server's `max_length` (`backend/app/models/game.py`). Two guards sit on top: flipping
`isLowestScoreWins` on a type with at least one **finished** game asks first, naming the
count, because `GameStanding.ranks` is recomputed from the scores every time and would
reverse every past standing; and a game-over condition pulling against the chosen winner is
flagged under the switch without blocking the save. A deletion asks
`GameTypeRepository.countGames` **before** offering itself, so the refusal is a localized
ICU plural rather than the repository's English exception. After a save that changed a
condition on a type that has rules, the screen *offers* the rules editor — nothing is
rewritten.

The form's last section is the **keypad shortcut** (`Key('game_type_shortcut_kind')`): *None*,
a value, a multiplication (positive scores only, which the item says), or an addition; then
the number (a leading minus allowed) and an optional label of up to 12 **code points** — a
formatter refuses the 13th as it is typed, the unit the model and the server count, so an
emoji label is never accepted and then dropped — whose hint is the label the key shows
without one. Changing the kind clears the label. The number is checked against
`KeypadShortcut.boundsOf` — values −999999 to 999999, multipliers 2 to 10, additions −99999
to 99999 but not 0 — and an error under the field names the range
(`keypadShortcutAmountRange`; `keypadShortcutAddRange` for an addition, which also names
the 0 it refuses). It is offered on every type, built-in ones included; *None*
saves `clearKeypadShortcut`.

**Player statistics.** `player_stats_screen` is a leaderboard: a row of game-type chips
(`Key('stats_chip_all')`, then `stats_chip_<key>` for each type with a finished game, most
played first), a teal hero for the best win rate with the leader's avatar in a
`kLeaderGold` ring, then one card per player — place, two-letter `PlayerAvatar`, games,
wins · win rate and a bar of the rate in the player's colour; a column header wider than its
column ("PARTIDAS") shrinks to fit on one line. A player with fewer than
`kMinGamesToRank` (5) finished games of the filter is listed last with no place. Tapping a
player opens `player_card_screen` on the same filter: a strip of the leaderboard's avatars
to switch player; games, wins and average place; the place over the last `kRankChartGames`
(12) games, drawn by `RankChartPainter` (a `CustomPainter`, no chart package) with wins as
gold dots and a trend; the current win streak and, on one type, the best final total; then
the average and best final totals and the opponent most often finished ahead of. On *All
games* the best total is left out whenever the games mix both win rules. Everything is
computed in `lib/models/player_stats.dart` from `PlayerStatsRepository.getFinishedGameResults`
(through `GameProvider.getFinishedGameResults`): live games with `finishedAt` set and at least
one score on a live round, each player keyed by the global `players.uuid`. Places share on a
tie (1, 2, 2, 4) and are `GameStanding.ranks`' places exactly: each `FinishedGameResult`
carries the `RankingRule` its game's type calls for
([above](#the-ranking-rule)) and, under `eliminationOrder`, the round each participant went
out at, and compares through the same `outranksUnder`. The repository derives both —
`GameStanding.ranksByEliminationOrder` over the live `game_types`, then one walk of the
game's scores in round order — so a finished ZapZap game gives the player card, the win
count, the average place and the rank chart the places its standings screen shows
(`wip/done/2026-09-20-statistics-rank-by-score-while-the-standings-rank-by-elimination.md`).
A game of any other type never leaves `RankingRule.score`.
Colours come from `playerColorsByUuid` — `assignPlayerColors` over the players in the order
they first appear walking back from the latest game — so the latest game shows exactly its
board's colours and the filter never recolours anyone. Tests:
`test/models/player_stats_test.dart`, `test/screens/player_stats_screen_test.dart`.

`group_settings_screen` is Settings → Group → *Comments and usage*, reached only from the
Group section once the device is in a group: the group's comment style (three chips,
`narrative` · `humorous` · `analytical`) and language (the app's ten, by endonym), read from
`GET /groups/me` and written back at once with `PATCH /groups/me/settings`, and the month's
LLM spending from `GET /groups/me/usage`, in US dollars against the budget. Nothing is kept
on the device: each visit reads the server again. It calls nothing without a server URL and
a device token (`GroupProvider.canReachGroup`). The budget is shown, never edited — see
[[Sync]].

`game_analysis_screen` sends a game shared with the device's group through
`GroupProvider.gameAnalysis` (`POST /groups/me/games/{uuid}/comments`, device token) and any
other game to `BackendClient.gameAnalysis` (the stateless endpoint): same payload, but the
group's budget, language and — when no voice was ever picked, which the screen shows as no
chip selected and the `analysisStyleGroupDefault` hint — the group's style apply. A 409 is
the group's spent budget, shown as `analysisErrorGroupBudget`. Tests:
`test/screens/game_analysis_group_test.dart`.

`home_screen` opens on a **Resume** card (`Key('resumeHero')`) for `resumableGame(games)` —
the open game with the latest `lastModified ?? createdAt`, which `GameRepository.update`
stamps on every score — showing its name, type, round (`roundCountOf`), leader and players,
with the game's overflow menu; there is no card when every game is finished. The other games
follow under *Recent*, each a white outlined card: a tile in the game type's colour (the
colour lives in the tile only, never tinting the card), the name, "type · date"
(`DateFormat.MMMd`, `yMMMd` for another year), the player avatars, and a status pill — *In
progress*, or the winner with a trophy — *Finished* under a flag when nobody scored or on a
tie for the lead, whose tooltip then names every tied player (`gameEndTie`). Leader and
winner come from `GameProvider.standingOf(game, gameType:)`, a `GameStanding`
(`lib/models/game_standing.dart`) of the players in seat order, their totals over the rounds
that still exist and the game's ranking rule ([below](#the-ranking-rule), which is why the
card passes the type): `soleLeader`, null on a tie, so a tied Resume card names no leader.
It is read per card, as the player names were before, without touching
the current game. The filter applies to both the card and the list.

From `kHomeGridBreakpoint` (600 dp, `home_screen.dart`) the *Recent* cards form a grid:
`homeGridColumns(width)` fits as many cards of at least `kHomeGridMinCardWidth` (360 dp) as
the padded width holds, and never fewer than two — 3 columns at 1200 dp, 4 at 1600. Each
grid row is an `IntrinsicHeight` row of equal-height cards, not a `GridView`, because a card
is as tall as its content. A grid card narrower than 360 dp (two columns, 600–775 dp) is
`compact`: its status pill moves beside the players, under the name. The Resume card keeps
the full width, and below 600 dp the list is one column as before.

`game_rules_screen` takes its `GameType` as a constructor argument rather than reading a
provider: both callers — the board's overflow menu and the game-type list — already hold
it, and the list has no "current game". It shows, in order, the type's own scoring summary
derived from its fields, then the user's rules if any, else the ruleset shipped for
`rulesSlug` (`lib/services/game_rules_catalog.dart`), else an empty state. See [[I18n]] for
why those rulesets are assets and not ARB keys.

`create_game_screen` — **New game**, direction A of the refresh
(`wip/assets/2026-09-19-new-game-screen-is-a-bare-form/target.png`): the name as a light
title field, prefilled with `nextGameName` of the last game (before any, the localized
`defaultGameName(1)`: "Partie 1", "Game 1"); the
game types as six tiles (`game_type_tile_grid.dart`), the types of the latest games first
and the rest by display name (`gameTypesRecentFirst` in `lib/utils/recent_game_types.dart`),
the selected type always on a tile (`gameTypeTiles`), *All games (N)* for the full list;
under them one line with the type's win rule and end condition, or for *Other* a segmented
choice of win rule; the players in **seat order** (`seat_order_list.dart`), coloured by
`assignPlayerColors` over the seats — the rule the board applies to the stored players, so a
player shows one colour here and on the board — with *Add a player* opening the "who's
playing" sheet (`player_picker_sheet.dart`); and a full-width *Start · N players* in the
`bottomNavigationBar`, enabled from two players. The seat order written is the list's order
(`orderIndex`). `boardBuilder` replaces the board in tests. The *Share with the group*
switch stays, under the players, while the device is in a group.

`about_screen` reads the displayed version from `package_info_plus`
(`PackageInfo.fromPlatform()`, held in a `static final` future) — i.e. from `pubspec.yaml`
`version:` at build time; the ARB key `version` is only the `"Version {version}"` frame.
It also carries a "Rate CountScore" `ListTile` (ARB key `rateApp`) that opens the Play
listing through `url_launcher` — the one rating path the user can take at will, next to the
prompt below.

### Widgets — `lib/widgets/`

Seventeen components shared out of the screens:

- `board_lanes.dart` — the board's default layout ([below](#the-board)): `BoardData` (what
  both layouts draw from: players in seat order, rounds, a `GameStanding`, colours, the
  elimination tests, the tap callbacks), `BoardLanes`, and the pieces the rows share —
  `BoardScoreText` (a zero on an amber pill, `·` for no score), `BoardCrown`, `BoardSkull`
  (drawn by a `CustomPainter`: Material Icons has no skull), `boardMark` (which of the two
  sits above an avatar), `boardTint`.
- `board_rows.dart` — `BoardRows`, the one-row-per-player layout.
- `game_ranking.dart` — the ranking the `StandingsScreen` draws, open or finished
  ([below](#the-standings-screen)): `GameRanking.of` (the current game best first, its ranks,
  colours, leader, winners and elimination tests; `GameRanking.fromStanding` builds the same
  from a `GameStanding`, for a test or a caller without a provider). The order is the
  standing's own `rankedPlayers`, which the board returns too — one sort, not two
  ([below](#the-ranking-rule)). `RankedPlayers` (the
  podium of the top three *and* the list of every player under it, the top three twice on
  purpose — since 2026-09-20 the list is the whole ranking, place 1 first, its first place on
  the primary container),
  `rankingSummary` (type · rounds · win rule). The elimination rule on a total is
  `GameType.isEliminated` / `isNearElimination` (`lib/models/game_type.dart`), which the board
  reads too.
- `score_keypad_sheet.dart` — `ScoreKeypadSheet`, the bottom sheet every score is entered
  through ([below](#the-board)).
- `share_result_button.dart` — `ShareResultButton`, the app-bar share action of the end
  screen, the standings and the analysis: from one `GameRanking.of` it builds the text
  (`buildGameResultShareText`) and a `ResultShareCard`, draws the card to a PNG
  (`renderWidgetToPng`), and hands both to `systemShareResult` — `share_plus` with the PNG as
  an `XFile.fromData` (`kShareImageName`) and `downloadFallbackEnabled: false`; if that share
  throws (a browser that cannot share files), the text alone is shared, as before. A card
  that fails to draw costs only the image; a sheet that fails to open becomes a `shareFailed`
  snackbar. Its `share` seam (`ShareResultFn`: text, subject, image) is passed through by the
  standings and the analysis screen for tests; `renderImage` catches the card instead of drawing it.
- `result_share_card.dart` — `ResultShareCard`, the shared picture: `shareResultTitle` (the
  date), the `rankingSummary` line, `RankedPlayers` itself — so the image ranks, colours and
  crowns as the screen does — and `appTitle`, 400 logical pixels wide on the theme's
  `surface`. No new string: it reuses the shared text's keys.

- `player_avatars.dart` — `PlayerAvatar` (an initial, or the first `letters` letters, on a
  colour, drawn in `onPlayerColor`) and `PlayerAvatarStack` (a game's players overlapping,
  two letters each as on the board, in seat order and in their `playerColorsById` colours,
  "+N" past `maxShown`). The home Resume hero rings its stack in its text colour, so a teal
  or cyan player does not vanish into the teal card.
- `fit_words_text.dart` — `FitWordsText`, a label for a narrow fixed-size box that never
  breaks inside a word: it shrinks its font until every word fits, and past its minimum
  scales each whole line down. The keypad's tall key uses it.
- `game_type_tile_grid.dart` — the New game screen's game types (below): `GameTypeTileGrid`,
  three colour-and-icon tiles a row, the selected one tinted in its colour, outlined in the
  primary and ticked; `showAllGameTypesSheet`, the full list by display name.
- `seat_order_list.dart` — `SeatOrderList`, the New game screen's players, one row per seat:
  seat number, two-letter `PlayerAvatar`, name, a *deals* badge on seat 1, and a handle
  (`ReorderableDragStartListener`) that drags the row to another seat; a row swiped to the
  start leaves the game.
- `player_picker_sheet.dart` — "Who's playing?" (`showPlayerPickerSheet`), which replaced
  the `player_picker_dialog.dart` of the old form: a search field that also creates a player
  (Enter, or *Create "name"*), the known players as chips most frequent first
  (`PlayerRepository.getGameCountsByName`), and *Same players as "last game"*. It resolves to
  the new seat list of `PlayerSelection`s (name, colour value): seats already taken keep
  their order, players checked here follow in the order checked. A new player is stored with
  no colour value — the display-time palette colours him.
- `who_starts_dialog.dart` — the board's overflow-menu **Who starts?**: draws one of the
  game's players at random, shows the name, and draws again on request. Nothing stored,
  nothing sent.
- `dice_roller_dialog.dart` — the board's overflow-menu **Roll dice**, next to **Who
  starts?** and offered whatever the players: choose 1 to 6 six-sided dice (chips), each
  choice rolls at once, *Roll again* re-rolls; each die and the total are shown. Opens on
  2 dice; the count is not remembered. Nothing stored, nothing sent. The six count chips are
  a `Row` in a `FittedBox`, not a `Wrap`, and the dialog takes a 16 dp `insetPadding`: they
  stay on one line (see *Decisions & History*).
- `turn_timer_dialog.dart` — the board's overflow-menu **Turn timer**, next to **Roll dice**:
  − and + by 15 s (15 s to 10 min), start / pause, reset; at zero "Time's up!" in the error
  colour, a heavy haptic and `GameSound.timerEnd`. The countdown is a 1 s `Timer.periodic`
  in the dialog's own `State`, so the board's is never touched and closing the dialog stops
  it. The last duration is remembered **per game type**, SharedPreferences
  `turnTimerSeconds.<game type id>` (`turnTimerSeconds.none` for a game without a type),
  default 60 s. No schema, no permission.
- `group_settings_section.dart` — Settings → Group: create or join a group, show its invite
  code, leave it, and show where sync stands; usable only once a server URL is set. *New
  code* is shown to the group's owner only; *Comments and usage* opens
  `group_settings_screen`.
- `group_devices_sheet.dart` — Settings → Group → Devices: the group's devices, this one and
  the owner marked; the owner alone gets revoke and *Make owner* on the others ([[Sync]]).
- `pwa_update_listener.dart` — `PwaUpdateListener`, wrapped around every screen by
  `MaterialApp.builder` in `main.dart`: on the web, once the service worker has a deploy's
  build waiting, a snackbar that stays until acted on (`pwaUpdateReady`, action
  `pwaUpdateReload`) and applies it. Does nothing off the web ([[Web]], "Offline and updates").

### Services — `lib/services/`

- `review_prompt.dart` — `ReviewPromptService`, and its `ReviewPromptService.instance`
  singleton, which decides when to hand the Play in-app review sheet (`in_app_review`) to
  the user. `recordFirstLaunch()` is awaited in `main()` and stamps the first launch once
  (SharedPreferences `reviewPromptFirstLaunch`). `onGameFinished()` is called, unawaited,
  wherever `GameProvider.setGameFinished` reports the transition that finishes a game — the
  board's finish menu entry and its game-over rule (`game_board_screen.dart`) and the game list's card menu
  (`home_screen.dart`). It asks only when every guard holds: at least `minGamesFinished`
  (3) games finished — `GameRepository.countFinished()`, the live games whose `finishedAt`
  is set, read when the prompt is due, so an undone finish or a reopen drops out and there
  is no stored counter to drift — `minAge` (7 days) since the first launch, not already asked for this
  app version (`reviewPromptVersion`), not already asked this session. There is no
  pre-prompt and nothing depends on the outcome, which Play never reports. The platform is
  behind the `ReviewRequester` seam; `PlatformReviewRequester` answers unavailable on the
  web, where `in_app_review` has no implementation, and an unavailable platform does not
  burn the version. The session guard is instance state, which is why every caller goes
  through `instance`.
- `backend_client.dart` — HTTP to the self-hosted backend, `BackendException` ([[Api]]).
- `commentary_report.dart` — the `mailto:` that reports an AI commentary, sent from the
  user's own mail app.
- `game_rules_catalog.dart` — the rulesets shipped under `assets/rules/` ([[I18n]]).
- `database_service.dart` — the sqflite bootstrap migrator; `drift/` — `AppDatabase` and
  its tables ([[DataLayer]]).
- `sync/` — the group-sync engine, store and stream ([[Sync]]).
- `uuid.dart` — platform-neutral v4 UUIDs.
- `pwa_update.dart` — `listenForPwaUpdate` / `applyPwaUpdate`: `dart:js_interop` over the
  `window.countscorePwa` object `web/flutter_bootstrap.js` defines (`pwa_update_web.dart`),
  and a no-op stub on native (`pwa_update_stub.dart`) ([[Web]]).
- `game_over_dismissals.dart` — `GameOverDismissals`: the games whose rule-raised end screen was
  answered "Continue playing", on this device only (SharedPreferences
  `gameOverDismissed.<game uuid>`; not synced, no schema). A deleted game leaves its key
  behind — one boolean, never read again.
- `game_sounds.dart` — `GameSounds` and its `GameSounds.instance`: the elimination, victory
  and turn-timer sounds (`GameSound`), bundled under `assets/sounds/` (WAV, synthesised by
  `scripts/generate_sounds.py`, CC0). One setting governs all three: Settings → Sounds →
  *Game sounds* (`SettingsProvider.gameSounds`), SharedPreferences `gameSounds`, **off by
  default**, read on every play so a board needs no provider. The platform is behind the
  `SoundPlayer` seam — `AudioplayersSoundPlayer` (audioplayers 6.8.1, MIT, one short-lived
  low-latency player per sound) in the app, `test/support/fake_sound_player.dart` in tests;
  `GameBoardScreen.sounds` takes the instance. A failure to play is swallowed. On the web
  the browser allows sound only after a user gesture, and a score typed on the keypad is one;
  audioplayers fetches the asset from the app's own origin (`connect-src 'self'`) and plays
  it in an `<audio>` element (`default-src 'self'`), so the PWA's CSP needs no change.

### Utilities — `lib/utils/`

Cross-cutting helpers, since 2026-09-16: `insets.dart`, `game_type_name.dart` — the switch
from a built-in game type's `builtin_key` to its localized name, which every screen showing a
game type's name goes through ([[I18n]]) — `play_again.dart`, `app_theme.dart`,
`player_colors.dart`, `recent_game_types.dart` (the New game screen's tile order),
`game_type_appearance.dart` — the two closed sets the game-type editor offers,
`kGameTypeIcons` (34 glyphs, every seeded one among them) and `kGameTypePalette` (18
swatches, each at least `kGameTypeColorMinContrast` = 3.0 against both themes' surfaces and
their tinted cards, checked in `test/utils/game_type_appearance_test.dart`); the seeded
`cardColorValue`s are deliberately left outside it, and a type already coloured otherwise
keeps its colour as an extra swatch —
`game_result_share.dart`, `widget_image.dart` and `undo_snack_bar.dart` — `undoSnackBar`, the one snackbar that
offers an action back: `persist: false` and `kUndoSnackBarDuration` (6 s), so the Undo
goes away on its own instead of staying up until dismissed, Flutter's default for a
snackbar with an action.

`game_result_share.dart` — `buildGameResultShareText`, a pure function from a `GameRanking`
to the shared text: "Game of {date}" (`DateFormat.yMMMd` in the l10n locale, the game's
`createdAt`), the `rankingSummary` line, one `shareResultStanding` line per player in the
ranking's order (ties share a place), the commentary when sharing the analysis, then
`shareResultFooter` naming `appTitle` with `kPlayStoreUrl` —
`https://play.google.com/store/apps/details?id=com.vemore.countscore`, built from the
application id, no tracking parameter. Tested in `test/utils/game_result_share_test.dart`
(a lowest-wins and a highest-wins game, all ten locales). It also names the shared PNG,
`kShareImageName` (`countscore-result.png`).

`widget_image.dart` — `renderWidgetToPng(context, widget)`: builds, lays out and paints a
widget in a `PipelineOwner`/`BuildOwner` of its own under a loose `BoxConstraints` (default
400 × 4000 logical, drawn at 3x), lending it the tapped context's themes
(`InheritedTheme.captureAll`), localizations (`Localizations.override`) and media query,
then `RenderRepaintBoundary.toImage` → PNG, and unmounts the tree. Nothing is shown on
screen. In a widget test its future completes only under `tester.runAsync`.

`app_theme.dart` — the one place the look is defined, and the palette's only home: the icon
(`design/icon/`), the store assets and `scripts/compose_screenshots.py` read their colours
from it, and no document restates them. `buildAppTheme(brightness)` seeds
`ColorScheme.fromSeed` with `kBrandSeedLight` (`#0E8F88`, the brand teal) or
`kBrandSeedDark` (`#5ED8CF`, the teal of the icon's third pawn) under `DynamicSchemeVariant.fidelity`, sets `primary` to the seed
itself, and sets the surfaces (`#F3F8F7` / `#0E1716`), white (dark: `#172221`) cards with a
1 px `outlineVariant` border and elevation 0, and `fontFamily: kAppFontFamily` (`Nunito`).
`kLeaderGold` (`#F2B705`) is the leader's colour for the screens that mark one. Nunito is
bundled under `flutter: fonts:` in `pubspec.yaml` — four static weights (400, 600, 700, 800)
in `assets/fonts/`, cut from the variable font — never through `google_fonts`, which
downloads from Google at runtime. Arabic, Devanagari and CJK text, which Nunito does not
cover, falls back to the system font. `registerFontLicenses()` (called from `main()`) adds
`assets/fonts/OFL.txt` to the licence page.

`player_colors.dart` — every player colour on screen is assigned **at display time**, never
written back. `playerColorsById(playersInSeatOrder)` returns a colour per player id:
in seat order, a player's own `colorValue` wins unless an earlier seat already shows it
**or one that clashes with it**; everyone else takes the first colour of `kPlayerPalette`
(ten mid-tone colours) that clashes with nothing the game shows; past ten the palette
repeats by seat. Two colours clash (`playerColorsClash`) when they are equal or closer than
`kPlayerColorClashDistance` (12) in CIEDE2000 (`colorDistance`): Material `green` and
`lightGreen` are 10.5 apart, the two closest palette colours 15.0.
`assignPlayerColors(colorValues, alreadyShown:)` is the same rule over bare colour values,
optionally avoiding colours another part of the screen shows. `onPlayerColor(colour)` is
the initial's colour on it — white or `black87`, whichever has the higher WCAG contrast
(`contrastRatio`), so every palette colour gets at least 4.5:1 and a legacy yellow a dark
initial. The home avatars, the board's lanes and rows, the standings, the keypad
chips, the Players screen, the statistics and the New game screen's seats and "who's playing" chips use it.


`insets.dart` — `withBottomInset(context, base)` adds `MediaQuery.paddingOf(context).bottom`
to an `EdgeInsets`. A `BoxScrollView` (`ListView`, `GridView`) inserts `MediaQuery.padding`
on its main axis **only when its `padding` argument is null**, so every root scrollable that
passes an explicit padding loses that compensation and cannot scroll its last row clear of
the system navigation bar — the app is edge-to-edge on `targetSdk` 36 and cannot opt out
(`android/app/src/main/kotlin/com/example/countscore/MainActivity.kt` is a bare
`FlutterActivity`; there is no `SystemChrome` call anywhere in `lib/`). Its eight call sites
are the root scrollables of `about_screen.dart:31` (on the child `Padding` — a
`SingleChildScrollView` never gets the compensation at all),
`game_types_screen.dart:50` (plus `kFabClearance`, below),
`home_screen.dart:91` (the drawer) and `:335`, `player_stats_screen.dart:119`, `player_card_screen.dart:110`,
`players_screen.dart:134`, and in `standings_screen.dart` on the *Play again* button's
`Padding` under the list, the last thing above the navigation bar. Only the bottom edge is compensated:
`Scaffold` drops the top padding for a body under an `AppBar`
(`scaffold.dart`, `removeTopPadding: widget.appBar != null`) and keeps the bottom one unless
there is a `bottomNavigationBar`, and `DrawerHeader` adds the status-bar height itself.
`settings_screen.dart:117` and `game_analysis_screen.dart` need nothing — the first passes no
padding, the second is a `SingleChildScrollView` inside the `SafeArea(top: false)` at l. 328.

`insets.dart` also holds `kFabClearance` (`56 + 16 + 16`): the bottom padding a list under
a floating action button needs so its last row, and that row's menu, scroll out from under
the button; pass it through `withBottomInset` so the navigation bar is added on top. Used
by `game_types_screen.dart`.

Every `IconButton` in `lib/` has a `tooltip:` from `AppLocalizations` — it is what TalkBack
and a browser screen reader announce, and what a test finds it by. One that deliberately has
none carries a `// No tooltip …` comment saying why (the icon picker's 32 unnamed glyphs);
`test/utils/icon_button_tooltips_test.dart` scans `lib/` for the rest.

`game_type_name.dart` — `gameTypeDisplayName(l10n, type)` and `isBuiltinRename(...)`. A
built-in type's name is read from its `builtin_key`, never from the stored `name`, which is
what lets two devices in different locales hold the same type. Renaming one clears the key.
`sortGameTypesByDisplayName(l10n, types)` orders a list by that displayed name; every
screen listing game types calls it, since the repository returns them unordered ([[I18n]]).

`play_again.dart` — `playAgain(context, source, board:)`, the one path behind *Play again*
(the standings' button, and a finished game's menu entry on the home screen, where an
unfinished game shows the same action as "New with same players"). It calls
`GameProvider.playAgain` — `createGame` with the source's type, win rule and players in
`orderIndex` order, nothing else read or written on the source — shares the new game if the
source was shared, and opens its board with `pushAndRemoveUntil(isFirst)`, so back returns
to the game list. The new game is named by `nextGameName`: `Skyjo 3` → `Skyjo 4`.
`StandingsScreen` and `HomeScreen` take an optional `boardBuilder`, for tests only, as the
board's `analysisRepo` is.

### Models — `lib/models/`

`game`, `game_type`, `keypad_shortcut`, `player`, `round`, `score`, `game_analysis`, `analysis_style`. Plain classes with
`toMap`/`fromMap`. `player.dart` has no `gameId` since v9 — its `id` is a
`game_players.id`. See [[SchemaV10]].

`analysis_style.dart` is an enum whose `id` is an ASCII string that travels to the backend
and into SharedPreferences (`analysisStyle`) and whose label is translated. It mirrors
`PERSONAS` in `backend/app/services/analysis/personas.py`: a new voice is added in both
places plus the ten ARB files.

`keypad_shortcut.dart` is the keypad's per-type key: a closed representation — a kind
(`value`, `multiply`, `add`), an integer amount within that kind's bounds, an optional label —
that exists only valid. `tryCreate` refuses an amount out of bounds, `decode` returns null for
anything that is not exactly a shortcut and never throws, so a malformed stored or pulled value
reads as "no shortcut" and cannot break the keypad. `game_type.dart` re-exports it.

`game.dart` carries `finishedAt` since v12, with `isFinished` next to `isShared`. Its
`copyWith` takes a `clearFinishedAt` flag: `x ?? this.x` cannot express "set this back to
null", and reopening a game is exactly that. `GameProvider.setGameFinished` is the single
write path — it returns true only for the transition that finishes a game, which is what
gates the Play review sheet.

Both screens show the state and both can change it: a status pill (in progress, or the winner) on the game
list card, a chip beside the title on the board, and a menu entry that finishes or reopens.
Finishing opens the standings (below); reopening is confirmed by a snackbar whose
**Undo** action finishes the game again (the repo's only `SnackBarAction`, built by
`undoSnackBar`; it expires after 6 s). The entry is
offered on a game that has at least one round or is already
finished — a game with no round was never played, which is why the list needs
`GameProvider.roundCountOf`. While the game is finished the board's round button
(`board_add_round`) is disabled; **Reopen** or **Continue playing** brings it back. Score
edits stay open, to correct a mistake.

`_GameBoardScreenState._maybeShowGameOver` finishes the game and opens its standings after
a score edit, after a round is added and after one is deleted — every mutation that can move
a total onto or past the game type's threshold — whenever the provider brings the open game new
totals or a new finished state (`_checkGameOverOnTotals`, a `GameProvider` listener: a group
sync pull reloads the game through `refreshFromSync`, so a round typed on another device ends
the game on this board too), and once on the board's first build. `_gameOverDismissed` keeps it to one crossing and re-arms as soon as
the condition is false again. Raised by the rule, the screen offers **Continue playing**,
which pops back to the board, reopens the game and is written to `GameOverDismissals`, keyed
by `Game.uuid`, and read back when the board opens, so leaving the board does not re-ask;
the stored answer is removed as soon as the condition is false. The back button leaves the
game finished. A finished game is never raised again; its standings stay one tap away
behind the app bar's single leaderboard button (`board_standings`, `_openStandings`).
A game the check finds **finished and past its threshold** — ended here, on another device or
by hand — is recorded as answered, in `_gameOverDismissed` and in `GameOverDismissals`, as
"Continue playing" is: a reopen, typed here or pulled from a device that chose to keep
playing, is never undone by this board re-ending the game on the next round. A crossing
this board did not end is not its to re-end.

While a score keypad sheet is open (`_keypadOpen`) the rule finishes the game without
pushing the end screen over the sheet; it opens when the sheet closes
(`_endScreenPending`, `_showPendingEndScreen`). "Round N" re-reads `isFinished` when its
sheet returns and drops the round if the game ended meanwhile, by the rule or by a pull; a
score edit is still written.

#### The standings screen

`StandingsScreen` (`lib/screens/standings_screen.dart`) is the app's one standings screen,
in two states, told apart by the current game's own `isFinished`:

- **open** — the title is *Ranking*, and the screen shows where the game stands;
- **finished** — the title is *Results*, and a headline names the winner
  (`game_end_headline`; a tie at the top names every player on it, and a game with no score
  says only *Game finished*), with **Analysis** beside *Play again*.

It shows the current game — the caller loads it, and the paths that end a game record it
finished first (`_finishAndShowEnd` on the board; the home card menu loads it before
pushing). Common to both states: the game type · rounds · win rule on one line
(`ranking_summary`), then `RankedPlayers` (`lib/widgets/game_ranking.dart`):
a podium of the top three in their display colours with their totals (first raised in the
middle; each step as high as the player's place, so a tie shares a step), the sole leader
(`GameStanding.soleLeader`) ringed in `kLeaderGold` under a `BoardCrown` — nobody is crowned
before the first score or on a tie for the lead — then the others in rank order
(`GameStanding.ranks`, ties sharing a place, under the game's ranking rule — [below](#the-ranking-rule)). As on the board, a total within 20
points of the type's elimination threshold is orange — except on the first step, whose
filled block keeps `onPrimary`, and on a first-place row, whose primary container does the
same — and an eliminated player is faded and struck through. When the standing's rule is
`RankingRule.eliminationOrder` — a *finished* game only — a second line under the summary
(`ranking_elimination_note`, `rankingEliminationNote`) says the places follow the
elimination order and not the totals; nothing shows it anywhere else, so the nineteen other
types carry no extra line, and the board's `#n` badges are untouched
(`wip/done/2026-09-20-elimination-ranking-is-unexplained-on-screen.md`). Actions: **Play again**
(`playAgain`, keyed `game_end_play_again` on a finished game and `ranking_play_again` on an
open one) and, only on a finished game with `BackendProvider.isConfigured`, **Analysis**
(`GameAnalysisScreen`) — Play again otherwise spans the row. Unlike the board's menu, a
cached analysis alone does not bring the button back. With `offerContinue` — the rule ended
the game, the user did not ask — a **Continue playing** action (`game_end_continue`) pops
the route with `true`, which the board reads as "reopen this game". The app bar's share
action (`ShareResultButton`) sends the standings as text and as a picture
(`ResultShareCard`); the analysis screen's share adds the commentary, and is offered only
once there is one. Every path that finishes a game — rule, board menu, home menu — calls
`ReviewPromptService.onGameFinished` once, on the transition `setGameFinished` reports.

Its three push sites are the board's leaderboard button and rule (`_openStandings`, which
reads the `true` back) and "End game" on the home list. There is no named route: all three
push a `MaterialPageRoute`.

#### The ranking rule

What "best" means is the standing's, not the screen's: `GameStanding`
(`lib/models/game_standing.dart`) carries a `RankingRule`, and every place in the app —
the board's `#n` badges and rank sort, the standings screen, the shared text and picture,
the home cards — reads it through `GameStanding.ranks` and `rankedPlayers`.

- **`RankingRule.score`** — the total decides, under the game's `isLowestScoreWins`. The
  default, the fallback, and what an **open** game always shows whatever its type: while the
  game runs, the score order is the right thing to show.
- **`RankingRule.eliminationOrder`** — the survivor first, then the others by *reverse*
  elimination order (the last one out ranks best), the total only breaking a tie. A
  **finished** game of a type that both puts a player out on a threshold
  (`playerDeadConditionType` + `playerDeadThreshold`) and ends on the last player standing
  (`gameOverConditionType` is `lastPlayerOver` **or** `lastPlayerUnder`, the two conditions
  `GameType.isGameOver` already treats as one shape) follows it. Of the twenty-two seeded
  types only `zapzap`, `rami` and `six_nimmt` do — all three `lastPlayerOver`; a
  `lastPlayerUnder` type can only come from the game-type editor.
  `GameStanding.ranksByEliminationOrder` is the one test.

The comparison itself is one function, `outranksUnder` (`lib/models/game_standing.dart`),
which `GameStanding._isBetter` and `FinishedGameResult` (the statistics, below) both call:
the two used to compare separately, and a finished ZapZap game got one order on its
standings and another on the player card
(`wip/done/2026-09-20-statistics-rank-by-score-while-the-standings-rank-by-elimination.md`).

Nothing of this is stored: no column, no migration. The round a player went out at is the
first round whose running total crosses the threshold, walked from the rounds in play order
(`RoundRepository.getByGame` returns them `ORDER BY roundNumber ASC`) and the scores already
in hand. `GameStanding.forGame` is the single seam the four call sites build through —
`game_board_screen.dart`, `GameRanking.of` (the standings screen, `ShareResultButton`) and
`GameProvider.standingOf` (the home cards) — so they cannot disagree on a place. The
statistics walk the same rounds in SQL, in
`DriftPlayerStatsRepository._eliminatedAtRound`. Tests:
`test/models/game_standing_test.dart` (the `lastPlayerUnder` mirror of the `over` case
among them), `test/models/player_stats_test.dart`, the standings-versus-statistics case in
`test/drift/drift_repositories_test.dart`, and the screen-level cases in
`test/screens/standings_screen_test.dart` and `test/screens/game_board_lanes_test.dart`.

#### The board

The board is **one lane per player** (`BoardLanes`, `lib/widgets/board_lanes.dart`): a band
tinted with the player's display colour (`playerColorsById`) runs from the header — a
two-letter `PlayerAvatar`, the name, the total, the place (`boardRank`) — down to the last
round. A lane's header and cells are one `Column`, so they cannot drift apart; the round
numbers are a column of their own, pinned on the left, and tapping one opens the round's
comment. The sole leader (`GameStanding.soleLeader`, following the game's
`isLowestScoreWins`; none before the first score, none on a tie for the lead) has its lane
outlined in its colour and a crown in `kLeaderGold`. Places are shared on a tie
(`GameStanding.ranks`, which follows the game's ranking rule — [below](#the-ranking-rule));
the rank sort (`BoardData.byRank`, the standing's own `rankedPlayers`), the places and the
ribbon's order key on `GameStanding.hasScores`, so a tied round still reads `#1` for every
player. A total within 20 points of the type's
`playerDeadThreshold` turns orange; an eliminated player's lane is dimmed and the name struck
through, with a skull (`BoardSkull`, `board_eliminated_skull`, label `boardEliminated`)
in the crown's place above the avatar — in lanes and rows alike, and in place of the crown
on a leader who is out; a type without elimination never shows one. A zero sits on an amber
pill, whatever the game type.

Widths come from a `LayoutBuilder`, not from a breakpoint: up to 8 players
(`kBoardMaxFittingLanes`) the lanes share the width and never scroll; beyond, a lane keeps
`kBoardMinLaneWidth` (56) and, when that no longer fits, the lanes scroll sideways under the
pinned round column, with a ranking ribbon of every player on top. The ribbon follows the
overflow, not the player count: at 1400 px ten lanes fit, and there is neither ribbon nor
scroll. The sideways scroll takes a finger, a stylus, a mouse drag and a trackpad pan
(`_LanesScrollBehavior`; Flutter's default leaves a mouse drag alone), and on the web it has
an always-visible scrollbar under the lanes. No lane grows past `kBoardMaxLaneWidth` (180) — on a
wide screen the lanes are centred. From 6 players (`kBoardCompactHeaderFrom`) the header is
compact: avatar, vertical name, total.

The app-bar toggle (`board_view_toggle`) switches to **one row per player** (`BoardRows`):
seat order, or rank order through a segmented button (not remembered); the last 4 rounds
(`kBoardRowsVisibleRounds`) as columns, older rounds a swipe to the right away, then the
total. The layout is `SettingsProvider.boardView`, app-wide and remembered. The board reads
the provider as nullable, so a test that does not provide one gets lanes.

**Scores are entered through a keypad bottom sheet** (`ScoreKeypadSheet`,
`lib/widgets/score_keypad_sheet.dart`); there is no text field and no system keyboard.
The board's button reads "Round N" (`boardRoundButton`, N from `GameProvider.nextRoundNumber`)
and opens the sheet on the first player in seat order, skipping the eliminated ones: chips of
the players (two-letter avatars as on the board, the current one outlined in its colour,
the scores already typed under the names), the large number, the total after it, and a 0-9
pad with ± and ⌫ — laid out left to right in every locale, Arabic included, as a phone
keypad is, while its labels keep the locale's direction. "Next", then the name on a line of
its own (`keypadNext` carries the line break in all ten languages), moves on; the tall key's
label is a `FitWordsText`, so no language breaks it inside a word; on the last player the key reads "Validate round", and only then is the round
written, in one go (`GameProvider.addRoundWithScores`, one notification) — closing the sheet
drops it, so an abandoned round leaves no empty row. An untouched player scores 0. For
a game type with a keypad shortcut (`GameType.keypadShortcut`, schema v21) the bottom-left
key is that shortcut (`Key('keypad_shortcut')`) and the 0 moves to the bottom of the third
column; for every other type it is the plain 0 and that corner is empty. The board passes
`gameType?.keypadShortcut`, nothing else. A **value** ("0 ZapZap", "162", "100") enters that
score and moves on, as the ZapZap key always did; an **operation** applies to the score on
display and stays on the player: "×2" doubles it (12 then ×2 is 24) and does nothing on a
zero or a negative score — Skyjo doubles a penalty, never a bonus — and "+50" adds to it. The
next digit after any shortcut starts a new number, as on a calculator — a value that cannot
move on (the round's last player, a single score) included, so "162" then 8 is 8; a result
past six digits is refused (the key does nothing). Built-in labels are digits and signs, plus the game's
name for ZapZap, the same in every locale, so they are not ARB keys (`keypadZeroZapZap` was
removed). From five players
(`kKeypadPositionFrom`) the chips scroll with the current one kept in view, and the caption
adds the position ("4/8"). A cell tap opens the same sheet on that one score, prefilled —
the first digit replaces it — with "Save". Both paths then note the eliminations — the
elimination sound once per write that puts a player out, never twice for the same player
until a correction brings them back, and only with *Game sounds* on — and run the game-over
check, as the score dialog they replace did. When that check ends the game by rule
(`_finishAndShowEnd(byRule: true)`, or the end screen held back while the keypad was open)
the victory sound plays; a finished game reopened plays nothing, nor does *End game* by hand.

### Toolchain

| | Version | Set in |
|---|---|---|
| Flutter | 3.47.2 (stable) | `/home/vemore/sdk/flutter`; pinned for CI in `.github/workflows/ci.yml` (`FLUTTER_VERSION`) |
| Dart | 3.13.2 | ships with Flutter |
| Dart SDK constraint | `^3.13.0` | `pubspec.yaml:25` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP | 9.1.0 | `android/settings.gradle.kts:23` |
| Kotlin (KGP) | 2.4.0 | `android/settings.gradle.kts:24` |
| compileSdk / targetSdk | 36 / 36 | `flutter.compileSdkVersion`, `flutter.targetSdkVersion` |
| minSdk | 24 | `flutter.minSdkVersion` |
| NDK | 28.2.13676358 | `flutter.ndkVersion` |
| SDK Build-Tools | 36.0.0 | AGP 9 minimum; install with `sdkmanager "build-tools;36.0.0"` |
| JVM target | 17 | `compileOptions` + the `kotlin { compilerOptions { } }` block |

These are Flutter 3.47.2's own template values, matched exactly. Flutter hard-errors below
Gradle 8.14, AGP 8.11.1, KGP 2.2.20 or Java 17 — see
`packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt` in the SDK.

`android/app/build.gradle.kts` does **not** apply `id("kotlin-android")`: Flutter's own
Gradle plugin applies it (`FlutterPluginUtils.detectApplyingKotlinGradlePlugin`). The JVM
target lives in a top-level `kotlin { compilerOptions { } }` block, not in the `kotlinOptions`
block AGP 9 dropped.

`android/gradle.properties` sets `android.newDsl=false` and `android.builtInKotlin=false`,
both of which AGP 9 flips to `true` by default. Flutter's template opts out of both, because
`org.jetbrains.kotlin.android` is incompatible with AGP's new DSL. Removing either line
produces `ClassCastException: ...ApplicationExtensionImpl... cannot be cast to BaseExtension`.

### The dynamic-icon constraint

`lib/models/game_type.dart` holds `defaultGameTypes()` and builds `IconData`
from codepoints stored in the database. Flutter's icon tree-shaker cannot see those
references, so **every** build must pass `--no-tree-shake-icons` — apk, appbundle, ios and
web alike. It costs roughly 200 KB. Omitting it fails the build with a tree-shake error.

Since analyzer 14 (Dart 3.13), `IconData`'s `codePoint` is flagged as needing a constant, so
`game_type.dart` carries a targeted `// ignore: non_const_argument_for_const_parameter` with
the reason. That warning *is* the tree-shaking constraint showing up in the analyzer — do
not "fix" it by hardcoding a codepoint.

## Decisions & History

- **The keypad shortcut is per game type, a closed value, and a column (2026-09-24,
  `feat/keypad-game-shortcuts`).** The ZapZap key was a `builtinKey` test in the board; the
  entry (`wip/done/2026-09-18-keypad-has-no-per-game-shortcut.md`) decided five shortcuts from
  the shipped rules and that a user's type may have its own. A closed shape (kind, amount,
  label) rather than free text or an expression, so both the app and the server can check it
  and a value from a later version degrades to a plain 0. One JSON column rather than three,
  so the shortcut moves, syncs and is cleared as one value. `multiply` applies to a positive
  score only because the only rule that asks for it — Skyjo's closer, doubled when not
  strictly lowest — doubles a penalty; a zero or negative score is left alone instead of
  being turned into a larger bonus. A value moves on (it is a whole score), an operation stays
  (the result is still to be checked). Built-in labels are not localized: digits, "×", "+"
  and a game's name read the same in the ten languages, as the keypad's own digits do; the
  "0 ZapZap" label moved from the ARB key into the seed.

- **The game-type editor saves with `copyWith`, and validates on the fields (2026-09-20,
  `fix/game-type-editor`).** It built a fresh `GameType` from the form, so every save wrote
  `rules`, `rulesSlug` and `isDefault` as NULL / 0 — a colour change silently destroyed a
  shipped ruleset, the text a user had written, and the flag every future back-fill selects
  on ([[SchemaV10]]). Five findings of one review closed together because they are one
  dialog: the data loss, three leaked controllers and an unvalidated form, a condition
  saved without a threshold (which every reader then treats as *no condition*), an English
  `Exception:` shown under "error during export" when a used type is deleted, and a win
  direction flippable under finished games. The user chose a **confirmation** for the
  direction rather than making it read-only, a **curated palette** rather than blending a
  freely picked colour towards contrast, and an **offer** to open the rules editor rather
  than generating or rewriting rules. `wip/done/2026-09-20-editing-a-game-type-erases-its-rules.md`
  and the four entries beside it.
- **Home is a card grid on a wide screen, not master-detail (2026-09-19,
  `feat/home-card-grid`).** At 1600 px a game card was a 1 568 px strip. A master-detail
  home would need a detail pane to show; the cards already carry what the list needs, so
  width buys more of them per screen. Home has its own 600 dp constant: the board has
  none since its lanes size themselves. Two columns start at 600 dp even though a card is
  then only 278 dp, so the compact card exists rather than a later breakpoint; a phone's
  one-column card is never compact (`wip/done/2026-09-18-home-master-detail.md`).

- **An elimination game's final standings follow the elimination order, and the rule is
  derived, not stored (2026-09-20, `feat/ranking-rule`).** The app knew one rule — count the
  better totals — so a ZapZap player out after one hand with 101 was ranked second, ahead of
  the two who played to the end. `GameStanding` now carries a `RankingRule`
  ([above](#the-ranking-rule)). The user decided both halves of it: a type with no rule of
  its own ranks by score, `other` included; and the elimination order applies only to a type
  that has an elimination threshold **and** ends on the last player standing — a threshold
  with a race-to-a-total ending is not enough. That second decision is what makes a stored
  field unnecessary: the two conditions `GameType` already carries say it, so there is no
  column and no migration. Only a **finished** game departs from the score order; an open one
  shows where it stands. The rank-then-seat sort, written twice until now, became
  `GameStanding.rankedPlayers`, which both the board and the standings return
  (`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`,
  `wip/done/2026-09-20-rank-then-seat-sort-is-duplicated.md`).

- **The board and the home card crown only a sole leader (2026-09-19,
  `fix/board-home-tie-crown`).** The board's crown, outlined lane and ribbon ring, the Resume
  card's leader and a finished card's winner all read `GameStanding.soleLeader`; the board's
  rank sort and places key on `hasScores` instead of a leader existing. `GameStanding.leader`,
  which broke a tie by seat, had no reader left and went; `GameStanding.leaders` lists the
  players on first place for the home pill's tie tooltip. No new string: the pill reuses
  `gameFinished` and `gameEndTie`. (`wip/done/2026-09-19-board-and-home-crown-a-tie.md`)

- **The analysis actions live in an overflow menu, and only with an analysis (2026-09-19).**
  Report, Regenerate and Delete used to be three app-bar icons, always drawn and disabled
  with nothing to act on; with Share added (#139) the French title was cut to "Analyse de
  la …" at 412 px. They moved into one `PopupMenuButton` that exists only once there is an
  analysis, so the bar carries at most Share and the menu.
  (`wip/done/2026-09-19-analysis-screen-offers-actions-on-nothing.md`)

- **One elimination rule, 6 qui prend seeded 65, no crown on a tie (2026-09-19).** The board
  kept three private copies of the elimination test; they went, and the board and the
  standings all call `GameType.isEliminated` / `isNearElimination`. `over` stays
  strict — ZapZap and Rami say *exceeds* 100 — so 6 qui prend, whose box rule stops at 66,
  is seeded with 65 rather than given an inclusive variant (no schema change); an existing
  row keeps 66, as with the Uno / Président seed change. The rankings crowned the earlier
  seat on a tie, so a round of all zeros crowned seat 1: they now crown
  `GameStanding.soleLeader`, null on a tie. `GameStanding.leader` still broke a tie by seat,
  because the board used it to decide whether to sort by rank; the board's own crown and the
  home card's winner still followed it.
  (`wip/done/2026-09-19-player-elimination-threshold-is-strictly-over.md`,
  `wip/done/2026-09-19-crown-before-any-round.md`)

- **"Last player standing" now means it, and the three elimination types are seeded with it
  (2026-09-20).** `lastPlayerOver` / `lastPlayerUnder` tested *every* total against the
  threshold — the survivor's included — while `gameRulesEndLastOver` promised "every player
  but one", in all ten languages. A player who is out stops being dealt in, so the
  survivor's total never moved and the condition could not fire. `GameType.isGameOver` now
  ends the game once at most one total is still on the near side (`_lastPlayerStanding`,
  `lib/models/game_type.dart`); a table of fewer than two players never ends this way, so a
  solo game is not over on its first round. The two choices are relabelled to the situation
  ("Dernier joueur en jeu (les autres au-dessus)" / "Last player standing (others over)",
  keys unchanged), and `zapzap`, `rami` and `six_nimmt` — the only types with an elimination
  rule — are seeded `lastPlayerOver` at their elimination threshold (100, 100, 65). As with
  Uno / Président and the 65 above, **no migration rewrites an existing row**: only a new
  database seeds it, and a user type that already carries `lastPlayerOver` gains the
  behaviour its own description claimed. `test/models_test.dart`,
  `test/l10n/game_over_labels_test.dart`, `test/drift/last_player_standing_seed_test.dart`,
  `test/migration_last_player_standing_test.dart`.
  (`wip/done/2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset.md`)
  > **Status: Outdated** (2026-09-24) — superseded by schema v20 (`fix/game-ends-on-last-player`):
  > `applyV20` gives `lastPlayerOver` to existing ZapZap, Rami and 6 qui prend rows that have
  > an `over` elimination and no end, at their own elimination threshold. A NULL end left
  > older groups with games that never ended by themselves. The user accepted that finished
  > games of these types are re-ranked by elimination order ([[SchemaV10]]).
  > `test/migration_last_player_standing_test.dart` is gone, replaced by
  > `test/migration_v19_to_v20_test.dart`.

- **`firstPlayerOver` means "reaches" (2026-09-19).** The game-over test moved from the
  board into `GameType.isGameOver` and `firstPlayerOver` became `>=`: the box rules its
  thresholds come from say *reaches* — Président is won at 10, Uno at 500, Skyjo stops at
  100 or more — and Président scores in steps of 1 and 2, so a player on exactly 10 was
  asked for another hand. Existing Skyjo and Belote games (and any custom type with the
  rule) now end one step earlier; the three other conditions are unchanged, and seeding
  499 / 9 / 99 instead was rejected as reading oddly on the rules page.
  (`wip/done/2026-09-18-game-over-threshold-is-strictly-over.md`)

- **Repositories are injected into `GameProvider` rather than constructed inside it.** That
  is what lets `test/drift/drift_repositories_test.dart` run the full lifecycle against an
  in-memory database without touching the singleton.
- **Icons are database-driven** so that a user can pick an icon for a custom game type.
  The `--no-tree-shake-icons` tax is the accepted price; the alternative was a fixed enum
  of icons, which would have made custom game types feel second-class.
- **The backend URL has no default, and that is the privacy model.** An install that has
  never been configured makes no network request at all; `--dart-define=BACKEND_URL` seeds
  the setting for a dev build and is absent from every published one. See [[LlmProviders]]
  and `README.md` (Privacy).
- **`ThemeProvider` is preloaded rather than self-loading.** `SettingsProvider` loads its
  prefs asynchronously from its own constructor, which is fine for a wakelock but would
  paint one frame of the wrong theme on every cold start. So the theme is read in `main()`
  instead and injected — the only reason the app has an `async` `main()`.
- **The About version comes from the build, not from the ARB files** (2026-09-15). It was
  `"Version 1.0.0"` in ten translations, so the 1.1.0 build still announced 1.0.0; every
  release would have needed ten ARB edits nobody remembered. `test/screens/about_screen_test.dart`
  mocks `PackageInfo` and keeps both of its checks in one test, because a static future
  completed in one test's fake-async zone never delivers in the next.
- **The bottom inset is a helper, not seven more `SafeArea`s** (2026-09-16). Six root
  `ListView`s and the About screen drew their last row behind the navigation bar; the bug had
  been fixed case by case before (`game_analysis_screen.dart:328`), never in principle.
  `withBottomInset` reproduces exactly what `BoxScrollView` does when `padding` is null,
  which is why it needed no measurement on hardware to be correct — a widget test that pumps
  a `MediaQuery` with a bottom padding and reads back the resolved padding pins it
  (`test/utils/insets_test.dart`). It uses `MediaQuery.paddingOf`, not
  `MediaQuery.of(context).padding`, so the keyboard opening does not rebuild a whole list.
- **The game-over refusal is in memory, and there is no check on the board's first build**
  (2026-09-16). Nothing records the user's "Continue playing", so a first-build check would
  raise the dialog every single time the board is opened for a game past its threshold —
  worse than the bug it fixes.
  > **Status: Outdated** (2026-09-18) — the refusal is now stored on the device
  > (`GameOverDismissals`, SharedPreferences keyed by the game's uuid), and the board checks
  > once on its first build. A synced column was weighed and not taken: the answer is a
  > per-device courtesy, not game data, and it would have cost a schema bump and LWW
  > (`wip/done/2026-09-16-game-over-dialog-only-on-score-edit.md`).
- **The review prompt counts finished games from the database, not a counter** (2026-09-18).
  `reviewPromptGamesFinished` counted the act of finishing, so an Undo left it one too high;
  a `COUNT` over `finishedAt` follows the state, survives a backup restore, and makes the
  finish → reopen → finish evening count once by construction. `recordFirstLaunch` removes
  the old key (`wip/done/2026-09-16-undo-does-not-take-back-the-review-prompt-count.md`).
- **Who starts? is the first of three table helpers** (2026-09-18) — the dice roller and
  the turn timer follow, one pull request each, so a bad idea is cheap to drop
  (`wip/done/2026-09-16-no-dice-timer-first-player-helpers.md`).
- **The turn timer, the game sounds and the skull shipped together** (2026-09-24,
  feat/board-skull-sounds-timer). The timer remembers its last duration per game type in
  SharedPreferences, keyed on the type's id, not in the schema (refinement 4, 2026-09-18). The
  sounds and the timer share one setting and one player, off by default; with it off, the
  unconditional `SystemSound.alert` the elimination used to play is gone too — it did
  nothing on most Android devices and on the web, and could not be turned off. The sounds
  are synthesised by a script in the repository rather than downloaded, so their provenance
  and CC0 dedication need no third party; audioplayers because it covers Android and the web
  with one API and adds no permission (its Android manifest declares none). The skull is
  painted, since the pinned Material Icons font has none and a bundled SVG would have needed
  a package (`wip/done/2026-09-18-no-turn-timer-on-the-board.md`,
  `wip/done/2026-09-23-no-optional-sound-on-elimination-and-victory.md`,
  `wip/done/2026-09-23-eliminated-players-have-no-skull-on-the-board.md`).
- **The dice roller is d6 only** (2026-09-19) — the refinement dropped a kind selector
  (d4 … d20) as clutter for the games CountScore scores; 1–6 dice cover Yahtzee (5) and
  Farkle (6). A die shows its numeral rather than pips, which reads the same in every
  locale and needs no asset (`wip/done/2026-09-18-no-dice-roller-on-the-board.md`).
- **A fixed row of controls in an `AlertDialog` is a `Row`, never a `Wrap`** (2026-09-20).
  `AlertDialog` sizes its column with `IntrinsicWidth`, and `RenderWrap`'s intrinsic width
  sums its children while ignoring its own `spacing`, so the dice roller's six count chips
  were given 30 dp less than they need and the sixth wrapped alone — at *every* screen
  width, 1600 px included, not only on a phone. A `Row` reports its spacers, a `FittedBox`
  absorbs a large text scale, and a 16 dp `insetPadding` buys the room the six need on a
  412 dp phone (`wip/done/2026-09-19-dice-count-chips-wrap-five-and-one.md`).
- **The game list counts rounds in one grouped query, not one per card** (2026-09-16).
  `DriftGameRepository.getAll` returns no count, and a `FutureBuilder` per card would be one
  query per row over the whole history; `RoundRepository.countByGame` is a single `GROUP BY`
  that `loadGames` folds into the provider.
- **The look is teal "Material soigné", with a bundled font** (2026-09-18). The deep-purple
  seed matched nothing in the icon of the time — a teal podium, replaced on 2026-09-20 by the
  cards-and-pawns artwork ([[Release]] §Icons), whose own teal is `kBrandSeedDark`. Cards
  tinted to 10 % of the game colour turned ZapZap's amber beige. Direction A of four mock-ups
  (`wip/assets/2026-09-18-app-looks-like-a-default-material-template/`). Nunito is bundled,
  not fetched with `google_fonts`: a runtime download from Google would be an outbound data
  flow in an app whose privacy model is that it makes none. Static instances rather than the
  variable file, because Flutter does not map `fontWeight` onto a variable font's `wght`
  axis on every renderer (`wip/done/2026-09-18-app-theme-is-default-deep-purple.md`).
- **Player colours are computed, not stored** (2026-09-18). Two players of one game could
  hold the same `colorValue` (global players choose theirs in other games), and ten players
  without one all drew the same `Colors.blue` fallback. Resolving collisions at display time
  fixes both with no migration and no sync write, and every screen gets the same answer from
  one function.
- **The mode is stored as `ThemeMode.name`, not its index**, so reordering the enum cannot
  silently flip a user's theme. An unknown stored value decodes to `ThemeMode.system`.
- **Directories are described by what they hold, not by counts** (2026-09-18). The page
  said "70 Dart files" under `lib/`, "exactly one" widget and gave `(N l.)` sizes; each drifted
  within days, and nothing in the code pins them. The only counts left are ones the code
  fixes: the 10 `supportedLocales` and the 6 providers in `MultiProvider`
  (`wip/done/2026-09-16-wiki-owed-by-rating-prompt.md`).
- **The large-screen layout starts with the score grid, not with a two-pane home** (2026-09-18,
  refinement). A score table is the content that gets better with width; a master-detail home
  is a separate entry (`wip/done/2026-09-18-home-master-detail.md`). The grid keeps its
  `DataTable` and its two scroll views, with a minimum width and flexed player columns added
  above 600 dp, so the phone layout is the same widget tree with nothing changed
  (`wip/done/2026-09-16-no-large-screen-layout.md`).
  > **Status: Outdated** (2026-09-18) — the `DataTable` and its 600 dp breakpoint are gone;
  > see the next entry.
- **The board became lanes, and lost its breakpoint** (2026-09-18, `feat/board-lanes`). The
  `DataTable` laid the header and the cells out separately, painted every cell in the game
  type's colour and marked no leader, so with 8 players a column was tied to its player by
  position alone. Lanes size themselves from the width they are given, so the wide/narrow
  switch (`kBoardWideBreakpoint`) had nothing left to decide. The crown is an icon
  (`Icons.emoji_events`), not an emoji: on the web an emoji makes CanvasKit fetch a colour
  emoji font from Google at run time. The one-row-per-player choice is app-wide rather than
  per game — a table that prefers rows prefers them every evening.
- **2026-09-19 — a keypad sheet replaces the per-cell score dialog**
  (`wip/done/2026-09-18-score-entry-takes-a-dialog-per-cell.md`, `feat/score-keypad`). The
  dialog cost four gestures per score and left empty rows when a round was abandoned halfway;
  "Add round" inserted the row first. The round is now held in the sheet and written only on
  validation. The ZapZap key is the only per-game shortcut for now; the others wait for a
  per-type setting, which needs a schema change. The ARB keys `addRound`, `score` and
  `enterScore` went with the dialog.
  > **Status: Outdated** (2026-09-24) — the per-type setting landed with schema v21
  > (`feat/keypad-game-shortcuts`): `game_types.keypad_shortcut`, five built-in shortcuts and
  > the editor's section. See the first entry of this list.
- **Finishing a game shows who won** (2026-09-19, `feat/game-end-screen`). The game-over
  `AlertDialog` ("continue" or "finish", then straight back to the list) and the home menu's
  "Game finished" snackbar never named the winner. Both became `GameEndScreen`, shown on
  every path. Reaching the rule now *finishes* the game before the screen opens, and
  "Continue playing" reopens it — rather than finishing only on an explicit button — so the
  back button, the one gesture a user makes without reading, leaves the result recorded.
  The review prompt still hears of each game once: `setGameFinished` reports the transition.
- **One ranking widget for the in-game and the end-of-game screens** (2026-09-19). After the
  end screen was restyled (#123), the in-game ranking still drew a teal banner, numbered
  badges and an amber trophy, with no player colour: a game had two rankings in two styles,
  depending on whether it was finished. Both now build from `GameRanking` / `RankedPlayers`;
  the banner became a single line under the title
  (`wip/done/2026-09-19-game-ranking-ignores-the-new-theme.md`).
- **The player statistics became a leaderboard and a player card** (2026-09-19,
  `feat/player-stats-leaderboard`). The screen was one collapsed `ExpansionTile` per player
  with "N games" as the only visible figure, avatars in the stored colour or `Colors.blue`
  — Lionel and Laurent both a cyan "L" — and nothing to compare players by. From four
  directions drawn, the user chose the leaderboard with the player card, both scoped to one
  game type. Only *finished* games count (the old aggregate counted open ones too), and a
  finished game with no score is left out rather than made a win for everyone. The rank
  chart is a `CustomPainter` because one chart does not justify a dependency and its licence
  entry. The five-game threshold keeps one lucky evening from topping the board.
- **Sharing a result is text, and goes through the system share sheet (2026-09-19).** A
  finished game could not leave the phone, so the players around the table had nothing to
  pass on and the app nothing to advertise it (`wip/done/2026-09-16-no-way-to-share-a-game-result.md`).
  The text is built from the same `GameRanking` as the screen, so the message cannot rank
  differently from the podium; it names the app with its plain Play URL and no tracking
  parameter. Being user-initiated through the platform sheet, it is not an outbound data flow
  of the app and the Data Safety answers do not move ([[Documentation]]). A rendered image of
  the standings is a later change (`wip/todo_nr/2026-09-19-share-result-as-image.md`).
  > **Status: Outdated** (2026-09-19) — the image shipped the same day (below).
- **2026-09-19 — The shared result carries a picture of the podium** (`feat/share-result-image`,
  `wip/done/2026-09-19-share-result-as-image.md`). In a group chat a picture stands out where
  a text line is scrolled past. The card is a widget built on `RankedPlayers`, not a
  screenshot of the screen: the screen scrolls and carries buttons, and a dedicated widget
  drawn from the same `GameRanking` cannot rank differently (the ranking test pumps the card
  the button drew and compares its order to the screen's). It is drawn in a pipeline of its
  own (`lib/utils/widget_image.dart`) so nothing flashes on screen; the themes, localizations
  and media query are lent from the tapped context. The image is a bonus — a card that fails
  to draw, or a browser that cannot share files, still gets the text — and share_plus's
  download fallback is off because a downloaded PNG would replace the text rather than join
  it. Keep the card free of `Ink`/`ListTile`: in the off-screen pipeline a `ListTile` failed a
  null check on the web and left CanvasKit with no picture to read (seen while probing).
- **2026-09-19 — New game redrawn in direction A** (`feat/new-game-screen`). The form was
  the one screen between home and the end of a game the refresh had not reached, and it
  coloured players by their stored `colorValue` while the board used the display-time
  palette, so a player could change colour between the two. It now colours seats through
  `assignPlayerColors`, and makes the seat order — which the lanes, the rows and the keypad
  follow — visible and draggable. The player dialog became a sheet that seats several
  players at once and offers the last game's players; a created player is no longer given a
  random stored colour, since the palette decides at display time. A type picked outside
  the six tiles takes the first tile rather than the last, so that the default ZapZap sits
  first before any game has been played.
- **One avatar and colour system everywhere (2026-09-19).** The keypad chips, the home
  Resume hero and the Players screen drew one letter, or a stored colour with a blue
  default, while the board drew two letters in `player_colors.dart`'s colours; they now all
  go through `PlayerAvatar` and the display-time colours. Stored colours from before the
  palette (random Material colours) are kept, but a near-twin of an earlier seat's colour
  now counts as a clash — CIEDE2000 rather than a hue threshold, because hue alone puts
  the palette's own cyan and slate, or vermilion and amber, closer than Material green and
  lightGreen. Choosing the initial's colour by WCAG contrast turned most palette discs'
  initials dark: white on the mid-tone palette measured 2.2–3.7:1. The Players screen's
  counts moved to the leaderboard's finished-games rule, and `getStatsByName` — which
  counted open games, made every player of an unscored game a winner, took the best
  total whatever the game's elimination rule and ran one query per game — was deleted rather than fixed.
  (`wip/done/2026-09-19-keypad-and-home-avatars-disagree-with-the-board.md`,
  `wip/done/2026-09-19-players-screen-counts-open-games-and-shows-blue-avatars.md`,
  `wip/done/2026-09-19-stored-player-colours-clash-on-the-board.md`,
  `wip/done/2026-09-19-es-pt-labels-wrap-mid-word.md`)
- **2026-09-19 — The lanes scroll under a mouse, the ribbon follows the overflow, Undo
  expires** (`fix/board-scroll-and-undo-snackbar`). On the PWA a mouse drag never moved the
  ten-player board, because Flutter's default scroll behaviour drags only with touch and
  stylus; the lanes now accept a mouse and a trackpad too, with a visible scrollbar on the
  web. A touch swipe already worked in a local build with touch emulation on. The ribbon was
  keyed on `n > 8`, so a wide window drew it over lanes that all fit. The reopen snackbar's
  Undo stayed up indefinitely (Flutter's `persist` default for a snackbar with an action);
  it now expires after 6 s. It is not hidden on navigation: the 6 s bound was judged enough.

- **2026-09-20 — one standings screen, and a list that holds everyone**
  (`refactor/standings-screen`,
  `wip/done/2026-09-20-ranking-and-end-screen-are-the-same-screen.md`,
  `wip/done/2026-09-20-podium-hides-the-first-three-from-the-list.md`). `RankingScreen` and
  `GameEndScreen` had converged on the same body — `rankingSummary`, `RankedPlayers`,
  `ShareResultButton`, *Play again* — and differed only by a headline and an *Analysis*
  button, so a finished game's app bar carried two adjacent icons onto two near-identical
  screens. They became `StandingsScreen`, which branches on the game's own `isFinished`: the
  distinction *live standings while open, final result when finished* now lives in one place,
  which is where the ranking **rule** per game type will branch next
  (`wip/todo/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`). The trophy button
  (`board_game_end`) went; the leaderboard one (`board_standings`) is the board's only way
  in. Every widget key survived the merge, `game_end_play_again` / `ranking_play_again`
  included — the *Play again* key says which state the screen is in — so the two test files
  merged into `test/screens/standings_screen_test.dart` rather than being rewritten. No ARB
  key was added or removed: `ranking` titles the open state and `gameEndResults`, until then
  the trophy's tooltip, titles the finished one.
  `RankedPlayers` now lists **every** player under the podium, first to last, the top three
  twice on purpose: with four players the list used to start at "4 Bob 140", so reading the
  order meant decoding the podium's 2-1-3 block layout first. The first place is drawn on the
  primary container to keep the head of the list as findable as the podium; the podium keeps
  ranking by place, so a tie still shares a step and a place number (1, 1, 3). A widget test
  holds the screen to no scrolling at 412×860 for four players, in both states.

- **2026-09-20 — one ranking model for the standings and the statistics**
  (`feat/elimination-ranking-model`,
  `wip/done/2026-09-20-last-player-under-does-not-rank-by-elimination-order.md`,
  `wip/done/2026-09-20-statistics-rank-by-score-while-the-standings-rank-by-elimination.md`).
  Two halves of the same gap, closed together. `ranksByEliminationOrder` tested
  `lastPlayerOver` exactly, though `GameType.isGameOver` documents `lastPlayerOver` and
  `lastPlayerUnder` as one shape and `isEliminated` already carries the direction: it now
  takes both, so a type built in the editor with a floor ranks like one with a ceiling. The
  narrow alternative — keep the predicate and warn in the editor — was rejected as asking the
  user to understand a distinction the model itself does not make. No seeded type is
  `lastPlayerUnder`, so no existing standing moved.
  The statistics ranked by the total whatever the type, because
  `getFinishedGameResults` handed `FinishedGameResult` totals only: the same finished ZapZap
  game read David, Chloé, Bob, Alice on its standings and David, Alice, Chloé, Bob on the
  player card, crediting Alice with a podium she did not earn. Rather than rebuild
  `FinishedGameResult` from a `GameStanding` — which would need the game's players, rounds
  and scores per game, four queries deep — the repository now carries the two things the
  rule needs: the rule itself (`ranksByEliminationOrder` over the live `game_types`, never a
  condition spelled out in SQL) and, for those games only, one walk of their scores in round
  order. The comparison moved to `outranksUnder`, called by both, so the next change to the
  rule cannot land on one side alone.
