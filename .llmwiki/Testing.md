# Testing

> Scope: what is tested, how to run it, and the traps.
> Related: [[MobileApp]] · [[DataLayer]] · [[SchemaV10]] · [[Backend]] · [[Web]] · [[KnownLimits]]
> Updated: 2026-09-20

## Facts

### Mobile unit tests — `flutter test`

| File | Coverage |
|---|---|
| `test/database_service_test.dart` | Fresh current schema (v10 tables and columns included), CRUD via the singleton, v8→v9 migration, model serialisation. `sqflite_common_ffi` in memory (`sqfliteFfiInit()`), schema built via `DatabaseService.instance.createDB`. |
| `test/migration_v8_to_v9_test.dart` | Hand-written v8 fixture; cross-game dedup and intra-game disambiguation. |
| `test/migration_v12_to_v13_test.dart` | Hand-written v12 `game_types` fixture through `applyV13`: `rules` and `rules_slug` added, the ten seeded names back-filled to their slug, a renamed or user-built type left with a NULL slug, a deleted type not resurrected. |
| `test/migration_v13_to_v14_test.dart` | The same shape one version on, through `applyV14`: the seeded rows back-filled to their `builtin_key` by name and `isDefault`, the twelve new types inserted, a deleted type not resurrected, a renamed one left keyless, two same-named rows yielding one key, a replay over that duplicate still yielding one, and a type the user made themselves neither claimed nor duplicated. |
| `test/migration_v15_to_v16_test.dart` | `applyV16`: the twelve long-tail rows back-filled to their slug by key whatever name they store, a renamed type keeping its slug, a pre-v16 rename, `Autre` and a user's own type left without one, a slug or a written ruleset never overwritten, nothing inserted, a replay changing nothing; the slug map, the seed factories and `GameRulesCatalog.slugs` agreeing; and the step through both engines' real upgrade callbacks. |
| `test/migration_v16_to_v17_test.dart` | `applyV17`, through both engines' real upgrade callbacks from a v16 file: an unused keyless copy of `zapzap` soft-deleted with `updated_at` = `deleted_at`; a copy with a game, a copy with only a deleted game, a user "Tarot" scoring differently, a copy with its own rules, a renamed copy and a shared (grouped) copy all kept; the 22 built-in rows untouched; a replay changing nothing. |
| `test/migration_v14_to_v15_test.dart` | `applyV15`: a second live copy of a built-in type refused whatever its name, a deleted copy not blocking a live one, a user's own type free to share a name with a deleted type, surplus keyed copies losing their key but never their row or games, a replay changing nothing, and both fresh installs carrying the index with each type seeded once. |
| `test/migration_v2_to_v14_test.dart` | The two oldest shapes in the chain, through the production callbacks. Both the v2→v3 and the v4→v5 step **seed** game types, and a seed writes `GameType.toMap()` against a table many versions older than the model: one key too many and `onUpgrade` throws, leaving the database unopenable. The fixtures are deliberately *missing* seeded types, because a device that has them all never reaches the failing INSERT — which is why nothing caught it. |
| `test/demo_db_test.dart` | The fictional demo database the store screenshots are taken on (`test/support/demo_db.dart`): built by the sqflite chain then written through the Drift repositories, one file at the current schema, six invented players, ten games with one in progress, one custom type, every player with the five finished games the statistics ranking needs. With `DEMO_DB_OUT=<path>` it also writes the file to import on the phone ([[StoreListing]]). |
| `test/seeded_scoring_test.dart` | Uno and Président seed highest-wins in a fresh database, sqflite and Drift alike, while an old database holding them lowest-wins keeps that through the whole upgrade chain — a seed change never migrates an existing row, because flipping the direction would reverse finished standings. |
| `test/utils/game_type_name_test.dart` | Every `builtinKey` has a case in the display-name switch; a built-in name follows the locale whatever the row stores; a user type and an unknown key fall back to the stored name; `isBuiltinRename` is trimmed on both sides and compared in the locale the user is looking at; and `sortGameTypesByDisplayName` orders by the displayed name with the locale's collation — accents folded in French, dictionary kana order in Japanese, ties broken so the order is total — without mutating its input. The switch is explicit because `AppLocalizations` has no lookup by name, so only this test catches a key added without its string. |
| `test/sync/sync_engine_resolve_test.dart` | The engine's reject-reason table against a `MockClient` server: `builtin_key_taken` is resolved by adopting the server's row, an unrecognised reason stays terminal, and a resolved delta does not loop the pass. The engine's `default` is `markRejected`, which is permanent and takes every dependent row with it, so each reason the server can return has to be a deliberate case. |
| `test/migration_v5_to_v10_test.dart` | The production upgrade: a real v5 file from tag `1.0.1+3`'s DDL, upgraded with the production callbacks (`DatabaseService.openForTesting`), then read back through Drift — games, merged players, scores, stats — and written to, `finishedAt` included. Its name understates its range: it asserts `DatabaseService.schemaVersion`, so it runs v5 → **v15** today and will follow the next bump without an edit. |
| `test/drift/drift_repositories_test.dart` | Full lifecycle through the Drift repositories over `AppDatabase.forTesting(NativeDatabase.memory())`; Drift `onCreate` builds the v10 tables; shared rows are tombstoned (game, round, membership, `deleteByName`), local ones deleted, and tombstones count in no statistic; `finishedAt` survives create, update and reopen — the only test that catches a field missing from `update`'s hand-written column list. |
| `test/drift/six_nimmt_seed_test.dart` | A fresh database seeds 6 qui prend at 65, so a player is out on exactly 66 and not on 65. |
| `test/drift/last_player_standing_seed_test.dart` | A fresh database seeds `lastPlayerOver` at the elimination threshold on ZapZap, Rami and 6 qui prend (100, 100, 65), and a four-player ZapZap ends once three are past 100 and not before; the types with no automatic end are seeded without one. |
| `test/migration_last_player_standing_test.dart` | The mirror image, through both engines' real upgrade callbacks: a database that already holds those three rows without a game-over condition keeps them condition-less — a seed change never rewrites an existing row. |
| `test/l10n/game_over_labels_test.dart` | The en and fr wording of `firstPlayerOver` and of the two last-player labels, and the `gameRulesEndLastOver` / `…Under` sentence checked against `GameType.isGameOver`: what the rules screen promises ("every player but one") is what the code does. |
| `test/sync/sync_store_test.dart` | Group sync without a network: capture triggers (local games capture nothing, sharing captures a game and its children, inherited `group_id`, deletes captured as deletes), `preparePush` (coalescing, uuid5 player links, parent-first order, stable lamports on retry, refused names), `applyPulled` (a full game from another device, merge by name, quarantine and replay, LWW, delete wins, own deltas skipped, score-cell adoption), `renumberRound`, `leave`; and `ended_at` both ways — sent even while open so that a reopen can clear it, a pulled null reopening the game rather than being ignored. |
| `test/sync/sync_ids_test.dart` | uuid5 against Python's `uuid.uuid5` vector, name normalisation, a built-in game type linked by its key rather than its localized name, the player-name allow-list — combining marks accepted after a letter and refused anywhere else, the same cases as `backend/tests/test_sync.py`. |
| `test/sync/sync_two_devices_test.dart` (`integration`) | Two in-memory devices through a **real** backend: a shared game and its scores both ways, the same round entered on both (renumbered, nothing lost), delete wins, same-name players merged, leaving. Skipped unless `SYNC_BACKEND_URL` is set — recipe below. |
| `test/widgets/group_settings_section_test.dart` | Settings → Group pumped with asserts on: create a group through the dialog against a `MockClient` server, and the group and its invite code appear; and removing a lost device shows the rotated invite code. Guards the dialog that disposed its controllers during its exit transition (`_dependents.isEmpty`, found on a Pixel on 2026-09-13, invisible in release builds). |
| `test/providers/game_provider_finish_test.dart` | `setGameFinished` reports only the transition that finishes a game — re-finishing and reopening return false — which is the single gate on the Play review sheet, so a finish → reopen → finish evening counts once. Plus the current game updating without a reload, which needs `copyWith`'s `clearFinishedAt` escape, and the round counts `loadGames` folds in: one grouped query, kept in step by `addRound` and `deleteRound`, with a tombstoned round counting for nothing. |
| `test/screens/home_screen_grid_test.dart` | The home card grid: one full-width column at 400 dp, three columns under a full-width Resume card at 1200 dp, two compact cards with the status pill under the name at 600 dp, and no overflow at any width from 320 to 1600 dp in 20 dp steps. |
| `test/screens/home_screen_finish_menu_test.dart` | The game card's overflow menu offers `finish_game` on a played or already finished game and on nothing else — the guard that keeps three empty games from satisfying the review prompt. It reads the menu through `itemBuilder` rather than tapping it open: the test font draws every glyph an em wide, so any Material popup menu overflows its 256 px in a widget test. |
| `test/screens/undo_snack_bar_test.dart` | Reopening a finished game, from the home card's menu and from the board's, shows the Undo snackbar, which is `persist: false` with `kUndoSnackBarDuration` and is gone once that has run out with nothing touched; the game stays reopened. The menus are driven through `onSelected`, for the popup-overflow reason above. |
| `test/screens/game_board_end_of_game_test.dart` | The board's end of game: the finished chip appears and disappears with `finishedAt` while **Round N** stays enabled, and the game type's rule finishes the game and opens the end screen — naming the winner on a highest-wins and on a lowest-wins type — after a round is validated on the keypad, keeps quiet for a crossing already answered "Continue playing" (which returns to the board with the game reopened; back leaves it finished), re-arms once the game is back under its threshold, is raised once on the board's first build for an open game past its threshold and not for a finished one, and remembers "Continue playing" across leaving the board (SharedPreferences, cleared when the game goes back under); a finished game's app bar reopens its end screen, without "Continue playing". `GameBoardScreen.analysisRepo` is injected for the same reason `GameProvider`'s repositories are — the default reaches the singleton. |
| `test/providers/game_provider_sync_test.dart` | A current game deleted by sync is reported once (`takeRemotelyDeletedGameName`), which the board uses to close itself. |
| `test/drift/web_upgrade_test.dart` | A v9 database (v10 to v16 stripped, `user_version` 9) reopened through Drift gets the sync tables, columns, triggers, `games.finishedAt` the back-filled `game_types.builtin_key`, every built-in type's `rules_slug` and the v15 unique index from `onUpgrade` — the PWA's upgrade path, and the only engine that runs it. |
| `test/drift/persistence_flush_test.dart` | The PWA reload fix, off the browser: `PersistenceFlushInterceptor` issues its `SELECT 1` outside any transaction once after the first open and after each outermost transaction — committed, rolled back (the error still surfaces), nested (once, after the outer one) or a batch — seen through a recording interceptor over `NativeDatabase.memory()`. And `onCreate` rerun on a full file whose `user_version` was reset to 0 completes: no duplicate built-in type, a tombstoned one not resurrected, the games kept, version back to 16. |
| `test/game_rules_catalog_test.dart` | The shipped rulesets in `assets/rules/`: every locale carries the same 21 slugs, the French and English masters say a game ends when a total *reaches* its threshold, and each keeps the numbers the app actually scores on — a translation that drops a threshold contradicts the type it documents. |
| `test/models_test.dart` | Model serialisation. It pins the built-in game types **by index**: the first ten are what a pre-v14 install already holds, so a new type is appended, never inserted. |
| `test/providers/theme_provider_test.dart` | `ThemeMode` decode fallbacks and the SharedPreferences round-trip. |
| `test/providers/backend_provider_test.dart` | Backend URL validation — https anywhere, http only on a private or loopback host — and the persistence round-trip, including that a cleared setting is not re-seeded from `--dart-define`. |
| `test/screens/game_analysis_group_test.dart` | Against a stubbed backend and a real `GroupProvider`: a shared game with no voice picked posts to `/groups/me/games/{uuid}/comments` with the device token and no `style`, shows no chip selected and the group-style hint; a picked voice travels; an unshared game keeps `/comments/game-analysis`; a 409 shows the localized budget message and is not retried on the stateless endpoint; a 404 syncs, retries once, then falls back on it. |
| `test/screens/game_analysis_screen_test.dart` | With no backend configured the analysis screen offers no generation, a cached analysis still renders, and configuring one restores the button; the two failure paths — a failed regeneration keeps the cached text and warns by snackbar, and with nothing cached the error state carries the HTTP status and no raw exception; the commentary report (a `mailto:` from the overflow menu, explained when there is no mail app); with no analysis the app bar has no menu, no Report, Regenerate or Delete, and no Share; with one, the French title is not ellipsized at 400 dp, measured in the app's own Nunito and theme since the test font draws every glyph a full em wide; a 503 asking to retry later rather than showing a code; and the voice chips — every style is offered, the last pick is remembered in SharedPreferences, an unreadable stored value falls back to `professor`, and the request carries the style, the app's language and the game type's rules. |
| `test/services/backend_client_test.dart` | `BackendException` carries the status, keeps the body for logging, and decodes utf8 on both the error and the success path; a 404 on `/comments/game-analysis` is retried once on the legacy path, and a 404 from both is still a failure; the group's device list sends the device token, revoking another device returns the rotated invite code, and revoking this one is leaving (204, no code). `MockClient` from `package:http/testing.dart`. |
| `test/services/review_prompt_test.dart` | `ReviewPromptService`'s guards around the Play in-app review sheet, through a fake `ReviewRequester` and a hand-moved clock, so no platform channel is touched: the first launch is stamped once and never moves; each guard refuses on its own — too few games however old the install, too young an install however many games, a clock that never started; with every guard satisfied it asks exactly once; a new session does not ask again for a version that already asked, an update does; and an unavailable platform does not burn the version. The game count is `GameRepository.countFinished()`: a fake holds it for the guards, and the real Drift repository behind `GameProvider` shows that finish then Undo leaves it unchanged and finish, reopen, finish counts one; the legacy `reviewPromptGamesFinished` key is removed. |
| `test/screens/game_board_dice_test.dart` | The board's overflow menu offers **Roll dice** right after **Who starts?**, and it opens with two dice rolled 1..6; driven through `itemBuilder`/`onSelected` like the Who starts test. |
| `test/widgets/dice_roller_dialog_test.dart` | With a seeded `Random`, for every count 1..6 and ten re-rolls each: as many dice as chosen, every value 1..6, the total shown is their sum, every face turns up; the same seed rolls the same dice. |
| `test/widgets/pwa_update_listener_test.dart` | The PWA's new-version prompt with a fake update source: nothing shown while no build waits; once one does, a snackbar that is still there a minute later and applies the update only on *Reload*; an update reported twice is offered once. The JS side (`web/flutter_bootstrap.js`, `web/service_worker.js`) has no automated test: it was checked with Playwright ([[Web]], "Offline and updates"). |
| `test/screens/game_board_who_starts_test.dart` | The board's overflow menu offers **Who starts?**; with N players every draw is one of their names, drawing again changes it, a single player is always the one. The menu is driven through `itemBuilder`/`onSelected`, for the popup-overflow reason above. |
| `test/screens/game_board_keypad_test.dart` | The score keypad sheet: a full 4-player round entered with no `TextField` in the tree, no round row until **Validate round**, then one; the total after the typed score (digits, ⌫, ±); closing the sheet halfway leaves the round count unchanged, in the provider and in the database; a tapped past cell opens on that score (first digit replaces it) and **Save** updates the score and the lane total, closing leaves it; "0 ZapZap" for ZapZap (a zero, then the next player) and a plain 0 with no shortcut key for Tarot; an eliminated player is skipped and gets no score; from five players the caption carries the position. |
| `test/screens/game_board_lanes_test.dart` | The board as lanes and as rows: the crown on the lowest total for a lowest-wins game and on the highest otherwise, none before a score; at 400 dp eight players fit without a sideways scroll, ten scroll with the round column staying put and a ranking ribbon on top; a touch, a mouse and a trackpad drag starting on a cell each bring the tenth lane into view; at 1400 dp ten lanes fit with no ribbon and no scroll; with 4, 8 and 10 players each lane header's left edge and width equal its cells'; at 1000 dp the lanes are capped and centred; the app-bar toggle shows one row per player in seat order (rank order on request), and a new `SettingsProvider` over the same SharedPreferences opens in rows; places are shared on a tie. The view size is set on `tester.view`, at a device pixel ratio of 1. |
| `test/services/commentary_report_test.dart` | The AI-commentary report `mailto:`: addressed to the listing contact with an encoded subject and body, an ampersand in the body unable to start a new parameter, truncation that counts code points so an emoji is never split, and the reference line skipping what is unknown. |
| `test/screens/game_end_screen_test.dart` | The game-end screen: the winner, the podium's three places with their totals and the rest in rank order; *Play again* creates the next game with the same players and opens it; *Analysis* is absent without a server (Play again then spans the row) and present with one; and "End game" from the home card menu finishes the game and opens the screen. |
| `test/screens/ranking_screen_test.dart` | The in-game ranking against the end screen: board colours, the sole leader crowned, the same order on both; no crown with no round played, after a round of all zeros, or on a tie, where the tied players stand on the same step and share a place number. |
| `test/screens/create_game_screen_test.dart` | The New game screen at 412 dp: six game-type tiles three a row, the last game's type first; the name after the last game's; the rule line; the seats under it in the last game's order, the first one dealing; a full-width *Start · N players* at the bottom. A player's avatar colour here equals his colour on the real board, also when two players own the same colour; a seat dragged by its handle changes the created game's `orderIndex`; the "who's playing" sheet creates a player and seats him after the ones checked; "All games" puts a type that was not on a tile onto one; "Other" offers the win rule; the first game is named in the app's language (`en`, `fr`, `ja`); with no game type at all it shows "No game types" (`game_type_empty`), not an endless "Loading game types…". The board is injected (`boardBuilder`). |
| `test/utils/recent_game_types_test.dart` | The tiles' order (types of the latest games first, the rest by display name, the selected type always on a tile) and `PlayerRepository.getGameCountsByName` — live games only. |
| `test/screens/play_again_test.dart` | *Play again* (`lib/utils/play_again.dart`): the ranking offers it and opens the new game — same type, win rule and players in order, the source game left untouched; a finished game's home menu offers it, a game still in play keeps "New with same players"; and `nextGameName` counts on from the last number. The board is injected (`boardBuilder`) and the home menu read through `itemBuilder`, as in the finish-menu test. |
| `test/screens/game_rules_screen_test.dart` | The rules page's precedence: the shipped ruleset when the user wrote none, the user's own rules winning over it, the scoring summary derived from the type rather than the text, the empty state for a type with neither, restore clearing the stored rules and not offered without a shipped ruleset, and an emptied editor meaning "no rules of mine" rather than an empty string. The ruleset is served from memory, never the asset bundle. |
| `test/screens/settings_screen_test.dart` | Settings at 412×860 behind a 48 px bottom inset, as the PWA (a provider without export/import, since `kIsWeb` is a constant) and as Android: every section heading has its row right under it — "Screen" its keep-awake switch, and no Backup heading on the web — the last row clears the inset, and the switch saves the setting ([[Web]]). |
| `test/screens/about_screen_test.dart` | The version comes from `PackageInfo` (mocked) rather than the ARB files, and the connected features are listed next to the local ones — one test, because a static future completed in one test's fake-async zone never delivers in the next ([[MobileApp]]). |
| `test/screens/game_types_screen_test.dart` | At 412×860 with twenty types, scrolled to the end, the last type's ⋮ menu does not overlap the "New type" button, is hit-testable and opens; the new-type dialog's icon and colour buttons carry the `chooseIcon` and `chooseColor` tooltips as their semantics. The dialog test runs at 1000×1400 because the test font overflows its dropdowns at phone width. |
| `test/screens/app_bar_tooltips_test.dart` | The home app bar's statistics icon (`playerStatistics`) and the board's leaderboard icon (`ranking`) are found by `find.byTooltip`, in English and in French. |
| `test/utils/icon_button_tooltips_test.dart` | A source scan of `lib/`: every `IconButton` passes a `tooltip:`, or has a `// No tooltip …` comment within the six lines above it saying why. |
| `test/utils/insets_test.dart` | `withBottomInset` under a `MediaQuery` with a bottom padding: the inset is added to the bottom edge only, nothing changes without an inset, a zero padding is compensated too (the drawer), and a `ListView` with an explicit padding really does lose Flutter's own compensation — the reason the helper exists. |

