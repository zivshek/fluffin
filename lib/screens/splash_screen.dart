import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/jellyfin_provider.dart';
import '../services/login_history_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // Give a brief moment for the splash screen to show
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Get the most recent user from history
      final userHistory = await LoginHistoryService.getUserHistory();

      if (userHistory.isNotEmpty) {
        // Get the most recent user (first in the list)
        final mostRecentUser = userHistory.first;

        // Try to get stored password
        final password = await LoginHistoryService.getStoredPassword(
          mostRecentUser.username,
          mostRecentUser.serverUrl,
        );

        if (password != null && mounted) {
          // Attempt auto-login with the most recent user
          final provider = context.read<JellyfinProvider>();
          final success = await provider.login(
            mostRecentUser.serverUrl,
            mostRecentUser.username,
            password,
          );

          if (success && mounted) {
            // Auto-login successful, navigate directly to library
            context.go('/library');
            return;
          }
        }
      }

      // No recent user, no stored password, or login failed
      // Navigate to library selection screen
      if (mounted) {
        context.go('/libraries');
      }
    } catch (e) {
      // Auto-login failed, show library selection
      if (mounted) {
        context.go('/libraries');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A4DC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                size: 80,
                color: Color(0xFF00A4DC),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Fluffin',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Jellyfin companion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
