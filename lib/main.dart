import 'package:avara_astrology_trial/screens/auth_gate.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global scaffold messenger key allowing services (like [AvaraApiClient])
/// to show safe floating SnackBars without requiring BuildContext.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Entry point.
///
/// [dotenv.load] runs before [runApp] so all `.env` values are available
/// synchronously everywhere in the widget tree.
///
/// Authentication routing is handled by [AuthGate], which calls
/// [AuthService.restoreSession] once on startup and routes to either
/// [MainNavigationScaffold] (authenticated) or [LoginScreen] (guest).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', mergeWith: {});
  runApp(const AvaraApp());
}

class AvaraApp extends StatelessWidget {
  const AvaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVARA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // AuthGate checks for a stored JWT; routes to MainNavigationScaffold
      // or LoginScreen accordingly. It also acts as the splash screen while
      // the async session-restore is in flight.
      home: const AuthGate(),
    );
  }
}