Neither the `SafeArea` inset nor the scheme-derived header colour has a widget test: both
need golden files this repo does not use, and an assertion that a `SafeArea` exists proves
nothing. They were verified on device on 2026-09-11.

The Analyze menu entry's own gating (`game_board_screen.dart`, `isConfigured ||
_hasCachedAnalysis`) has **no** widget test: pumping the board needs a loaded game and six
repositories. It was verified on device on 2026-09-11 — both directions, and the p171 case
where neither condition holds.

`flutter test` reported **207 passing, 1 skipped, across 30 files** on 2026-09-18;
`sync_two_devices_test.dart` is the skip, unless a backend is given.

### Group sync against a local backend

```bash
docker run -d --rm --name cs-sync-pg -e POSTGRES_PASSWORD=pw -e POSTGRES_USER=cs \
  -e POSTGRES_DB=cs -p 55433:5432 postgres:17-alpine
cd backend && DATABASE_URL=postgresql://cs:pw@localhost:55433/cs uv run alembic upgrade head
DATABASE_URL=postgresql+asyncpg://cs:pw@localhost:55433/cs GROUP_RL_PER_MINUTE=1000 \
  GROUP_RL_PER_HOUR=10000 SYNC_PUSH_RL_PER_MINUTE=1000 uv run uvicorn app.main:app --port 8765 &
