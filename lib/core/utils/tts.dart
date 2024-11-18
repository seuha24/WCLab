part of core;

class TTS {
  static bool enable = false;
  final FlutterTts tts;

  TTS({required this.tts});

  Future<void> call(String text) async {
    await tts.stop();
    if (enable) {
      await tts.speak(text);
    }
  }
}
