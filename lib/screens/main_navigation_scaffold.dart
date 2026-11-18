import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/home_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/screens/profile_screen.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/global_voice_assistant_modal.dart';
import 'package:flutter/material.dart';

/// Root navigation scaffold — 6-tab bottom navigation bar:
/// Home · Astrology · Finance · Health · Track · Insights.
///
/// Features:
/// - Reactive visual localization (English, Telugu, Tanglish).
/// - Voice command listener for hands-free tab navigation.
/// - Floating voice assistant button to speak commands anywhere.
class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({
    super.key,
    this.userName = 'Guest',
    this.apiKey = '',
  });

  final String userName;
  final String apiKey;

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Connect VoiceService navigation callbacks
    VoiceService.instance.onNavigateRequest = (index) {
      if (mounted && index >= 0 && index < _screens.length) {
        setState(() => _currentIndex = index);
      }
    };
    VoiceService.instance.onRouteRequest = (route) {
      if (route == 'profile' && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(userName: widget.userName),
          ),
        );
      }
    };
  }

  // ── Tab definitions ───────────────────────────────────────────────────────
  static const _destinations = <_NavDestination>[
    _NavDestination(
      labelKey: 'tab_home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavDestination(
      labelKey: 'tab_astrology',
      icon: Icons.nightlight_outlined,
      activeIcon: Icons.nightlight_round,
    ),
    _NavDestination(
      labelKey: 'tab_finance',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
    ),
    _NavDestination(
      labelKey: 'tab_health',
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
    ),
    _NavDestination(
      labelKey: 'tab_track',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard,
    ),
    _NavDestination(
      labelKey: 'tab_insights',
      icon: Icons.auto_graph_outlined,
      activeIcon: Icons.auto_graph,
    ),
  ];

  late final List<Widget> _screens = [
    HomeScreen(userName: widget.userName),          // 0 — Home
    AstrologyHubScreen(apiKey: widget.apiKey),      // 1 — Astrology hub
    const FinanceScreen(),                          // 2 — Finance
    const HealthScreen(),                           // 3 — Health
    const HabitsScreen(),                           // 4 — Track (Habits)
    const InsightsScreen(),                         // 5 — Insights
  ];

  @override
  Widget build(BuildContext context) {
    assert(
      _destinations.length == _screens.length,
      'Bottom-nav destinations (${_destinations.length}) and screens '
      '(${_screens.length}) must be the same length.',
    );

    final tr = AppLanguageService.instance.tr;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GlobalVoiceAssistantModal.show(context),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: tr('voice_assistant_title'),
        child: const Icon(Icons.mic_rounded, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.secondaryText,
        backgroundColor: AppColors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(
              icon: Icon(d.icon),
              activeIcon: Icon(d.activeIcon),
              label: tr(d.labelKey),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

class _NavDestination {
  const _NavDestination({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });

  final String labelKey;
  final IconData icon;
  final IconData activeIcon;
}