cd .. && SYNC_BACKEND_URL=http://127.0.0.1:8765 flutter test test/sync/sync_two_devices_test.dart
```

Raise the group rate limit: every test creates a group. The `sync` CI job runs exactly this
(port 5432, a services container) on every pull request — if the recipe and the job
disagree, the job is the one that is kept green. Adding
`PWA_BASE_PATH=/countscore PWA_DIR=$PWD/build/web` after a
`scripts/build_web.sh --base-href=/countscore/` serves the PWA on the same host under `_PWA_CSP` — how the
two-browser check of 2026-09-13 ran (Playwright, one context per device), and the
no-Google-request check of 2026-09-19 ([[Web]]).

**On a real phone against production** (2026-09-13, Pixel 9 Pro XL, debug build): a v9
database with 64 real games upgraded to v11 intact; create a group, the production PWA
joins; a shared game created on the phone reaches the PWA, scores entered on either side
appear on the other's open board within seconds; a delete propagates; leaving revokes the
device. A **debug** build is what found the dialog assertion — the PWA runs release, with
asserts compiled out — so run a debug APK on a device before calling a UI change done.

### End-to-end — `integration_test/app_test.dart`

One golden-path `testWidgets`, shared by web and device: create a ZapZap game → 2 global
players (Alice, Bob) → 3 rounds of scores → check totals → end the game from the board's
menu (the leaderboard counts finished games only) → check the leaderboard and Alice's player
card (1 game, 1 win: lowest wins) → generate a ZapZap analysis over a real network call → prove the
`game_analyses` cache was used. The analysis half lives in `_analyse`, skipped whole when no
backend is configured, so the teardown always runs.

Finders are locale-proof across all 10 languages: `Key`s (`create_add_player`,
`player_picker_search`, `player_picker_create`, `player_chip_<name>`,
`player_picker_confirm`, `create_game_submit`, `board_add_round`, the keypad's
`keypad_digit_<d>` and `keypad_primary`, `game_end_headline`, `board_finished_badge`,
`stats_row_<uuid>`, `card_games`, `card_wins`, `analysis_generate`), icons,
and the untranslated literal `ZapZap`.

**`pumpAndSettle` cannot be used while the analysis screen is loading.** Its
`CircularProgressIndicator` animates forever, so the call times out; and settling *after* the
failure waits out the snackbar's own auto-dismiss, leaving nothing to assert. The failure
tests hand-pump instead — see `_pumpFailure` in `test/screens/game_analysis_screen_test.dart`.

**`pumpAndSettle` is not sufficient on web.** The Drift web worker resolves asynchronously
without scheduling a frame, so the suite uses hand-rolled waiters `_waitFor`, `_waitEnabled`
and `_pumpUntil` (which also waits for the keypad's round to reach the database). Do not "simplify" them back to `pumpAndSettle`.

**Tap a text field before each `enterText` on web.** `enterText` only opens a text-input
connection when the focused editable *changes*; on web, tapping a button outside the field
unfocuses it (`TextField`'s default `onTapOutside`) and closes the connection, so a second
`enterText` on the same field sends its text nowhere and the field stays empty. The
who's-playing step taps the search field before typing each name.

**Go back through `_back`, not a bare `pageBack`.** A route still sliding in or out keeps its
back button in the tree, and `pageBack` refuses two; `_back` waits for exactly one, then for
the popped route to leave the tree. It finds and taps the `BackButton` by type: `pageBack` and
`find.byTooltip('Back')` both match the *English* tooltip, so they fail on a device whose
language is not English (a French Pixel says "Retour"), while the web run, in an English
browser, passes. For the same reason the board's menu is found inside the last `AppBar`: the
home route underneath keeps its cards' `more_vert` icons in the tree.

**Web run** — `chromedriver` major version must match the installed Chrome (`google-chrome --version`;
the matching build is `https://storage.googleapis.com/chrome-for-testing-public/<version>/linux64/chromedriver-linux64.zip`):

