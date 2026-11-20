import 'package:avara_astrology_trial/screens/astrologers_screen.dart';
import 'package:avara_astrology_trial/screens/astrology_chat_screen.dart';
import 'package:avara_astrology_trial/screens/explore_topics_screen.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:avara_astrology_trial/widgets/creative_graphics.dart';
import 'package:avara_astrology_trial/widgets/fact_popup.dart';
import 'package:avara_astrology_trial/widgets/language_selector_sheet.dart';
import 'package:flutter/material.dart';

/// AVARA Astrology Hub.
///
/// Three entry points:
/// - **Ask a Question** → [AstrologyChatScreen] (Simple, relatable self-help Q&A)
/// - **Explore Topics** → [ExploreTopicsScreen] (Interactive bubbles for Love, Education, Career — NO chatbot)
/// - **Talk to an Astrologer** → [AstrologersScreen] (🔒 Locked VIP Consultation Feature)
class AstrologyHubScreen extends StatelessWidget {
  const AstrologyHubScreen({super.key, this.apiKey = ''});

  /// Google AI Studio key forwarded to [AstrologyChatScreen].
  final String apiKey;

  void _showLockedAstrologerDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.lock_rounded, size: 34, color: Color(0xFFE65100)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Feature Locked: Astrologer Consultation',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'To ensure personalized guidance, 1-on-1 consultations with verified human astrologers unlock when you complete a 7-day self-help habit streak or enter an invite code.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Self-Help Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('3 of 7 days completed • 4 days remaining to unlock', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AstrologersScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Preview Astrologers Directory', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back to Astrology Hub', style: TextStyle(color: AppColors.secondaryText)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLanguageService.instance.tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('astrology_title'), style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.blue),
            tooltip: 'Scientific Facts & Vedic Wisdom',
            onPressed: () => FactPopup.show(context, category: 'astrology'),
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => LanguageSelectorSheet.show(context),
            tooltip: tr('lang_switch_title'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card
            AvaraSurfaceCard(
              backgroundColor: AppColors.lavender,
              borderColor: null,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('astrology_hero_title'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vedic Self-Help & Life Guidance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Timeless planetary wisdom connected with modern behavioral science to uplift your day.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const ZodiacCelestialOrbitWidget(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation tiles
            _HubTile(
              icon: Icons.auto_awesome,
              iconColor: AppColors.blue,
              iconBg: AppColors.lightBlue,
              label: 'Ask a Question (Everyday Guidance)',
              subtitle: 'Relatable life questions with instant explanations',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AstrologyChatScreen(apiKey: apiKey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Point 6: Explore Topics with Bubbles of Love, Education, Career (NO CHATBOT)
            _HubTile(
              icon: Icons.bubble_chart_rounded,
              iconColor: AppColors.violet,
              iconBg: AppColors.lightPink,
              label: 'Explore Topics (Love, Education, Career)',
              subtitle: 'Interactive self-help bubbles, remedies & science',
              badgeText: 'Interactive Bubbles',
              badgeColor: AppColors.violet,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ExploreTopicsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Point 7: Lock to the Talk to Astrology feature
            _HubTile(
              icon: Icons.person_search_outlined,
              iconColor: const Color(0xFFE65100),
              iconBg: const Color(0xFFFFF3E0),
              label: 'Talk to an Astrologer',
              subtitle: '1-on-1 Certified Pandit Consultation',
              isLocked: true,
              badgeText: '🔒 Locked (VIP)',
              badgeColor: const Color(0xFFE65100),
              onTap: () => _showLockedAstrologerDialog(context),
            ),
            const SizedBox(height: 24),

            // Fact Banner Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Did You Know?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Lunar cycles correlate directly with sleep chronobiology and mood.', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => FactPopup.show(context, category: 'astrology'),
                    child: const Text('Read Fact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              tr('astrology_disclaimer'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isLocked = false,
    this.badgeText,
    this.badgeColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLocked;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.blue).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor ?? AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.chevron_right,
            color: isLocked ? const Color(0xFFE65100) : AppColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
