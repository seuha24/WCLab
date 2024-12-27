import 'package:flutter_tts/flutter_tts.dart';

/// TtsService 클래스는 텍스트를 음성으로 변환(TTS)하는 기능을 제공합니다.
///
/// FlutterTts 라이브러리를 사용하여 텍스트를 음성으로 변환하며, 재생, 중지, 일시정지와 같은
/// 기본적인 제어 기능을 제공합니다.
class TtsService {
  /// FlutterTts 인스턴스. 텍스트 음성 변환(TTS)을 처리합니다.
  final FlutterTts _tts = FlutterTts();

  /// [TtsService] 클래스의 생성자.
  ///
  /// 생성 시 [_initTts]를 호출하여 초기 설정을 진행합니다.
  TtsService() {
    _initTts();
  }

  /// TTS 초기 설정을 수행합니다.
  ///
  /// 언어를 한국어(`ko-KR`)로 설정하고, 음성 재생 속도를 0.6으로 지정합니다.
  Future<void> _initTts() async {
    await _tts.setLanguage("ko-KR"); // 한국어 설정
    await _tts.setSpeechRate(0.6);   // 재생 속도 설정
  }

  /// 주어진 텍스트를 음성으로 변환하여 재생합니다.
  ///
  /// [text] 텍스트 입력.
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// 현재 재생 중인 음성을 중지합니다.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// 현재 재생 중인 음성을 일시정지합니다.
  Future<void> pause() async {
    await _tts.pause();
  }
}