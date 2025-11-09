# CountScore

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-^3.9.2-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS-green.svg)](https://flutter.dev/)

A Flutter application for score tracking and management. CountScore makes it easy to track scores for various games and activities with customizable game types, player management, and persistent storage.

## Features

- **Multiple Game Types**: Pre-configured game types (ZapZap, Uno, Scrabble) with custom game support
- **Flexible Scoring**: Support for both lowest-wins and highest-wins scoring systems
- **Player Management**: Add, edit, and manage players across games
- **Persistent Storage**: SQLite database for reliable data persistence
- **Customization**: Custom icons and colors for game types using flex_color_picker
- **Material Design 3**: Modern, clean UI following Material Design guidelines
- **State Management**: Efficient state management using Provider pattern
- **Screen Awake**: Keep screen on during active games with wakelock_plus

## Tech Stack

- **Framework**: Flutter SDK ^3.9.2
- **Language**: Dart with null safety
- **State Management**: Provider ^6.1.2
- **Database**: SQLite (sqflite ^2.4.1)
- **Storage**: path_provider, shared_preferences
- **UI Components**: Material Design, flex_color_picker ^3.5.1
- **Utilities**: wakelock_plus, intl, file_picker, path

## Getting Started

### Prerequisites

- Flutter SDK ^3.9.2 or higher
- Android Studio / VS Code with Flutter extensions
- An Android or iOS device/emulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/countscore.git
cd countscore
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release --no-tree-shake-icons
```

**iOS:**
```bash
flutter build ios --no-tree-shake-icons
```

**Note**: The `--no-tree-shake-icons` flag is required because CountScore uses dynamic IconData created from database values. See [CLAUDE.md](CLAUDE.md) for details.

## Project Structure

```
countscore/
├── lib/
│   ├── models/          # Data models (GameType, Player, etc.)
│   ├── screens/         # Full-screen widgets
│   ├── widgets/         # Reusable UI components
│   ├── providers/       # Provider state management
│   ├── services/        # Database and external services
│   └── utils/           # Helper functions and constants
├── android/             # Android platform code
├── ios/                 # iOS platform code
├── test/                # Unit and widget tests
└── pubspec.yaml         # Dependencies and configuration
```

## Development

### Code Quality

Run static analysis:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and analysis (`flutter analyze && flutter test`)
4. Commit your changes (`git commit -m 'feat: add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

CountScore uses several open-source packages. All dependencies use permissive licenses (MIT and BSD variants). See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for complete attribution and license information.

You can also view dependency licenses in the app through the built-in Flutter license viewer.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite Guide](https://pub.dev/packages/sqflite)

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Icons from [Material Icons](https://fonts.google.com/icons)
- State management by [Provider](https://pub.dev/packages/provider)
- All dependency authors and contributors listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)

---

**CountScore** - Track scores, enjoy games!
