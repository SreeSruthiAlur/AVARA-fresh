import 'package:flutter/material.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';

/// A sleek microphone button that attaches to any [TextEditingController].
///
/// When tapped:
/// - Listens via [VoiceService] to what the user speaks.
/// - Displays a prominent floating live status indicator with real-time transcription.
/// - Automatically enters the recognized speech directly into [controller].
/// - Detects spoken commands (e.g. "Change to Telugu", "Open Astrology") and executes them.
/// - Animates a pulsing recording ring and live soundwave feedback while listening.
/// - Provides clear Chrome permission guidance if microphone access is blocked.
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
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    VoiceService.instance.addListener(_onVoiceServiceChanged);
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onVoiceServiceChanged() {
    if (!mounted) return;
    final voice = VoiceService.instance;
    if (voice.errorMessage != null && _isListening) {
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      _showFloatingStatusOverlay(
        text: '⚠️ ${voice.errorMessage!}',
        isListening: false,
        isError: true,
      );
      Future.delayed(const Duration(seconds: 4), _removeOverlay);
    } else if (!voice.isListening && _isListening) {
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    VoiceService.instance.removeListener(_onVoiceServiceChanged);
    _removeOverlay();
    _pulseController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showFloatingStatusOverlay({
    required String text,
    bool isListening = true,
    bool isSuccess = false,
    bool isError = false,
  }) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 84,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFC62828)
                  : (isSuccess
                      ? const Color(0xFF1B5E20)
                      : (isListening ? AppColors.deepNavy : const Color(0xFF37474F))),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isListening) ...[
                  const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                ] else if (isSuccess) ...[
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                ] else if (isError) ...[
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isListening)
                  GestureDetector(
                    onTap: _stopListening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  Future<void> _stopListening() async {
    final voice = VoiceService.instance;
    await voice.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      Future.delayed(const Duration(milliseconds: 1500), _removeOverlay);
    }
  }

  Future<void> _toggleListening() async {
    final voice = VoiceService.instance;

    if (_isListening) {
      await _stopListening();
      return;
    }

    setState(() => _isListening = true);
    _pulseController.forward();
    _showFloatingStatusOverlay(text: '🔴 Listening... Speak clearly now');

    final success = await voice.initialize();
    if (!success) {
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
        _removeOverlay();
        _showPermissionHelpDialog();
      }
      return;
    }

    final initialText = widget.append ? widget.controller.text : '';

    await voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;

        // 1. In real-time while listening: immediately type what the user is saying into the text field
        if (text.trim().isNotEmpty) {
          if (widget.append && initialText.isNotEmpty) {
            widget.controller.text = '$initialText $text';
          } else {
            widget.controller.text = text;
          }
          // Move cursor to end so user sees typing progression
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );

          // Update live preview in floating banner
          _showFloatingStatusOverlay(text: '🎙️ Heard: "$text"');
        }

        // 2. When speech is finalized (after speaking or natural pause): do what the user asked
        if (isFinal) {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();

          if (text.trim().isNotEmpty) {
            // First check if the finalized statement is an app command (e.g. "change to telugu")
            final commandResult = voice.tryExecuteCommand(text);
            if (commandResult != null &&
                (commandResult.type == VoiceCommandType.changeLanguage ||
                    (widget.onSpeechComplete == null &&
                        commandResult.type != VoiceCommandType.dictateText))) {
              _showFloatingStatusOverlay(
                text: '✅ ${commandResult.feedbackMessage ?? "Command executed!"}',
                isListening: false,
                isSuccess: true,
              );
              Future.delayed(const Duration(seconds: 2), _removeOverlay);
              return;
            }

            // Automatically execute the action (e.g. submit question in Chat screen)
            if (widget.onSpeechComplete != null) {
              widget.onSpeechComplete!();
            }

            _showFloatingStatusOverlay(
              text: '✅ Captured: "$text"',
              isListening: false,
              isSuccess: true,
            );
          } else {
            _showFloatingStatusOverlay(
              text: 'No words detected. Try again.',
              isListening: false,
              isSuccess: false,
            );
          }
          Future.delayed(const Duration(seconds: 2), _removeOverlay);
        }
      },
    );
  }

  /// Dialog shown if microphone hardware or Chrome permissions are blocked.
  void _showPermissionHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text('Microphone Access', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AVARA needs permission to listen to your voice input.\n',
              style: TextStyle(fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('In Google Chrome:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('1. Look at the top address bar next to "localhost".', style: TextStyle(fontSize: 12)),
                  Text('2. Click the 🔒 lock or tune icon.', style: TextStyle(fontSize: 12)),
                  Text('3. Toggle Microphone to "Allow".', style: TextStyle(fontSize: 12)),
                  Text('4. Tap the microphone again to speak.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showFallbackDictationDialog();
            },
            child: const Text('Quick Voice Phrases'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _toggleListening();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry Microphone'),
          ),
        ],
      ),
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
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _isListening ? Colors.redAccent : widget.inactiveColor,
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
