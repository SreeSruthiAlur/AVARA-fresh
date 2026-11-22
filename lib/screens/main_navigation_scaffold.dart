import 'package:avara_astrology_trial/models/finance_model.dart';
import 'package:avara_astrology_trial/screens/astrologers_screen.dart';
import 'package:avara_astrology_trial/screens/astrology_chat_screen.dart';
import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/birth_profile_screen.dart';
import 'package:avara_astrology_trial/screens/explore_topics_screen.dart';
import 'package:avara_astrology_trial/screens/finance_add_expense_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/home_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/screens/profile_screen.dart';
import 'package:avara_astrology_trial/screens/register_screen.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/finance_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
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
    // Connect VoiceService navigation and action callbacks
    VoiceService.instance.onAgeCohortChangeRequest = (group) {
      if (mounted) setState(() {});
    };

    VoiceService.instance.onNavigateRequest = (index) {
      if (mounted && index >= 0 && index < _destinations.length) {
        setState(() => _currentIndex = index);
      }
    };

    VoiceService.instance.onRouteRequest = (route) {
      if (!mounted) return;
      if (route == 'profile') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(userName: widget.userName),
          ),
        );
      }
    };

    VoiceService.instance.onOpenScreenRequest = (screen) {
      if (!mounted) return;
      switch (screen) {
        case 'chat':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AstrologyChatScreen(apiKey: widget.apiKey),
            ),
          );
          break;
        case 'explore_topics':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ExploreTopicsScreen(),
            ),
          );
          break;
        case 'add_expense':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FinanceAddExpenseScreen(),
            ),
          );
          break;
        case 'astrologers':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AstrologersScreen(),
            ),
          );
          break;
        case 'birth_profile':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BirthProfileScreen(),
            ),
          );
          break;
        case 'profile':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(userName: widget.userName),
            ),
          );
          break;
        case 'register':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RegisterScreen(),
            ),
          );
          break;
      }
    };

    VoiceService.instance.onAskAstrologyRequest = (question) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AstrologyChatScreen(
            apiKey: widget.apiKey,
            initialQuestion: question,
          ),
        ),
      );
    };

    VoiceService.instance.onAddExpenseRequest =
        (amount, category, description) async {
      try {
        await FinanceService.instance.addExpense(
          Expense(
            amount: amount,
            category: category,
            description: description,
            date: DateTime.now().toIso8601String().substring(0, 10),
          ),
        );
        if (mounted) {
          setState(() => _currentIndex = 2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Added ₹${amount.toInt()} for $description ($category)'),
              backgroundColor: AppColors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FinanceAddExpenseScreen(),
            ),
          );
        }
      }
    };
  }

  @override
  void dispose() {
    VoiceService.instance.onAgeCohortChangeRequest = null;
    VoiceService.instance.onJapaMalaTapRequest = null;
    VoiceService.instance.onJapaMalaResetRequest = null;
    VoiceService.instance.onNavigateRequest = null;
    VoiceService.instance.onRouteRequest = null;
    VoiceService.instance.onOpenScreenRequest = null;
    VoiceService.instance.onAskAstrologyRequest = null;
    VoiceService.instance.onAddExpenseRequest = null;
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AgeProfileService.instance,
        AppLanguageService.instance,
      ]),
      builder: (context, _) {
        final tr = AppLanguageService.instance.tr;
        final currentLang = AppLanguageService.instance.currentLanguage;
        final ageTheme = AgeProfileService.instance.activeTheme;
        final isSenior = ageTheme.group == AgeGroup.senior;

        final stateKey = '${currentLang.code}_${ageTheme.group.name}';
        final screens = [
          HomeScreen(
            key: ValueKey('home_$stateKey'),
            userName: widget.userName,
          ),
          AstrologyHubScreen(
            key: ValueKey('astro_$stateKey'),
            apiKey: widget.apiKey,
          ),
          FinanceScreen(
            key: ValueKey('finance_$stateKey'),
          ),
          HealthScreen(
            key: ValueKey('health_$stateKey'),
          ),
          HabitsScreen(
            key: ValueKey('habits_$stateKey'),
          ),
          InsightsScreen(
            key: ValueKey('insights_$stateKey'),
          ),
        ];

        assert(
          _destinations.length == screens.length,
          'Bottom-nav destinations (${_destinations.length}) and screens '
          '(${screens.length}) must be the same length.',
        );

        return MobileDeviceFrameWrapper(
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: isSenior ? const Color(0xFFFFFDF5) : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: ageTheme.primaryAccent.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: ageTheme.primaryAccent,
                unselectedItemColor: isSenior ? const Color(0xFF92400E) : AppColors.secondaryText,
                backgroundColor: isSenior ? const Color(0xFFFFFDF5) : AppColors.white,
                elevation: 0,
                iconSize: isSenior ? 26 : 24,
                selectedFontSize: isSenior ? 13 : 12,
                unselectedFontSize: isSenior ? 11.5 : 11,
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ageTheme.primaryAccent,
                ),
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
            ),
          ),
        );
      },
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
