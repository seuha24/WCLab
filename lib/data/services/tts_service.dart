import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:text_to_speech/text_to_speech.dart';

/// TtsService 클래스는 텍스트를 음성으로 변환(TTS)하여 재생하는 기능을 제공합니다.
///
/// 내부적으로 TextToSpeech 라이브러리를 사용하며, TTS 요청을 큐로 관리하여 순차적으로 처리합니다.
class TtsService {
  /// TextToSpeech 인스턴스. 텍스트를 음성으로 변환(TTS)합니다.
  final TextToSpeech _tts = TextToSpeech();

  /// 기본 언어 설정 (한국어).
  final String _defaultLanguage = "ko-KR";

  /// TTS 요청을 저장하고 처리하기 위한 스트림 컨트롤러.
  final _ttsQueue = StreamController<String>();

  /// 현재 TTS 요청이 처리 중인지 나타내는 상태 변수.
  Future<void>? _currentTask;

  /// TtsService 생성자.
  ///
  /// 초기화 작업으로 [_initTts]를 호출하며, TTS 요청 처리를 위해 [_processQueue]를 실행합니다.
  TtsService() {
    _initTts();
    _processQueue();
  }

  /// TTS 초기 설정을 수행합니다.
  ///
  /// - 기본 언어를 설정합니다.
  /// - 음성 재생 속도와 볼륨을 초기화합니다.
  void _initTts() {
    debugPrint('initTts()');
    _tts.setLanguage(_defaultLanguage); // 기본 언어 설정 (한국어)
    if (Platform.isAndroid) {
      _tts.setRate(1.6);                // 안드로이드 재생 속도 설정
    } else if (Platform.isIOS) {
      _tts.setRate(1.2);                // iOS 재생 속도 설정
    }
    _tts.setVolume(1.0);                // 볼륨 설정 (최대값)
  }

  /// 주어진 텍스트를 큐에 추가하여 TTS로 변환합니다.
  ///
  /// [text]: 변환할 텍스트.
  void speak(String text) {
    _ttsQueue.add(text); // 텍스트를 큐에 추가
  }

  /// 현재 재생 중인 음성을 중지하고 큐를 초기화합니다.
  ///
  /// - TTS 재생을 즉시 중단합니다.
  /// - 큐에 있는 모든 요청을 삭제합니다.
  void stop() {
    _ttsQueue.close(); // 스트림 컨트롤러 종료
    _tts.stop(); // 현재 재생 중단
  }

  /// TTS 요청 큐를 처리합니다.
  ///
  /// 큐에 추가된 텍스트를 순차적으로 재생하며, 각 요청이 완료된 후 다음 요청을 처리합니다.
  void _processQueue() {
    _ttsQueue.stream.listen((text) async {
      // 이전 작업이 완료될 때까지 대기
      if (_currentTask != null) {
        await _currentTask;
      }

      // 현재 작업을 처리하고 완료를 기다림
      final completer = Completer<void>();
      _currentTask = completer.future;

      debugPrint('Speaking: $text');
      _tts.speak(text);

      // 예상 재생 시간 계산 (초당 10자 기준)
      final estimatedTime = text.length / 10.0;
      await Future.delayed(Duration(seconds: estimatedTime.ceil()));

      // 작업 완료 후 상태 업데이트
      completer.complete();
    });
  }
}