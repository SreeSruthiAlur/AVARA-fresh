import 'package:avara_astrology_trial/screens/login_screen.dart';
import 'package:avara_astrology_trial/screens/main_navigation_scaffold.dart';
import 'package:avara_astrology_trial/services/auth_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The root routing widget of the AVARA app.
///
/// On first render it calls [AuthService.restoreSession] once. While that
/// `Future` is in flight the widget shows a branded splash / loading screen.
/// The outcome routes the user to the correct destination:
///
/// ```
/// restoreSession() returns AuthUser  →  MainNavigationScaffold (authenticated)
/// restoreSession() returns null      →  LoginScreen (no session / expired)
/// restoreSession() throws            →  LoginScreen (defensive fallback)
/// ```
///
/// Because [FutureBuilder] calls the `future` factory only once per state
/// object lifecycle, wrapping it in a [StatefulWidget] and storing the Future
/// in `initState` prevents redundant calls during rebuilds.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Resolved once in [initState] so `FutureBuilder` never re-fires it on
  /// widget rebuilds triggered by ancestor tree changes.
  late final Future<AuthUser?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService.instance.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        // --- Loading / splash state -----------------------------------------
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        // --- Authenticated ---------------------------------------------------
        final user = snapshot.data;
        if (user != null) {
          final apiKey = dotenv.get('GROQ_API_KEY',
              fallback: dotenv.get('GEMINI_API_KEY', fallback: ''));
          return MainNavigationScaffold(
            apiKey: apiKey,
            userName:
                user.fullName.isNotEmpty ? user.fullName : user.username,
          );
        }

        // --- Unauthenticated (null result or error) --------------------------
        return const LoginScreen();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Splash / loading screen
// ---------------------------------------------------------------------------

/// Shown while [AuthGate] awaits [AuthService.restoreSession].
///
/// Uses the AVARA brand colours so the transition from splash to the main
/// app (or login) feels seamless rather than showing a blank white frame.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand initial badge — mirrors the LoginScreen header mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AVARA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
