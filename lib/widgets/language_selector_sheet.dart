import 'package:flutter/material.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';

/// Interactive modal sheet to switch visual display language (English, Telugu, Tanglish).
///
/// Supports both:
/// 1. Direct visual tap on language card.
/// 2. Voice recognition: speak "Change to Telugu", "Tanglish lo marchu", or "Switch to English"!
class LanguageSelectorSheet extends StatefulWidget {
  const LanguageSelectorSheet({super.key});

  /// Static helper to display the sheet from anywhere in the app.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSelectorSheet(),
    );
  }

  @override
  State<LanguageSelectorSheet> createState() => _LanguageSelectorSheetState();
}

class _LanguageSelectorSheetState extends State<LanguageSelectorSheet> {
  bool _isListening = false;
  String _spokenVoiceFeedback = '';

  @override
  void dispose() {
    VoiceService.instance.stopListening();
    super.dispose();
  }

  Future<void> _startVoiceLanguageChange() async {
    final voice = VoiceService.instance;
    if (_isListening) {
      await voice.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _spokenVoiceFeedback = 'Listening... Say "Telugu", "Tanglish", or "English"';
    });

    final ready = await voice.initialize();
    if (!ready) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _spokenVoiceFeedback = 'Microphone unavailable. Please tap an option below.';
        });
      }
      return;
    }

    await voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _spokenVoiceFeedback = 'Heard: "$text"';
        });

        final result = voice.parseAndExecuteCommand(text);
        if (result.type == VoiceCommandType.changeLanguage) {
          voice.stopListening();
          setState(() {
            _isListening = false;
            _spokenVoiceFeedback = result.feedbackMessage ?? 'Language updated!';
          });
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) Navigator.of(context).pop();
          });
        } else if (isFinal) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langService = AppLanguageService.instance;
    final currentLang = langService.currentLanguage;
    final tr = langService.tr;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Title & Voice Mic Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: AppColors.blue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('lang_switch_title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('lang_switch_subtitle'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Voice Command Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.lightOrange.withValues(alpha: 0.6)
                  : AppColors.lightBlue.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListening ? AppColors.orange : AppColors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _startVoiceLanguageChange,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening ? AppColors.orange : AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isListening
                            ? tr('voice_listening')
                            : 'Use Voice to Change Language',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _isListening ? AppColors.orange : AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _spokenVoiceFeedback.isNotEmpty
                            ? _spokenVoiceFeedback
                            : 'Tap mic & say "Telugu", "Tanglish", or "English"',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3 Language Cards
          _buildLanguageCard(
            context: context,
            language: AppLanguage.english,
            title: 'English',
            nativeTitle: 'English (Default)',
            sampleText: 'Welcome to AVARA Astrology & Guidance',
            isSelected: currentLang == AppLanguage.english,
          ),
          const SizedBox(height: 12),
          _buildLanguageCard(
            context: context,
            language: AppLanguage.telugu,
            title: 'తెలుగు (Telugu)',
            nativeTitle: 'పూర్తి తెలుగు లిపి',
            sampleText: 'AVARA జ్యోతిషం మరియు మార్గదర్శకంలోకి స్వాగతం',
            isSelected: currentLang == AppLanguage.telugu,
          ),
          const SizedBox(height: 12),
          _buildLanguageCard(
            context: context,
            language: AppLanguage.tanglish,
            title: 'Tanglish',
            nativeTitle: 'Telugu in English Letters',
            sampleText: 'AVARA Jathakam mariyu guidance loki swagatham',
            isSelected: currentLang == AppLanguage.tanglish,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required AppLanguage language,
    required String title,
    required String nativeTitle,
    required String sampleText,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        await AppLanguageService.instance.setLanguage(language);
        if (mounted) Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightBlue.withValues(alpha: 0.8)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          nativeTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sampleText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.blue
                          : AppColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.blue, size: 24)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}
