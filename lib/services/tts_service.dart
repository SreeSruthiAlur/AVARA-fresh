import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avara_astrology_trial/services/app_language_service.dart';

/// Text-To-Speech (TTS) Voice Synthesis Engine for AVARA.
///
/// Converts AI predictions, astrological insights, and system confirmations
/// into natural spoken voice so that users who cannot type or read can listen
/// to the app's responses in their preferred language (Telugu, Tanglish, English).
class TtsService extends ChangeNotifier {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  String? _currentlySpeakingText;
  String? get currentlySpeakingText => _currentlySpeakingText;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('🔊 [AVARA TTS Error]: $msg');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('🔊 [AVARA TTS Init Exception]: $e');
    }
  }

  /// Speaks the given text aloud in the user's selected language.
  /// Automatically strips out raw markdown and technical tags.
  Future<void> speak(String text, {AppLanguage? language}) async {
    await init();
    final clean = _cleanForSpeech(text);
    if (clean.isEmpty) return;

    final lang = language ?? AppLanguageService.instance.currentLanguage;

    try {
      await _tts.stop();

      // Configure locale
      if (lang == AppLanguage.telugu) {
        await _tts.setLanguage('te-IN');
      } else {
        await _tts.setLanguage('en-IN');
      }

      _currentlySpeakingText = text;
      _isSpeaking = true;
      notifyListeners();

      await _tts.speak(clean);
    } catch (e) {
      debugPrint('🔊 [AVARA TTS Speak Exception]: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Stops current speech output.
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      _currentlySpeakingText = null;
      notifyListeners();
    } catch (_) {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Toggles speech for a specific text message (e.g. from an audio play button).
  Future<void> toggleSpeak(String text, {AppLanguage? language}) async {
    if (_isSpeaking && _currentlySpeakingText == text) {
      await stop();
    } else {
      await speak(text, language: language);
    }
  }

  /// Strips out markdown syntax, Kundli tags, emojis, and links for natural reading.
  static String _cleanForSpeech(String raw) {
    return raw
        .replaceAll(RegExp(r'\[RENDER_SQUARE_KUNDLI\]'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'[*_#`~>]'), '')
        .replaceAll(RegExp(r'\n+'), '. ')
        .trim();
  }
}
