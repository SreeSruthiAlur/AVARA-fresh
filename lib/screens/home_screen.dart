import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/screens/profile_screen.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// A single entry in the Home "Explore AVARA" grid.
///
/// Passed into [HomeScreen.exploreModules] so the grid is fully data-driven
/// rather than hardcoded.
class ExploreModule {
  const ExploreModule({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    this.subtitle,
  });

  /// Module display name, e.g. "Astrology".
  final String label;

  /// Leading icon.
  final IconData icon;

  /// Accent color for the icon badge.
  final Color color;

  /// Pastel card background.
  final Color background;

  /// Optional one-line subtitle.
  final String? subtitle;
}

/// AVARA Home screen (draft).
///
/// Layout mirrors the "02 - Home" screen: a safe area, a dynamic greeting row
/// that accepts a [userName], the lavender "Take a moment for yourself" card,
/// and the "Explore AVARA" module grid. All copy is driven by constructor
/// parameters so the UI never hardcodes static names.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    this.momentTitle = 'Take a moment for yourself',
    this.momentSubtitle =
        'A short ritual to start your day grounded and intentional.',
    this.exploreModules = defaultExploreModules,
    this.onMomentTap,
    this.onModuleTap,
  });

  /// Dynamic user name shown in the greeting.
  final String userName;

  /// Copy for the lavender moment card.
  final String momentTitle;
  final String momentSubtitle;

  /// Modules rendered in the "Explore AVARA" grid.
  final List<ExploreModule> exploreModules;

  /// Optional tap handler for the moment card.
  final VoidCallback? onMomentTap;

  /// Optional tap handler for an explore module.
  /// When `null` the screen uses its own default routing table.
  final void Function(ExploreModule module)? onModuleTap;

  /// Default explore modules (Astrology, Finance, Habits, Health, Insights)
  /// tinted with the AVARA secondary palette.
  static const List<ExploreModule> defaultExploreModules = [
    ExploreModule(
      label: 'Astrology',
      subtitle: 'Find guidance',
      icon: Icons.nightlight_round,
      color: AppColors.violet,
      background: AppColors.lightPink,
    ),
    ExploreModule(
      label: 'Finance',
      subtitle: 'Track spending',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.green,
      background: AppColors.lightGreen,
    ),
    ExploreModule(
      label: 'Habits',
      subtitle: 'Build consistency',
      icon: Icons.track_changes,
      color: AppColors.orange,
      background: AppColors.lightOrange,
    ),
    ExploreModule(
      label: 'Health',
      subtitle: 'Track wellness',
      icon: Icons.favorite,
      color: AppColors.tealBlue,
      background: AppColors.lightCyan,
    ),
    ExploreModule(
      label: 'Insights',
      subtitle: 'See your progress',
      icon: Icons.auto_graph,
      color: AppColors.magentaPurple,
      background: AppColors.lightPink,
    ),
  ];

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Default routing table — maps module labels to real screens.
  ///
  /// Callers can override by supplying [HomeScreen.onModuleTap].
  void _defaultModuleTap(ExploreModule module) {
    switch (module.label) {
      case 'Finance':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const FinanceScreen()),
        );
      case 'Health':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HealthScreen()),
        );
      case 'Habits':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
        );
      case 'Insights':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const InsightsScreen()),
        );
      case 'Astrology':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
              builder: (_) => const AstrologyHubScreen()),
        );
      // Additional modules will be wired here as their screens land.
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${module.label} — coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onModuleTap ?? _defaultModuleTap;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(context),
              const SizedBox(height: 24),
              _buildMomentCard(context),
              const SizedBox(height: 28),
              _buildExploreHeader(context),
              const SizedBox(height: 16),
              _buildExploreGrid(context, onTap),
            ],
          ),
        ),
      ),
    );
  }

  // -- Greeting ---------------------------------------------------------------

  Widget _buildGreeting(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingPrefix(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 2),
              Text(widget.userName,
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _TappableAvatar(name: widget.userName),
      ],
    );
  }

  String _greetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // -- Moment card ------------------------------------------------------------

  Widget _buildMomentCard(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.lavender,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.momentTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  widget.momentSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.self_improvement,
                color: AppColors.violet, size: 28),
          ),
        ],
      ),
    );
  }

  // -- Explore ----------------------------------------------------------------

  Widget _buildExploreHeader(BuildContext context) {
    return Text('Explore AVARA',
        style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildExploreGrid(BuildContext context, void Function(ExploreModule) onTap) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.exploreModules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.45, // rectangular cards matching Figma
      ),
      itemBuilder: (context, index) => _ExploreModuleCard(
        module: widget.exploreModules[index],
        onTap: onTap,
      ),
    );
  }
}

/// Tappable circular avatar — navigates to [ProfileScreen] on tap.
class _TappableAvatar extends StatelessWidget {
  const _TappableAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(userName: name),
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.lavender,
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: AppColors.deepNavy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      buffer.write(part[0].toUpperCase());
    }
    final result = buffer.toString();
    return result.isEmpty ? '?' : result;
  }
}

/// A single tinted card in the "Explore AVARA" grid.
class _ExploreModuleCard extends StatelessWidget {
  const _ExploreModuleCard({required this.module, required this.onTap});

  final ExploreModule module;
  final void Function(ExploreModule module) onTap;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: module.background,
      borderColor: null,
      onTap: () => onTap(module),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: module.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(module.icon, color: AppColors.white, size: 22),
          ),
          const Spacer(),
          Text(module.label, style: Theme.of(context).textTheme.titleMedium),
          if (module.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(module.subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
