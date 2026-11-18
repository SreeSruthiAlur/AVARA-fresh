import 'package:flutter/material.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';

/// Full interactive Voice Assistant Sheet.
///
/// Can be invoked from the global floating mic orb or header button.
/// Features:
/// - Pulsing voice waveform / orb.
/// - Live transcription.
/// - Automatically executes language switches, navigation, and dictation.
/// - Sample command chips in English, Telugu, and Tanglish.
class GlobalVoiceAssistantModal extends StatefulWidget {
  const GlobalVoiceAssistantModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalVoiceAssistantModal(),
    );
  }

  @override
  State<GlobalVoiceAssistantModal> createState() =>
      _GlobalVoiceAssistantModalState();
}

class _GlobalVoiceAssistantModalState extends State<GlobalVoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _transcript = '';
  String _statusMessage = 'Tap the microphone and speak your command';
  VoiceCommandResult? _lastResult;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

    // Auto-start listening on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    VoiceService.instance.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final voice = VoiceService.instance;
    setState(() {
      _isListening = true;
      _transcript = '';
      _statusMessage = 'Listening... Speak now';
      _lastResult = null;
    });
    _pulseController.forward();

    final ok = await voice.initialize();
    if (!ok) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage =
              'Microphone access is unavailable. You can tap any sample command below!';
        });
        _pulseController.stop();
        _pulseController.reset();
      }
      return;
    }

    await voice.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcript = words;
        });

        // Check if command is recognized
        final result = voice.parseAndExecuteCommand(words);
        if (result.isActionable && result.type != VoiceCommandType.dictateText) {
          voice.stopListening();
          setState(() {
            _isListening = false;
            _lastResult = result;
            _statusMessage = result.feedbackMessage ?? 'Command executed!';
          });
          _pulseController.stop();
          _pulseController.reset();

          // Auto-close after a brief success delay
          Future.delayed(const Duration(milliseconds: 1100), () {
            if (mounted) Navigator.of(context).pop();
          });
        } else if (isFinal) {
          setState(() {
            _isListening = false;
            _lastResult = result;
            _statusMessage = result.feedbackMessage ?? 'Recognized: "$words"';
          });
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await VoiceService.instance.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = 'Listening paused';
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _executeSample(String command) {
    setState(() {
      _transcript = command;
    });
    final result = VoiceService.instance.parseAndExecuteCommand(command);
    setState(() {
      _lastResult = result;
      _statusMessage = result.feedbackMessage ?? 'Command executed!';
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLanguageService.instance.tr;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            tr('voice_assistant_title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _isListening ? AppColors.blue : AppColors.secondaryText,
              fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 28),

          // Glowing Mic Orb
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      Container(
                        width: 88 * _pulseAnimation.value,
                        height: 88 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue.withValues(alpha: 0.15),
                        ),
                      ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [AppColors.blue, AppColors.violet]
                              : [AppColors.deepNavy, AppColors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Live transcript box
          if (_transcript.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
              ),
              child: Text(
                '“$_transcript”',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNavy,
                ),
              ),
            ),

          // Sample Voice Commands
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sample Voice Commands (Tap or Speak):',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _commandChip(
                icon: Icons.translate,
                label: 'Change to Telugu',
                onTap: () => _executeSample('Change to Telugu'),
              ),
              _commandChip(
                icon: Icons.translate,
                label: 'Tanglish lo marchu',
                onTap: () => _executeSample('Tanglish lo marchu'),
              ),
              _commandChip(
                icon: Icons.translate,
                label: 'Switch to English',
                onTap: () => _executeSample('Switch to English'),
              ),
              _commandChip(
                icon: Icons.account_balance_wallet,
                label: 'Go to Finance',
                onTap: () => _executeSample('Go to Finance'),
              ),
              _commandChip(
                icon: Icons.nightlight_round,
                label: 'Open Astrology',
                onTap: () => _executeSample('Open Astrology'),
              ),
              _commandChip(
                icon: Icons.favorite,
                label: 'Open Health',
                onTap: () => _executeSample('Open Health'),
              ),
              _commandChip(
                icon: Icons.track_changes,
                label: 'Open Habits',
                onTap: () => _executeSample('Open Habits'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _commandChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.blue),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }
}
