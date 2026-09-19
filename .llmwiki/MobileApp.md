# Mobile App

> Scope: the Flutter app's own structure — entry point, state, screens, models.
> Related: [[DataLayer]] · [[SchemaV10]] · [[I18n]] · [[Web]] · [[Testing]]
> Updated: 2026-09-19

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
| `settings_provider.dart` | Wakelock toggle and the board's layout, `BoardView` (`lanes` or `rows`, key `boardView`, app-wide) — both SharedPreferences-backed, read by `ready` — and DB export/import. The **only** caller of `DatabaseService` for I/O. Exposes `supportsDbExportImport => !kIsWeb`. |
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
`players_screen` · `player_stats_screen` · `settings_screen` ·
`about_screen` · `ranking_screen` (where an open game stands, below) · `game_end_screen` (who won, below) · `game_rules_screen` ·
`group_settings_screen`.

`group_settings_screen` is Settings → Group → *Comments and usage*, reached only from the
Group section once the device is in a group: the group's comment style (three chips,
`narrative` · `humorous` · `analytical`) and language (the app's ten, by endonym), read from
`GET /groups/me` and written back at once with `PATCH /groups/me/settings`, and the month's
LLM spending from `GET /groups/me/usage`, in US dollars against the budget. Nothing is kept
on the device: each visit reads the server again. It calls nothing without a server URL and
a device token (`GroupProvider.canReachGroup`). The budget is shown, never edited — see
[[Sync]].

`home_screen` opens on a **Resume** card (`Key('resumeHero')`) for `resumableGame(games)` —
the open game with the latest `lastModified ?? createdAt`, which `GameRepository.update`
stamps on every score — showing its name, type, round (`roundCountOf`), leader and players,
with the game's overflow menu; there is no card when every game is finished. The other games
follow under *Recent*, each a white outlined card: a tile in the game type's colour (the
colour lives in the tile only, never tinting the card), the name, "type · date"
(`DateFormat.MMMd`, `yMMMd` for another year), the player avatars, and a status pill — *In
progress*, or the winner with a trophy (*Finished* when nobody scored). Leader and winner
come from `GameProvider.standingOf(game)`, a `GameStanding` (`lib/models/game_standing.dart`)
of the players in seat order and their totals over the rounds that still exist, a tie going
to the earlier seat. It is read per card, as the player names were before, without touching
the current game. The filter applies to both the card and the list.

`game_rules_screen` takes its `GameType` as a constructor argument rather than reading a
provider: both callers — the board's overflow menu and the game-type list — already hold
it, and the list has no "current game". It shows, in order, the type's own scoring summary
derived from its fields, then the user's rules if any, else the ruleset shipped for
`rulesSlug` (`lib/services/game_rules_catalog.dart`), else an empty state. See [[I18n]] for
why those rulesets are assets and not ARB keys.

`about_screen` reads the displayed version from `package_info_plus`
(`PackageInfo.fromPlatform()`, held in a `static final` future) — i.e. from `pubspec.yaml`
`version:` at build time; the ARB key `version` is only the `"Version {version}"` frame.
It also carries a "Rate CountScore" `ListTile` (ARB key `rateApp`) that opens the Play
listing through `url_launcher` — the one rating path the user can take at will, next to the
prompt below.

### Widgets — `lib/widgets/`

Nine components shared out of the screens:

- `board_lanes.dart` — the board's default layout ([below](#the-board)): `BoardData` (what
  both layouts draw from: players in seat order, rounds, a `GameStanding`, colours, the
  elimination tests, the tap callbacks), `BoardLanes`, and the pieces the rows share —
  `BoardScoreText` (a zero on an amber pill, `·` for no score), `BoardCrown`, `boardTint`.