```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=BACKEND_URL=<your backend URL>
```

The ZapZap network step is **skipped** on web whenever the configured backend's
`CORS_ORIGINS` does not list the serving origin — normally the case for `localhost`. It is
validated separately by `curl` and by the device run.

It is also skipped, on both targets, when **no** `--dart-define=BACKEND_URL` was passed: the
backend URL is a runtime setting with no default, so the Analyze menu entry is legitimately
absent and `_analyse` is not entered. The teardown still runs.

**Device run** — a clean database is required so the defaults are ZapZap and the localized first-game name ("Partie 1", "Game 1"):

```bash
adb shell pm clear com.vemore.countscore
flutter test integration_test/app_test.dart -d <device_id> \
  --dart-define=BACKEND_URL=<your backend URL>
```

This one exercises the real network call, with no CORS in the way. For broader on-device
work, use the `flutter-device-test` skill.

### Web reload — `integration_test/reload_persistence_test.dart`

Web only (skipped elsewhere), no backend. A page cannot reload itself inside an integration
test, so the test reads what a reload would: `integration_test/support/persisted_db_web.dart`
opens the IndexedDB database `countscore` through a fresh `IndexedDbFileSystem` and a second
`sqlite3.wasm`, read-only — what drift's worker has not flushed is invisible to it, as to the
next page load. Straight after the app opens the database it asserts the stored
`user_version` is the current `schemaVersion` and the built-in types are all there; after
creating two games and deleting one (a transaction), that the deletion is stored. Without
`PersistenceFlushInterceptor` it fails on both (version 0; the deleted game still stored) —
checked on 2026-09-19. `sqlite3` is a dev dependency for this, at the version drift already
locks.

```bash
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/reload_persistence_test.dart \
  -d web-server --browser-name=chrome --headless
```

A real reload was checked by hand, in Chromium through Playwright on a release build: the
IndexedDB page 1 holds `user_version` 16 after the first load and after each reload, with no
uncaught error; a browser left at version 0 by the previous build recovers on its first load
of the fixed one.

### Backend — `pytest`

`tests/test_groups.py` (create, join, revoke, rotate) · `test_sync_contract.py` (batch
isolation, group scoping, delete-wins, reject reasons, and the fields added for the Flutter
client — including `games.ended_at` in both directions: set, cleared back to null, and
carried on `/sync/pull`) · `test_sync.py` (push/pull,
idempotence, round conflicts, payload bounds, player-name allow-list, and row-level LWW
between two devices — SQLite in memory, `pg_notify` stubbed) ·
`test_sync_ws_integration.py` (WS handshake + push → NOTIFY → new_seq → pull on a **real
Postgres** via testcontainers) · `test_comments.py` (mocked Anthropic, rate limit, budget,
prompt injection) · `test_game_analysis.py` (the route on **both** paths, bounds,
clipping, name filtering, injection through a player name *and* through the game type, and
the prompt builder) · `test_group_analysis.py` (a shared game's analysis through the group
endpoint: billed to the group's usage, the group's style and language when no voice is
sent, 409 over budget, 404 for another group's game, nothing charged on an upstream
failure) · `test_analysis_prompt.py` (the nine-by-ten matrix of voice by
language, the editorial contract, and that no composed prompt names a real person) ·
`test_analysis_game_rules.py` (the registry, the generic fallback, and that the payload's
configuration overrides it) · `test_analysis_signals.py` (the derived facts, which the model
is forbidden to recite and so cannot check) · `test_llm_providers.py` ·
`test_ip_rate_limit.py` · `test_health.py` (the `/health` shape, including that the resolved
LLM model is reported and that an unknown `LLM_PROVIDER` still answers 200).

**Tests never read `backend/.env`.** `tests/conftest.py` sets `Settings.model_config["env_file"]`
to `None` before `app.db` builds its settings at import, so a developer's local `.env` cannot
make a code-default assertion pass in CI and fail locally
(`test_settings_ignore_a_local_env_file`). Set per-test values with `monkeypatch.setenv`, then
`get_settings.cache_clear()`.

