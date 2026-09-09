# Mobile App

> Scope: the Flutter app's own structure — entry point, state, screens, models.
> Related: [[DataLayer]] · [[SchemaV9]] · [[I18n]] · [[Web]] · [[Testing]]
> Updated: 2026-09-09

## Facts

49 Dart files under `lib/` (including generated localizations).

### Entry point

`lib/main.dart` — `MyApp` wraps a `MultiProvider` (4 providers) around a `MaterialApp`.
Material 3, seed colour `Colors.deepPurple`. 10 `supportedLocales` with a
`localeResolutionCallback` falling back to `en`. Home is `HomeScreen`.
There is no DI container. `main()` is `async` and calls
`WidgetsFlutterBinding.ensureInitialized()` for one reason: to `await ThemeProvider.load()`
and hand the result to `MyApp(initialThemeMode:)`, so the first frame is already themed.

### Providers — `lib/providers/`, all `ChangeNotifier` (provider ^6.1.2)

| Provider | Responsibility |
|---|---|
| `game_provider.dart` (339 l.) | The substantial one. Repositories are constructor-injectable, defaulting to the six Drift implementations over `AppDatabase.instance`. Owns `_games`, `_currentGame`, `_currentPlayers`, `_currentRounds` and `_scores` (keyed `"playerId_roundId"`). Game/round/score CRUD plus stats. |
| `game_type_provider.dart` (46 l.) | Game-type list CRUD, `getGameTypeById`. |
| `settings_provider.dart` (72 l.) | Wakelock toggle (SharedPreferences-backed) and DB export/import. The **only** caller of `DatabaseService` for I/O. Exposes `supportsDbExportImport => !kIsWeb`. |
| `theme_provider.dart` (33 l.) | `ThemeMode` only, persisted to SharedPreferences under `themeMode` as `ThemeMode.name`. `load()` is called from `main()` before `runApp`. |

### Screens — `lib/screens/` (10)

`home_screen` (545 l.) · `game_board_screen` (792 l., the scoring grid) ·
`game_types_screen` (491 l.) · `create_game_screen` (372 l.) ·
`game_analysis_screen` (334 l., the LLM analysis — see [[LlmProviders]]) ·
`players_screen` (326 l.) · `player_stats_screen` (299 l.) · `settings_screen` (216 l.) ·
`about_screen` (145 l.) · `ranking_screen` (140 l.).

`lib/widgets/` holds exactly one component: `player_picker_dialog.dart` (291 l.).

### Models — `lib/models/` (6)

`game`, `game_type`, `player`, `round`, `score`, `game_analysis`. Plain classes with
`toMap`/`fromMap`. `player.dart` has no `gameId` since v9 — its `id` is a
`game_players.id`. See [[SchemaV9]].

### The dynamic-icon constraint

`lib/models/game_type.dart` (228 l.) holds `defaultGameTypes()` and builds `IconData`
from codepoints stored in the database. Flutter's icon tree-shaker cannot see those
references, so **every** build must pass `--no-tree-shake-icons` — apk, appbundle, ios and
web alike. It costs roughly 200 KB. Omitting it fails the build with a tree-shake error.

## Decisions & History

- **Repositories are injected into `GameProvider` rather than constructed inside it.** That
  is what lets `test/drift/drift_repositories_test.dart` run the full lifecycle against an
  in-memory database without touching the singleton.
- **Icons are database-driven** so that a user can pick an icon for a custom game type.
  The `--no-tree-shake-icons` tax is the accepted price; the alternative was a fixed enum
  of icons, which would have made custom game types feel second-class.
- **`ThemeProvider` is preloaded rather than self-loading.** `SettingsProvider` loads its
  prefs asynchronously from its own constructor, which is fine for a wakelock but would
  paint one frame of the wrong theme on every cold start. So the theme is read in `main()`
  instead and injected — the only reason the app has an `async` `main()`.
- **The mode is stored as `ThemeMode.name`, not its index**, so reordering the enum cannot
  silently flip a user's theme. An unknown stored value decodes to `ThemeMode.system`.