- `board_rows.dart` — `BoardRows`, the one-row-per-player layout.
- `game_ranking.dart` — the one ranking both `RankingScreen` and `GameEndScreen` draw
  ([below](#the-game-end-screen)): `GameRanking.of` (the current game best first, its ranks,
  colours, leader, winners and elimination tests), `RankedPlayers` (podium and rows),
  `rankingSummary` (type · rounds · win rule), and `isEliminatedBy` /
  `isNearEliminationBy`, the type's elimination rule on a total.
- `score_keypad_sheet.dart` — `ScoreKeypadSheet`, the bottom sheet every score is entered
  through ([below](#the-board)).

- `player_avatars.dart` — `PlayerAvatar` (an initial on a colour, drawn in
  `onPlayerColor`) and `PlayerAvatarStack` (a game's players overlapping, in seat order and
  in their `playerColorsById` colours, "+N" past `maxShown`).
- `player_picker_dialog.dart` — `create_game_screen`'s player picker: searches the known
  players or creates one, giving a new player a colour no one else in the list uses, and
  returns a `PlayerSelection` (name and colour).
- `who_starts_dialog.dart` — the board's overflow-menu **Who starts?**: draws one of the
  game's players at random, shows the name, and draws again on request. Nothing stored,
  nothing sent.
- `group_settings_section.dart` — Settings → Group: create or join a group, show its invite
  code, leave it, and show where sync stands; usable only once a server URL is set. *New
  code* is shown to the group's owner only; *Comments and usage* opens
  `group_settings_screen`.
- `group_devices_sheet.dart` — Settings → Group → Devices: the group's devices, this one and
  the owner marked; the owner alone gets revoke and *Make owner* on the others ([[Sync]]).

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
- `game_over_dismissals.dart` — `GameOverDismissals`: the games whose rule-raised end screen was
  answered "Continue playing", on this device only (SharedPreferences
  `gameOverDismissed.<game uuid>`; not synced, no schema). A deleted game leaves its key
  behind — one boolean, never read again.

### Utilities — `lib/utils/`

Cross-cutting helpers, since 2026-09-16: `insets.dart`, `game_type_name.dart` — the switch
from a built-in game type's `builtin_key` to its localized name, which every screen showing a
game type's name goes through ([[I18n]]) — `play_again.dart`, `app_theme.dart` and
`player_colors.dart`.

`app_theme.dart` — the one place the look is defined. `buildAppTheme(brightness)` seeds
`ColorScheme.fromSeed` with `kBrandSeedLight` (`#0E8F88`, the icon's teal) or
`kBrandSeedDark` (`#5ED8CF`) under `DynamicSchemeVariant.fidelity`, sets `primary` to the seed
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
in seat order, a player's own `colorValue` wins unless an earlier seat already shows it;
everyone else takes the first colour of `kPlayerPalette` (ten mid-tone colours) no one in
the game shows; past ten the palette repeats by seat. `assignPlayerColors(colorValues)` is
the same rule over bare colour values, and `onPlayerColor(colour)` the initial's colour on
it. The home avatars and the board's lanes and rows use it.


`insets.dart` — `withBottomInset(context, base)` adds `MediaQuery.paddingOf(context).bottom`
to an `EdgeInsets`. A `BoxScrollView` (`ListView`, `GridView`) inserts `MediaQuery.padding`
on its main axis **only when its `padding` argument is null**, so every root scrollable that
passes an explicit padding loses that compensation and cannot scroll its last row clear of
the system navigation bar — the app is edge-to-edge on `targetSdk` 36 and cannot opt out
(`android/app/src/main/kotlin/com/example/countscore/MainActivity.kt` is a bare
`FlutterActivity`; there is no `SystemChrome` call anywhere in `lib/`). Its eight call sites
are the root scrollables of `about_screen.dart:31` (on the child `Padding` — a
`SingleChildScrollView` never gets the compensation at all),
`create_game_screen.dart:200`, `game_types_screen.dart:43`,
`home_screen.dart:91` (the drawer) and `:335`, `player_stats_screen.dart:83`,
`players_screen.dart:61`, and in `ranking_screen.dart` on the *Play again* button's
`Padding` under the list, the last thing above the navigation bar. Only the bottom edge is compensated:
`Scaffold` drops the top padding for a body under an `AppBar`
(`scaffold.dart`, `removeTopPadding: widget.appBar != null`) and keeps the bottom one unless
there is a `bottomNavigationBar`, and `DrawerHeader` adds the status-bar height itself.
`settings_screen.dart:117` and `game_analysis_screen.dart` need nothing — the first passes no
padding, the second is a `SingleChildScrollView` inside the `SafeArea(top: false)` at l. 328.

`game_type_name.dart` — `gameTypeDisplayName(l10n, type)` and `isBuiltinRename(...)`. A
built-in type's name is read from its `builtin_key`, never from the stored `name`, which is
what lets two devices in different locales hold the same type. Renaming one clears the key.
`sortGameTypesByDisplayName(l10n, types)` orders a list by that displayed name; every
screen listing game types calls it, since the repository returns them unordered ([[I18n]]).

`play_again.dart` — `playAgain(context, source, board:)`, the one path behind *Play again*
(the ranking's and the game-end screen's buttons, and a finished game's menu entry on the home screen, where an
unfinished game shows the same action as "New with same players"). It calls
`GameProvider.playAgain` — `createGame` with the source's type, win rule and players in
`orderIndex` order, nothing else read or written on the source — shares the new game if the
source was shared, and opens its board with `pushAndRemoveUntil(isFirst)`, so back returns
to the game list. The new game is named by `nextGameName`: `Skyjo 3` → `Skyjo 4`.
`RankingScreen`, `GameEndScreen` and `HomeScreen` take an optional `boardBuilder`, for tests only, as the
board's `analysisRepo` is.

### Models — `lib/models/`

`game`, `game_type`, `player`, `round`, `score`, `game_analysis`, `analysis_style`. Plain classes with
`toMap`/`fromMap`. `player.dart` has no `gameId` since v9 — its `id` is a
`game_players.id`. See [[SchemaV10]].

`analysis_style.dart` is an enum whose `id` is an ASCII string that travels to the backend
and into SharedPreferences (`analysisStyle`) and whose label is translated. It mirrors
`PERSONAS` in `backend/app/services/analysis/personas.py`: a new voice is added in both
places plus the ten ARB files.

`game.dart` carries `finishedAt` since v12, with `isFinished` next to `isShared`. Its
`copyWith` takes a `clearFinishedAt` flag: `x ?? this.x` cannot express "set this back to
null", and reopening a game is exactly that. `GameProvider.setGameFinished` is the single
write path — it returns true only for the transition that finishes a game, which is what
gates the Play review sheet.

Both screens show the state and both can change it: a status pill (in progress, or the winner) on the game
list card, a chip beside the title on the board, and a menu entry that finishes or reopens.
Finishing opens the game-end screen (below); reopening is confirmed by a snackbar whose
**Undo** action finishes the game again (the repo's only `SnackBarAction`). The entry is
offered on a game that has at least one round or is already
finished — a game with no round was never played, which is why the list needs
`GameProvider.roundCountOf`. Nothing is locked: a finished game still takes rounds and score
edits.

`_GameBoardScreenState._maybeShowGameOver` finishes the game and opens its end screen after
a score edit, after a round is added and after one is deleted — every mutation that can move
a total past the game type's threshold — and once on the board's first build, for an open
game already past it. `_gameOverDismissed` keeps it to one crossing and re-arms as soon as
the condition is false again. Raised by the rule, the screen offers **Continue playing**,
which pops back to the board, reopens the game and is written to `GameOverDismissals`, keyed
by `Game.uuid`, and read back when the board opens, so leaving the board does not re-ask;
the stored answer is removed as soon as the condition is false. The back button leaves the
game finished. A finished game is never raised again: the board's app bar carries a trophy
(`board_game_end`) that reopens its end screen.

#### The game-end screen

`GameEndScreen` (`lib/screens/game_end_screen.dart`) shows the current game — the caller
loads it and records it finished (`_finishAndShowEnd` on the board; the home card menu
loads it before pushing). The winner's name (a tie at the top names every player on it),
the game type · rounds · win rule, then `RankedPlayers` (`lib/widgets/game_ranking.dart`):
a podium of the top three in their display colours with their totals (first raised in the
middle, ringed in `kLeaderGold`, the leader under a `BoardCrown`), then the others in rank
order (`GameStanding.ranks`, ties sharing a place). As on the board, a total within 20
points of the type's elimination threshold is orange — except on the first step, whose
filled block keeps `onPrimary` — and an eliminated player is faded and struck through. Actions: **Play again**
(`playAgain`) and **Analysis** (`GameAnalysisScreen`), the latter only when
`BackendProvider.isConfigured` — Play again then spans the row. Unlike the board's menu, a
cached analysis alone does not bring the button back. Every path that finishes a game —
rule, board menu, home menu — calls `ReviewPromptService.onGameFinished` once, on the
transition `setGameFinished` reports.

#### The ranking screen

`RankingScreen` (`lib/screens/ranking_screen.dart`), from the board's leaderboard button,
shows an open game with the same `RankedPlayers` as the end screen, so the two cannot rank
differently; above it, the win rule is one line (`rankingSummary`) under the *Ranking*
title, and **Play again** stays at the bottom. No headline: the game is not over.

#### The board

The board is **one lane per player** (`BoardLanes`, `lib/widgets/board_lanes.dart`): a band
tinted with the player's display colour (`playerColorsById`) runs from the header — a
two-letter `PlayerAvatar`, the name, the total, the place (`boardRank`) — down to the last
round. A lane's header and cells are one `Column`, so they cannot drift apart; the round
numbers are a column of their own, pinned on the left, and tapping one opens the round's
comment. The leader (`GameStanding.leader`, following the game's `isLowestScoreWins`; none
before the first score) has its lane outlined in its colour and a crown in `kLeaderGold`.
Places are shared on a tie (`GameStanding.ranks`). A total within 20 points of the type's
`playerDeadThreshold` turns orange; an eliminated player's lane is dimmed and the name struck
through; a zero sits on an amber pill, whatever the game type.

Widths come from a `LayoutBuilder`, not from a breakpoint: up to 8 players
(`kBoardMaxFittingLanes`) the lanes share the width and never scroll; beyond, a lane keeps
`kBoardMinLaneWidth` (56) and the lanes scroll sideways under the pinned round column, with a
ranking ribbon of every player on top. No lane grows past `kBoardMaxLaneWidth` (180) — on a
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
the players (the current one outlined in its colour, the scores already typed under the
names), the large number, the total after it, and a 0-9 pad with ± and ⌫. "Next <name>"
moves on; on the last player the key reads "Validate round", and only then is the round
written, in one go (`GameProvider.addRoundWithScores`, one notification) — closing the sheet
drops it, so an abandoned round leaves no empty row. An untouched player scores 0. For
ZapZap (`builtinKey == 'zapzap'`) the bottom-left key is "0 ZapZap", a zero that moves on;
for every other game it is the plain 0 (per-game shortcuts are
`wip/todo_nr/2026-09-18-keypad-has-no-per-game-shortcut.md`). From five players
(`kKeypadPositionFrom`) the chips scroll with the current one kept in view, and the caption
adds the position ("4/8"). A cell tap opens the same sheet on that one score, prefilled —
the first digit replaces it — with "Save". Both paths play the elimination alert and then
run the game-over check, as the score dialog they replace did.

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
- **The game list counts rounds in one grouped query, not one per card** (2026-09-16).
  `DriftGameRepository.getAll` returns no count, and a `FutureBuilder` per card would be one
  query per row over the whole history; `RoundRepository.countByGame` is a single `GROUP BY`
  that `loadGames` folds into the provider.
- **The look is teal "Material soigné", with a bundled font** (2026-09-18). The deep-purple
  seed matched nothing in the icon's teal podium, and cards tinted to 10 % of the game colour
  turned ZapZap's amber beige. Direction A of four mock-ups
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
  is a separate entry (`wip/todo_nr/2026-09-18-home-master-detail.md`). The grid keeps its
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
