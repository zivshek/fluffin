import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';

import 'providers/jellyfin_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/library_selection_screen.dart';
import 'screens/library_content_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/player_screen.dart';
import 'generated/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(const FluffinApp());
}

class FluffinApp extends StatelessWidget {
  const FluffinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => JellyfinProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Fluffin',
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('de'),
            ],
            locale: Locale(settings.appLanguage),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00A4DC),
                brightness:
                    settings.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/libraries',
  routes: [
    // Library selection (main hub)
    GoRoute(
      path: '/libraries',
      builder: (context, state) => const LibrarySelectionScreen(),
    ),

    // Login flow
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LoginScreen(
          prefilledServerUrl: extra?['serverUrl'],
          prefilledUsername: extra?['username'],
        );
      },
    ),

    // Library content (no bottom nav)
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryContentScreen(),
    ),

    // Search (no bottom nav)
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),

    // Favorites (no bottom nav)
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),

    // Settings (no bottom nav)
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Full-screen player
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PlayerScreen(
          itemId: extra?['itemId'] ?? '',
          title: extra?['title'] ?? '',
        );
      },
    ),
  ],
);
