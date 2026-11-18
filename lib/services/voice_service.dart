import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avara_astrology_trial/services/app_language_service.dart';

/// Categories of voice commands supported by AVARA.
enum VoiceCommandType {
  changeLanguage,
  navigate,
  dictateText,
  none,
}

/// Structured outcome of processing spoken voice input.
class VoiceCommandResult {
  const VoiceCommandResult({
    required this.type,
    required this.rawTranscript,
    this.targetLanguage,
    this.targetTabIndex,
    this.targetRouteName,
    this.feedbackMessage,
    this.dictatedText,
  });

  final VoiceCommandType type;
  final String rawTranscript;
  final AppLanguage? targetLanguage;
  final int? targetTabIndex;
  final String? targetRouteName;
  final String? feedbackMessage;
  final String? dictatedText;

  bool get isActionable => type != VoiceCommandType.none;
}

/// Voice Recognition and Intelligent Speech Command Service for AVARA.
///
/// Handles:
/// 1. Real-time microphone speech-to-text dictation into text fields.
/// 2. Natural language voice commands to switch app display visuals
///    (English, Telugu, and Tanglish).
/// 3. Voice navigation across AVARA's 6 main tabs.
/// 4. Graceful fallbacks for environments without microphone access.
class VoiceService extends ChangeNotifier {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _lastWords = '';
  String get lastWords => _lastWords;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Global navigation callback fired when voice commands dictate a tab change.
  void Function(int tabIndex)? onNavigateRequest;

