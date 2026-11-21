import 'package:flutter/material.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';
import 'package:avara_astrology_trial/services/voice_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';

/// Full interactive Voice Assistant Sheet.
///
/// Can be invoked from the global floating mic orb or header button.
/// Features:
/// - Real-time soundwave audio visualizer reacting to voice volume.
/// - Live word-by-word transcription box.
/// - Automatic execution of language switches (Telugu, Tanglish, English) and navigation.
/// - Clear permission guidance if browser blocks the microphone.
/// - Live text command tester and quick sample chips.
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
  String _liveTranscript = '';
  String _statusMessage = 'Tap the microphone to speak';
  String? _errorMessage;
  VoiceCommandResult? _lastResult;
  final TextEditingController _testCommandController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start listening as soon as the modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startListening();
    });
  }

  void _onVoiceServiceChanged() {
    if (!mounted) return;
    final voice = VoiceService.instance;
    if (voice.errorMessage != null && _isListening) {
      setState(() {
        _errorMessage = voice.errorMessage;
        _statusMessage = '⚠️ ${voice.errorMessage}';
        _isListening = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    } else if (!voice.isListening && _isListening && voice.lastWords.isEmpty) {
      setState(() {
        _isListening = false;
        _statusMessage = voice.errorMessage != null
            ? '⚠️ ${voice.errorMessage}'
            : 'Finished listening';
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    VoiceService.instance.removeListener(_onVoiceServiceChanged);
    _pulseController.dispose();
    _testCommandController.dispose();
    VoiceService.instance.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final voice = VoiceService.instance;
    setState(() {
      _errorMessage = null;
      _liveTranscript = '';
      _statusMessage = 'Listening... Speak clearly into your microphone';
      _isListening = true;
      _lastResult = null;
    });
    _pulseController.forward();

    final available = await voice.initialize();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _errorMessage = voice.errorMessage ??
            'Microphone access was denied. Please allow microphone permissions in Chrome.';
        _statusMessage = 'Microphone permission needed';
      });
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    await voice.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _liveTranscript = words;
          _statusMessage = 'Hearing: "$words"';
        });

        // Check if command is recognized
        final result = voice.parseCommandOnly(words);
        if (result.isActionable && result.type != VoiceCommandType.dictateText) {
          voice.stopListening();
          setState(() {
            _isListening = false;
            _lastResult = result;
            _statusMessage = result.feedbackMessage ?? 'Command executed!';
          });
          _pulseController.stop();
          _pulseController.reset();

          if (result.feedbackMessage != null) {
            TtsService.instance.speak(
              result.feedbackMessage!,
              language: result.targetLanguage,
            );
          }

          // Conversational queries stay open to read and listen to the answer
          if (result.type == VoiceCommandType.conversational) {
            return;
          }

          // Dismiss modal first, then dispatch action on the root screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
              voice.dispatchCommandResult(result);
            }
          });
        } else if (isFinal && words.trim().isNotEmpty) {
          // For non-typing users: any spoken question or sentence that isn't a direct
          // system command is automatically dispatched to the AI Assistant!
          final aiResult = VoiceCommandResult(
            type: VoiceCommandType.askAstrology,
            rawTranscript: words,
            astrologyQuestion: words,
            feedbackMessage: 'Opening AVARA AI for: "$words"',
          );
          voice.stopListening();
          setState(() {
            _isListening = false;
            _lastResult = aiResult;
            _statusMessage = 'Asking AVARA AI: "$words"...';
          });
          _pulseController.stop();
          _pulseController.reset();

          TtsService.instance.speak('Asking AVARA: $words');

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
              voice.dispatchCommandResult(aiResult);
            }
          });
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await VoiceService.instance.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = _liveTranscript.isNotEmpty
            ? 'Finished listening'
            : 'Tap the microphone to speak';
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _executeCommand(String command) {
    if (command.trim().isEmpty) return;
    setState(() {
      _liveTranscript = command.trim();
    });
    final voice = VoiceService.instance;
    var result = voice.parseCommandOnly(command.trim());
    if (!result.isActionable || result.type == VoiceCommandType.dictateText) {
      result = VoiceCommandResult(
        type: VoiceCommandType.askAstrology,
        rawTranscript: command.trim(),
        astrologyQuestion: command.trim(),
        feedbackMessage: 'Opening AVARA AI for: "${command.trim()}"',
      );
    }
    setState(() {
      _lastResult = result;
      _statusMessage = result.feedbackMessage ?? 'Command executed!';
    });

    if (result.feedbackMessage != null &&
        result.type != VoiceCommandType.dictateText) {
      TtsService.instance.speak(
        result.feedbackMessage!,
        language: result.targetLanguage,
      );
    }

    if (result.type == VoiceCommandType.conversational) {
      return;
    }

    // Dismiss modal cleanly first, then dispatch action on root screen
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
        voice.dispatchCommandResult(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLanguageService.instance.tr;
    final currentLang = AppLanguageService.instance.currentLanguage;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 18),

            // Header title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_rounded, color: AppColors.blue, size: 26),
                const SizedBox(width: 8),
                Text(
                  tr('voice_assistant_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : (_lastResult != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : AppColors.background),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isListening)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isListening
                            ? AppColors.blue
                            : (_lastResult != null
                                ? Colors.green.shade800
                                : AppColors.secondaryText),
                        fontWeight: _isListening
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Large Animated Microphone Orb
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening) ...[
                        Container(
                          width: 96 * _pulseAnimation.value,
                          height: 96 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.blue.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [const Color(0xFFE53935), const Color(0xFFFF5252)]
                                : [AppColors.deepNavy, AppColors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.red : AppColors.blue)
                                  .withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening
                  ? '🔴 Listening... Tap to stop'
                  : 'Tap to start speaking',
              style: TextStyle(
                fontSize: 12,
                color: _isListening ? Colors.red.shade700 : AppColors.secondaryText,
                fontWeight: _isListening ? FontWeight.bold : FontWeight.w500,
              ),
            ),

            // Real-time Sound Wave Meter (Animates dynamically when microphone is active)
            if (_isListening) ...[
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  final animVal = _pulseAnimation.value;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 7; i++)
                        Builder(builder: (ctx) {
                          final h = (8.0 + (animVal * ((i % 3 + 1) * 7.5))).clamp(8.0, 32.0);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 4,
                            height: h,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // Live Transcript Card
            if (_liveTranscript.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _lastResult != null
                        ? Colors.green.shade400
                        : AppColors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _lastResult != null
                          ? '✅ Executed Action'
                          : 'Recognized Speech:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _lastResult != null
                            ? Colors.green.shade800
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“$_liveTranscript”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _lastResult != null
                            ? Colors.green.shade900
                            : AppColors.deepNavy,
                      ),
                    ),
                    if (_lastResult == null) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _stopListening();
                          _executeCommand(_liveTranscript);
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text(
                          '🚀 Do It Now (Ask AVARA / Execute)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Microphone Permission Notice (if error occurred)
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFFE65100), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Chrome Microphone Permission Guide',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '1. Look at your Chrome URL bar at the top (next to localhost).\n'
                      '2. Click the 🔒 lock or tune icon.\n'
                      '3. Set Microphone to "Allow".\n'
                      '4. Tap "Retry Microphone" below or use the test box.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _startListening,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Microphone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Interactive Command Tester Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _testCommandController,
                      decoration: const InputDecoration(
                        hintText: 'Type voice command (e.g. Change to Telugu)...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(fontSize: 12),
                      ),
                      onSubmitted: _executeCommand,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.blue, size: 20),
                    tooltip: 'Test Command',
                    onPressed: () => _executeCommand(_testCommandController.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sample voice commands
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Voice Commands (Tap to run or speak):',
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
                  icon: Icons.auto_awesome,
                  label: 'What is my horoscope?',
                  onTap: () => _executeCommand('What is my horoscope'),
                ),
                _commandChip(
                  icon: Icons.nightlight_round,
                  label: 'What is my Rasi?',
                  onTap: () => _executeCommand('What is my rasi'),
                ),
                _commandChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Open Astrology Chat',
                  onTap: () => _executeCommand('Open Astrology Chat'),
                ),
                _commandChip(
                  icon: Icons.coffee_rounded,
                  label: 'Add expense 150 coffee',
                  onTap: () => _executeCommand('Add expense 150 for coffee'),
                ),
                _commandChip(
                  icon: Icons.translate,
                  label: 'Change to Telugu (తెలుగు)',
                  onTap: () => _executeCommand('Change to Telugu'),
                ),
                _commandChip(
                  icon: Icons.translate,
                  label: 'Tanglish lo marchu',
                  onTap: () => _executeCommand('Tanglish lo marchu'),
                ),
                _commandChip(
                  icon: Icons.translate,
                  label: 'Switch to English',
                  onTap: () => _executeCommand('Switch to English'),
                ),
                _commandChip(
                  icon: Icons.account_balance_wallet,
                  label: 'Go to Finance',
                  onTap: () => _executeCommand('Go to Finance'),
                ),
                _commandChip(
                  icon: Icons.favorite,
                  label: 'Open Health',
                  onTap: () => _executeCommand('Open Health'),
                ),
                _commandChip(
                  icon: Icons.track_changes,
                  label: 'Open Habits',
                  onTap: () => _executeCommand('Open Habits'),
                ),
                _commandChip(
                  icon: Icons.person_outline_rounded,
                  label: 'Open Profile',
                  onTap: () => _executeCommand('Open Profile'),
                ),
              ],
            ),
          ],
        ),
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
