# CountScore

[![CI](https://github.com/vemore/countscore/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vemore/countscore/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20Web-green.svg)](https://flutter.dev/)

An offline-first score tracker for card and board games. CountScore is a Flutter client —
Android and a web PWA — that keeps every game in a local SQLite database and works with no
network at all. Alongside it lives an optional FastAPI backend providing group sharing,
delta-log sync and LLM-generated game commentary.

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
- **ZapZap analysis** (optional, network): a long-form LLM commentary on a finished ZapZap
  game. Always user-initiated, never automatic, and cached locally once generated.
- **Comfort**: light/dark/system theme, screen kept awake during a game, database
  export/import (Android only).
- **Material Design 3** throughout.

## Tech stack

### App

| | |
|---|---|
| Framework | Flutter 3.47.2 / Dart 3.13.2 (SDK constraint `^3.13.0`) |
| State management | `provider` ^6.1.2 |
| Database | `drift` ^2.34.4 + `drift_flutter` ^0.3.1 over SQLite |
| — on Android | native SQLite via FFI |
| — on web | `sqlite3.wasm` persisted through OPFS |
| Legacy migrator | `sqflite` ^2.4.3 — bootstraps an existing database to schema v9, then Drift takes over |
| UI | `flex_color_picker` ^4.0.0, `flutter_markdown_plus` |
| Utilities | `intl`, `http`, `wakelock_plus`, `shared_preferences`, `path_provider`, `file_picker` |

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
flutter run -d chrome --dart-define=BACKEND_URL=<url>    # web
```

Localizations are generated automatically by `flutter pub get` and every build
(`flutter: generate: true` in `pubspec.yaml`). Run `flutter gen-l10n` by hand only after
editing an `.arb` file.

## Building for production

```bash
flutter build apk       --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons   # Play Store
flutter build web       --release --no-tree-shake-icons \
  --dart-define=BACKEND_URL=<url>
```

**`--no-tree-shake-icons` is mandatory on every target.** Game-type icons are `IconData`
built from codepoints stored in the database, so Flutter's icon tree-shaker cannot see those
references and the build fails without the flag. It costs roughly 200 KB. See
[CLAUDE.md](CLAUDE.md).

## Project structure

```
countscore/
├── lib/
│   ├── models/          # Plain data models (game, game_type, player, round, score, …)
│   ├── screens/         # Full-screen widgets
│   ├── widgets/         # Reusable UI components
│   ├── providers/       # Provider state management
│   ├── repositories/    # Data-access interfaces + their Drift implementations
│   ├── services/        # Drift database, sqflite bootstrap migrator, helpers
│   ├── l10n/            # ARB files (10 languages) + generated localizations
│   └── main.dart
├── backend/             # FastAPI service (groups, sync, LLM commentary)
├── web/                 # PWA shell + sqlite3.wasm and drift_worker.js (tracked on purpose)
├── android/             # Android platform code
├── test/                # Unit, Drift and migration tests
├── integration_test/    # End-to-end suite (web + real device)
├── store_listing/       # Play Store assets and the per-locale listing text
├── docs/                # Published by GitHub Pages — the privacy policy Play links to
├── scripts/             # Keystore, screenshots, privacy page, hook self-test
├── .llmwiki/            # Durable project knowledge — start at INDEX.md
└── pubspec.yaml
```

## Backend

The backend is **optional** — the app is fully usable without it. It exposes:

| Surface | Purpose |
|---|---|
| `/groups/*` | Create/join a group, device tokens, share-link rotation |
| `/sync/push`, `/sync/pull` | Delta-log sync with row-level last-write-wins |
| `/sync/stream` | WebSocket change signalling (Postgres `LISTEN/NOTIFY`) |
| `/comments/*` | LLM game commentary, including the ZapZap analysis |

**Current state, stated plainly:** the server side of groups and sync is implemented and
tested, but **the Flutter client for it has not been written yet**. The app is therefore
local-only today, and the single live app↔backend call is the ZapZap analysis. See
[TODO.md](TODO.md) and `.llmwiki/Architecture.md`.

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
ruff check .
mypy
pytest -m 'not integration' -q   # fast, no Docker; drop the marker to run everything
```

The end-to-end suite lives in `integration_test/app_test.dart` and drives one golden path
across the whole stack. It runs on web via `chromedriver` and on a real device, but not in
CI — it calls the production endpoint. See `.llmwiki/Testing.md`.

### Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs three jobs on every push to
`main` and every pull request:

- **Backend** — `ruff check`, `mypy`, `pytest` (integration tests included).
- **App** — codegen, `flutter analyze`, `flutter test`, release web build.
- **Android** — debug APK from a clean checkout, as a fresh-clone build proof, plus an
  assertion that the release manifest still declares `INTERNET`.

### Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Generate code (`dart run build_runner build`) — required before anything compiles.
4. Run the gates: `flutter analyze && flutter test` must be green before you commit.
5. Commit your changes (`git commit -m 'feat: add amazing feature'`).
6. Push the branch and open a Pull Request.

Working conventions live in [CLAUDE.md](CLAUDE.md): never hardcode a user-facing string
(everything goes through `AppLocalizations`), and record open work in `TODO.md` / closed work
in `DONE.md`. The rules a Claude Code hook enforces on its own — the build flag above, the
gates, secrets, the branch — are in `.llmwiki/Hooks.md`. Architecture, schema and deployment
knowledge is in `.llmwiki/` — start at `.llmwiki/INDEX.md`.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

### Third-party licenses

CountScore uses several open-source packages. All dependencies use permissive licenses (MIT
and BSD variants). See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for complete
attribution, or the built-in Flutter license viewer in the app.

## Privacy

**No accounts, no analytics, no ads, no tracking.** One feature sends data off the device,
and only when you ask it to — described below.

- ✅ **No analytics, no tracking**: we don't track how you use the app.
- ✅ **No ads**.
- ✅ **No account**: nothing to sign up for, no identity attached to your data.
- ✅ **Open source**: the code is publicly auditable.

**Where your data lives**: game types, player names, scores, game history and app
preferences are stored in a local SQLite database on your device. Delete a game or a player
at any time; uninstalling removes everything permanently.

**The one time data leaves your device**: asking for a **ZapZap analysis** sends that game's
data — game type, player names, round scores and per-player history — to the CountScore
backend, which forwards it to an LLM provider to generate the commentary. This is always
user-initiated: no analysis is ever generated automatically, and no data is sent unless you
tap the button. The result is cached locally so it is generated once.

Group sharing and sync exist on the server but are not reachable from the app yet, so no
data leaves your device through them today.

The release build declares one Android permission, `INTERNET`, for that request and nothing
else.

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
