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
              subtitle: 'Modern energetic graphics • Studies, exams, passion & self-discovery',
              isSelected: _selectedAgeGroup == AgeGroup.youth,
              onTap: () => setState(() => _selectedAgeGroup = AgeGroup.youth),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.work_outline_rounded,
              title: 'Achiever & Professional (22 - 45)',
              subtitle: 'Sleek executive visuals • Career growth, financial mindfulness & balance',
              isSelected: _selectedAgeGroup == AgeGroup.adult,
              onTap: () => setState(() => _selectedAgeGroup = AgeGroup.adult),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.spa_rounded,
              title: 'Grace & Serenity (45+)',
              subtitle: 'Warm high-contrast sacred art • Inner peace, daily health & family harmony',
              isSelected: _selectedAgeGroup == AgeGroup.senior,
              onTap: () => setState(() => _selectedAgeGroup = AgeGroup.senior),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _optionTile(
              icon: Icons.self_improvement_rounded,
              title: 'Inner Peace & Mental Calm',
              subtitle: 'Stress reduction, clarity, and daily mindfulness rituals',
              isSelected: _selectedFocus == 'Inner Peace & Mental Calm',
              onTap: () => setState(() => _selectedFocus = 'Inner Peace & Mental Calm'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.rocket_launch_rounded,
              title: 'Career & Financial Growth',
              subtitle: 'Right livelihood, productive focus, and mindful wealth building',
              isSelected: _selectedFocus == 'Career & Financial Growth',
              onTap: () => setState(() => _selectedFocus = 'Career & Financial Growth'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.favorite_rounded,
              title: 'Love & Family Relationships',
              subtitle: 'Harmony, compatibility, and deeper emotional understanding',
              isSelected: _selectedFocus == 'Love & Family Relationships',
              onTap: () => setState(() => _selectedFocus = 'Love & Family Relationships'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.track_changes_rounded,
              title: 'Habit Mastery & Vitality',
              subtitle: 'Healthy circadian routine, fitness, and daily consistency',
              isSelected: _selectedFocus == 'Habit Mastery & Vitality',
              onTap: () => setState(() => _selectedFocus = 'Habit Mastery & Vitality'),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _optionTile(
              icon: Icons.timer_off_rounded,
              title: 'Procrastination & Inconsistent Routine',
              subtitle: 'Want to replace delays with steady, effortless daily execution',
              isSelected: _selectedChallenge == 'Inconsistent Routine & Procrastination',
              onTap: () => setState(() => _selectedChallenge = 'Inconsistent Routine & Procrastination'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.psychology_alt_rounded,
              title: 'Overthinking & Restless Anxiety',
              subtitle: 'Mind runs ahead with worry; need grounding breath & Vedic calm',
              isSelected: _selectedChallenge == 'Overthinking & Restless Anxiety',
              onTap: () => setState(() => _selectedChallenge = 'Overthinking & Restless Anxiety'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.bedtime_rounded,
              title: 'Late Bedtimes & Low Morning Energy',
              subtitle: 'Late night phone usage and waking up tired or sluggish',
              isSelected: _selectedChallenge == 'Late Bedtimes & Low Morning Energy',
              onTap: () => setState(() => _selectedChallenge = 'Late Bedtimes & Low Morning Energy'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.payments_rounded,
              title: 'Impulsive Spending & Budget Stress',
              subtitle: 'Want to build financial discipline and cut emotional purchases',
              isSelected: _selectedChallenge == 'Impulsive Spending & Budget Stress',
              onTap: () => setState(() => _selectedChallenge = 'Impulsive Spending & Budget Stress'),
            ),
          ],
        );
      case 3:
      default:
        return Column(
          children: [
            _optionTile(
              icon: Icons.checklist_rtl_rounded,
              title: 'Practical & Action-Oriented Steps',
              subtitle: 'Direct micro-habits, progress percentages, and behavioral science',
              isSelected: _selectedStyle == 'Practical & Action-Oriented Steps',
              onTap: () => setState(() => _selectedStyle = 'Practical & Action-Oriented Steps'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.auto_awesome,
              title: 'Gentle Vedic & Spiritual Insights',
              subtitle: 'Deeper planetary wisdom, timeless Vedic principles, and karma flow',
              isSelected: _selectedStyle == 'Gentle Vedic & Spiritual Insights',
              onTap: () => setState(() => _selectedStyle = 'Gentle Vedic & Spiritual Insights'),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.wb_sunny_rounded,
              title: 'Balanced Holistic Companion',
              subtitle: 'The best of both: ancient wisdom backed by everyday science',
              isSelected: _selectedStyle == 'Balanced Holistic Companion',
              onTap: () => setState(() => _selectedStyle = 'Balanced Holistic Companion'),
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
