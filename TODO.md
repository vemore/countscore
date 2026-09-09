# TODO

## Upgrade Flutter to 3.47 to unblock the held-back dependencies

**Status:** open — noted 2026-09-09, during the dependency update (`f0a8bd6`).

We currently run **Flutter 3.41.9 / Dart 3.11.5**. Latest stable is **3.47**.
Six upgrades are blocked by that, and one of them is an actual defect rather
than just a version lag.

### The reason this matters now: the drift_dev CLI is broken

`dart run drift_dev <anything>` fails to compile at the pinned
**drift 2.34.4 / drift_dev 2.34.0** pairing:

```
drift_dev-2.34.0/lib/src/services/schema/verifier_common.dart:45
  The getter 'allSchemaEntities' isn't defined for the type 'GeneratedDatabase'
  - from drift-2.34.4/lib/src/drift3_preview/src/database/db_base.dart
```

Code generation through `build_runner` is **not** affected — that is the path
the project actually uses, and `database.g.dart` regenerates fine. What is
broken is every CLI subcommand, including `make-web-worker`, which is how
`web/drift_worker.js` would normally be regenerated.

That is why `web/sqlite3.wasm` and `web/drift_worker.js` are committed
(`8a13541`) despite being ~1.1 MB: with the CLI down, the repo is the only
reliable source for them. Once the CLI builds again, reconsider tracking them.

`drift_dev` **2.34.6** is the candidate fix, but it needs a newer `analyzer`
than Dart 3.11 allows — hence the Flutter upgrade.

### What else the upgrade unblocks

| Package | Pinned at | Latest | Blocked by |
|---|---|---|---|
| `drift_dev` | 2.34.0 | 2.34.6 | analyzer tied to Dart 3.11 |
| `build_runner` | 2.15.1 | 2.16.1 | analyzer tied to Dart 3.11 |
| `flex_color_picker` | 3.8.0 | 4.0.0 | requires Flutter 3.47 |
| `wakelock_plus` | 1.7.0 | 1.8.0 | requires Flutter 3.47 |
| `sqflite` | 2.4.2+1 | 2.4.3 | requires Dart 3.12 |
| `intl` | 0.20.2 | 0.20.3 | pinned by `flutter_localizations` |

`flex_color_picker` 4.0.0 is the only major among them. Its one real breaking
change — the removal of `colorCodeIcon`, deprecated since 2.0.0 — does not
affect us: `game_types_screen.dart` and `players_screen.dart` use only
`ColorPicker(color:, onColorChanged:, pickersEnabled:)`.

### Things to watch when doing it

- **Kotlin/AGP drift.** `android/settings.gradle.kts` pins Kotlin 2.2.20 and
  AGP 8.9.1; Flutter 3.41.9's template ships AGP 8.11.1 / Gradle 8.14, and
  3.47's will be newer again. Kotlin already had to be bumped once for
  `wakelock_plus` 1.7.0 to compile at all — expect the same class of problem.
- **Clean build required.** Gradle's incremental state survives plugin
  swaps badly; `flutter clean` before judging any failure.
- **`sqlite3_flutter_libs` resolves to `0.6.0+eol`** (transitive of
  `drift_flutter`). The `+eol` suffix marks end-of-life; check whether a newer
  `drift_flutter` moves off it.
- Regenerate afterwards: `dart run build_runner build` (note `*.g.dart` is
  gitignored, so a clean checkout must run this) and `flutter gen-l10n`.
- Verify on a real device, not just tests: the export/import flow
  (`file_picker`) and the wakelock toggle have no automated coverage. See
  `.claude/skills/flutter-device-test/`.

### Also open, unrelated to the SDK

- `openai` is pinned `>=2,<3` in `backend/pyproject.toml` while 3.x is out.
  3.0 switches to `httpx2`, like `anthropic` 1.x did. Our usage
  (`AsyncOpenAI`, `chat.completions.create`, `openai.OpenAIError`) passes no
  httpx objects, so it should be a lift-the-pin change — but it deserves its
  own pass rather than riding along with an SDK upgrade.
