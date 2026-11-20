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
