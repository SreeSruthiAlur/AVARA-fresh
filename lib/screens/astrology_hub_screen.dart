import 'package:avara_astrology_trial/screens/astrologers_screen.dart';
import 'package:avara_astrology_trial/screens/astrology_chat_screen.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// AVARA Astrology hub — mirrors "03 — Astrology" Figma.
///
/// Three entry points:
/// - **Ask a Question** → [AstrologyChatScreen] (AI chat-first)
/// - **Explore Topics** → [AstrologyChatScreen] (AI chat-first)
/// - **Talk to an Astrologer** → [AstrologersScreen] (human directory)
class AstrologyHubScreen extends StatelessWidget {
  const AstrologyHubScreen({super.key, this.apiKey = ''});

  /// Google AI Studio key forwarded to [AstrologyChatScreen].
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AVARA Astrology',
            style: Theme.of(context).textTheme.titleLarge),
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
                    'AVARA Astrology',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ask Questions. Get Perspectives.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.violet,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find Guidance for your journey',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Icon(Icons.nightlight_round,
                        size: 64, color: AppColors.violet),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Navigation tiles
            _HubTile(
              icon: Icons.auto_awesome,
              iconColor: AppColors.blue,
              iconBg: AppColors.lightBlue,
              label: 'Ask a Question',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AstrologyChatScreen(apiKey: apiKey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _HubTile(
              icon: Icons.explore_outlined,
              iconColor: AppColors.violet,
              iconBg: AppColors.lightPink,
              label: 'Explore Topics',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AstrologyChatScreen(apiKey: apiKey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _HubTile(
              icon: Icons.person_search_outlined,
              iconColor: AppColors.tealBlue,
              iconBg: AppColors.lightCyan,
              label: 'Talk to an Astrologer',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AstrologersScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Astrology offers traditional interpretations, not guaranteed outcomes.',
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
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AvaraSurfaceCard(
      backgroundColor: AppColors.white,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.secondaryText, size: 22),
        ],
      ),
    );
  }
}
