import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/backend_provider.dart';
import 'providers/game_provider.dart';
import 'providers/game_type_provider.dart';
import 'providers/group_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/sync/sync_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the theme before the first frame so a dark-mode user never sees a
  // light flash on cold start.
  final themeMode = await ThemeProvider.load();
  // Same reasoning for the backend URL: the ZapZap entry in the game menu must
  // not appear and then vanish once preferences have loaded.
  final backendUrl = await BackendProvider.load();
  runApp(MyApp(initialThemeMode: themeMode, initialBackendUrl: backendUrl));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialThemeMode,
    this.initialBackendUrl,
  });

  final ThemeMode initialThemeMode;
  final String? initialBackendUrl;

  /// Sync conflicts are reported wherever the user happens to be, not only on
  /// the screen that caused them.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => GameTypeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialThemeMode)),
        ChangeNotifierProvider(
          create: (_) => BackendProvider(initialBackendUrl),
        ),
        // Sync runs only while a server is configured *and* this device is in a
        // group; the proxy hands it every change of server URL.
        ChangeNotifierProxyProvider<BackendProvider, GroupProvider>(
          create: (context) => GroupProvider(
            onRemoteChange: () => context.read<GameProvider>().refreshFromSync(),
          ),
          update: (_, backend, group) => group!..updateBackend(backend.baseUrl),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            builder: (context, child) => _SyncEventListener(child: child!),
            title: 'CountScore',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('fr', ''), // French
              Locale('es', ''), // Spanish
              Locale('zh', ''), // Chinese (Simplified)
              Locale('hi', ''), // Hindi
              Locale('ar', ''), // Arabic
              Locale('pt', ''), // Portuguese
              Locale('ru', ''), // Russian
              Locale('ja', ''), // Japanese
              Locale('de', ''), // German
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) {
                return const Locale('en', '');
              }
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
              return const Locale('en', '');
            },
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}


/// Turns sync events into snackbars, on whichever screen is showing.
class _SyncEventListener extends StatefulWidget {
  const _SyncEventListener({required this.child});
  final Widget child;

  @override
  State<_SyncEventListener> createState() => _SyncEventListenerState();
}

class _SyncEventListenerState extends State<_SyncEventListener> {
  StreamSubscription<SyncEvent>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= context.read<GroupProvider>().events.listen((event) {
      final messenger = MyApp.scaffoldMessengerKey.currentState;
      final l10n = AppLocalizations.of(messenger?.context ?? context);
      if (messenger == null || l10n == null) return;
      switch (event) {
        case RoundRenumbered(:final newNumber):
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.roundRenumbered(newNumber))),
          );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
