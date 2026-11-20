import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/survey_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Interactive Onboarding Self-Help Survey shown when a user logs in or enters as a guest.
///
/// Collects age group (to dynamically power creative graphics) and life priorities
/// to personalize AVARA as a true self-help companion.
class SurveyModal extends StatefulWidget {
  const SurveyModal({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  static Future<void> show(BuildContext context, {required VoidCallback onCompleted}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SurveyModal(onCompleted: onCompleted),
    );
  }

  @override
  State<SurveyModal> createState() => _SurveyModalState();
}

class _SurveyModalState extends State<SurveyModal> {
  int _currentStep = 0;

  AgeGroup _selectedAgeGroup = AgeGroup.adult;
  String _selectedFocus = 'Inner Peace & Mental Calm';
  String _selectedChallenge = 'Inconsistent Routine & Procrastination';
  String _selectedStyle = 'Practical & Action-Oriented Steps';

  final List<String> _stepTitles = [
    'Welcome! What is your age group?',
    'What is your main focus right now?',
    'What daily challenge do you want to conquer?',
    'How should AVARA guide you?',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar & Step Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.self_improvement_rounded, color: AppColors.blue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'AVARA Self-Help Survey (${_currentStep + 1}/4)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _finishSurvey,
                  child: const Text('Skip', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 20),

            // Question Header
            Text(
              _stepTitles[_currentStep],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _stepSubtitles[_currentStep],
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            // Step Content
            _buildStepContent(),
            const SizedBox(height: 24),

            // Navigation Buttons
            Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Back', style: TextStyle(color: AppColors.deepNavy)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _finishSurvey();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _currentStep == 3 ? 'Personalize My AVARA' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _stepSubtitles = [
    'Helps us tune graphics, readability, and content specifically for your generation.',
    'Select the life area where you seek the greatest clarity and progress today.',
    'AVARA will design micro-habit steps to transform this into your superpower.',
    'Choose the coaching tone that feels most natural and uplifting to you.',
  ];

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            _optionTile(
              icon: Icons.school_rounded,
              title: 'Youth & Explorer (Under 22)',
              subtitle: 'Modern energetic visuals • Studies, exams, passion & self-discovery',
              isSelected: _selectedAgeGroup == AgeGroup.youth,
              onTap: () {
                setState(() {
                  _selectedAgeGroup = AgeGroup.youth;
                  _selectedFocus = AgeProfileService.instance.getSurveyFocusOptions(AgeGroup.youth).first.title;
                  _selectedChallenge = AgeProfileService.instance.getSurveyChallengeOptions(AgeGroup.youth).first.title;
                });
              },
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.work_outline_rounded,
              title: 'Achiever & Professional (22 - 45)',
              subtitle: 'Sleek executive visuals • Career growth, financial mindfulness & balance',
              isSelected: _selectedAgeGroup == AgeGroup.adult,
              onTap: () {
                setState(() {
                  _selectedAgeGroup = AgeGroup.adult;
                  _selectedFocus = AgeProfileService.instance.getSurveyFocusOptions(AgeGroup.adult).first.title;
                  _selectedChallenge = AgeProfileService.instance.getSurveyChallengeOptions(AgeGroup.adult).first.title;
                });
              },
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.spa_rounded,
              title: 'Grace & Serenity (45+)',
              subtitle: 'Warm high-contrast sacred art • Inner peace, daily health & family harmony',
              isSelected: _selectedAgeGroup == AgeGroup.senior,
              onTap: () {
                setState(() {
                  _selectedAgeGroup = AgeGroup.senior;
                  _selectedFocus = AgeProfileService.instance.getSurveyFocusOptions(AgeGroup.senior).first.title;
                  _selectedChallenge = AgeProfileService.instance.getSurveyChallengeOptions(AgeGroup.senior).first.title;
                });
              },
            ),
          ],
        );
      case 1:
        final focusOptions = AgeProfileService.instance.getSurveyFocusOptions(_selectedAgeGroup);
        return Column(
          children: focusOptions.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _optionTile(
                icon: opt.icon,
                title: opt.title,
                subtitle: opt.subtitle,
                isSelected: _selectedFocus == opt.title,
                onTap: () => setState(() => _selectedFocus = opt.title),
              ),
            );
          }).toList(),
        );
      case 2:
        final challengeOptions = AgeProfileService.instance.getSurveyChallengeOptions(_selectedAgeGroup);
        return Column(
          children: challengeOptions.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _optionTile(
                icon: opt.icon,
                title: opt.title,
                subtitle: opt.subtitle,
                isSelected: _selectedChallenge == opt.title,
                onTap: () => setState(() => _selectedChallenge = opt.title),
              ),
            );
          }).toList(),
        );
      case 3:
      default:
        final toneTitle = _selectedAgeGroup == AgeGroup.youth
            ? 'High-Energy & Gamified Streaks'
            : (_selectedAgeGroup == AgeGroup.senior
                ? 'Serene, Reverent & Peaceful'
                : 'Action-Oriented & Executive Steps');
        final toneSub = _selectedAgeGroup == AgeGroup.youth
            ? 'Fast, encouraging prompts with level-ups and energetic motivation'
            : (_selectedAgeGroup == AgeGroup.senior
                ? 'Comforting Vedic wisdom with gentle warmth and spiritual calmness'
                : 'Clear, structured milestones that fit a demanding daily routine');

        return Column(
          children: [
            _optionTile(
              icon: Icons.bolt_rounded,
              title: toneTitle,
              subtitle: toneSub,
              isSelected: _selectedStyle == toneTitle || _selectedStyle == 'Practical & Action-Oriented Steps',
              onTap: () => setState(() => _selectedStyle = toneTitle),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.psychology_rounded,
              title: 'Science & Behavioral Neuroscience',
              subtitle: 'Explains dopamine, prefrontal focus, and neuroplasticity facts',
              isSelected: _selectedStyle == 'Science & Behavioral Neuroscience',
              onTap: () => setState(() => _selectedStyle = 'Science & Behavioral Neuroscience'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.self_improvement_rounded,
              title: 'Timeless Vedic Wisdom',
              subtitle: 'Anchored in Patanjali sutras, dosha balance, and planetary harmony',
              isSelected: _selectedStyle == 'Timeless Vedic Wisdom',
              onTap: () => setState(() => _selectedStyle = 'Timeless Vedic Wisdom'),
            ),
          ],
        );
    }
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.blue : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _finishSurvey() async {
    await SurveyService.instance.saveSurveyResponse(
      ageGroup: _selectedAgeGroup,
      primaryFocus: _selectedFocus,
      habitChallenge: _selectedChallenge,
      guidanceStyle: _selectedStyle,
    );
    if (mounted) {
      Navigator.of(context).pop();
      widget.onCompleted();
    }
  }
}