```bash
cd backend
pytest -m 'not integration' -q   # fast, no Docker
pytest -v                        # everything; the integration marker needs Docker
```

`asyncio_mode = "auto"`, `testpaths = ["tests"]`, marker `integration`.

### CI — `.github/workflows/ci.yml`

Six jobs, on every push to `main`, every pull request, a weekly `schedule:` (Mondays 06:17
UTC) and `workflow_dispatch`. `scope` runs first and alone, in ~10 s, and decides which of
the other five run; they are parallel behind it. On `main`, on the weekly run and on
`workflow_dispatch` every flag is `true` — those keep a complete verification record.
Flutter is pinned to **3.47.2** by the `FLUTTER_VERSION` env key — that pin and the
toolchain table in [[MobileApp]] must move together.

| Job | Steps |
|---|---|
| `scope` | `scripts/ci_scope_selftest.sh` → `scripts/retry_sqlite3_hash_selftest.sh` → `gh api repos/{owner}/{repo}/pulls/<n>/files` (`.filename` **and** `.previous_filename`) → `scripts/ci_scope.sh` → five `name=true\|false` flags into `$GITHUB_OUTPUT` |
| `backend` | `postgres:17-alpine` service → checkout at depth 2 → privacy page tests (`scripts/test_build_privacy_page.py`) → pandoc **3.6.4** (release archive, checksum-pinned) → `scripts/build_privacy_page.py --check --base HEAD^1` → `uv sync --locked --extra dev` → `ruff check .` → `ruff format --check .` → `mypy` → `pytest -v` → `play_publish.py` tests (`.claude/skills/release-android/scripts/`, fake Google service) → `fonts-roboto-unhinted` → `scripts/test_compose_screenshots.py` → `compose_screenshots.py --check` → `alembic upgrade head` → `downgrade base` → `upgrade head` → `check` (a migration round trip) → `uv export` + `pip-audit` |
| `image` | `docker build backend` → runs as non-root, no compiler, no dev dependencies, read-only code → `docker build -f backend/Dockerfile.backup backend` → `age --version`, `pg_dump --version` (17) → `countscore-backup --once` with no recipient must exit non-zero → `docker compose config --quiet` on both compose files, failing on any warning |
| `app` | `scripts/hooks_selftest.sh` → `scripts/check_web_build_selftest.sh` → `osv-scanner` on `pubspec.lock` → `pub get` → sqlite3 native-library cache (below) → `scripts/web_binaries.sh --check` (and `--fetch` on the weekly run only) → `scripts/test_third_party_licenses.py` → `scripts/third_party_licenses.py --check` → `dart run build_runner build` → `analyze` → `test` (through `scripts/retry_sqlite3_hash.sh`) → fallback-font cache → `scripts/build_web.sh` → `scripts/check_web_build.sh build/web` |
| `android` | `pub get` → sqlite3 native-library cache → `dart run build_runner build` → `build apk --debug` (through `scripts/retry_sqlite3_hash.sh`) |
| `sync` | `postgres:17-alpine` service → `uv sync --locked` → `alembic upgrade head` → `.venv/bin/uvicorn` on 8765 (waits on `/health`; never `uv run`, whose parent process holds the uv cache lock and makes setup-uv's post-job `uv cache prune` time out whenever `uv.lock` changed) → `pub get` → sqlite3 native-library cache → `build_runner build` → `flutter test test/sync/sync_two_devices_test.dart` (through `scripts/retry_sqlite3_hash.sh`) |

**What `scope` decides, and what it must never do.** `scripts/ci_scope.sh` is a pure
function — changed paths on stdin, five flags on stdout, no `gh` and no network — so it is
replayable by hand (`git diff --name-only origin/main...HEAD | scripts/ci_scope.sh`) and
pinned by `scripts/ci_scope_selftest.sh`, which runs as the job's first step. First match
wins, per path:

| Path | Jobs |
|---|---|
| `privacy_policy.md`, `docs/privacy-policy.html` | `backend` (the privacy page check) |
| `THIRD_PARTY_LICENSES.md` | `app` (the licence list check) |
| `store_listing/*/screenshots/*`, `store_listing/*/raw/*`, `store_listing/*/screenshot_captions.txt`, `scripts/compose_screenshots.py`, `scripts/test_compose_screenshots.py` | `backend` (the composer's tests and `--check`) |
| `*.md`, `.llmwiki/`, `wip/`, `docs/`, `store_listing/`, `LICENSE` | *none* |
| `backend/` | `backend`, `image`, `sync` |
| `android/` | `android` |
| `web/` | `app` |
| `pubspec.yaml`, `pubspec.lock` | `app`, `android`, `sync` |
| `lib/`, `test/`, `integration_test/`, `test_driver/`, `l10n.yaml`, `analysis_options.yaml` | `app`, `sync` |
| **anything else** — `.github/`, `.claude/` outside its `.md` files, `scripts/`, `ios/`, a root config, an unclassified path | **all five** |

A `case` glob's `*` crosses `/`, so `*.md` is `**/*.md`: `backend/README.md` and a skill's
`SKILL.md` are documentation, and nothing outside that line is. `android` is in the
dependency rule — a package can bring a Gradle plugin, Kotlin or a build hook — but not in
the Dart rule (2026-09-19, below): on a pull request a Dart-only change does not build the
APK, and on `main` and the weekly run every flag is forced true, which
`ci_scope_selftest.sh` asserts. The catch-all is the whole safety
argument: being wrong costs a slow run, never an untested merge.

**A job-level `if:`, never a workflow-level `paths:`.** A workflow skipped by path filtering
reports *no status at all*, so a required check stays Pending and the pull request never
merges; a job skipped by a conditional reports **Success**
([GitHub docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/troubleshooting-required-status-checks)).
Each of the five carries `if: ${{ !cancelled() && needs.scope.outputs.<job> != 'false' }}`.
Three details are load-bearing, and `ci_scope_selftest.sh` greps for two of them:

- **`!cancelled()`** — `needs:` adds an implicit `success()`, dropped only when the
  expression contains a status function. Without it a failed `scope` would skip all five,
  each reporting Success, and anything would merge. `always()` would be worse: it would also
  run them on a genuinely cancelled run, defeating `cancel-in-progress`.
- **`!= 'false'`, not `== 'true'`** — `needs.scope.outputs.<x>` is the empty string whenever
  the output was not written (job failed, job skipped, output name mistyped), and
  `'' != 'false'`. Read it as *run unless `scope` succeeded and explicitly said no*.
- **The `${{ }}` is not cosmetic** — a bare `if: !cancelled() && …` is invalid YAML (`!`
  opens a tag), and a workflow that does not parse reports nothing, blocking every open pull
  request.

`scope` is deliberately **not** a required check: see [[ParallelDelivery]]. The
`pulls/<n>/files` endpoint has no `path` key — `-q '.[].path'` would emit one `null` per
file, every `null` would hit the catch-all, and the change would be green forever having
saved nothing. It is also capped at 3000 files, which the step handles by scoping nothing
out. Fork pull requests work: `github.token` is read-only there, but the endpoint is public
and so is this repository.

**Codegen comes before analyze, test and every build.** `*.g.dart` is gitignored, so
`lib/services/drift/database.g.dart` does not exist in a fresh clone; skipping the step
fails with `Target of URI hasn't been generated` and a cascade of undefined `_$AppDatabase`
errors. On the `android` job that cascade appears *after* minutes of Gradle configuration,
so it reads like a Gradle fault when it is not.

`uv`, not `pip install -e ".[dev]"`: `testcontainers` and `httpx-ws` live in
`[dependency-groups]`, which pip does not read, so a pip-based job would silently skip the
integration test. `--locked` additionally fails if `uv.lock` has drifted from
`pyproject.toml`.

**The sqlite3 native libraries are cached, and a bad download is retried once.**
`package:sqlite3` 3.x's build hook, run by `flutter test` and `flutter build apk` (not by
`build_runner`), downloads a precompiled `libsqlite3` from the package's GitHub release into
`.dart_tool/hooks_runner/shared/sqlite3/build/download-<first 8 hex of its SHA-256>/`, and
reuses a file already there only when its hash matches
(`lib/src/hook/compile/description.dart` in the pub cache). It hashes the response body
without looking at the HTTP status, so a GitHub error page fails as `Bad state: Hash of
downloaded file <name> is <digest>, expected <hash>` — runs 35335702639 (`android`) and
35429735515 (`sync`) both got digest `2514114…f003` for two different files. `app`, `sync` and
`android` each read the `sqlite3` version from `pubspec.lock` and restore those `download-*`
directories with `actions/cache@v6`, key `sqlite3-native-<job>-<os>-<version>`: per job,
because each downloads different files (Linux x64 for the tests, three Android ABIs for the
APK) and a cache entry is immutable once saved. The hook still hashes every restored file.
The step that runs the hook goes through `scripts/retry_sqlite3_hash.sh`, which runs the
command once more **only** when it failed with that message — the first run after a
`sqlite3` bump misses every cache — and returns the second attempt's status as final, so a
job that fails twice fails. `scripts/retry_sqlite3_hash_selftest.sh` pins both, in `scope`.

The `android` job caps the Gradle heap by appending to `$HOME/.gradle/gradle.properties`,
which outranks the project's `android/gradle.properties` and its `-Xmx8G` request; the
committed file is not touched. It builds **debug** only — release signing reads
`android/key.properties`, absent in CI by design — and asserts afterwards that the Flutter
tool injected the gitignored `gradlew` and `gradle-wrapper.jar`.

The `sync` job is the only one where the client meets the real server contract. uvicorn is
started with `GROUP_RL_PER_MINUTE`/`_PER_HOUR` and `SYNC_PUSH_RL_PER_MINUTE` raised, since
every test creates a group from one address; its log is printed only when the job fails.
It sets `SYNC_TEST_REQUIRED=true`, which makes the test *fail* when `SYNC_BACKEND_URL` is
missing — without it, a renamed variable would turn the job into a green run of nothing.

**`alembic check` fails on any difference between the migrated schema and the SQLModel
models** — a type, a nullability, an index. The fix is on whichever side is wrong: a model
that drifted from the DDL gets an explicit `sa_column` (as `change_log.id`,
`.client_lamport`, `.server_seq` and `comments.content` did), a real schema change gets a
revision (`db-migration` skill). `backend/tests/test_model_ddl.py` pins those four columns in
the fast suite. A `BigInteger` primary key needs `.with_variant(Integer(), "sqlite")`: only an
`INTEGER PRIMARY KEY` autoincrements on SQLite, which the tests run on.

**The dependency audit** exports `uv.lock` with hashes — runtime, the `dev` extra and the
`dev` group — and runs `pip-audit` 2.10.1 (pinned in the `uvx` call) with `--strict`. Any
advisory fails the job. One with no fix yet is ignored explicitly with `--ignore-vuln <ID>` in
the step and tracked by a `wip/` entry, never left red. **It no longer runs on a pull
request that leaves `backend/` alone** — it used to, incidentally, on every documentation
pull request. The weekly `schedule:` run is what replaces that, and caps the exposure window
at seven days — as long as it still fires, which is what `scripts/check_scheduled_runs.sh`
watches (below).

**The Flutter dependencies have the same gate, in the `app` job (2026-09-18).**
`osv-scanner` 2.6.0 — downloaded from its GitHub release and checked against a pinned
SHA-256 in the step — scans every package `pubspec.lock` resolves, direct and transitive,
with `--all-vulns`; any advisory fails the job (exit 1). `dart pub audit` does not exist.
osv-scanner has no `--ignore-vuln` flag: its equivalent is an `[[IgnoredVulns]]` block
(`id`, `reason`, optionally `ignoreUntil`) in `.github/osv-scanner.toml`, passed with
`--config`, and the `reason` names the `wip/` entry that tracks it — same rule as
`pip-audit`. It runs right after the hooks self-test, before Flutter is even installed, and
`scripts/ci_scope.sh` sends every `pubspec.lock` change to `app`, so a Dependabot or
`deps.yml` lock bump is audited before it merges; the weekly run covers the weeks nothing
touched it. It found nothing on 2026-09-18 (162 packages).

| Ecosystem | Version updates | Vulnerability gate (fails CI) |
|---|---|---|
| `uv` (backend) | `.github/dependabot.yml`, weekly | `pip-audit --strict`, `backend` job |
| `pub` (app) | `.github/dependabot.yml`, weekly (direct only) + `deps.yml`, monthly (transitive) | `osv-scanner` on `pubspec.lock`, `app` job |
| `github-actions` | `.github/dependabot.yml`, weekly | none — Dependabot alerts only |

`.github/dependabot.yml` raises *version* updates only, and only for the direct
dependencies written in `pubspec.yaml`. The transitive half is refreshed by
`.github/workflows/deps.yml` (below) — a **freshness** cadence, not a vulnerability scan.

**The committed `web/` binaries are gated.** `scripts/web_binaries.sh --check` runs in the
`app` job right after `flutter pub get` and fails it when `web/drift_worker.js` does not
match the drift version `pubspec.lock` resolves, or when `web/sqlite3.wasm` does not match
the digest and version recorded in `web/sqlite3.wasm.sha256` beside it. It is offline
(~20 ms) and both binaries are always checked, so one Dependabot week that moves both
packages prints both problems. On the weekly `schedule:` run a second step adds
`--fetch`, which compares the committed wasm with the asset GitHub serves today and so
catches a re-cut upstream release; it is written `|| [ $? -eq 3 ]` because exit 3 is "could
not check" (no network) while exit 1 is a real mismatch. See [[Web]] for the two sources
and the `--refresh` procedure. This gate does **not** prove the PWA still works with the
new binaries: the web e2e is still not in CI (§Gaps), so a `--refresh` is followed by that
run by hand.

**`THIRD_PARTY_LICENSES.md` is generated and gated (2026-09-19).**
`scripts/third_party_licenses.py` (stdlib Python) writes it from the direct `dependencies:`
and `dev_dependencies:` of `pubspec.yaml`: licence family and copyright line from each
package's `LICENSE`, repository from its own `pubspec.yaml`, both found through
`.dart_tool/package_config.json` — so it needs `flutter pub get` first, and reads the version
the lock resolves. The Nunito font, the `in_app_review` note and the licence texts are
hand-written inside the script. It prints no version numbers, so a Dependabot bump fails the
check only when a package's copyright line or licence moves. A `LICENSE` it cannot classify
(anything but MIT, BSD-2-Clause, BSD-3-Clause) exits 3 rather than guessing. The `app` job
runs its tests (`scripts/test_third_party_licenses.py`, fixtures under `tmp_path`) and then
`--check`, which prints the diff and fails; the fix is `uv run --no-project
scripts/third_party_licenses.py` and a commit. `scope` sends the file itself to `app`, ahead
of the documentation rule; `pubspec.yaml` and `pubspec.lock` already go there.

**The transitive refresh is `.github/workflows/deps.yml`**, monthly (`cron: "23 5 4 * *"`)
plus `workflow_dispatch`: `flutter pub upgrade` → `scripts/web_binaries.sh --refresh
--fetch` → `scripts/third_party_licenses.py` → `build_runner build` → `analyze` → `test`, and when `pubspec.lock` or `web/`
(or `THIRD_PARTY_LICENSES.md`)
moved it commits to `chore/deps-YYYY-MM-DD`, pushes that branch and writes the ready-made
`gh pr create` line into the run summary. `material_color_utilities`, `cli_util` and
`test_api` are pinned by the Flutter SDK and only `FLUTTER_VERSION` moves them.

**It cannot be dry-run before it is on `main`.** GitHub only exposes the dispatch endpoint
for a workflow present on the *default* branch, so `gh workflow run deps.yml --ref
<branch>` answers `HTTP 404: Not Found` from a pull request branch. A new scheduled
workflow is therefore first exercised by `gh workflow run deps.yml` right after its merge —
and the branch that run pushes is deleted unless it is wanted.

**Both crons are watched, because GitHub turns them off.** A workflow triggered by a
`schedule:` and nothing else is disabled after 60 days without repository activity, and
re-enabling it is a manual click. Neither of these two goes red when it stops — a scheduled
run has no pull request in front of it. `scripts/check_scheduled_runs.sh` asks GitHub for the
state of `ci.yml` and `deps.yml` (`disabled_inactivity` is GitHub's own name for the rule)
and for the age of each one's newest `schedule`-event run, against a threshold per workflow:
10 days for the weekly, 40 for the monthly. It exits 0 silent when both are healthy, 1 with a
report, and 3 — also silent — when it cannot ask. `.claude/hooks/session-start.sh` runs it at
most once a day ([[Hooks]]); nothing in CI does, since a check of the crons that is itself a
cron has the same problem. Run it by hand any time: `scripts/check_scheduled_runs.sh`.
Its answers — fresh, overdue, disabled, never run, unauthenticated, not GitHub — are pinned
offline in `scripts/hooks_selftest.sh` against a stubbed `gh`, together with the hook's
once-a-day stamp.

What covers them instead is **Dependabot alerts**, enabled on the repository on 2026-09-16
together with the dependency graph they require. Both had been off since the repository was
created: `gh api repos/{owner}/{repo}/dependabot/alerts` answered
`403 Dependabot alerts are disabled for this repository`, and now answers `[]` — enabled,
no open advisory on any ecosystem.

Two things this does *not* give, and the difference matters:

- **Nothing fails a build.** An alert is a notification on the repository, not a gate. The
  gates are `pip-audit --strict` (backend) and `osv-scanner` (`pubspec.lock`, since
  2026-09-18, `wip/done/2026-09-16-dependabot-alerts-disabled.md`); a `github-actions`
  advisory still reaches only GitHub's security tab.
- **Nothing opens a fix.** *Dependabot security updates* — the setting that turns an alert
  into a pull request — is deliberately left off, so a security bump arrives on the normal
  weekly version-update schedule like any other.

A repository setting can also be switched off again without leaving a trace in git, which is
the other reason the CI gate is the durable half of this.

Not in CI on purpose: the e2e suite (it calls the real production endpoint) and the signed
release APK/AAB (needs the keystore secrets).

### Gaps

**The e2e suite does not run in CI.** `integration_test/app_test.dart` drives a real
network call against production, so it stays a manual step — on web via chromedriver, on a
device via the `flutter-device-test` skill. The web reload test beside it is manual too: no
CI job runs chromedriver. Export/import has no automated coverage at all
and must be checked on a device; the wakelock toggle is covered only down to the saved
setting (`test/screens/settings_screen_test.dart`) — whether the platform holds the lock is
checked on a device, or in a browser through `navigator.wakeLock` ([[Web]]).

**The sync conflict branch is untested.**

> **Status: Outdated** (2026-09-13) — covered now. Three tests in `test_sync.py` drive two
> devices of one group at the same `entity_uuid`: an older lamport answers `merged_lww` and
> contributes nothing, including a field only the loser set (the row-level fact); a newer
> lamport from the other device wins; an equal lamport is broken by the greater
> `origin_device_id`. Each fails when its half of the comparison at
> `backend/app/routes/sync.py` is removed.

## Decisions & History

- **The scheduled refresh pushes a branch, it does not open the pull request**
  (2026-09-16). A pull request created with the default `GITHUB_TOKEN` triggers no
  workflow, by GitHub's design against recursion, so the five required checks of `ci.yml`
  would never report on it and it could never merge — a bot pull request that is permanently
  unmergeable is worse than none. The alternatives were a personal access token or a GitHub
  App, both a new secret to store and rotate for a repository whose only user is its author;
  the branch plus a copy-pasteable `gh pr create` line costs one command and no secret.
  `deps.yml` is the second workflow exposed to GitHub disabling a scheduled workflow after
  60 days of repository inactivity — closed since by
  `wip/done/2026-09-16-scheduled-workflow-auto-disabled.md`: both crons are now watched from
  the session-start hook (above), rather than moved to a daily cadence, which would have
  rested on the unverified premise that a scheduled run is itself "repository activity".
- **The binary check is a script, not inline YAML** (2026-09-16). The same command has to
  be the CI gate, the local check and the fix (`--refresh`), or the fix drifts from what the
  gate demands — which is how `web/drift_worker.js` was left behind by Dependabot #43 in the
  first place. Exit 3 exists so a scheduled `--fetch` can tolerate a network failure without
  tolerating a real mismatch.
- **The e2e suite is one golden path, not a matrix.** It is the smallest thing that proves
  the whole stack — UI, Drift, migration defaults, network, cache — is wired together. Its
  value is breadth, not depth; depth belongs in the unit tests.
- **Finders key off `Key`s rather than text** so the suite survives all 10 locales.
  Adding a language must never break the tests.
- **The WS integration test uses testcontainers instead of a stub** because
  `LISTEN/NOTIFY` and JSONB are exactly the Postgres-specific behaviour the rest of the
  suite mocks away. It is marked `integration` so the default run stays Docker-free.
- **CI runs the full backend suite, integration tests included** (2026-09-09). The runner
  has Docker, so paying ~40 s to start `postgres:17-alpine` buys mechanical coverage of
  `LISTEN/NOTIFY` and JSONB, which nothing else exercises. `TESTCONTAINERS_RYUK_DISABLED`
  is set because the runner is ephemeral and Ryuk is a known flake source. If it ever turns
  flaky, the fallback is `-m 'not integration'` on PRs and the full run on `main`.
- **The Android CI job builds debug, and there are no path filters** (2026-09-09). Debug
  because release signing needs `android/key.properties`, which is never committed. No
  `paths:` filters because a filtered-out job never reports a status, so branch protection
  with required checks would hang forever on docs-only PRs — and because the bug that
  motivated CI at all (`settings.gradle` shadowing `settings.gradle.kts` for years) was
  precisely a "nobody built it" bug. Narrowing when the build runs would reopen that hole.
  > **Status: Outdated** (2026-09-16) — the second half held only for workflow-level
  > `paths:` filters, which are still forbidden and still absent. A job-level `if:` reports
  > Success when it skips, so the same narrowing is possible without hanging a required
  > check; see the `scope` decision below. The `android` job still builds on every Dart
  > change, so the "nobody built it" hole stays shut.
  > **Status: Outdated** (2026-09-19) — it no longer does on a pull request; see the
  > `android` decision below. Every push to `main` and the weekly run still build it.
- **A `scope` job, not `paths:` filters** (2026-09-16). Every pull request ran all five jobs:
  ~4 min 30 and ~13 runner-minutes to start a Postgres and build an APK for a change to
  `wip/`. Replaying the last 20 merged pull requests through `scripts/ci_scope.sh`, 8 would
  have run nothing at all — measured at 12 s wall clock on pull request #64, against 4 min 30. Runner minutes are free on a public repository — what this buys is
  latency on documentation and backend pull requests, and runner contention when
  `ship-parallel` pushes four or five branches at once (5 jobs × 5 branches is past the
  20-concurrent-job ceiling). It is **not** a win everywhere: `scope` is a serialised hop, so
  a `lib/`-only pull request gets ~20 s *slower* and still pays the 4 min 17 `android` job.
  Dropping `android` from the Dart rule is the only lever that would change that, and it is
  deliberately not pulled here (`wip/todo_nr/2026-09-16-android-job-on-every-dart-change.md`).
  > **Status: Outdated** (2026-09-19) — the lever is pulled; see the next decision.
  Rejected alternative: classify inside each job and exit early — that boots five runners
  instead of one, and reports a green job that did nothing.
- **`android` leaves the Dart rule** (2026-09-19). The job is the critical path (4 min 17,
  against 3 min 30 for `app`), and its stated purpose — the injected `gradlew` and wrapper
  jar, the pinned SDK packages, the release manifest's `INTERNET` — does not depend on
  `lib/`. The evidence: every `ci.yml` run from the first (2026-09-09) to 2026-09-19, 416 of
  them, searched through `gh run list` and each failed or rerun attempt's jobs
  (`actions/runs/<id>/attempts/1/jobs`). Two had `android` red and `app` green, both on
  feat/play-again-and-type-order and both network flakes that passed on rerun: 35335702639
  (the sqlite3 hash mismatch above) and 35336544456 (Maven Central answering 403). None
  was an AOT compile failure the analyzer and the tests had missed. So a pull request
  touching only `lib/`, `test/`, `integration_test/`, `test_driver/`, `l10n.yaml` or
  `analysis_options.yaml` no longer builds the APK; `pubspec.*` still does, and so do every
  push to `main` and the weekly run, which force all five flags — the "nobody built it"
  hole of 2026-09-09 stays shut at merge time, one push later than before. If a Dart-only
  change ever breaks the APK build, it goes red on `main` and the rule goes back.
- **Cache the sqlite3 downloads rather than retry blindly** (2026-09-19). The hash mismatch
  recurred in a second job after the first entry was dropped as a one-off. A cache makes the
  download rare instead of making it succeed on a second try; the retry exists only for the
  first run after a version bump, is limited to the hook's message and to one attempt, and
  never touches the hash check — a tampered library would still fail twice, and the job with
  it.
- **The two-device sync test runs in CI, as its own job** (2026-09-14). Not folded into
  `app`: it needs Python, a Postgres and a running server, and a failure there should read
  as a sync regression rather than a Flutter one. A `services:` container, not
  testcontainers, because the server and the Flutter test are separate processes that both
  need a fixed port. It adds ~5 min of wall time in parallel, not in series.
- **`alembic check` and the dependency audit are steps of `backend`, not jobs of their own**
  (2026-09-14). The job name is a required status check in branch protection; a new job
  would not be required until someone edits the protection, and a renamed one would block
  every open pull request. The Postgres `services:` container is used by `alembic check`
  alone — the integration test keeps its testcontainers instance on a random port. Found
  on 2026-09-13: `alembic check` reported four columns narrower in the models than in
  `0001_initial.py`; the models were aligned, no revision was needed. `pip-audit` rather
  than `uv audit`, which uv 0.12 still ships as a preview command; both found nothing on
  2026-09-14.
- **The privacy page is checked in `backend`** (2026-09-18). #75 and #77 edited
  `privacy_policy.md` without running `scripts/build_privacy_page.py`, so the page Play links
  to went two days without their details, and neither added a Version History entry.
  `build_privacy_page.py --check --base HEAD^1` renders the page and diffs it against the
  committed one, and fails when the policy changed but its `**Last Updated**` line did not.
  A step of `backend`, not a job, for the same reason as below: that job is a required check
  and already has Python. `scope` sends both files there, ahead of the documentation rule
  that used to run nothing for them; a privacy-only pull request now pays the backend suite,
  which is rare enough not to matter. `--check` diffs in Python instead of
  `git diff --exit-code`, so it works on an uncommitted page locally and writes nothing.
  pandoc is pinned at 3.6.4 by version and checksum — the page on `main` rendered
  byte-identical with that release archive, so it was not regenerated.
- **The backup sidecar and the compose files are checked in `image`, the `pub` audit in
  `app`** (2026-09-18). Steps, not jobs, for the same reason as above: both job names are
  required checks. The sidecar used to be built only by `deploy_nas.sh`, so a bad
  `postgres:17-alpine3.23` / `age~1.2` pin would have surfaced as a failed production deploy
  (`wip/done/2026-09-14-ci-build-backup-image.md`). `docker compose config` exits 0 on an
  unset variable and only warns, hence the any-stderr rule. osv-scanner rather than a
  GitHub action: a checksummed binary is pinned exactly, like `pip-audit@2.10.1`, and
  needs no extra permission (`wip/done/2026-09-16-dependabot-alerts-disabled.md`).
- **The unit-test table names what each file covers, not how many tests it has**
  (2026-09-18). The per-file counts had gone wrong in seven rows and six files had no row at
  all, while the total said 128 against 207 run. A row is owed whenever a test file is added;
  the one dated total is re-read from a `flutter test` run, never summed from the table
  (`wip/done/2026-09-16-wiki-owed-by-rating-prompt.md`).
- **`THIRD_PARTY_LICENSES.md` is generated, not written** (2026-09-19). The hand-written
  file named a 2025 dependency set — four stale constraints, seven direct dependencies
  missing — because nothing tied it to `pubspec.yaml`; a rule in `CLAUDE.md` naming it was
  the alternative, and was refused at refinement for a script and a CI check. A step of
  `app`, the one required job that already has the pub cache. No versions in the file: they
  would turn every Dependabot week red for no compliance gain, and `pubspec.lock` has them
  (`wip/done/2026-09-14-third-party-licenses-stale.md`).
- **The screenshot composer's tests run in `backend` (2026-09-19).** They were local only,
  and nothing refused a raw 1080×2400 capture committed under
  `store_listing/<locale>/screenshots/phone/`: `store_listing/` selected no job. A step of
  `backend`, the required job that already has uv, like `play_publish.py`'s tests; `scope`
  routes the screenshots, the raw captures, the captions and the composer to it, ahead of the
  documentation rule. `--check` also refuses a PNG there that matches no raw capture, so a
  file the composer did not write cannot ride along. The runner has no Roboto, so the step
  installs `fonts-roboto-unhinted`; the CJK, Arabic and Devanagari fonts are not needed, the
  tests draw Latin only (`wip/todo/2026-09-18-store-screenshots-show-french-ui-everywhere.md`).
