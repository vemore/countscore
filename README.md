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

- **10 pre-configured game types** — ZapZap, Uno, Scrabble, Skyjo, Président, Belote, Tarot,
  Bridge, Rami and a generic "Autre" — plus custom types with a user-picked icon and colour.
- **Flexible scoring**: lowest-wins and highest-wins, per game type.
- **Scoring grid**: rounds, running totals, live ranking and per-player statistics.
- **Global players**: a player exists once and is shared across games, so statistics follow
  them from one game to the next.
- **10 languages**, fully translated: English, French, Spanish, German, Portuguese (BR),
  Russian, Chinese (Simplified), Japanese, Hindi and Arabic — Arabic including RTL layout.
- **Offline-first**: everything works with no network. Data lives on the device.
- **ZapZap analysis** (optional, network, off until you configure a server): a long-form
  LLM commentary on a finished ZapZap game. Always user-initiated, never automatic, and
  cached locally once generated. A **Report this commentary** action opens a prefilled email
  to the developer if the generated text is offensive or wrong.
- **Group sharing** (optional, network, off until you configure a server and join a group):
  create a group or join one with an invite code, then share games with the group's other
  devices — scores entered on one phone appear on the others within seconds, offline edits
  catch up on reconnect, and players with the same name are merged. New games are shared by
  default while you are in a group; games you do not share stay on the device. A lost or sold
  phone can be removed from the group's device list, which also replaces the invite code.
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
- **Material Design 3** throughout.

## Tech stack

### App

| | |
|---|---|
| Framework | Flutter 3.47.2 / Dart 3.13.2 (SDK constraint `^3.13.0`) |
| State management | `provider` ^6.1.2 |
| Database | `drift` ^2.35.0 + `drift_flutter` ^0.3.1 over SQLite |
| — on Android | native SQLite via FFI |
| — on web | `sqlite3.wasm` persisted through OPFS |
| Legacy migrator | `sqflite` ^2.4.3 — bootstraps an existing database to schema v11, then Drift takes over |
| UI | `flex_color_picker` ^4.0.0, `flutter_markdown_plus` |
| Group sync | `web_socket_channel` ^3.0.3 (change signal), `flutter_secure_storage` ^11.1.1 (device token), `crypto` ^3.0.7 (name-based uuids) |
| Utilities | `intl`, `http`, `url_launcher` (report email, Play listing), `in_app_review` ^2.0.12 (Play review sheet), `package_info_plus` (version), `wakelock_plus`, `shared_preferences`, `path_provider`, `file_picker` |

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
flutter build web       --release --no-tree-shake-icons
```

**`--no-tree-shake-icons` is mandatory on every target.** Game-type icons are `IconData`
built from codepoints stored in the database, so Flutter's icon tree-shaker cannot see those
references and the build fails without the flag. It costs roughly 200 KB. See
[CLAUDE.md](CLAUDE.md).

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
│   ├── l10n/            # ARB files (10 languages) + generated localizations
│   └── main.dart
├── backend/             # FastAPI service (groups, sync, LLM commentary)
├── web/                 # PWA shell + sqlite3.wasm and drift_worker.js (tracked on purpose)
├── android/             # Android platform code
├── test/                # Unit, Drift and migration tests
├── integration_test/    # End-to-end suite (web + real device)
├── store_listing/       # Play Store assets and the listing text, in 10 locales
├── docs/                # Published by GitHub Pages — the privacy policy Play links to
├── scripts/             # Keystore, screenshots, privacy page, PWA deploy, web binaries, self-tests
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
| `/comments/*` | LLM game commentary, including the ZapZap analysis |
| `$PWA_BASE_PATH/` | Optional: the web app itself, same origin as the API (off unless `PWA_BASE_PATH` is set) |

**Current state, stated plainly:** the server side of groups and sync is implemented and
tested, but **the Flutter client for it has not been written yet**. The app is therefore
local-only today, and the single live app↔backend call is the ZapZap analysis — which
itself only happens once you have configured a server. See [wip/](wip/README.md) and
`.llmwiki/Architecture.md`.

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
  checks that the container runs as a non-root user, with no compiler and no dev dependencies.
- **App** — checks that the two binaries committed under `web/` match the versions
  `pubspec.lock` resolves ([`scripts/web_binaries.sh`](scripts/web_binaries.sh)), then
  codegen, `flutter analyze`, `flutter test`, release web build.
- **Android** — debug APK from a clean checkout, as a fresh-clone build proof, plus an
  assertion that the release manifest still declares `INTERNET`.
- **Sync** — the backend on a real Postgres, then the two-device group sync test against it.

[`.github/dependabot.yml`](.github/dependabot.yml) opens weekly, grouped update pull requests
for the backend (`uv`), the app (`pub`) and the GitHub Actions. It only proposes the
dependencies *written in* `pubspec.yaml`, so
[`.github/workflows/deps.yml`](.github/workflows/deps.yml) runs `flutter pub upgrade`
monthly for the transitive half, refreshes the committed `web/` binaries to match, runs the
gates and pushes a `chore/deps-<date>` branch when anything moved.

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
and BSD variants). See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for complete
attribution, or the built-in Flutter license viewer in the app.

## Privacy

**No accounts, no analytics, no ads, no tracking.** By default **nothing leaves the device
at all**: there is no server address in the app, so there is nowhere for data to go. Two
features can send data off the device, and only after you have configured a server of your
own — described below.

- ✅ **No analytics, no tracking**: we don't track how you use the app.
- ✅ **No ads**.
- ✅ **No account**: nothing to sign up for, no identity attached to your data.
- ✅ **Open source**: the code is publicly auditable.

**Where your data lives**: game types, player names, scores, game history and app
preferences are stored in a local SQLite database on your device. Delete a game or a player
at any time; uninstalling removes everything permanently.

**When data can leave your device — 1, the ZapZap analysis**: asking for one sends that
game's data — game type, player names, round scores and per-player history — to the
CountScore backend **you configured in Settings → Server**, which forwards it to an LLM
provider to generate the commentary. Two conditions, both yours: no server configured means
the feature is not even offered, and with one configured nothing is sent until you tap the
button. No analysis is ever generated automatically. The result is cached locally so it is
generated once.

Because the server is one you run, the data goes to infrastructure you control — and on to
whichever LLM provider *your* server is configured to use. We operate no service on your
behalf and receive nothing. The one exception is yours to make: **Report this commentary**
opens your own email app with a message to the developer, prefilled with the analysis text —
we receive it only if you press send.

**2, group sharing**: once you have also created or joined a group (Settings → Group), the
games you share — their name, type, player names and colours, round comments, scores and
analysis — are uploaded to **your** server, which **stores** them with a log of every change,
and downloaded by the group's other devices. Each device of the group also sees the others'
names and when they were last seen, so a lost phone can be recognised and removed. Anyone with
the group's invite code can join, so share it only with the people you mean to. Games you do not share never leave the device.
Leaving the group keeps your copies as local games; it does not remove them from the server,
whose operator — you — deletes them there.

The release build declares one Android permission, `INTERNET`, for these two features and
nothing else. It is unused until you configure a server.

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
- State management by [Provider](https://pub.dev/packages/provider)
- All dependency authors and contributors listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)

---

**CountScore** — Track scores, enjoy games!
