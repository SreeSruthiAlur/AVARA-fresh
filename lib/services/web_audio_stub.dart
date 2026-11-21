/// Cross-platform stub for non-web environments (tests, VM).
void playSacredChantWeb(String sanskrit, String telugu) {}
void stopSacredChantWeb() {}
void playTempleBellWeb() {}
void playTranslationAudioWeb(String mantraKey, String langCode) {}

bool isWebSpeechRecognitionSupported() => false;

bool startWebSpeechRecognition({
  required String lang,
  required void Function(String text, bool isFinal) onResult,
  required void Function() onEnd,
  required void Function(String error) onError,
}) => false;

void stopWebSpeechRecognition() {}
