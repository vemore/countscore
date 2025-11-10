# CountScore - Project Instructions for Claude Code

## Project Overview
**CountScore** is a Flutter application for score tracking and management.

**Tech Stack:**
- Flutter SDK: ^3.9.2
- State Management: Provider (^6.1.2)
- Database: SQLite (sqflite ^2.4.1)
- Storage: path_provider, shared_preferences
- UI: Material Design, flex_color_picker
- Features: Wakelock support, internationalization (intl)

## Project Structure
```
countscore/
├── lib/                    # Application source code
├── android/                # Android platform code
├── ios/                    # iOS platform code
├── test/                   # Unit and widget tests
├── build/                  # Build artifacts (generated)
└── pubspec.yaml           # Dependencies and configuration
```

## Development Guidelines

### Flutter-Specific Rules
1. **State Management**: Use Provider pattern for state management
2. **Database Operations**: All SQLite operations should be async and handle errors
3. **Material Design**: Follow Material Design 3 guidelines for UI consistency
4. **Null Safety**: Project uses Dart null safety - handle nulls appropriately
5. **Internationalization**: ALWAYS use AppLocalizations for user-facing text - NEVER hardcode strings

### Internationalization (i18n)

**Current Setup:**
- **Languages Supported**: 10 languages
  - English (en) - Default fallback
  - French (fr) - Template language
  - Spanish (es)
  - Chinese Simplified (zh)
  - Hindi (hi)
  - Arabic (ar) - RTL support
  - Portuguese (pt) - Brazilian Portuguese
  - Russian (ru)
  - Japanese (ja)
  - German (de)