  /// Global route callback (e.g. for profile).
  void Function(String route)? onRouteRequest;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Prepares the speech recognition engine.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          _errorMessage = val.errorMsg;
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          notifyListeners();
        },
      );
      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _errorMessage = 'Speech initialization failed: $e';
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Speech Recognition (Listening & Dictation)
  // ---------------------------------------------------------------------------

  /// Starts listening to the user's voice with the appropriate language locale.
  ///
  /// [onResult] receives partial and final transcripts as words are spoken.
  /// [autoStop] will stop after speech pauses.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String? localeOverride,
  }) async {
    _errorMessage = null;
    _lastWords = '';

    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        _errorMessage = 'Microphone or Speech Recognition is not available on this device.';
        notifyListeners();
        return;
      }
    }

    // Determine locale from AppLanguageService unless overridden
    final appLang = AppLanguageService.instance.currentLanguage;
    final localeId = localeOverride ?? appLang.speechLocaleId;

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onResult(result.recognizedWords, result.finalResult);
          notifyListeners();
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      _errorMessage = 'Error while listening: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stops current speech recognition listening session.
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
      }
    } catch (_) {
      _isListening = false;
      notifyListeners();
    }
  }

  /// Directly attaches voice input to a [TextEditingController], appending
  /// or replacing text as the user speaks.
  Future<void> listenAndFillController({
    required TextEditingController controller,
    bool append = false,
    VoidCallback? onDone,
  }) async {
    final initialText = append ? controller.text : '';

    await startListening(
      onResult: (text, isFinal) {
        if (text.trim().isNotEmpty) {
          if (append && initialText.isNotEmpty) {
            controller.text = '$initialText $text';
          } else {
            controller.text = text;
          }
          // Move cursor to the end
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
        if (isFinal) {
          onDone?.call();
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Voice Command Intent Classifier
  // ---------------------------------------------------------------------------

  /// Analyzes a spoken sentence and checks if it matches any system commands:
  /// - Language switching (Telugu, Tanglish, English)
  /// - Tab navigation (Home, Astrology, Finance, Health, Habits, Insights)
  /// - Fallback to plain text dictation
  VoiceCommandResult parseAndExecuteCommand(String spokenText) {
    final clean = spokenText.trim().toLowerCase();
    if (clean.isEmpty) {
      return const VoiceCommandResult(
        type: VoiceCommandType.none,
        rawTranscript: '',
      );
    }

    // 1. Language Switching Commands
    // Telugu triggers:
    if (_matchesPattern(clean, [
      'change to telugu',
      'switch to telugu',
      'set to telugu',
      'telugu lo marchu',
      'telugu lo pettandi',
      'telugu lo chupinchu',
      'telugu bhasha',
      'telugulo',
      'telugu',
      'తెలుగు',
    ])) {
      AppLanguageService.instance.setLanguage(AppLanguage.telugu);
      return VoiceCommandResult(
        type: VoiceCommandType.changeLanguage,
        rawTranscript: spokenText,
        targetLanguage: AppLanguage.telugu,
        feedbackMessage: 'భాష తెలుగులోకి మార్చబడింది (Changed to Telugu)',
      );
    }

    // Tanglish triggers:
    if (_matchesPattern(clean, [
      'change to tanglish',
      'switch to tanglish',
      'set to tanglish',
      'tanglish lo marchu',
      'tanglish lo pettandi',
      'tanglish bhasha',
      'tanglish',
      'english telugu mixed',
    ])) {
      AppLanguageService.instance.setLanguage(AppLanguage.tanglish);
      return VoiceCommandResult(
        type: VoiceCommandType.changeLanguage,
        rawTranscript: spokenText,
        targetLanguage: AppLanguage.tanglish,
        feedbackMessage: 'Language changed to Tanglish (Telugu in English)',
      );
    }

    // English triggers:
    if (_matchesPattern(clean, [
      'change to english',
      'switch to english',
      'set to english',
      'english lo marchu',
      'english bhasha',
      'english',
      'anglam',
    ])) {
      AppLanguageService.instance.setLanguage(AppLanguage.english);
      return VoiceCommandResult(
        type: VoiceCommandType.changeLanguage,
        rawTranscript: spokenText,
        targetLanguage: AppLanguage.english,
        feedbackMessage: 'Display language changed to English',
      );
    }

    // 2. Navigation Commands
    // Home tab (0)
    if (_matchesPattern(clean, [
      'go to home',
      'open home',
      'home screen',
      'home ki vellu',
      'హోమ్',
      'home',
    ])) {
      onNavigateRequest?.call(0);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 0,
        feedbackMessage: 'Navigated to Home',
      );
    }

    // Astrology tab (1)
    if (_matchesPattern(clean, [
      'go to astrology',
      'open astrology',
      'astrology screen',
      'astrology ki vellu',
      'jyotish',
      'jyotisham',
      'jathakam',
      'kundali',
      'kundli',
      'జ్యోతిషం',
      'astrology',
    ])) {
      onNavigateRequest?.call(1);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 1,
        feedbackMessage: 'Opened Astrology Hub',
      );
    }

    // Finance tab (2)
    if (_matchesPattern(clean, [
      'go to finance',
      'open finance',
      'finance screen',
      'finance ki vellu',
      'kharchulu',
      'expenses',
      'money',
      'spending',
      'ఆర్థికం',
      'finance',
    ])) {
      onNavigateRequest?.call(2);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 2,
        feedbackMessage: 'Opened Finance & Expenses',
      );
    }

    // Health tab (3)
    if (_matchesPattern(clean, [
      'go to health',
      'open health',
      'health screen',
      'health ki vellu',
      'aarogyam',
      'wellness',
      'mood',
      'ఆరోగ్యం',
      'health',
    ])) {
      onNavigateRequest?.call(3);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 3,
        feedbackMessage: 'Opened Health & Wellness',
      );
    }

    // Habits / Track tab (4)
    if (_matchesPattern(clean, [
      'go to habits',
      'open habits',
      'go to track',
      'open track',
      'habits screen',
      'alavatlu',
      'goals',
      'routine',
      'అలవాట్లు',
      'habits',
      'track',
    ])) {
      onNavigateRequest?.call(4);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 4,
        feedbackMessage: 'Opened Habits & Goals Tracker',
      );
    }

    // Insights tab (5)
    if (_matchesPattern(clean, [
      'go to insights',
      'open insights',
      'insights screen',
      'pragathi',
      'progress',
      'trends',
      'విశ్లేషణలు',
      'insights',
    ])) {
      onNavigateRequest?.call(5);
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 5,
        feedbackMessage: 'Opened Insights & Analytics',
      );
    }

    // Profile screen
    if (_matchesPattern(clean, [
      'open profile',
      'go to profile',
      'my profile',
      'profile screen',
      'settings',
      'ప్రొఫైల్',
    ])) {
      onRouteRequest?.call('profile');
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetRouteName: 'profile',
        feedbackMessage: 'Opening Profile & Preferences',
      );
    }

    // 3. Fallback: Treat as dictated text entry for active fields
    return VoiceCommandResult(
      type: VoiceCommandType.dictateText,
      rawTranscript: spokenText,
      dictatedText: spokenText,
      feedbackMessage: 'Captured: "$spokenText"',
    );
  }

  static bool _matchesPattern(String input, List<String> patterns) {
    for (final p in patterns) {
      if (input == p || input.contains(p)) return true;
    }
    return false;
  }
}
