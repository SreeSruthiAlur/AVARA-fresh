import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avara_astrology_trial/services/age_profile_service.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';
import 'package:avara_astrology_trial/services/tts_service.dart';
import 'package:avara_astrology_trial/services/web_audio_stub.dart'
    if (dart.library.js) 'package:avara_astrology_trial/services/web_audio_web.dart';

/// Categories of voice commands supported by AVARA.
enum VoiceCommandType {
  changeLanguage,
  changeAgeCohort,
  japaMalaAction,
  navigate,
  openScreen,
  askAstrology,
  addExpense,
  conversational,
  dictateText,
  none,
}

/// Structured outcome of processing spoken voice input.
class VoiceCommandResult {
  const VoiceCommandResult({
    required this.type,
    required this.rawTranscript,
    this.targetLanguage,
    this.targetAgeGroup,
    this.targetTabIndex,
    this.targetRouteName,
    this.feedbackMessage,
    this.dictatedText,
    this.astrologyQuestion,
    this.expenseAmount,
    this.expenseCategory,
    this.expenseDescription,
  });

  final VoiceCommandType type;
  final String rawTranscript;
  final AppLanguage? targetLanguage;
  final AgeGroup? targetAgeGroup;
  final int? targetTabIndex;
  final String? targetRouteName;
  final String? feedbackMessage;
  final String? dictatedText;
  final String? astrologyQuestion;
  final double? expenseAmount;
  final String? expenseCategory;
  final String? expenseDescription;

  bool get isActionable =>
      type != VoiceCommandType.none && type != VoiceCommandType.dictateText;
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

  /// Callback when user speaks a login or guest access command from the Login screen.
  void Function()? onLoginAsGuestRequest;

  /// Callback when user asks an astrology question by voice.
  void Function(String question)? onAskAstrologyRequest;

  /// Callback when user dictates an expense by voice.
  void Function(double amount, String category, String description)? onAddExpenseRequest;

  /// Callback when user requests to open a specific screen (e.g. 'chat', 'add_expense', 'astrologers', 'birth_profile', 'profile', 'register').
  void Function(String screenName)? onOpenScreenRequest;

  /// Callback when user commands an age cohort mode change by voice.
  void Function(AgeGroup group)? onAgeCohortChangeRequest;

  /// Callback when user commands japa mala counting or reset by voice.
  void Function()? onJapaMalaTapRequest;
  void Function()? onJapaMalaResetRequest;

