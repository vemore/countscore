import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
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
import 'services/join_link_inbox.dart';
import 'services/join_link_location.dart';
import 'services/review_prompt.dart';
import 'services/sync/sync_engine.dart';
import 'utils/app_theme.dart';
import 'widgets/join_link_listener.dart';
import 'widgets/pwa_update_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A scanned configuration QR, before anything else: on the web its `#/join?…`
  // route leaves the address bar before Flutter's history reads it, a later
  // `#/join?…` is stripped from its history entry by a listener registered
  // ahead of Flutter's, and the inbox answers the `#/join` pushes ahead of
  // WidgetsApp (registered first). On Android, app_links delivers
  // `countscore://join?…`: the launch intent, then each new one, and the launch
  // intent again when the system recreates a killed activity (JoinLinkInbox).
  // The home screen opens what arrives (JoinLinkListener).
  final joinLinks = JoinLinkInbox(
    initialRoute: takeJoinRouteFromLocation(),
    takeStrippedRoute: takeStrippedJoinRoute,
  );
  watchJoinRoutesInLocation();
  WidgetsBinding.instance.addObserver(joinLinks);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    joinLinks.listenTo(AppLinks().stringLinkStream);
  }
  registerFontLicenses();
  // Read the theme before the first frame so a dark-mode user never sees a
  // light flash on cold start.
  final themeMode = await ThemeProvider.load();
  // Same reasoning for the backend URL: the ZapZap entry in the game menu must
  // not appear and then vanish once preferences have loaded.
  final backendUrl = await BackendProvider.load();
  // Starts the "installed for at least a week" clock. Cheap: it writes only on
  // the very first launch, and preferences are already in memory by now.
  await ReviewPromptService.instance.recordFirstLaunch();
  runApp(MyApp(
    initialThemeMode: themeMode,
    initialBackendUrl: backendUrl,
    joinLinks: joinLinks,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialThemeMode,
    this.initialBackendUrl,
    this.joinLinks,
  });

  final ThemeMode initialThemeMode;
  final String? initialBackendUrl;

  /// The configuration links received; none are opened without it.
  final JoinLinkInbox? joinLinks;

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
            builder: (context, child) => _SyncEventListener(
              child: PwaUpdateListener(
                messengerKey: scaffoldMessengerKey,
                child: child!,
              ),
            ),
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
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            home: joinLinks == null
                ? const HomeScreen()
                : JoinLinkListener(
                    inbox: joinLinks!,
                    // The PWA in an Android browser offers the app first.
                    offerAppHandOver: kIsWeb && defaultTargetPlatform == TargetPlatform.android,
                    openInApp: openLinkInPlace,
                    child: const HomeScreen(),
                  ),
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
