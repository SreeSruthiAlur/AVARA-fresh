import 'package:flutter/material.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';

/// A sleek microphone button that attaches to any [TextEditingController].
///
/// When tapped:
/// - Listens via [VoiceService] to what the user speaks.
/// - Automatically enters the recognized speech directly into [controller].
/// - Animates a pulsing recording ring while listening.
/// - Provides a fallback quick-dictation sheet if speech hardware is unavailable.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.controller,
    this.append = false,
    this.size = 20,
    this.activeColor = AppColors.blue,
    this.inactiveColor = AppColors.secondaryText,
    this.onSpeechComplete,
    this.tooltip,
  });

  /// The text controller where voice recognition will enter text.
  final TextEditingController controller;

  /// Whether to append to existing text or replace it.
  final bool append;

  /// Icon size.
  final double size;

  /// Color when active/recording.
  final Color activeColor;

  /// Color when idle.
  final Color inactiveColor;

  /// Optional callback invoked when voice recognition finishes.
  final VoidCallback? onSpeechComplete;

  /// Custom tooltip.
  final String? tooltip;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final voice = VoiceService.instance;

    if (_isListening) {
      await voice.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
      }
      return;
    }

    setState(() => _isListening = true);
    _pulseController.forward();

    final success = await voice.initialize();
    if (!success) {
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
        _showFallbackDictationDialog();
      }
      return;
    }

    final initialText = widget.append ? widget.controller.text : '';

    await voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        if (text.trim().isNotEmpty) {
          if (widget.append && initialText.isNotEmpty) {
            widget.controller.text = '$initialText $text';
          } else {
            widget.controller.text = text;
          }
          // Move cursor to end
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }

        if (isFinal) {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
          widget.onSpeechComplete?.call();
        }
      },
    );
  }

  /// Fallback modal if microphone hardware or permissions are unavailable.
  void _showFallbackDictationDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FallbackDictationSheet(
        controller: widget.controller,
        onSubmitted: (text) {
          widget.controller.text = text;
          widget.onSpeechComplete?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLanguageService.instance.tr;

    return Tooltip(
      message: widget.tooltip ?? tr('voice_tap_to_speak'),
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? widget.activeColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? widget.activeColor : widget.inactiveColor,
                  size: widget.size,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fallback quick voice simulator & tester sheet
class _FallbackDictationSheet extends StatelessWidget {
  const _FallbackDictationSheet({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    final currentLang = AppLanguageService.instance.currentLanguage;

    final samples = _samplePhrasesFor(currentLang);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('voice_assistant_title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Voice entry assistance & quick phrases',
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
          const SizedBox(height: 16),
          Text(
            'Quick Voice Entry Options:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sample in samples)
                ActionChip(
                  label: Text(sample, style: const TextStyle(fontSize: 13)),
                  backgroundColor: AppColors.lavender.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () {
                    onSubmitted(sample);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('btn_close')),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _samplePhrasesFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return [
          'What does my Moon sign say?',
          'Tell me about my career',
          'Bengaluru',
          'Coffee 150',
          'Good morning walk',
        ];
      case AppLanguage.telugu:
        return [
          'నా చంద్ర రాశి ఏమిటి?',
          'నా కెరీర్ గురించి చెప్పండి',
          'హైదరాబాద్',
          'కాఫీ ఖర్చు 150',
          'ఉదయం నడక అలవాటు',
        ];
      case AppLanguage.tanglish:
        return [
          'Naa Moon sign gurinchi cheppu',
          'Naa career ela untundi?',
          'Hyderabad',
          'Snacks 150',
          'Morning walk chesanu',
        ];
    }
  }
}