  Timer? _silenceTimer;
  bool _hasFinalized = false;
  void Function(String text, bool isFinal)? _activeOnResult;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Prepares the speech recognition engine.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (kIsWeb && isWebSpeechRecognitionSupported()) {
      _isInitialized = true;
      _hasPermissionError = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    try {
      _hasPermissionError = false;
      _errorMessage = null;

      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('🎤 [AVARA Voice Error]: ${val.errorMsg} (permanent: ${val.permanent})');
          final lower = val.errorMsg.toLowerCase();
          if (lower.contains('no-speech') ||
              lower.contains('no_speech') ||
              lower.contains('aborted') ||
              lower.contains('canceled') ||
              lower.contains('cancelled')) {
            // Transient silence or intentional cancellation — do not treat as fatal error
            debugPrint('🎤 [AVARA Voice]: Transient silence or cancellation detected, continuing.');
            return;
          }
          if (lower.contains('language') || lower.contains('not-supported')) {
            debugPrint('🎤 [AVARA Voice]: Specific locale not supported, retrying with default speech.');
            _speech.listen(
              onResult: (result) {
                _lastWords = result.recognizedWords;
                if (result.finalResult) {
                  _hasFinalized = true;
                  _activeOnResult?.call(_lastWords, true);
                } else {
                  _activeOnResult?.call(result.recognizedWords, false);
                }
                notifyListeners();
              },
              listenFor: const Duration(seconds: 60),
              pauseFor: const Duration(seconds: 6),
              listenMode: stt.ListenMode.dictation,
              cancelOnError: false,
              partialResults: true,
            );
            return;
          }
          _errorMessage = _humanFriendlyError(val.errorMsg);
          if (lower.contains('not-allowed') ||
              lower.contains('denied') ||
              lower.contains('permission')) {
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
            // When browser engine stops receiving speech, finalize recognized words immediately
            if (!_hasFinalized && _lastWords.trim().isNotEmpty) {
              _hasFinalized = true;
              _silenceTimer?.cancel();
              debugPrint('🎤 [AVARA Web Speech onEnd]: Finalizing pending words: "$_lastWords"');
              _activeOnResult?.call(_lastWords, true);
            }
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
    _hasFinalized = false;
    _activeOnResult = onResult;

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

    // First priority on Web: Native Chrome SpeechRecognition
    if (kIsWeb && isWebSpeechRecognitionSupported()) {
      _isListening = true;
      notifyListeners();

      final started = startWebSpeechRecognition(
        lang: localeId,
        onResult: (text, isFinal) {
          _lastWords = text;
          if (isFinal) {
            _hasFinalized = true;
            _isListening = false;
            _soundLevel = 0.0;
            onResult(text, true);
            notifyListeners();
          } else {
            _soundLevel = 0.75;
            onResult(text, false);
            notifyListeners();
          }
        },
        onEnd: () {
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('🎤 [AVARA Web Speech Error]: $err');
          final lower = err.toLowerCase();
          if (lower.contains('not-allowed') ||
              lower.contains('denied') ||
              lower.contains('permission')) {
            _hasPermissionError = true;
            _errorMessage =
                'Microphone permission blocked. Click the 🔒 lock icon in the Chrome URL bar and select "Allow" for Microphone.';
          } else if (lower.contains('no-speech') ||
              lower.contains('no_speech') ||
              lower.contains('aborted') ||
              lower.contains('canceled') ||
              lower.contains('cancelled')) {
            // Normal silence or cancellation — do not show error banner
            _errorMessage = null;
          } else {
            _errorMessage = 'Voice status: $err';
          }
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
      );

      if (started) return;
    }

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;

          if (result.finalResult) {
            _silenceTimer?.cancel();
            _hasFinalized = true;
            onResult(_lastWords, true);
            notifyListeners();
            return;
          }

          onResult(result.recognizedWords, false);
          notifyListeners();

          // Debounce timer for web browsers where finalResult is not sent during continuous speech
          _silenceTimer?.cancel();
          if (result.recognizedWords.trim().isNotEmpty) {
            _silenceTimer = Timer(const Duration(milliseconds: 1400), () {
              if (!_hasFinalized && _lastWords.trim().isNotEmpty) {
                _hasFinalized = true;
                debugPrint('🎤 [AVARA Silence Detection]: Auto-finalizing: "$_lastWords"');
                onResult(_lastWords, true);
                stopListening();
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          // Normalize sound level
          _soundLevel = level;
          notifyListeners();
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 6),
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
            if (result.finalResult) {
              _hasFinalized = true;
              onResult(_lastWords, true);
            } else {
              onResult(result.recognizedWords, false);
            }
            notifyListeners();
          },
          onSoundLevelChange: (level) {
            _soundLevel = level;
            notifyListeners();
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 6),
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
    _silenceTimer?.cancel();
    _silenceTimer = null;
    if (kIsWeb) {
      stopWebSpeechRecognition();
    }
    try {
      if (!_hasFinalized && _lastWords.trim().isNotEmpty) {
        _hasFinalized = true;
        _activeOnResult?.call(_lastWords, true);
      }
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
    if (lower.contains('aborted') ||
        lower.contains('canceled') ||
        lower.contains('cancelled')) {
      return '';
    }
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

  /// Parses spoken text into a [VoiceCommandResult] without executing callbacks.
  VoiceCommandResult parseCommandOnly(String spokenText) {
    return _parseCommandInternal(spokenText);
  }

  /// Dispatches callbacks for a previously parsed [VoiceCommandResult].
  void dispatchCommandResult(VoiceCommandResult result) {
    switch (result.type) {
      case VoiceCommandType.changeLanguage:
        if (result.targetLanguage != null) {
          AppLanguageService.instance.setLanguage(result.targetLanguage!);
        }
        break;
      case VoiceCommandType.changeAgeCohort:
        if (result.targetAgeGroup != null) {
          AgeProfileService.instance.setAgeGroup(result.targetAgeGroup!);
          onAgeCohortChangeRequest?.call(result.targetAgeGroup!);
        }
        break;
      case VoiceCommandType.japaMalaAction:
        if (result.feedbackMessage?.toLowerCase().contains('reset') ?? false) {
          onJapaMalaResetRequest?.call();
        } else {
          TtsService.instance.playTempleBell();
          onJapaMalaTapRequest?.call();
        }
        break;
      case VoiceCommandType.navigate:
        if (result.targetTabIndex != null) {
          onNavigateRequest?.call(result.targetTabIndex!);
        } else if (result.feedbackMessage?.contains('Guest') ?? false) {
          onLoginAsGuestRequest?.call();
        }
        break;
      case VoiceCommandType.openScreen:
        if (result.targetRouteName != null) {
          if (onOpenScreenRequest != null) {
            onOpenScreenRequest?.call(result.targetRouteName!);
          } else if (result.targetRouteName == 'profile') {
            onRouteRequest?.call('profile');
          }
        }
        break;
      case VoiceCommandType.askAstrology:
        if (result.astrologyQuestion != null) {
          if (onAskAstrologyRequest != null) {
            onAskAstrologyRequest?.call(result.astrologyQuestion!);
          } else {
            onNavigateRequest?.call(1);
          }
        }
        break;
      case VoiceCommandType.addExpense:
        if (result.expenseAmount != null) {
          onAddExpenseRequest?.call(
            result.expenseAmount!,
            result.expenseCategory ?? 'Other',
            result.expenseDescription ?? 'Expense',
          );
        }
        break;
      case VoiceCommandType.conversational:
      case VoiceCommandType.dictateText:
      case VoiceCommandType.none:
        break;
    }
  }

  /// Analyzes a spoken sentence, executes matching callbacks, and speaks feedback aloud.
  VoiceCommandResult parseAndExecuteCommand(String spokenText, {bool speakFeedback = true}) {
    final result = _parseCommandInternal(spokenText);
    dispatchCommandResult(result);
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

    // Malayalam triggers:
    if (_matchesPattern(clean, [
      'change to malayalam',
      'switch to malayalam',
      'set to malayalam',
      'malayalam aakkuka',
      'malayalathil aakkuka',
      'malayalam bhasha',
      'malayalathil',
      'malayalam',
      'മലയാളം',
    ])) {
      AppLanguageService.instance.setLanguage(AppLanguage.malayalam);
      return VoiceCommandResult(
        type: VoiceCommandType.changeLanguage,
        rawTranscript: spokenText,
        targetLanguage: AppLanguage.malayalam,
        feedbackMessage: 'ഭാഷ മലയാളത്തിലേക്ക് മാറ്റി (Changed to Malayalam)',
      );
    }

    // Manglish triggers:
    if (_matchesPattern(clean, [
      'change to manglish',
      'switch to manglish',
      'set to manglish',
      'manglish aakkuka',
      'manglish bhasha',
      'manglish',
      'malayalam in english',
      'malayalam english mixed',
    ])) {
      AppLanguageService.instance.setLanguage(AppLanguage.manglish);
      return VoiceCommandResult(
        type: VoiceCommandType.changeLanguage,
        rawTranscript: spokenText,
        targetLanguage: AppLanguage.manglish,
        feedbackMessage: 'Language changed to Manglish (Malayalam in English)',
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

    // Age Cohort Mode Switching
    if (_matchesPattern(clean, [
      'youth mode',
      'switch to youth',
      'change to youth',
      'youngster mode',
      'youth',
      'youngster',
      'level up',
      'explorer mode',
      'cosmic explorer',
      'teens',
      'yuvakulu',
      'student mode',
    ])) {
      AgeProfileService.instance.setAgeGroup(AgeGroup.youth);
      return VoiceCommandResult(
        type: VoiceCommandType.changeAgeCohort,
        rawTranscript: spokenText,
        targetAgeGroup: AgeGroup.youth,
        feedbackMessage: 'Switched to Youth & Cosmic Explorer Mode! 🚀 (Under 22)',
      );
    }

    if (_matchesPattern(clean, [
      'adult mode',
      'switch to adult',
      'change to adult',
      'executive mode',
      'focus mode',
      'professional mode',
      'adult',
      'peddalu',
      'achiever',
    ])) {
      AgeProfileService.instance.setAgeGroup(AgeGroup.adult);
      return VoiceCommandResult(
        type: VoiceCommandType.changeAgeCohort,
        rawTranscript: spokenText,
        targetAgeGroup: AgeGroup.adult,
        feedbackMessage: 'Switched to Mindful Professional & Executive Mode (22-45)',
      );
    }

    if (_matchesPattern(clean, [
      'senior mode',
      'switch to senior',
      'change to senior',
      'vedic sanctuary',
      'spiritual mode',
      'senior',
      'vrudhulu',
      'peddala mode',
      'elderly mode',
      'shanti mode',
    ])) {
      AgeProfileService.instance.setAgeGroup(AgeGroup.senior);
      return VoiceCommandResult(
        type: VoiceCommandType.changeAgeCohort,
        rawTranscript: spokenText,
        targetAgeGroup: AgeGroup.senior,
        feedbackMessage: 'Switched to Grace & Serenity Vedic Sanctuary Mode (45+)',
      );
    }

    // Sacred Japa Mala & Chanting Commands
    if (_matchesPattern(clean, [
      'count bead',
      'count mala',
      'japa',
      'om namah shivaya',
      'gayatri mantra',
      'next bead',
      'japam',
      'mani',
      'om namo narayanaya',
      'maha mrityunjaya',
      'hare krishna',
      'chant',
      'chanting',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.japaMalaAction,
        rawTranscript: spokenText,
        feedbackMessage: 'Japa bead counted. Temple bell sounded 🔔',
      );
    }

    if (_matchesPattern(clean, [
      'reset mala',
      'reset japa',
      'clear mala',
      'restart mala',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.japaMalaAction,
        rawTranscript: spokenText,
        feedbackMessage: 'Japa Mala counter reset to zero',
      );
    }

    // 2. Specific Screen Direct Navigation
    // Astrology Chat Screen:
    if (_matchesPattern(clean, [
      'open chat',
      'open astrology chat',
      'astrology chat',
      'chat with astrologer',
      'chat with ai',
      'talk to ai',
      'ask a question',
      'chat screen',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'chat',
        feedbackMessage: 'Opening Astrology AI Chat',
      );
    }

    // Explore Topics (Bubbles for Love, Education, Career — Point 6):
    if (_matchesPattern(clean, [
      'explore topics',
      'open explore topics',
      'explore bubbles',
      'topic bubbles',
      'explore love',
      'explore education',
      'explore career',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'explore_topics',
        feedbackMessage: 'Opening Explore Topics (Love, Education, Career)',
      );
    }

    // Human Astrologers Directory:
    if (_matchesPattern(clean, [
      'talk to astrologer',
      'consult astrologer',
      'astrologers',
      'human astrologer',
      'astrologer list',
      'pandit',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'astrologers',
        feedbackMessage: 'Opening Verified Astrologers Directory',
      );
    }

    // Birth Profile / Kundli:
    if (_matchesPattern(clean, [
      'open kundli',
      'birth profile',
      'open birth profile',
      'my kundli',
      'my chart',
      'kundali screen',
      'jathakam chart',
      'birth chart',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'birth_profile',
        feedbackMessage: 'Opening Janma Kundali & Birth Profile',
      );
    }

    // Add Expense Screen (explicit command without amount):
    if (_matchesPattern(clean, [
      'open add expense',
      'add expense screen',
      'new expense',
      'enter expense',
      'log expense screen',
      'add my expense',
      'kharchu add',
    ]) && !clean.contains(RegExp(r'\d+'))) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'add_expense',
        feedbackMessage: 'Opening Add Expense Screen',
      );
    }

    // Profile & Preferences:
    if (_matchesPattern(clean, [
      'open profile',
      'go to profile',
      'my profile',
      'settings',
      'profile screen',
      'ప్రొఫైల్',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'profile',
        feedbackMessage: 'Opening Profile & Preferences',
      );
    }

    // Login / Guest / Open App command:
    if (_matchesPattern(clean, [
      'login',
      'sign in',
      'guest',
      'continue',
      'open app',
      'start app',
      'enter app',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetRouteName: 'login_guest',
        feedbackMessage: 'Entering AVARA App as Guest',
      );
    }

    // Register / Sign up command:
    if (_matchesPattern(clean, [
      'sign up',
      'register',
      'create account',
      'new account',
      'open sign up',
    ])) {
      return VoiceCommandResult(
        type: VoiceCommandType.openScreen,
        rawTranscript: spokenText,
        targetRouteName: 'register',
        feedbackMessage: 'Opening Sign Up Screen',
      );
    }

    // 3. Add Expense with Amount & Details (Actionable Expense Voice Dictation)
    final bool hasExpenseTrigger = _matchesPattern(clean, [
      'add expense',
      'spent',
      'log expense',
      'record expense',
      'paid',
      'kharchu chesa',
    ]);
    if (hasExpenseTrigger && clean.contains(RegExp(r'\d+'))) {
      final parsed = extractExpenseFromSpeech(spokenText);
      final double? amt = parsed['amount'] as double?;
      if (amt != null && amt > 0) {
        final cat = parsed['category'] as String? ?? 'Other';
        final desc = parsed['description'] as String? ?? 'Expense';
        return VoiceCommandResult(
          type: VoiceCommandType.addExpense,
          rawTranscript: spokenText,
          expenseAmount: amt,
          expenseCategory: cat,
          expenseDescription: desc,
          feedbackMessage: 'Added expense of ₹${amt.toInt()} for $desc ($cat)',
        );
      }
    }

    // 4. Astrology AI Questions (Direct Voice Q&A with Vedic AI)
    final bool isAstrologyQuestion = _matchesPattern(clean, [
      'what is my horoscope',
      'tell me my horoscope',
      'today horoscope',
      'horoscope',
      'rasiphalalu',
      'rasi phalalu',
      'what is my rasi',
      'what is my rashi',
      'naa rasi',
      'naa raasi',
      'moon sign',
      'sun sign',
      'what is my nakshatra',
      'naa nakshatram',
      'janma nakshatra',
      'what is my lagna',
      'ascendant',
      'lagnam',
      'kundli',
      'kundali',
      'jathakam',
      'jyothish',
      'jyotisham',
      'when will i get married',
      'naa marriage',
      'pelli epudu',
      'career',
      'my job',
      'udyogam',
      'mahadasha',
      'dasha period',
      '7th house',
      'tell me my future',
      'bhavishyath',
    ]);
    if (isAstrologyQuestion ||
        clean.startsWith('ask astrology') ||
        clean.startsWith('ask astrologer') ||
        clean.startsWith('panditji')) {
      final question = spokenText
          .replaceFirst(
            RegExp(r'^(ask astrology|ask astrologer|panditji|tell me)\s*', caseSensitive: false),
            '',
          )
          .trim();
      final finalQ = question.isNotEmpty ? question : spokenText;
      return VoiceCommandResult(
        type: VoiceCommandType.askAstrology,
        rawTranscript: spokenText,
        astrologyQuestion: finalQ,
        feedbackMessage: 'Opening Astrology AI to answer: "$finalQ"',
      );
    }

    // 5. Navigation Commands
    // Home tab (0)
    if (_matchesPattern(clean, [
      'go to home',
      'open home',
      'home screen',
      'home ki vellu',
      'హోమ్',
      'home',
    ])) {
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
      'water',
      'sleep',
      'ఆరోగ్యం',
      'health',
    ])) {
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
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        rawTranscript: spokenText,
        targetTabIndex: 5,
        feedbackMessage: 'Opened Insights & Analytics',
      );
    }

    // 6. Conversational Guidance & Info
    if (_matchesPattern(clean, [
      'who are you',
      'what is avara',
      'help',
      'what can you do',
      'commands',
      'features',
      'namaskaram',
      'hello',
    ])) {
      final isTe = AppLanguageService.instance.currentLanguage == AppLanguage.telugu;
      final msg = isTe
          ? 'నేను AVARA, మీ వేద జ్యోతిష మరియు లైఫ్‌స్టైల్ AI మార్గదర్శిని. మీరు మాట్లాడి జ్యోతిష ప్రశ్నలు అడగవచ్చు, ఖర్చులు నమోదు చేయవచ్చు మరియు భాషను మార్చవచ్చు.'
          : 'I am AVARA, your Vedic Astrology and life companion. Speak to ask astrology questions, add expenses, switch languages, or navigate anywhere.';
      return VoiceCommandResult(
        type: VoiceCommandType.conversational,
        rawTranscript: spokenText,
        feedbackMessage: msg,
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

    // Clean up command keywords and currency words
    description = description
        .replaceAll(
          RegExp(
            r'\b(add|expense|expenses|record|log|paid|rupees|rs|rupayalu|spent|for|on|ki|lo)\b',
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
    final cleanInput = input.trim().toLowerCase();
    for (final p in patterns) {
      final cleanP = p.trim().toLowerCase();
      if (cleanInput == cleanP) return true;
      if (cleanP.contains(' ')) {
        if (cleanInput.contains(cleanP)) return true;
      } else {
        // Single words must match as whole word, not substring
        final regex = RegExp(r'\b' + RegExp.escape(cleanP) + r'\b', caseSensitive: false);
        if (regex.hasMatch(cleanInput)) {
          // If input is a long sentence (> 4 words), avoid triggering short navigation words like "home"
          final wordCount = cleanInput.split(RegExp(r'\s+')).length;
          if (wordCount <= 4 || cleanP.length >= 6) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
