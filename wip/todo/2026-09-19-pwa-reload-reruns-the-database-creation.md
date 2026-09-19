# Every reload of the PWA reruns the database creation: game types vanish and deletions come back

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** web
- **Area:** web
- **Blocks release:** no — Android is unaffected (sqflite bootstraps its own file); the production PWA is broken for any returning user

Reproduced on the production PWA and on a local debug build of the same commit (`0785b72`).
In a fresh Chromium profile everything works. After **any reload**, whether 1 s or 30 s
after first load:

- **Game types are gone from every screen that loads them.** "Types de jeux" shows "Aucun
  type de jeu" ([capture](../assets/2026-09-19-pwa-reload-reruns-the-database-creation/types-empty-after-reload.png)). "Nouvelle partie" stays on
  "Chargement des types de jeux…" and then throws `Bad state: No element`
  (`create_game_screen.dart:62-73`, a `.first` on an empty list). **A returning user cannot
  create a game.** The home filter sheet still lists them, and existing games still open.
- **A deleted game comes back.** Create two games, delete one, reload (even 30 s later): both
  are listed again ([capture](../assets/2026-09-19-pwa-reload-reruns-the-database-creation/deleted-game-back-after-reload.png)). Scores entered just
  before a reload do survive.
- Four uncaught `Error`s are logged on each such screen. The debug build names them:
  `SqliteException(2067): UNIQUE constraint failed: game_types.builtin_key`, raised by
  `INSERT INTO game_types (builtin_key, …) VALUES (…, zapzap, …)`, which is
  `_insertDefaultGameTypes()` in **`onCreate`** (`lib/services/drift/database.dart:36-45`).
  So Drift believes the database is new on each reload.
- Drift logs `Using WasmStorageImplementation.sharedIndexedDb` (no `SharedArrayBuffer`
  without COOP/COEP), so the file lives in IndexedDB. Same-origin prod and local behave alike.

**Likely cause, to confirm:** the IndexedDB-backed file loses its header page between
sessions. `user_version` reading 0 would explain `onCreate` running again. A stale header,
such as the page count or freelist, would explain a `DELETE` that does not stick while
appended rows do. Before v15 (#103) the rerun must have duplicated the built-in types
silently, which is probably the real origin of the duplicates #103 guarded against. The v15
unique index turned that silent duplication into this failure.

Supersedes [[2026-09-18-pwa-uncaught-error-at-startup]] (the same bare `Error`, whose entry
believed the data survived a reload).

**Fix:** reproduce in a web e2e test (load, write, reload, assert `user_version` = 16 and
the rows). Then fix the persistence, for example by awaiting drift's flush before the page
can unload, choosing another `WasmStorageImplementation`, or updating drift and
sqlite3.dart. Also make `onCreate` seeding idempotent (`INSERT … WHERE NOT EXISTS
(builtin_key)`, as `applyV14` already does), and give the create screen an empty state (#138 replaced the `.first`
crash with a guard at `create_game_screen.dart:82`, but it now shows `loadingGameTypes`
forever, :273-274). Check what the reload-time `POST /sync/push` observed during the pass
actually sends.

**Acceptance:**
- A web e2e test: after a reload, `PRAGMA user_version` is 16 (the current `schemaVersion`) and no uncaught error is logged.
- The same test: after a reload the "Types de jeux" list still holds the built-in types, and
  a game deleted before the reload stays deleted.
- A widget test: the New game screen with no game types shows an empty state, neither an
  exception nor an endless "Loading game types…".
