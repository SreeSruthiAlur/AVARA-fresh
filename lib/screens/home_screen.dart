import 'dart:async';
import 'dart:math' as math;
import 'package:avara_astrology_trial/screens/astrology_hub_screen.dart';
import 'package:avara_astrology_trial/screens/explore_topics_screen.dart';
import 'package:avara_astrology_trial/screens/finance_screen.dart';
import 'package:avara_astrology_trial/screens/habits_screen.dart';
import 'package:avara_astrology_trial/screens/health_screen.dart';
import 'package:avara_astrology_trial/screens/insights_screen.dart';
import 'package:avara_astrology_trial/screens/profile_screen.dart';
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/fact_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/fact_popup.dart';
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
      listenable: Listenable.merge([
        AgeProfileService.instance,
        AppLanguageService.instance,
      ]),
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
          body: AgeCohortAmbientBackground(
            ageGroup: ageGroup,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(context),
                    const SizedBox(height: 12),
                    // Age Cohort Mode Switcher (Youth / Adult / Senior instant transformation)
                    const AgeCohortSelectorBar(),
                    const SizedBox(height: 14),
                    // Dynamic Living Cohort Canvas Banner (Adapts with animated graphics per age)
                    _buildAgeAdaptiveCard(context),
                    const SizedBox(height: 18),
                    // Prominent Unified 5-Pillars Connected Flow River (Continuous Life Loop)
                    UnifiedFivePillarsLifeRiver(onOpenPillar: _navigateToPillar),
                    const SizedBox(height: 18),
                    // Render the completely bespoke UI/UX dashboard for this age cohort with smooth AnimatedSwitcher:
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.04),
                              end: Offset.zero,
                            ).animate(animation),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(ageGroup),
                        child: switch (ageGroup) {
                          AgeGroup.youth => _buildYouthDashboard(context),
                          AgeGroup.adult => _buildAdultDashboard(context),
                          AgeGroup.senior => _buildSeniorDashboard(context),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYouthDashboard(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final conn1 = switch (lang) {
      AppLanguage.telugu => '⚡ ఖగోళ హోరా ➔ రోజువారీ క్వెస్ట్ శక్తి ⚡',
      AppLanguage.tanglish => '⚡ Cosmic Hora Feeds Daily Quest Energy ⚡',
      AppLanguage.malayalam => '⚡ ജ്യോതിഷ ഹോര ➔ ദൈനംദിന ക്വസ്റ്റ് ഊർജ്ജം ⚡',
      AppLanguage.manglish => '⚡ Jyothisha Hora ➔ Daily Quest Oorjjam ⚡',
      AppLanguage.english => '⚡ Cosmic Hora Feeds Daily Energy & Quests ⚡',
    };
    final conn2 = switch (lang) {
      AppLanguage.telugu => '🎯 సాధించిన క్వెస్టులు ➔ 5 స్తంభాల సమతుల్యత 🎯',
      AppLanguage.tanglish => '🎯 Quests Discipline ➔ 5-Pillar Equilibrium 🎯',
      AppLanguage.malayalam => '🎯 ക്വസ്റ്റ് അച്ചടക്കം ➔ 5 തൂണുകളുടെ സന്തുലിതാവസ്ഥ 🎯',
      AppLanguage.manglish => '🎯 Quest Discipline ➔ 5 Pillars Equilibrium 🎯',
      AppLanguage.english => '🎯 Gamified Quests Fuel 5-Pillar Equilibrium 🎯',
    };
    final conn3 = switch (lang) {
      AppLanguage.telugu => '🔗 5 స్తంభాల అఖండ జీవన ప్రవాహం & సమన్వయం 🔗',
      AppLanguage.tanglish => '🔗 5-Pillar Interconnected Life Flow 🔗',
      AppLanguage.malayalam => '🔗 5 തൂണുകളുടെ അഖണ്ഡ ജീവന പ്രവാഹം 🔗',
      AppLanguage.manglish => '🔗 5 Pillars Interconnected Jeevana Pravaham 🔗',
      AppLanguage.english => '🔗 5-Pillar Connected Life Flow & Synergy 🔗',
    };
    final conn4 = switch (lang) {
      AppLanguage.telugu => '📈 నిరంతర దైనందిన జీవన ప్రవాహం 📈',
      AppLanguage.tanglish => '📈 Daily Continuous Life Stream 📈',
      AppLanguage.malayalam => '📈 തുടർച്ചയായ ദൈനംദിന ജീവിത പ്രവാഹം 📈',
      AppLanguage.manglish => '📈 Thudarchayaaya Daily Jeevitha Stream 📈',
      AppLanguage.english => '📈 Continuous Chronological Life Stream 📈',
    };
    final conn5 = switch (lang) {
      AppLanguage.telugu => '📊 సమగ్ర విశ్లేషణలు & దైనందిన నివేదికలు 📊',
      AppLanguage.tanglish => '📊 Holistic Insights & Daily Reports 📊',
      AppLanguage.malayalam => '📊 സമഗ്ര ഉൾക്കാഴ്ചകളും ദൈനംദിന റിപ്പോർട്ടുകളും 📊',
      AppLanguage.manglish => '📊 Holistic Insights & Daily Reports 📊',
      AppLanguage.english => '📊 Synergy Insights & Multi-Graphic Analytics 📊',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Cyber-Glow Hero with XP Bar & Quick Focus Pods
        CyberGlowHeroWidget(
          userName: widget.userName,
          onOpenFocus: () => _showYouthPomodoroModal(context),
          onOpenBreathing: () => _showYouthBreathingModal(context),
          onOpenCareer: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ExploreTopicsScreen()),
          ),
          onOpenDetox: () => _showYouthDetoxModal(context),
        ),
        const SizedBox(height: 14),

        // Creative Graphic: Interactive Holographic Cyber-Orb & XP Core
        const CyberHolographicOrbWidget(),
        FlowConduitConnector(title: conn1),

        // 2. Interactive Mind Quests & XP Task Tracker
        const YouthCyberQuestEngine(),
        FlowConduitConnector(title: conn2),

        // 3. 5-Pillar Synergy Spider Radar (Gamified Life Harmony)
        const HolisticRadarSynergyChart(),
        FlowConduitConnector(title: conn3),

        // 4. Cybernetic Nexus Graph (Astrology, Health, Habits, Finance, Insights)
        ConnectedPillarsNexusWidget(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn4),

        // 5. Chronological Daily Synergy Stream
        UnifiedHolisticSynergyStream(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn5),

        // 6. Daily Self-Help Multi-Graphic Reports
        _buildDailyReportsSection(context),
      ],
    );
  }

  Widget _buildAdultDashboard(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final conn1 = switch (lang) {
      AppLanguage.telugu => '⚡ ఎగ్జిక్యూటివ్ సామర్థ్యం ➔ సర్కాడియన్ జీవ లయ ⚡',
      AppLanguage.tanglish => '⚡ Executive Performance ➔ Circadian Rhythm ⚡',
      AppLanguage.malayalam => '⚡ ഉന്നത പ്രകടനം ➔ സർക്കാഡിയൻ ജൈവ താളം ⚡',
      AppLanguage.manglish => '⚡ High Performance ➔ Circadian Bio-Rhythm ⚡',
      AppLanguage.english => '⚡ High Performance ➔ Circadian Bio-Rhythm ⚡',
    };
    final conn2 = switch (lang) {
      AppLanguage.telugu => '💼 అత్యున్నత ఏకాగ్రతా సమయం ➔ వివేక నిర్ణయాలు 💼',
      AppLanguage.tanglish => '💼 Peak Energy Hours ➔ Clear Decision Making 💼',
      AppLanguage.malayalam => '💼 ഊർജ്ജസ്വല നിമിഷങ്ങൾ ➔ വിവേകപൂർണ്ണമായ തീരുമാനങ്ങൾ 💼',
      AppLanguage.manglish => '💼 Peak Hours ➔ Clear Decisions 💼',
      AppLanguage.english => '💼 Peak Cognitive Hours Drive Mindful Decisions 💼',
    };
    final conn3 = switch (lang) {
      AppLanguage.telugu => '⚖️ వివేక నిర్ణయాలు ➔ జీవన సమతుల్యత ⚖️',
      AppLanguage.tanglish => '⚖️ Mindful Choices ➔ Life Radar Balance ⚖️',
      AppLanguage.malayalam => '⚖️ വിവേകപരമായ തീരുമാനങ്ങൾ ➔ ജീവിത സന്തുലിതാവസ്ഥ ⚖️',
      AppLanguage.manglish => '⚖️ Mindful Choices ➔ Life Balance ⚖️',
      AppLanguage.english => '⚖️ Mindful Choices Balance Life Radar ⚖️',
    };
    final conn4 = switch (lang) {
      AppLanguage.telugu => '🔗 5 స్తంభాల అనుసంధానం: క్రమశిక్షణ సంపదను కాపాడుతుంది 🔗',
      AppLanguage.tanglish => '🔗 5-Pillars Connected: Habits Protect Wealth 🔗',
      AppLanguage.malayalam => '🔗 5 സ്തംഭ ശൃംഖല: അച്ചടക്കം സമ്പത്ത് സംരക്ഷിക്കുന്നു 🔗',
      AppLanguage.manglish => '🔗 5 Pillars Connected: Discipline Protects Wealth 🔗',
      AppLanguage.english => '🔗 5-Pillar Ecosystem: Discipline Protects Wealth 🔗',
    };
    final conn5 = switch (lang) {
      AppLanguage.telugu => '📈 అనుసంధాన ఎగ్జిక్యూటివ్ జీవన ప్రవాహం 📈',
      AppLanguage.tanglish => '📈 Integrated Executive Life Stream 📈',
      AppLanguage.malayalam => '📈 സമഗ്ര എക്സിക്യൂട്ടീവ് ജീവിത പ്രവാഹം 📈',
      AppLanguage.manglish => '📈 Integrated Executive Life Stream 📈',
      AppLanguage.english => '📈 Integrated Executive Life Stream 📈',
    };
    final conn6 = switch (lang) {
      AppLanguage.telugu => '📊 ఆరోగ్యం, సంపద, అలవాట్ల సమగ్ర నివేదికలు 📊',
      AppLanguage.tanglish => '📊 Health, Wealth & Habit Reports 📊',
      AppLanguage.malayalam => '📊 ആരോഗ്യം, സമ്പത്ത്, ശീലം സമഗ്ര റിപ്പോർട്ടുകൾ 📊',
      AppLanguage.manglish => '📊 Health, Wealth & Habit Reports 📊',
      AppLanguage.english => '📊 Multi-Metric Health, Wealth & Habit Reports 📊',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Executive KPI Equilibrium Widget
        ExecutiveKpiEquilibriumWidget(
          userName: widget.userName,
          onOpenPillar: _navigateToPillar,
        ),
        FlowConduitConnector(title: conn1),

        // 2. Executive Circadian Energy Flow & Peak Hours
        const ExecutiveCircadianFlowCard(),
        const SizedBox(height: 14),

        // Creative Graphic: 3-Channel Live Biometric Spectrum Waveform
        const ExecutiveBiorhythmMatrixCard(),
        FlowConduitConnector(title: conn2),

        // 3. Executive Moment Card (Circadian Peak & Decision Making)
        _buildMomentCard(context),
        FlowConduitConnector(title: conn3),

        // 4. 5-Pillar Executive Radar
        const HolisticRadarSynergyChart(),
        FlowConduitConnector(title: conn4),

        // 5. Connected Pillars Nexus Widget
        ConnectedPillarsNexusWidget(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn5),

        // 6. Daily Executive Circadian Stream
        UnifiedHolisticSynergyStream(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn6),

        // 7. Multi-Graphic Daily Reports
        _buildDailyReportsSection(context),
      ],
    );
  }

  Widget _buildSeniorDashboard(BuildContext context) {
    final lang = AppLanguageService.instance.currentLanguage;
    final conn1 = switch (lang) {
      AppLanguage.telugu => '📿 ఉదయపు శ్లోకాలు ➔ 108 వేద జపమాల సాధన 📿',
      AppLanguage.tanglish => '📿 Morning Slokas Flow into 108 Japa Mala 📿',
      AppLanguage.malayalam => '📿 പ്രഭാത ശ്ലോകങ്ങൾ ➔ 108 ജപമാല സാധന 📿',
      AppLanguage.manglish => '📿 Morning Slokas ➔ 108 Japa Mala Sadhana 📿',
      AppLanguage.english => '📿 Morning Slokas Flow into 108 Japa Chanting 📿',
    };
    final conn2 = switch (lang) {
      AppLanguage.telugu => '🌿 జప కంపనాలు ➔ ఆయుర్వేద త్రిదోష సమతుల్యత 🌿',
      AppLanguage.tanglish => '🌿 Sacred Japa Vibrations Balance Tridoshas 🌿',
      AppLanguage.malayalam => '🌿 ജപ പ്രകമ്പനങ്ങൾ ➔ ആയുർവേദ ത്രിദോഷ സന്തുലനം 🌿',
      AppLanguage.manglish => '🌿 Japa Vibrations Balance Ayurvedic Doshas 🌿',
      AppLanguage.english => '🌿 Sacred Japa Vibrations Balance Ayurvedic Doshas 🌿',
    };
    final conn3 = switch (lang) {
      AppLanguage.telugu => '🔗 5 స్తంభాల పవిత్ర జీవన సమన్వయ మండలం 🔗',
      AppLanguage.tanglish => '🔗 Sacred 5-Pillar Mandala of Harmony 🔗',
      AppLanguage.malayalam => '🔗 5 സ്തംഭ പവിത്ര ജീവിത സമന്വയ മണ്ഡലം 🔗',
      AppLanguage.manglish => '🔗 Sacred 5 Pillars Mandala of Harmony 🔗',
      AppLanguage.english => '🔗 Sacred 5-Pillar Mandala of Life Harmony 🔗',
    };
    final conn4 = switch (lang) {
      AppLanguage.telugu => '🌸 సమగ్ర దైనందిన వేద జీవన ప్రవాహం 🌸',
      AppLanguage.tanglish => '🌸 Daily Vedic Routine Stream 🌸',
      AppLanguage.malayalam => '🌸 സമഗ്ര ദൈനംദിന വേദ ജീവിത പ്രവാഹം 🌸',
      AppLanguage.manglish => '🌸 Daily Vedic Routine Stream 🌸',
      AppLanguage.english => '🌸 Integrated Daily Vedic Routine Stream 🌸',
    };
    final conn5 = switch (lang) {
      AppLanguage.telugu => '✨ ప్రశాంత మనస్సు ➔ ఆత్మ సమతుల్యత ✨',
      AppLanguage.tanglish => '✨ Peaceful Mind ➔ Soul Equilibrium ✨',
      AppLanguage.malayalam => '✨ പ്രശാന്ത മനസ്സ് ➔ ആത്മീയ സന്തുലിതാവസ്ഥ ✨',
      AppLanguage.manglish => '✨ Peaceful Mind ➔ Soul Equilibrium ✨',
      AppLanguage.english => '✨ Peaceful Mind Shapes Soul Equilibrium ✨',
    };
    final conn6 = switch (lang) {
      AppLanguage.telugu => '📊 దైనందిన ఆరోగ్య & ఆధ్యాత్మిక ప్రగతి నివేదికలు 📊',
      AppLanguage.tanglish => '📊 Daily Wellness & Spiritual Growth Reports 📊',
      AppLanguage.malayalam => '📊 ദൈനംദിന ആരോഗ്യ & ആത്മീയ പുരോഗതി റിപ്പോർട്ടുകൾ 📊',
      AppLanguage.manglish => '📊 Daily Wellness & Spiritual Growth Reports 📊',
      AppLanguage.english => '📊 Daily Wellness & Spiritual Growth Reports 📊',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sacred Vedic Sanctuary Arched Header & Daily Sloka Card with Audio
        SacredVedicSanctuaryCard(
          userName: widget.userName,
          onOpenAyurveda: () => _navigateToPillar(1), // Health
          onOpenWalk: () => _navigateToPillar(2), // Habits
          onOpenBlessings: () => _navigateToPillar(0), // Astrology
        ),
        FlowConduitConnector(title: conn1),

        // 2. 108-Bead Sacred Japa Mala Counter (Tap to chant)
        const SacredJapaMalaCounterWidget(),
        FlowConduitConnector(title: conn2),

        // 3. Ayurvedic Tridosha Vitality Wheel (Vata, Pitta, Kapha)
        const AyurvedicTridoshaWheel(),
        const SizedBox(height: 14),

        // Creative Graphic: Sacred 7-Chakra Vitality & Diya Meditation
        const SacredChakraKundaliniMandala(),
        FlowConduitConnector(title: conn3),

        // 4. Sacred 5-Pillar Mandala of Life Harmony
        ConnectedPillarsNexusWidget(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn4),

        // 5. Chronological Spiritual Daily Routine
        UnifiedHolisticSynergyStream(onOpenPillar: _navigateToPillar),
        FlowConduitConnector(title: conn5),

        // 6. Holistic Life Radar
        const HolisticRadarSynergyChart(),
        FlowConduitConnector(title: conn6),

        // 7. Daily Reports
        _buildDailyReportsSection(context),
      ],
    );
  }

  Widget _buildAgeAdaptiveCard(BuildContext context) {
    final ageService = AgeProfileService.instance;
    final activeTheme = ageService.activeTheme;
    final currentLang = AppLanguageService.instance.currentLanguage;

    final themeDisplayName = switch (ageService.ageGroup) {
      AgeGroup.youth => switch (currentLang) {
          AppLanguage.telugu => '⚡ యువత & విద్యార్థి (< 22)',
          AppLanguage.tanglish => '⚡ Youth & Student (< 22)',
          AppLanguage.malayalam => '⚡ യുവാക്കൾ & വിദ്യാർത്ഥി (< 22)',
          AppLanguage.manglish => '⚡ Youth & Student (< 22)',
          AppLanguage.english => '⚡ Youth & Explorer (< 22)',
        },
      AgeGroup.adult => switch (currentLang) {
          AppLanguage.telugu => '💼 ఎగ్జిక్యూటివ్ ప్రవాహం (22 - 45)',
          AppLanguage.tanglish => '💼 Executive Flow (22 - 45)',
          AppLanguage.malayalam => '💼 എക്സിക്യൂട്ടീവ് ഫ്ലോ (22 - 45)',
          AppLanguage.manglish => '💼 Executive Flow (22 - 45)',
          AppLanguage.english => '💼 Executive Harmony (22 - 45)',
        },
      AgeGroup.senior => switch (currentLang) {
          AppLanguage.telugu => '🌸 వేద శాంతి & సౌభాగ్యం (45+)',
          AppLanguage.tanglish => '🌸 Veda Shanti & Soubhagyam (45+)',
          AppLanguage.malayalam => '🌸 വേദ ശാന്തിയും സൗഭാഗ്യവും (45+)',
          AppLanguage.manglish => '🌸 Veda Shanthiyum Soubhagyavum (45+)',
          AppLanguage.english => '🌸 Grace & Vedic Serenity (45+)',
        },
    };

    final themeTagline = switch (ageService.ageGroup) {
      AgeGroup.youth => switch (currentLang) {
          AppLanguage.telugu => 'సైబర్‌-గ్లో ఆరా, XP క్వెస్ట్‌లు & ఫోకస్ పాడ్స్ 🚀',
          AppLanguage.tanglish => 'Cyber-Glow Aura, XP Quests & Focus Pods 🚀',
          AppLanguage.malayalam => 'സൈബർ ഗ്ലോ പ്രഭാവലയം, XP ക്വസ്റ്റുകൾ & ഫോക്കസ് പോഡുകൾ 🚀',
          AppLanguage.manglish => 'Cyber-Glow Aura, XP Quests & Focus Pods 🚀',
          AppLanguage.english => 'Cyber-Glow Aura, Mind Quests & Focus Pods 🚀',
        },
      AgeGroup.adult => switch (currentLang) {
          AppLanguage.telugu => 'సర్కాడియన్ వేవ్ రిథమ్ & ఎగ్జిక్యూటివ్ సమతుల్యత ⚖️',
          AppLanguage.tanglish => 'Circadian Wave Rhythm & Executive Balance ⚖️',
          AppLanguage.malayalam => 'സർക്കാഡിയൻ വേവ് റിഥം & എക്സിക്യൂട്ടീവ് സന്തുലിതാവസ്ഥ ⚖️',
          AppLanguage.manglish => 'Circadian Wave Rhythm & Executive Balance ⚖️',
          AppLanguage.english => 'Circadian Wave Dynamics & Peak Productivity Flow ⚖️',
        },
      AgeGroup.senior => switch (currentLang) {
          AppLanguage.telugu => '108 రుద్రాక్ష జపమాల, వేద శ్లోకాలు & ఆయుర్వేద చక్రం 📿',
          AppLanguage.tanglish => '108 Rudraksha Japamala, Veda Slokas & Ayurveda Chakram 📿',
          AppLanguage.malayalam => '108 രുദ്രാക്ഷ ജപമാല, വേദ ശ്ലോകങ്ങൾ & ആയുർവേദ ചക്രം 📿',
          AppLanguage.manglish => '108 Rudraksha Japamala, Veda Slokas & Ayurveda Chakram 📿',
          AppLanguage.english => '108 Rudraksha Japa Mala, Sacred Slokas & Ayurvedic Wheel 📿',
        },
    };

    final themeStyleDesc = switch (ageService.ageGroup) {
      AgeGroup.youth => switch (currentLang) {
          AppLanguage.telugu => 'కన్స్టెల్లేషన్ లేజర్ కణాలు & నియోన్ సైబర్ పల్స్',
          AppLanguage.tanglish => 'Constellation laser particles & neon cyber pulse',
          AppLanguage.malayalam => 'കോൺസ്റ്റലേഷൻ ലേസർ കണങ്ങളും നിയോൺ സൈബർ പൾസും',
          AppLanguage.manglish => 'Constellation laser particles & neon cyber pulse',
          AppLanguage.english => 'Constellation laser particles & neon cyber pulse',
        },
      AgeGroup.adult => switch (currentLang) {
          AppLanguage.telugu => 'హార్మోనిక్ సర్కాడియన్ వేవ్ & ఎగ్జిక్యూటివ్ రిథమ్',
          AppLanguage.tanglish => 'Harmonic circadian wave & executive rhythm',
          AppLanguage.malayalam => 'ഹാർമോണിക് സർക്കാഡിയൻ വേവും എക്സിക്യൂട്ടീവ് റിഥവും',
          AppLanguage.manglish => 'Harmonic circadian wave & executive rhythm',
          AppLanguage.english => 'Harmonic circadian wave & biometric executive rhythm',
        },
      AgeGroup.senior => switch (currentLang) {
          AppLanguage.telugu => 'వికసించే బంగారు పద్మ ఆరా & వేద గంట మ్రోత',
          AppLanguage.tanglish => 'Vikasinchay bangaru padma aura & veda ganta mrotha',
          AppLanguage.malayalam => 'വിരിയുന്ന സുവർണ്ണ താമര പ്രഭാവലയവും വേദ മണിനാദവും',
          AppLanguage.manglish => 'Viriyunna swarna thaamara auroyum veda maninadavum',
          AppLanguage.english => 'Blooming golden sacred lotus aura & temple bell chime',
        },
    };

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
                            themeDisplayName,
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
                      themeTagline,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Artistic Aura: $themeStyleDesc',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.85),
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
    final tr = AppLanguageService.instance.tr;
    final lang = AppLanguageService.instance.currentLanguage;
    final factsLabel = switch (lang) {
      AppLanguage.telugu => '💡 వాస్తవాలు',
      AppLanguage.malayalam => '💡 വസ്തുതകൾ',
      _ => '💡 Facts',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tr('daily_growth_report'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => FactPopup.show(context),
              icon: const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.blue),
              label: Text(factsLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  AgeGroup.youth => switch (currentLang) {
                      AppLanguage.telugu => '⚡ హలో, అన్వేషకుడా!',
                      AppLanguage.tanglish => '⚡ Hello, explorer!',
                      AppLanguage.malayalam => '⚡ നമസ്കാരം, പര്യവേക്ഷകാ!',
                      AppLanguage.manglish => '⚡ Hello, explorer!',
                      AppLanguage.english => '⚡ Hey there, explorer!',
                    },
                  AgeGroup.adult => _greetingPrefix(),
                  AgeGroup.senior => switch (currentLang) {
                      AppLanguage.telugu => '🌸 నమస్తే, శాంతి మరియు సంపూర్ణ ఆరోగ్యం.',
                      AppLanguage.tanglish => '🌸 Namaste, shanti mariyu sampoorna arogyam.',
                      AppLanguage.malayalam => '🌸 നമസ്തേ, ശാന്തിയും പൂർണ്ണ ആരോഗ്യവും.',
                      AppLanguage.manglish => '🌸 Namaste, shanthiyum poorna aarogyavum.',
                      AppLanguage.english => '🌸 Namaste, peace & good health.',
                    },
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
                  AgeGroup.senior => switch (currentLang) {
                      AppLanguage.telugu => '${widget.userName} గారు 🙏',
                      AppLanguage.tanglish => '${widget.userName} garu 🙏',
                      AppLanguage.malayalam => '${widget.userName} അവർകൾ 🙏',
                      AppLanguage.manglish => '${widget.userName} ji 🙏',
                      AppLanguage.english => '${widget.userName} ji 🙏',
                    },
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

  void _showYouthPomodoroModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF13092C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return _YouthPomodoroSheet(
          onCompleted: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚡ +50 XP Awarded! Astral Focus Sprint Completed! 🚀'),
                backgroundColor: Color(0xFF6C5CE7),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  void _showYouthBreathingModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return const _YouthBreathingSheet();
      },
    );
  }

  void _showYouthDetoxModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13092C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF00CEC9)),
        ),
        title: const Row(
          children: [
            Icon(Icons.phonelink_erase_rounded, color: Color(0xFF55EFC4), size: 26),
            SizedBox(width: 10),
            Text('Dopamine Detox Pod', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset your neurochemical dopamine baseline:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('• 1 Hour Zero-Screen Deep Study or Walking', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            Text('• No social media reels or notifications', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            Text('• Replenishes prefrontal attention span by 40%', style: TextStyle(color: Color(0xFF55EFC4), fontSize: 13, fontWeight: FontWeight.bold, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚡ +30 XP! 1-Hour Dopamine Detox Challenge Started!'),
                  backgroundColor: Color(0xFF00CEC9),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CEC9),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Detox (+30 XP)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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

/// Interactive 25-minute Pomodoro timer bottom sheet for Youth mode.
class _YouthPomodoroSheet extends StatefulWidget {
  const _YouthPomodoroSheet({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_YouthPomodoroSheet> createState() => _YouthPomodoroSheetState();
}

class _YouthPomodoroSheetState extends State<_YouthPomodoroSheet> {
  static const int _totalSeconds = 25 * 60;
  int _secondsRemaining = _totalSeconds;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          widget.onCompleted();
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalSeconds;
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_secondsRemaining / _totalSeconds);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFFFEAA7), size: 24),
                  SizedBox(width: 8),
                  Text(
                    '25m Cyber Focus Pod',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Circular Neon Timer Disc
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00CEC9)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRunning ? 'FOCUSING...' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: _isRunning ? const Color(0xFF55EFC4) : Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                label: const Text('Reset', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
                label: Text(
                  _isRunning ? 'Pause Sprint' : 'Start Focus (+50 XP)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CEC9),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '💡 Mercury Hora is active. Deep work blocks finish 30% faster today!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

/// Guided 4-7-8 Exam Calm Cosmic Breathing Orb sheet for Youth mode.
class _YouthBreathingSheet extends StatefulWidget {
  const _YouthBreathingSheet();

  @override
  State<_YouthBreathingSheet> createState() => _YouthBreathingSheetState();
}

class _YouthBreathingSheetState extends State<_YouthBreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  int _phase = 0; // 0: Inhale (4s), 1: Hold (7s), 2: Exhale (8s)
  Timer? _phaseTimer;

  static const List<Map<String, dynamic>> _phases = [
    {'title': 'INHALING (4s)', 'sub': 'Draw in calm cosmic oxygen', 'color': Color(0xFF74B9FF), 'scale': 1.3},
    {'title': 'HOLDING (7s)', 'sub': 'Settle your heart rate & mind', 'color': Color(0xFFA29BFE), 'scale': 1.3},
    {'title': 'EXHALING (8s)', 'sub': 'Release all exam tension & anxiety', 'color': Color(0xFF55EFC4), 'scale': 0.8},
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startCycle();
  }

  void _startCycle() {
    _stepPhase(0);
  }

  void _stepPhase(int p) {
    if (!mounted) return;
    setState(() => _phase = p);

    int dur = 4;
    if (p == 0) {
      dur = 4;
      _breathController.animateTo(1.0, duration: const Duration(seconds: 4));
    } else if (p == 1) {
      dur = 7;
    } else if (p == 2) {
      dur = 8;
      _breathController.animateTo(0.0, duration: const Duration(seconds: 8));
    }

    _phaseTimer = Timer(Duration(seconds: dur), () {
      if (mounted) {
        _stepPhase((p + 1) % 3);
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _phases[_phase];
    final color = cur['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.air_rounded, color: Color(0xFF74B9FF), size: 24),
                  SizedBox(width: 8),
                  Text(
                    '4-7-8 Cosmic Pranayama',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Pulsing Glow Breathing Orb
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, _) {
              final scale = 0.8 + (_breathController.value * 0.4);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cur['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),

          Text(
            cur['sub'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Done Breathing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