- **Default Behavior**: Automatically follows device system language
- **Fallback**: English for unsupported languages
- **Translation Files**: `lib/l10n/app_*.arb` (one file per language)
- **Generated Code**: `lib/l10n/app_localizations*.dart` (auto-generated, don't edit)

**Adding User-Facing Text:**
1. **Add to ARB files** (both app_fr.arb and app_en.arb):
   ```json
   "myNewString": "Mon texte",
   "@myNewString": {
     "description": "Description for translators"
   }
   ```

2. **For strings with parameters:**
   ```json
   "welcomeUser": "Bienvenue {userName}",
   "@welcomeUser": {
     "description": "Welcome message with user name",
     "placeholders": {
       "userName": {
         "type": "String",
         "example": "Alice"
       }
     }
   }
   ```

3. **For plurals:**
   ```json
   "itemCount": "{count, plural, =0{0 items} =1{1 item} other{{count} items}}",
   "@itemCount": {
     "description": "Item count with plural forms",
     "placeholders": {
       "count": {
         "type": "int",
         "example": "5"
       }
     }
   }
   ```

4. **Regenerate localization code:**
   ```bash
   flutter gen-l10n
   ```

5. **Use in code:**
   ```dart
   import '../l10n/app_localizations.dart';

   // In build method:
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.myNewString)
   Text(l10n.welcomeUser('Alice'))
   Text(l10n.itemCount(5))
   ```

**Important Rules:**
- ❌ NEVER hardcode user-facing strings (e.g., `Text('Bonjour')`)
- ✅ ALWAYS use AppLocalizations (e.g., `Text(l10n.hello)`)
- ❌ NEVER hardcode plurals (e.g., `'${n} item${n > 1 ? 's' : ''}'`)
- ✅ ALWAYS use ICU plural forms in ARB files
- ✅ Keep date/time formatting with intl's DateFormat (already locale-aware)
- ✅ User-generated content (names, scores) stays as-is, don't translate

**Adding a New Language:**
1. Create `lib/l10n/app_XX.arb` (where XX is the language code)
2. Copy content from app_en.arb and translate all 103 strings
3. Handle plural forms according to the language's grammar rules
4. Add locale to `main.dart` supportedLocales list
5. Run `flutter gen-l10n` to generate the code

**Current Language Coverage:**
The app currently supports the 10 most widely used languages globally, covering approximately 5 billion native and secondary speakers worldwide. This includes:
- **Western languages**: English, Spanish, Portuguese, French, German
- **Asian languages**: Chinese (Simplified), Hindi, Japanese
- **Middle Eastern**: Arabic (with RTL support)
- **Cyrillic**: Russian

**File Structure:**
```
lib/
├── l10n/
│   ├── app_fr.arb                # French (template) - source
│   ├── app_en.arb                # English
│   ├── app_es.arb                # Spanish
│   ├── app_zh.arb                # Chinese (Simplified)
│   ├── app_hi.arb                # Hindi
│   ├── app_ar.arb                # Arabic
│   ├── app_pt.arb                # Portuguese
│   ├── app_ru.arb                # Russian
│   ├── app_ja.arb                # Japanese
│   ├── app_de.arb                # German
│   ├── app_localizations.dart    # Generated - DO NOT EDIT
│   └── app_localizations_*.dart  # Generated for each language - DO NOT EDIT
└── [screens/widgets using AppLocalizations]
```

**Configuration Files:**
- `l10n.yaml` - Localization generation config
- `pubspec.yaml` - Contains `generate: true` and `flutter_localizations` dependency

### Code Style
- Follow Dart style guide and analysis_options.yaml rules
- Use meaningful widget names (e.g., `ScoreListWidget`, `GameSettingsScreen`)
- Prefer const constructors for immutable widgets
- Extract complex widgets into separate files
- Keep build methods clean and readable

### File Organization
- **Screens**: `lib/screens/` - Full screen widgets
- **Widgets**: `lib/widgets/` - Reusable UI components
- **Models**: `lib/models/` - Data models and business logic
- **Services**: `lib/services/` - Database, storage, external services
- **Providers**: `lib/providers/` - Provider state management classes
- **Utils**: `lib/utils/` - Helper functions and constants

### Testing Requirements
- Write widget tests for complex UI components
- Write unit tests for business logic and data models
- Test database operations with mock data
- Run tests before committing: `flutter test`

### Build and Run Commands
```bash
# Development
flutter run                           # Run on connected device
flutter run --release                 # Release mode

# Production builds
flutter build apk --no-tree-shake-icons                     # Build Android APK (required due to dynamic IconData in GameType)
flutter build apk --release --no-tree-shake-icons          # Build release APK
flutter build ios --no-tree-shake-icons                     # Build iOS app

# Note: --no-tree-shake-icons is required because GameType uses dynamic IconData
# created from database values (game_type.dart:20). This adds ~200KB to APK size
# but is necessary for the database-driven icon system.

# Quality checks
flutter analyze                       # Static analysis
flutter test                          # Run tests
flutter test --coverage              # Generate coverage report

# Dependencies
flutter pub get                       # Install dependencies
flutter pub upgrade                   # Upgrade dependencies
flutter pub outdated                 # Check outdated packages
```

### Performance Guidelines
1. **Widget Rebuilds**: Minimize unnecessary rebuilds using const constructors
2. **Database**: Use batch operations for multiple inserts/updates
3. **Memory**: Dispose controllers and listeners properly
4. **Async Operations**: Use FutureBuilder or async/await appropriately
5. **Wakelock**: Use wakelock_plus only when actively needed (game in progress)

### Database Schema Guidelines
- Use sqflite for local data persistence
- Define clear migration paths for schema changes
- Handle database errors gracefully
- Consider using transactions for related operations
- Close database connections when not in use

### UI/UX Considerations
1. **Responsive Design**: Support various screen sizes and orientations
2. **Color Themes**: Utilize flex_color_picker for customizable themes
3. **Accessibility**: Provide semantic labels for screen readers
4. **Loading States**: Show progress indicators for async operations
5. **Error Messages**: Display user-friendly error messages

### Common Patterns
```dart
// Provider pattern
class ScoreProvider extends ChangeNotifier {
  // State management
  void updateScore() {
    // Update logic
    notifyListeners();
  }
}

// Database operations
class DatabaseService {
  Future<Database> get database async {
    // Database initialization
  }

  Future<void> insertScore(Score score) async {
    final db = await database;
    await db.insert('scores', score.toMap());
  }
}

// Widget structure
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, provider, child) {
        // UI implementation
      },
    );
  }
}
```

### Git Workflow
- Always work on feature branches
- Commit messages: `feat: description`, `fix: description`, `refactor: description`
- Run `flutter analyze && flutter test` before committing
- Don't commit build artifacts or generated files

### Dependencies Management
**Before adding new dependencies:**
1. Check if functionality exists in current dependencies
2. Verify package quality (pub.dev score, recent updates)
3. Consider bundle size impact
4. Update pubspec.yaml with specific version constraints
5. Run `flutter pub get` after adding

**Current Key Dependencies:**
- `provider`: State management - use for all state handling
- `sqflite`: Database - use for persistent data storage
- `path_provider`: File system access
- `shared_preferences`: Simple key-value storage
- `flex_color_picker`: Color selection UI
- `wakelock_plus`: Prevent screen sleep during active games
- `intl`: Date/time formatting and localization

**Dev Dependencies:**
- `flutter_launcher_icons`: Generates app launcher icons from 512×512 source image

### Common Issues and Solutions

**Issue: Hot reload not working**
- Solution: Try hot restart (`R` in terminal) or full restart

**Issue: Database version conflicts**
- Solution: Increment database version and implement migration

**Issue: Provider not updating UI**
- Solution: Ensure `notifyListeners()` is called after state changes

**Issue: Build failures after dependency updates**
- Solution: `flutter clean && flutter pub get && flutter run`

### Quality Checklist
Before marking any feature complete:
- [ ] Code follows Dart style guidelines
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Tests pass: `flutter test`
- [ ] UI tested on different screen sizes
- [ ] Database operations handle errors
- [ ] State management properly implements Provider pattern
- [ ] Async operations have loading indicators
- [ ] Navigation flows work correctly
- [ ] Colors work in both light and dark themes (if applicable)

### Play Store Publishing

**Status**: Configured for Play Store release

**Prerequisites**:
1. Generate upload keystore: `./scripts/generate_keystore.sh`
2. Create `android/key.properties` from `android/key.properties.template`
3. Never commit keystore or key.properties files

**Build for Production**:
```bash
# Build Android App Bundle (required for Play Store)
flutter build appbundle --release --no-tree-shake-icons

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Security Configuration**:
- ✅ Release signing configured in `android/app/build.gradle.kts`
- ✅ ProGuard/R8 disabled (open-source app, no obfuscation needed)
- ✅ Keystore files excluded from version control
- ✅ App name: "CountScore" (production-ready)

**App Icon Configuration**:
- ✅ App icon integrated using `flutter_launcher_icons` package
- ✅ Source icon: `store_listing/assets/icon_512.png` (512×512 PNG)
- ✅ Android launcher icons automatically generated in all densities
- ✅ Adaptive icon support with white background (#FFFFFF)
- ✅ To update icon: Modify `icon_512.png` and run `flutter pub run flutter_launcher_icons`

**Publishing Checklist**:
See [PUBLISHING.md](PUBLISHING.md) for complete step-by-step guide including:
- App signing setup
- Privacy policy requirements
- Store listing assets
- Play Console configuration
- Testing procedures

**Important Notes**:
- `--no-tree-shake-icons` flag is required (see game_type.dart:20)
- Backup your keystore securely - losing it means you can't update the app
- Test release builds thoroughly before submission
- Target API level 35 (Android 15) for 2025 compliance

### Contact and Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite Guide](https://pub.dev/packages/sqflite)
- [Play Store Publishing](https://docs.flutter.dev/deployment/android)

---
**Note**: This file provides project-specific context for Claude Code. Update as the project evolves.
