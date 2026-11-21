// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web implementation invoking browser AudioContext & Web Speech API.
void playSacredChantWeb(String sanskrit, String telugu) {
  try {
    js.context.callMethod('playSacredChant', [sanskrit, telugu]);
  } catch (e) {
    // ignore: avoid_print
    print('Web chant JS error: $e');
  }
}

void stopSacredChantWeb() {
  try {
    js.context.callMethod('stopSacredChant', []);
  } catch (_) {}
}

void playTempleBellWeb() {
  try {
    js.context.callMethod('playTempleBell', []);
  } catch (_) {}
}

void playTranslationAudioWeb(String mantraKey, String langCode) {
  try {
    js.context.callMethod('playTranslationAudio', [mantraKey, langCode]);
  } catch (e) {
    // ignore: avoid_print
    print('Web translation JS error: $e');
  }
}

bool isWebSpeechRecognitionSupported() {
  try {
    return js.context.callMethod('isWebSpeechAvailable', []) == true;
  } catch (_) {
    return false;
  }
}

bool startWebSpeechRecognition({
  required String lang,
  required void Function(String text, bool isFinal) onResult,
  required void Function() onEnd,
  required void Function(String error) onError,
}) {
  try {
    final res = js.context.callMethod('startWebSpeechRecognition', [
      lang,
      js.allowInterop((dynamic text, dynamic isFinal) {
        onResult(text?.toString() ?? '', isFinal == true);
      }),
      js.allowInterop(() {
        onEnd();
      }),
      js.allowInterop((dynamic err) {
        onError(err?.toString() ?? 'speech_error');
      }),
    ]);
    return res == true;
  } catch (e) {
    // ignore: avoid_print
    print('startWebSpeechRecognition JS error: $e');
    return false;
  }
}

void stopWebSpeechRecognition() {
  try {
    js.context.callMethod('stopWebSpeechRecognition', []);
  } catch (_) {}
}
