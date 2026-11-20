import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/screens/profile_screen.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/fact_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/fact_popup.dart';
import 'package:avara_astrology_trial/widgets/global_voice_assistant_modal.dart';
import 'package:avara_astrology_trial/widgets/language_selector_sheet.dart';
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
  @override
  void initState() {
    super.initState();
    AgeProfileService.instance.loadPreferences();
    AgeProfileService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AgeProfileService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _navigateToPillar(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const AstrologyHubScreen()),
        );
      case 1:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HealthScreen()),
        );
      case 2:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
        );
      case 3:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const FinanceScreen()),
        );
      case 4:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const InsightsScreen()),
        );
    }
  }

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
    return ListenableBuilder(
      listenable: AgeProfileService.instance,
      builder: (context, _) {
        final ageService = AgeProfileService.instance;
        final ageGroup = ageService.ageGroup;
        final bgColor = switch (ageGroup) {
          AgeGroup.youth => const Color(0xFFFAF9FF),
          AgeGroup.adult => const Color(0xFFF8FAFC),
          AgeGroup.senior => const Color(0xFFFFFDF5),
        };

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: 12),
                  // Age Cohort Mode Switcher (Youth / Adult / Senior instant transformation)
                  const AgeCohortSelectorBar(),
                  const SizedBox(height: 16),
                  // Dynamic Age-Adaptive Creative Header Graphic (Point 11 & Point 9)
                  _buildAgeAdaptiveCard(context),
                  const SizedBox(height: 20),
                  _buildMomentCard(context),
                  const SizedBox(height: 24),
                  // Daily Self-Help Multi-Graphic Reports (Point 10 & Point 3)
                  _buildDailyReportsSection(context),
                  const SizedBox(height: 28),
                  // 5-Pillar Holistic Synergy Radar (Astrology, Health, Habits, Finance, Insights)
                  const HolisticRadarSynergyChart(),
                  const SizedBox(height: 20),
                  // Unified Interconnected Pillars Nexus (Interactive pentagonal ecosystem)
                  ConnectedPillarsNexusWidget(onOpenPillar: _navigateToPillar),
                  const SizedBox(height: 18),
                  // Chronological Daily Holistic Synergy Stream
                  UnifiedHolisticSynergyStream(onOpenPillar: _navigateToPillar),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgeAdaptiveCard(BuildContext context) {
    final ageService = AgeProfileService.instance;
    final activeTheme = ageService.activeTheme;

    return Stack(
      children: [
        AgeAdaptiveHeaderGraphic(ageGroup: ageService.ageGroup, height: 140),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(activeTheme.iconData, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            activeTheme.displayName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Age group quick switcher chip
                    PopupMenuButton<AgeGroup>(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                      tooltip: 'Change Age Graphics',
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (group) => ageService.setAgeGroup(group),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: AgeGroup.youth,
                          child: Text('🎒 Youth Theme (< 22)'),
                        ),
                        const PopupMenuItem(
                          value: AgeGroup.adult,
                          child: Text('💼 Achiever Theme (22 - 45)'),
                        ),
                        const PopupMenuItem(
                          value: AgeGroup.senior,
                          child: Text('🌸 Grace & Serenity (45+)'),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeTheme.tagline,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Creative Style: ${activeTheme.graphicStyleDescription}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReportsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Holistic Growth Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            TextButton.icon(
              onPressed: () => FactPopup.show(context),
              icon: const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.blue),
              label: const Text('💡 Facts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Graphic 1: Radial Multi-Ring Energy Gauge (Point 10)
        const RadialEnergyGauge(
          mindScore: 0.88,
          vitalityScore: 0.74,
          habitScore: 0.91,
          wealthScore: 0.80,
        ),
        const SizedBox(height: 14),
        // Graphic 2: Interactive Mindful Breathing Aura Sphere
        const MindfulBreathingAuraWidget(),
        const SizedBox(height: 14),
        // Graphic 3: Circadian Waveform Flow Curve (Point 10)
        const CircadianWaveformChart(),
        const SizedBox(height: 14),
        // Graphic 4: Planetary Harmony 5-Axis Radar Matrix (Point 10)
        const PlanetaryHarmonyRadar(),
        const SizedBox(height: 14),
        // Graphic 5: Live Celestial Orbit & Navagraha Matrix
        const ZodiacCelestialOrbitWidget(),
      ],
    );
  }

  // -- Greeting ---------------------------------------------------------------

  Widget _buildGreeting(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    final currentLang = AppLanguageService.instance.currentLanguage;
    final activeTheme = AgeProfileService.instance.activeTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: activeTheme.primaryAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeTheme.iconData, size: 12, color: activeTheme.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          activeTheme.greetingBadge,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: activeTheme.primaryAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                switch (activeTheme.group) {
                  AgeGroup.youth => '⚡ Hey there, explorer!',
                  AgeGroup.adult => _greetingPrefix(),
                  AgeGroup.senior => '🌸 Namaste, peace & good health.',
                },
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 2),
              Text(
                switch (activeTheme.group) {
                  AgeGroup.youth => '${widget.userName} ⚡',
                  AgeGroup.adult => widget.userName,
                  AgeGroup.senior => '${widget.userName} ji 🙏',
                },
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: activeTheme.group == AgeGroup.senior
                          ? const Color(0xFF78350F)
                          : (activeTheme.group == AgeGroup.youth
                              ? const Color(0xFF4834D4)
                              : AppColors.deepNavy),
                      fontSize: activeTheme.group == AgeGroup.senior ? 24 : 20,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Quick Language Switcher Badge
        GestureDetector(
          onTap: () => LanguageSelectorSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded,
                    size: 16, color: AppColors.blue),
                const SizedBox(width: 4),
                Text(
                  currentLang.shortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Quick Voice Assistant Button
        GestureDetector(
          onTap: () => GlobalVoiceAssistantModal.show(context),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.mic_rounded,
                size: 20, color: AppColors.blue),
          ),
        ),
        const SizedBox(width: 8),

        _TappableAvatar(name: widget.userName),
      ],
    );
  }

  String _greetingPrefix() {
    final tr = AppLanguageService.instance.tr;
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('greeting_morning');
    if (hour < 17) return tr('greeting_afternoon');
    return tr('greeting_evening');
  }

  // -- Moment card (Dynamically customized by user's age) ---------------------

  Widget _buildMomentCard(BuildContext context) {
    final activeTheme = AgeProfileService.instance.activeTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: activeTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: activeTheme.primaryAccent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activeTheme.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeTheme.momentTitle,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: activeTheme.primaryAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeTheme.momentSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeTheme.primaryAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(activeTheme.iconData, color: activeTheme.primaryAccent, size: 28),
          ),
        ],
      ),
    );
  }

  // -- Explore ----------------------------------------------------------------

  Widget _buildExploreHeader(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    return Text(tr('explore_avara'),
        style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildExploreGrid(BuildContext context, void Function(ExploreModule) onTap) {
    final tr = AppLanguageService.instance.tr;

    final localizedModules = [
      ExploreModule(
        label: tr('mod_astrology_title'),
        subtitle: tr('mod_astrology_sub'),
        icon: Icons.nightlight_round,
        color: AppColors.violet,
        background: AppColors.lightPink,
      ),
      ExploreModule(
        label: tr('mod_finance_title'),
        subtitle: tr('mod_finance_sub'),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.green,
        background: AppColors.lightGreen,
      ),
      ExploreModule(
        label: tr('mod_habits_title'),
        subtitle: tr('mod_habits_sub'),
        icon: Icons.track_changes,
        color: AppColors.orange,
        background: AppColors.lightOrange,
      ),
      ExploreModule(
        label: tr('mod_health_title'),
        subtitle: tr('mod_health_sub'),
        icon: Icons.favorite,
        color: AppColors.tealBlue,
        background: AppColors.lightCyan,
      ),
      ExploreModule(
        label: tr('mod_insights_title'),
        subtitle: tr('mod_insights_sub'),
        icon: Icons.auto_graph,
        color: AppColors.magentaPurple,
        background: AppColors.lightPink,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: localizedModules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) => _ExploreModuleCard(
        module: localizedModules[index],
        onTap: (module) {
          // Route by index so localized labels route identically
          switch (index) {
            case 0:
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const AstrologyHubScreen()),
              );
            case 1:
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const FinanceScreen()),
              );
            case 2:
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
              );
            case 3:
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const HealthScreen()),
              );
            case 4:
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const InsightsScreen()),
              );
          }
        },
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