- There is **no CI**. Nothing mechanically checks that a fresh clone builds,
  which is uncomfortable given `*.g.dart` is gitignored.

---

## Surfaced during the LLM-wiki migration

**Status:** open — noted 2026-09-09, while decomposing `CLAUDE.md` and `ARCHITECTURE.md`
into `.llmwiki/`. None of these were introduced by that change; they were found by reading
the whole tree at once. Background for each lives in the wiki page named alongside it.

### Backend lint debt — 40 ruff errors

`ruff check .` in `backend/` has never been clean against the pinned ruff 0.16.6:

| Rule | Count | What it is |
|---|---:|---|
| `UP017` | 16 | `timezone.utc` → `datetime.UTC` |
| `I001` | 5 | Unsorted import blocks |
| `F401` | 4 | Unused imports (`sync.py` imports `HTTPException` and `Group` for nothing) |
| `E501` | 4 | Lines over 100 |
| `RUF100` | 4 | `noqa: E402` directives that no longer suppress anything |
| `RUF059` | 3 | Unpacked-but-unused `group_id` in `test_sync.py` |
| `SIM105` | 2 | `try`/`except`/`pass` → `contextlib.suppress` |
| `SIM118`, `UP041` | 1 each | `key in dict.keys()`; aliased `TimeoutError` |

**30 of the 40 are auto-fixable.** `UP017` and `I001` together are 21 of them and are purely
mechanical. The four `F401`/`RUF059` are worth reading rather than auto-fixing — an unused
import can mean a dropped call site.

This matters more than it did: `backend/CLAUDE.md` now advertises `ruff check .` as part of
the loop, so leaving it red trains everyone to ignore it. Do the auto-fixable pass, then
decide case by case on the rest.

### mypy is declared but never configured

`mypy>=2.3.1` sits in the dev extras and a `.mypy_cache/` exists, so it has been run by
hand — but there is no `[tool.mypy]`, no `mypy.ini`, no `setup.cfg` anywhere. Either
configure it (and add it to the loop next to ruff) or drop the dependency. Right now it is
neither a gate nor an honest absence. See `.llmwiki/Backend.md`.

### The Flutter web app has no deployment path

`.llmwiki/Deployment.md` covers the FastAPI container completely. For the PWA there is
nothing: no vhost, no Web Station config, no deploy script, no documented `--base-href`.
The app is built and served by hand. Whoever deploys it next has to rediscover how.
See `.llmwiki/Web.md`.

### `PUBLISHING.md` predates the backend

It describes a purely local, offline app. Any release shipping group sharing or LLM
commentary needs the Play Data Safety declaration rewritten first, to disclose the network
calls and what game data leaves the device. `PLAY_STORE_DATA_SAFETY.md` and
`privacy_policy.md` need the same pass. **This blocks the next store release**, not the next
commit. See `.llmwiki/Release.md` and `.llmwiki/Security.md`.

### Smaller, self-contained

- **`ThemeProvider` never persists.** `lib/providers/theme_provider.dart` is 19 lines and
  holds `ThemeMode` in memory only, so the app resets to `ThemeMode.system` on every
  restart. `SettingsProvider` already has the SharedPreferences wiring to copy.
- **`test/widget_test.dart` pumps no widgets.** Its 8 tests are model serialisation. The
  name implies widget coverage that does not exist anywhere in the repo — rename it, or
  give it real widget tests.
- **The Drift repositories are raw SQL.** `drift_repositories.dart` uses `customSelect` /
  `customInsert` throughout, a faithful port of the sqflite queries. That was the right
  call for a safe migration, but the type-safe-query argument for adopting Drift is still
  unbanked. Converting the simplest repositories first would prove the pattern.
- **Backend security debt is catalogued but untouched** — `device_token` in the WebSocket
  query string, no rate limit on `POST /groups` or `/groups/join`, `share_token` returned
  by `GET /groups/me`, no bounds validation on scores and rounds, no security headers. Each
  is a considered trade-off at household scale; all of them need revisiting before anything
  public. See `.llmwiki/Security.md`.
