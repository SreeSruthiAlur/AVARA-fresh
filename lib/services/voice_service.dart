import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';

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

  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  String _lastWords = '';
  String get lastWords => _lastWords;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasPermissionError = false;
  bool get hasPermissionError => _hasPermissionError;

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
      _hasPermissionError = false;
      _errorMessage = null;

      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('🎤 [AVARA Voice Error]: ${val.errorMsg} (permanent: ${val.permanent})');
          _errorMessage = _humanFriendlyError(val.errorMsg);
          if (val.errorMsg.toLowerCase().contains('not-allowed') ||
              val.errorMsg.toLowerCase().contains('denied') ||
              val.errorMsg.toLowerCase().contains('permission')) {
            _hasPermissionError = true;
          }
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('🎤 [AVARA Voice Status]: $status');
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
            _soundLevel = 0.0;
          }
          notifyListeners();
        },
        debugLogging: false,
      );
      notifyListeners();
      return _isInitialized;
    } catch (e) {
      debugPrint('🎤 [AVARA Voice Init Exception]: $e');
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
  /// Automatically handles Web/Chrome hyphens and fallbacks.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String? localeOverride,
  }) async {
    _errorMessage = null;
    _hasPermissionError = false;
    _lastWords = '';
    _soundLevel = 0.0;

    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        _errorMessage =
            'Microphone or Speech Recognition is not available. Check browser permissions.';
        _hasPermissionError = true;
        notifyListeners();
        return;
      }
    }

    // Determine locale from AppLanguageService unless overridden
    final appLang = AppLanguageService.instance.currentLanguage;
    String rawLocale = localeOverride ?? appLang.speechLocaleId;
    // Ensure BCP-47 hyphens for web browsers (e.g. en-IN instead of en_IN)
    final localeId = rawLocale.replaceAll('_', '-');

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onResult(result.recognizedWords, result.finalResult);
          notifyListeners();
        },
        onSoundLevelChange: (level) {
          // Normalize sound level
          _soundLevel = level;
          notifyListeners();
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('🎤 [AVARA Voice Listen Error with locale $localeId]: $e');
      // If specific locale failed on browser, retry without explicit locale (uses browser default)
      try {
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            onResult(result.recognizedWords, result.finalResult);
            notifyListeners();
          },
          onSoundLevelChange: (level) {
            _soundLevel = level;
            notifyListeners();
          },
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        );
      } catch (retryError) {
        _errorMessage = 'Error while listening: $retryError';
        _isListening = false;
        notifyListeners();
      }
    }
  }

  /// Stops current speech recognition listening session.
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        _soundLevel = 0.0;
        notifyListeners();
      }
    } catch (_) {
      _isListening = false;
      _soundLevel = 0.0;
      notifyListeners();
    }
  }

  /// Converts technical speech engine error codes to user-friendly advice.
  static String _humanFriendlyError(String code) {
    final lower = code.toLowerCase();
    if (lower.contains('permission') ||
        lower.contains('not-allowed') ||
        lower.contains('denied')) {
      return 'Microphone permission blocked. Click the 🔒 lock icon in the Chrome URL bar and select "Allow" for Microphone, then try again.';
    }
    if (lower.contains('no_speech') || lower.contains('no-speech')) {
      return 'No speech detected. Please speak closer to your microphone.';
    }
    if (lower.contains('network')) {
      return 'Network error: Chrome speech recognition requires an active internet connection.';
    }
    if (lower.contains('busy') || lower.contains('audio-capture')) {
      return 'Microphone is currently in use or audio capture failed.';
    }
    if (lower.contains('not-supported') || lower.contains('language')) {
      return 'Language model unavailable on this browser. Falling back to default speech.';
    }
    return 'Voice status: $code';
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

  /// Checks whether a recognized phrase is a navigation or language command.
  /// If so, executes it and returns the [VoiceCommandResult].
  /// If not a system command, returns null so caller can treat it as normal text dictation.
  VoiceCommandResult? tryExecuteCommand(String text) {
    final result = parseAndExecuteCommand(text);
    if (result.type != VoiceCommandType.dictateText &&
        result.type != VoiceCommandType.none) {
      return result;
    }
    return null;
  }

  /// Analyzes a spoken sentence and checks if it matches any system commands:
  /// - Language switching (Telugu, Tanglish, English)
  /// - Tab navigation (Home, Astrology, Finance, Health, Habits, Insights)
  /// - Fallback to plain text dictation
  ///
  /// When [speakFeedback] is true, the response is spoken out loud via [TtsService].
  VoiceCommandResult parseAndExecuteCommand(String spokenText, {bool speakFeedback = true}) {
    final result = _parseCommandInternal(spokenText);
    if (speakFeedback &&
        result.feedbackMessage != null &&
        result.type != VoiceCommandType.dictateText) {
      TtsService.instance.speak(
        result.feedbackMessage!,
        language: result.targetLanguage,
      );
    }
    return result;
  }

  VoiceCommandResult _parseCommandInternal(String spokenText) {
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

  /// Extracts expense details (amount, category, description) from spoken sentence.
  /// Example: "Coffee 150 rupees" -> amount: 150.0, description: "Coffee", category: "Food & Dining"
  Map<String, dynamic> extractExpenseFromSpeech(String text) {
    double? amount;
    String description = text;
    String category = 'Other';

    // Extract numbers (digits)
    final numMatch = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(text);
    if (numMatch != null) {
      amount = double.tryParse(numMatch.group(1)!);
      description = text.replaceFirst(numMatch.group(1)!, '').trim();
    }

    // Clean up currency words
    description = description
        .replaceAll(
          RegExp(
            r'\b(rupees|rs|rupayalu|spent|for|on|ki|lo)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = text.toLowerCase();
    if (lower.contains('coffee') ||
        lower.contains('tea') ||
        lower.contains('food') ||
        lower.contains('dinner') ||
        lower.contains('lunch') ||
        lower.contains('tiffin') ||
        lower.contains('restaurant') ||
        lower.contains('snacks')) {
      category = 'Food & Dining';
    } else if (lower.contains('petrol') ||
        lower.contains('diesel') ||
        lower.contains('auto') ||
        lower.contains('cab') ||
        lower.contains('uber') ||
        lower.contains('bus') ||
        lower.contains('travel')) {
      category = 'Transportation';
    } else if (lower.contains('shopping') ||
        lower.contains('cloth') ||
        lower.contains('dress') ||
        lower.contains('market') ||
        lower.contains('grocery') ||
        lower.contains('groceries')) {
      category = 'Shopping';
    } else if (lower.contains('recharge') ||
        lower.contains('wifi') ||
        lower.contains('bill') ||
        lower.contains('rent') ||
        lower.contains('current')) {
      category = 'Bills & Utilities';
    } else if (lower.contains('movie') ||
        lower.contains('game') ||
        lower.contains('outing')) {
      category = 'Entertainment';
    } else if (lower.contains('medicine') ||
        lower.contains('doctor') ||
        lower.contains('hospital') ||
        lower.contains('tablet')) {
      category = 'Health & Medical';
    }

    return {
      'amount': amount,
      'category': category,
      'description': description.isNotEmpty ? description : text,
    };
  }

  static bool _matchesPattern(String input, List<String> patterns) {
    for (final p in patterns) {
      if (input == p || input.contains(p)) return true;
    }
    return false;
  }
}
