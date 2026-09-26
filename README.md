# CountScore

[![CI](https://github.com/vemore/countscore/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vemore/countscore/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20Web-green.svg)](https://flutter.dev/)

An offline-first score tracker for card and board games. CountScore is a Flutter client —
Android and a web PWA — that keeps every game in a local SQLite database and works with no
network at all. Alongside it lives an optional FastAPI backend providing group sharing,
delta-log sync and LLM-generated game commentary — **which you host yourself**. The app
ships with no server address, so out of the box it never makes a network request; point it
at your own server in Settings → Server if you want the connected features.

## Features

- **22 pre-configured game types** — ZapZap, Uno, Scrabble, Skyjo, President, Belote, Tarot,
  Bridge, Rummy, Coinche, Yahtzee, Phase 10, Flip 7, Mille Bornes, Rummikub, Take 6, Qwirkle,
  Farkle, Canasta, Wizard, Triomino and a generic "Other" — each named in your own language —
  plus custom types with a user-picked icon and colour.
- **Flexible scoring**: lowest-wins and highest-wins, per game type.
- **Rules for the game you are playing** — reachable from the score table and from the
  game-type list. Every pre-configured type but *Other* ships a ruleset — 21 of them,
  translated into all ten languages — next to a summary of how CountScore scores that type — and every type, shipped
  or your own, gets that summary. Any of it can be
  rewritten: your table's own rules replace the shipped text and travel with your group.
- **Scoring grid**: one coloured lane per player — avatar, big total, place, a crown on the
  leader, a skull on a player a game type with elimination has put out — or one row per player at the tap of a button (remembered for every game); rounds,
  live ranking and per-player statistics.
- **A keypad for scores**, with a shortcut key per game type: "0 ZapZap", Skyjo's "×2" on the
  score typed, Belote's "162", Scrabble's "+50", Rami's "100" — and one of your choosing (a
  value, a multiplication or an addition, with its own label) on any type in the game-type
  editor.
- **An explicit end**: any game that has been played can be declared over from the board or
  the game list, which marks it in the history and opens the standings on their result: the
  winner, a podium of the top three with their totals, every player in the list under it in
  rank order, then *Play again* and — with a server configured — *Analysis*. The same screen
  shows where an open game stands, from the score table's leaderboard button; a finished
  game's board brings the result back from that same button, and
  reopening a game lets you play on. Game types that define a threshold (Skyjo, Président,
  Belote, Uno …) end the game by themselves as soon as a score or a round brings a total to
  that threshold, or when you open a game already at or past it — once: the standings then offer
  "Continue playing", remembered on the device until the game drops back under its threshold.
  The games played to a last survivor (ZapZap, Rami, 6 qui prend) end instead once every
  player but one is past the elimination threshold — last player standing, and their final
  standings follow the order the players went out in: the survivor first, then whoever lasted
  longest, so a player out after one hand is last however low their total — on the standings
  and in the statistics alike. A game type you build yourself follows the same rule as soon
  as it both puts a player out on a threshold and ends on the last player standing, whether
  the threshold is a ceiling or a floor. Every other game, and every game still in play,
  ranks by the total.
- **Who starts?**: the score table's menu draws one of the game's players at random.
- **Roll dice**: the score table's menu rolls 1 to 6 six-sided dice and shows each die and the total.
- **Turn timer**: the score table's menu counts down from 15 seconds to 10 minutes, with
  pause and reset, and says so at zero; each game type reopens it on its own last duration.
- **Game sounds** (Settings → Sounds, off by default): a sound when a player is eliminated,
  when a game type's rule ends the game, and when the turn timer reaches zero. The three
  sounds are bundled in the app (CC0, made by `scripts/generate_sounds.py`); nothing is
  fetched, and no permission is needed.
- **Play again**: from the standings or a finished game in the history, one tap starts
  the next game with the same type and the same players in the same order.
- **Share a result**: the standings and the analysis share them as a
  short text — game type, date, places and totals, the commentary on the analysis — and as a
  picture of the podium in the players' colours, through the system share sheet, with a link
  to the app's Play listing.
- **Global players**: a player exists once and is shared across games, so statistics follow
  them from one game to the next.
- **Player statistics**: a leaderboard of the finished games, all of them or one game type
  at a time — win rate, wins and games, the best win rate up top — and, a tap on a player
  away, their card on that game: average place, the place over the last 12 games, the
  current win streak, the best and average final totals, the opponent most often beaten.
  Every place counted here is the place the game's own standings show, elimination order
  included.
- **10 languages**, fully translated: English, French, Spanish, German, Portuguese (BR),
  Russian, Chinese (Simplified), Japanese, Hindi and Arabic — Arabic including RTL layout.
- **Offline-first**: everything works with no network. Data lives on the device.
- **AI game analysis** (optional, network, off until you configure a server): a one-page
  LLM commentary on any finished game, whatever its type, in **one of nine voices** — the
  caustic professor, a sports commentator, a wildlife documentary, a noir detective, a bard,
  a kind coach, a corporate consultant, an astrologer or a reality-TV voice-over — and in
  the language the app is displayed in. It tells you how each player played and what it says
  about their habits; the numbers stay on the Ranking and Player-statistics screens. Always
  user-initiated, never automatic, and cached locally once generated. A **Report this
  commentary** action opens a prefilled email to the developer if the generated text is
  offensive or wrong.
- **Group sharing** (optional, network, off until you configure a server and join a group):
  create a group or join one with an invite code, then share games with the group's other
  devices — scores entered on one phone appear on the others within seconds, offline edits
  catch up on reconnect, and players with the same name are merged. New games are shared by
  default while you are in a group; games you do not share stay on the device. A lost or sold
  phone can be removed from the group's device list, which also replaces the invite code.
  Any member can set the style and language of the group's comments and see how much of its
  monthly AI budget has been spent: a shared game's analysis is written in the group's
  language — and its style, unless you picked a voice — and counts against that budget.
- **Bring your own backend**: the server address is a setting, empty by default. Run the
  FastAPI service in `backend/` on hardware you control and your data never touches anyone
  else's infrastructure.
- **Rate the app** (Android): once you have finished a few games and had the app for a week,
  Google Play's own review sheet may appear when you end a game — at most once per app
  version, never twice in a session, and nothing in the app is gated on whether or how you
  rate. The About screen also links to the Play listing. No data is sent by the app either
  way: the sheet belongs to the Play Store.
- **Comfort**: light/dark/system theme, screen kept awake during a game, database
  export/import (Android only).
- **Material Design 3** throughout, in a teal theme with the Nunito typeface bundled in the
  app (no font is fetched at runtime; the PWA serves its fallback fonts itself). The game list opens on a **Resume** card for the game
  last played, and every game shows its players and whether it is in progress or who won.

## Tech stack

### App

| | |
|---|---|
| Framework | Flutter 3.47.2 / Dart 3.13.2 (SDK constraint `^3.13.0`) |
| State management | `provider` ^6.1.2 |
| Database | `drift` ^2.35.0 + `drift_flutter` ^0.3.1 over SQLite |
| — on Android | native SQLite via FFI |
| — on web | `sqlite3.wasm` persisted in IndexedDB |
| Legacy migrator | `sqflite` ^2.4.3 — runs the migration chain on an existing database up to the current schema version, then Drift takes over |
| UI | `flex_color_picker` ^4.0.0, `flutter_markdown_plus` |
| Group sync | `web_socket_channel` ^3.0.3 (change signal), `flutter_secure_storage` ^11.1.1 (device token), `crypto` ^3.0.7 (name-based uuids) |
| Utilities | `intl`, `http`, `url_launcher` (report email, Play listing), `share_plus` (share a result), `in_app_review` ^2.0.12 (Play review sheet), `package_info_plus` (version), `audioplayers` ^6.8.1 (game sounds), `wakelock_plus`, `shared_preferences`, `path_provider`, `file_picker` |

Data access goes through the repository interfaces in `lib/repositories/`; screens never
touch the database directly.

### Backend (`backend/`)

FastAPI + uvicorn, SQLModel over PostgreSQL 17, Alembic migrations, argon2-hashed device
tokens, and pluggable LLM providers (Anthropic, AWS Bedrock, Gemini, Mistral). See
[backend/README.md](backend/README.md).

## Getting started

### Prerequisites

- Flutter 3.47.2 (stable)
- Android Studio or VS Code with the Flutter extensions
- An Android device/emulator, or Chrome for the web build

### Installation

1. Clone the repository:
```bash
git clone https://github.com/vemore/countscore.git
cd countscore
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Generate code — this step is mandatory:**
```bash
dart run build_runner build
```
`*.g.dart` files are gitignored, so `lib/services/drift/database.g.dart` does not exist in a
fresh clone. Skipping this step fails with `Target of URI hasn't been generated` and a
cascade of undefined `_$AppDatabase` errors.

4. Run the app:
```bash
flutter run                                              # connected device
flutter run -d chrome                                    # web
```

The connected features need a backend, which you host: see
[backend/README.md](backend/README.md), then enter its URL in Settings → Server. There is no
default and none is compiled in. `--dart-define=BACKEND_URL=<url>` exists for development
only — it pre-fills that setting on a profile that has never configured a server, and no
release build passes it.

Localizations are generated automatically by `flutter pub get` and every build
(`flutter: generate: true` in `pubspec.yaml`). Run `flutter gen-l10n` by hand only after
editing an `.arb` file.

## Building for production

```bash
flutter build apk       --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons   # Play Store
scripts/build_web.sh                                       # the PWA, see below
```

**`--no-tree-shake-icons` is mandatory on every target.** Game-type icons are `IconData`
built from codepoints stored in the database, so Flutter's icon tree-shaker cannot see those
references and the build fails without the flag. It costs roughly 200 KB. See
[CLAUDE.md](CLAUDE.md).

**The PWA is built by `scripts/build_web.sh`**, which adds `--no-web-resources-cdn` and copies
the engine's fallback fonts (Noto, Roboto) into the build, so a browser loading the PWA asks
nothing of Google: CanvasKit and every font come from whoever serves the app. It also arms the
PWA's service worker (`web/service_worker.js`): after one online visit the app opens and works
with no network, and after a deploy an open app offers a reload onto the new version. Extra
arguments (`--base-href=/subpath/`) are passed to `flutter build web`.

### Publishing the PWA

The backend can serve the web app itself, under a sub-path of its own host (set
`PWA_BASE_PATH`, e.g. `/countscore`, in the backend's `.env`) — same origin as the API, so no
CORS setup. `scripts/deploy_web.sh` builds for that sub-path and publishes the build to the
server over SSH; it reuses the backend's untracked `backend/scripts/deploy.env` and reads
`PWA_BASE_PATH` from the server, so the deployment target never enters the repository.

```bash
scripts/deploy_web.sh --dry-run   # build + checks, prints what it would run
scripts/deploy_web.sh             # publish, keeping the previous release
scripts/deploy_web.sh --rollback  # swap the previous release back
```

The PWA is also published on **GitHub Pages**, at `https://<owner>.github.io/<repo>/`, by
[`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml): on every push to
`main` that touches the app, and on demand from the Actions tab. That build carries no server
address, so it runs local-only — scores and statistics in the browser — until the visitor
enters a server of their own in Settings → Server. It runs the same checks as
`deploy_web.sh` (`scripts/check_web_build.sh`, `scripts/web_binaries.sh --check`) and
publishes the privacy policy page next to it. A fork publishes at its own path: the base href
comes from the repository name.

**If you operate a backend** that users of a Pages build will connect to, that build is
**cross-origin** to your server, unlike the one it serves itself:

- add the Pages origin to `CORS_ORIGINS` in the backend's `.env` — scheme and host only, no
  path: `CORS_ORIGINS=https://<owner>.github.io` (comma-separated with any others). Without
  it the game analysis and group sync fail in the browser, and only there;
- serve the backend over `https://`: a Pages page cannot call an `http://` server, not even
  one on your LAN;
- games stored by the PWA on one origin do not appear in the PWA on another (browser storage
  is per origin), except through group sync.

## Project structure

```
countscore/
├── lib/
│   ├── models/          # Plain data models (game, game_type, player, round, score, …)
│   ├── screens/         # Full-screen widgets
│   ├── widgets/         # Reusable UI components
│   ├── providers/       # Provider state management
│   ├── repositories/    # Data-access interfaces + their Drift implementations
│   ├── services/        # Drift database, sqflite bootstrap migrator, backend client, sync/
│   ├── utils/           # Cross-cutting helpers (system inset compensation)
│   ├── l10n/            # ARB files (10 languages) + generated localizations
│   └── main.dart
├── backend/             # FastAPI service (groups, sync, LLM commentary)
├── web/                 # PWA shell + sqlite3.wasm and drift_worker.js (tracked on purpose)
├── android/             # Android platform code
├── test/                # Unit, Drift and migration tests
├── integration_test/    # End-to-end suite (web + real device)
├── store_listing/       # Play Store assets and the listing text, in 10 locales
├── docs/                # Published by GitHub Pages — the privacy policy Play links to
├── scripts/             # Keystore, screenshots, privacy page, PWA deploy, web binaries, CI freshness, delivery and agent metrics, self-tests
├── .llmwiki/            # Durable project knowledge — start at INDEX.md
└── pubspec.yaml
```

## Backend

The backend is **optional and self-hosted** — the app is fully usable without it, and no
server is configured by default. There is no public CountScore instance to point at: run
your own, and your data stays on it. It exposes:

| Surface | Purpose |
|---|---|
| `/groups/*` | Create/join a group, device tokens, share-link rotation |
| `/sync/push`, `/sync/pull` | Delta-log sync with row-level last-write-wins |
| `/sync/stream` | WebSocket change signalling (Postgres `LISTEN/NOTIFY`) |
| `/comments/*` | LLM game commentary, including the game analysis |
| `$PWA_BASE_PATH/` | Optional: the web app itself, same origin as the API (off unless `PWA_BASE_PATH` is set) |

Once a server is configured in Settings → Server, the app is a client of every surface
above except the web app itself: the game analysis goes to `/comments/*` for a game played
alone, and to the group's comment endpoint for a game shared with a group; creating or
joining a group (Settings → Group) turns on `/groups/*`, and a group's games then sync
through `/sync/push`, `/sync/pull` and the change stream (`lib/services/sync/`). With no
server configured, none of these calls is made. See `.llmwiki/Architecture.md`.

The app accepts an `https://` URL for any host, and an `http://` URL only for a private or
loopback address (`192.168.x.x`, `10.x.x.x`, `172.16–31.x.x`, `localhost`, `*.local`), so a
backend on your LAN works without a certificate while a public one must use TLS. On the web
build, a browser additionally refuses to call an `http://` backend from an `https://` page.

Running the backend locally, and deploying it, are covered in
[backend/README.md](backend/README.md).

## Development

### Quality gates

```bash
# App
flutter analyze
flutter test
flutter test --coverage

# Backend (from backend/)
ruff check . && ruff format --check .
mypy
pytest -m 'not integration' -q   # fast, no Docker; drop the marker to run everything
```

The end-to-end suite lives in `integration_test/app_test.dart` and drives one golden path
across the whole stack. It runs on web via `chromedriver` and on a real device, but not in
CI — it calls the production endpoint. See `.llmwiki/Testing.md`.

### Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs six jobs on every push to
`main`, every pull request, and once a week:

- **Scope** — reads the files the pull request changes and decides which of the five below it
  needs: a documentation-only pull request runs none of them. On `main`, on the weekly run and
  on demand, all five run. The rules are in [`scripts/ci_scope.sh`](scripts/ci_scope.sh), and
  [`scripts/ci_scope_selftest.sh`](scripts/ci_scope_selftest.sh) pins them on every run.
- **Backend** — `ruff check`, `ruff format --check`, `mypy`, `pytest` (integration tests included),
  an Alembic round trip on a real Postgres — upgrade, `downgrade base`, upgrade, then
  `alembic check` (every downgrade runs, and the models and the migrations describe the same
  schema) — and a `pip-audit` of every package locked in `backend/uv.lock`. The weekly run
  exists for that audit: it is the only thing that runs it on a week where nothing touched
  `backend/`.
- **Backend image** — builds `backend/Dockerfile` (dependencies locked to `uv.lock`) and
  checks that the container runs as a non-root user, with no compiler and no dev dependencies;
  builds the backup sidecar (`backend/Dockerfile.backup`), checks its `age` and `pg_dump` and
  that it refuses to back up without an encryption key; resolves both compose files.
- **App** — an [`osv-scanner`](https://github.com/google/osv-scanner) audit of every package
  in `pubspec.lock` that fails on any advisory (ignores, each with a `wip/` entry, go in
  [`.github/osv-scanner.toml`](.github/osv-scanner.toml)), then checks that the two binaries committed under `web/` match the versions
  `pubspec.lock` resolves ([`scripts/web_binaries.sh`](scripts/web_binaries.sh)) and that
  `THIRD_PARTY_LICENSES.md` matches `pubspec.yaml`
  ([`scripts/third_party_licenses.py`](scripts/third_party_licenses.py)), then codegen, `flutter analyze`, `flutter test`, release web build,
  checked by [`scripts/check_web_build.sh`](scripts/check_web_build.sh) — the check both
  publishing paths run.
- **Android** — debug APK from a clean checkout, as a fresh-clone build proof, plus an
  assertion that the release manifest still declares `INTERNET`. On a pull request it runs
  when `android/`, `pubspec.*` or the CI tooling changes, not for Dart alone; on `main` and
  the weekly run it always runs.
- **Sync** — the backend on a real Postgres, then the two-device group sync test against it.

[`.github/dependabot.yml`](.github/dependabot.yml) opens weekly, grouped update pull requests
for the backend (`uv`), the app (`pub`) and the GitHub Actions. It only proposes the
dependencies *written in* `pubspec.yaml`, so
[`.github/workflows/deps.yml`](.github/workflows/deps.yml) runs `flutter pub upgrade`
monthly for the transitive half, refreshes the committed `web/` binaries and
`THIRD_PARTY_LICENSES.md` to match, runs the
gates and pushes a `chore/deps-<date>` branch when anything moved.
[`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml) is not a check: it
publishes the PWA and the privacy page on GitHub Pages after a merge
([Publishing the PWA](#publishing-the-pwa)).

Both of those cadences are load-bearing and both are triggered by a `schedule:` alone, which
GitHub disables after 60 days without repository activity — silently, since a scheduled run
has no pull request in front of it.
[`scripts/check_scheduled_runs.sh`](scripts/check_scheduled_runs.sh) asks GitHub whether each
one is still enabled and still firing within its own period, and the Claude Code session-start
hook runs it once a day.

### Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Generate code (`dart run build_runner build`) — required before anything compiles.
4. Run the gates: `flutter analyze && flutter test` must be green before you commit.
5. Commit your changes (`git commit -m 'feat: add amazing feature'`).
6. Push the branch and open a Pull Request.

Working conventions live in [CLAUDE.md](CLAUDE.md): never hardcode a user-facing string
(everything goes through `AppLocalizations`), and record work one file per entry under
[`wip/`](wip/README.md) (`todo/`, `todo_nr/`, `done/`). The rules a Claude Code hook enforces on its own — the build flag above, the
gates, secrets, the branch — are in `.llmwiki/Hooks.md`. Architecture, schema and deployment
knowledge is in `.llmwiki/` — start at `.llmwiki/INDEX.md`.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

### Third-party licenses

CountScore uses several open-source packages. All dependencies use permissive licenses (MIT
and BSD variants); the bundled Nunito font is under the SIL Open Font License 1.1. See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for complete
attribution, or the built-in Flutter license viewer in the app. That file is generated from
`pubspec.yaml` by `scripts/third_party_licenses.py` (after `flutter pub get`), and CI fails
when the committed copy differs.

## Privacy

**No accounts, no analytics, no ads, no tracking.** By default **nothing leaves the device
at all**: there is no server address in the app, so there is nowhere for data to go. Two
features can send data off the device, and only after you have configured a server of your
own — described below.

- ✅ **No analytics, no tracking**: we don't track how you use the app.
- ✅ **No ads**.
- ✅ **No account**: nothing to sign up for, no identity attached to your data.
- ✅ **Open source**: the code is publicly auditable.

**Where your data lives**: game types and their rules text, player names, scores, game
history and app
preferences are stored in a local SQLite database on your device. Delete a game or a player
at any time; uninstalling removes everything permanently.

**When data can leave your device — 1, the AI game analysis**: asking for one sends that
game's data — game type and its scoring rules, player names, round scores and per-player
history — plus the voice you picked and the language the app is displayed in, to the
CountScore backend **you configured in Settings → Server**, which forwards it to an LLM
provider to generate the commentary. Two conditions, both yours: no server configured means
the feature is not even offered, and with one configured nothing is sent until you tap the
button. No analysis is ever generated automatically. The result is cached locally so it is
generated once. For a game shared with your group, the request also carries the device's
group token: the analysis is billed to the group's monthly AI budget, written in the group's
language, and kept with the group on your server.

Because the server is one you run, the data goes to infrastructure you control — and on to
whichever LLM provider *your* server is configured to use. We operate no service on your
behalf and receive nothing. The one exception is yours to make: **Report this commentary**
opens your own email app with a message to the developer, prefilled with the analysis text —
we receive it only if you press send.

**2, group sharing**: once you have also created or joined a group (Settings → Group), the
games you share — their name, type, player names and colours, round comments, scores,
whether and when you ended them, and analysis — are uploaded to **your** server, which **stores** them with a log of every change,
and downloaded by the group's other devices. Each device of the group also sees the others'
names (the nickname each one chose, which it can change in Settings → Group) and when they were last seen, so a lost phone can be recognised and removed. The
group's comment style and language, if a member changes them (Settings → Group → Comments and
usage), are stored there too, with the analyses generated for shared games. Anyone with
the group's invite code can join, so share it only with the people you mean to. Games you do not share never leave the device.
Leaving the group keeps your copies as local games; it does not remove them from the server,
whose operator — you — deletes them there.

**Sharing a result** is not a third way out: the app builds the text and the picture of the
standings on the device and hands them to your phone's share sheet (the browser's, in the
PWA); it sends nothing itself, and they go only where you choose to send them.

The one Android permission the app declares is `INTERNET`, for these two features and
nothing else. It is unused until you configure a server. The merged release manifest also
carries `com.vemore.countscore.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, which
`androidx.core` injects: a signature-level permission private to the app, which lets it
register its own broadcast receivers without exposing them to other apps. It grants access to
nothing and sends nothing.

**Privacy Policy**: [privacy_policy.md](privacy_policy.md) for complete details — published
at https://vemore.github.io/countscore/privacy-policy.html — and
[PLAY_STORE_DATA_SAFETY.md](PLAY_STORE_DATA_SAFETY.md) for the store declarations.

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Dart language tour](https://dart.dev/guides/language/language-tour)
- [Provider](https://pub.dev/packages/provider)
- [Drift](https://drift.simonbinder.eu/)
- [FastAPI](https://fastapi.tiangolo.com/)

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Icons from [Material Icons](https://fonts.google.com/icons)
- Typeface [Nunito](https://github.com/googlefonts/nunito), bundled with the app
- State management by [Provider](https://pub.dev/packages/provider)
- All dependency authors and contributors listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)

---

**CountScore** — Track scores, enjoy games!
