import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/home_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Root navigation scaffold — 6-tab bottom navigation bar:
/// Home · Astrology · Finance · Health · Track · Insights.
///
/// The AI tab has been removed. Finance and Health are now first-class tabs.
/// Each tab drives an [IndexedStack] so state is preserved across switches.
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

  // ── Tab definitions ───────────────────────────────────────────────────────
  // IMPORTANT: _destinations and _screens must stay in sync (same length,
  // same order) to prevent index-out-of-bounds errors in the IndexedStack.
  static const _destinations = <_NavDestination>[
    _NavDestination(           // 0
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavDestination(           // 1
      label: 'Astrology',
      icon: Icons.nightlight_outlined,
      activeIcon: Icons.nightlight_round,
    ),
    _NavDestination(           // 2
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
    ),
    _NavDestination(           // 3
      label: 'Health',
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
    ),
    _NavDestination(           // 4
      label: 'Track',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard,
    ),
    _NavDestination(           // 5
      label: 'Insights',
      icon: Icons.auto_graph_outlined,
      activeIcon: Icons.auto_graph,
    ),
  ];

  /// Screens are built once and kept alive by [IndexedStack].
  /// Length and order must exactly match [_destinations].
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.secondaryText,
        backgroundColor: AppColors.white,
        elevation: 0,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(
              icon: Icon(d.icon),
              activeIcon: Icon(d.activeIcon),
              label: d.label,
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
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
