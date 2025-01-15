import 'package:flutter/foundation.dart';
import 'package:text_to_speech/text_to_speech.dart';

/// TtsService 클래스는 텍스트를 음성으로 변환(TTS)하는 기능을 제공합니다.
///
/// TextToSpeech 라이브러리를 사용하여 텍스트를 음성으로 변환하며, 재생 속도와 음량 같은
/// 기본적인 설정 기능을 제공합니다.
class TtsService {
  /// TextToSpeech 인스턴스. 텍스트 음성 변환(TTS)을 처리합니다.
  final TextToSpeech _tts = TextToSpeech();

  /// 기본 언어 설정 (한국어)
  final String _defaultLanguage = "ko-KR";

  /// [TtsService] 클래스의 생성자.
  ///
  /// 생성 시 [_initTts]를 호출하여 초기 설정을 진행합니다.
  TtsService() {
    _initTts();
  }

  /// TTS 초기 설정을 수행합니다.
  ///
  /// 언어를 기본 언어로 설정하고, 음성 재생 속도와 볼륨을 초기화합니다.
  void _initTts() {
    debugPrint('initTts()');
    _tts.setLanguage(_defaultLanguage); // 한국어 설정
    _tts.setRate(1.1);                  // 재생 속도 설정
    _tts.setVolume(1.0);                // 볼륨 설정 (0.0 ~ 1.0)
  }

  /// 주어진 텍스트를 음성으로 변환하여 재생합니다.
  ///
  /// [text] 텍스트 입력.
  void speak(String text) {
    _tts.speak(text);
  }

  /// 현재 재생 중인 음성을 중지합니다.
  void stop() {
    _tts.stop();
  }
}
