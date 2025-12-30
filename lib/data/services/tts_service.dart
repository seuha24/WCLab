import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

const _kTtsDebug = false;

// 큐 최대 길이 (필요하면 나중에 조정)
const int _kMaxQueueSize = 30;
/// ETtsChannel
/// 선언 순서 = 우선순위 (index 낮을수록 우선순위 높음)
/// FEEDBACK > SYSTEM_ANNOUNCE > ALERT >  NAVIGATE
enum ETtsChannel {
  FEEDBACK,         // 사용자 피드백
  SYSTEM_ANNOUNCE,  // 재탐색, 모드 변경 등
  ALERT,            // 경로 이탈, 위험
  NAVIGATE,         // 일반 경로 안내
}

extension ETtsChannelPriority on ETtsChannel {
  int get priority => index;
}

/// TTS 요청 DTO (내부 전용)
class _TtsRequest {
  _TtsRequest({
    required this.text,
    required this.channel,
    required this.createdAt,
    this.cooldownKey,
    this.cooldown,
  });

  final String text;
  final ETtsChannel channel;
  final DateTime createdAt;
  final String? cooldownKey;
  final Duration? cooldown;
}

// 앱 전역 TTS 서비스 (FlutterTts 기반)
/// - 채널 우선순위: ALERT > FEEDBACK > SYSTEM_ANNOUNCE > NAVIGATE
/// - 쿨다운: 같은 이벤트를 특정 시간 내에 반복 재생 방지
/// - 큐: 요청들을 순차 재생, 높은 우선순위는 재생 중인 것 인터럽트 가능
class TtsService {
  TtsService(this._tts) {
    _initTtsSync();
    _attachHandlers();
  }

  final FlutterTts _tts;

  /// 재생 대기 큐
  final List<_TtsRequest> _queue = [];

  /// 쿨다운 관리용 맵
  final Map<String, DateTime> _cooldownMap = {};

  /// 현재 재생 중인 요청
  _TtsRequest? _current;

  bool _isPlaying = false;
  bool _initialized = false;
  bool _isEnabled = true;

  bool get isPlaying => _isPlaying;
  bool get isEnabled => _isEnabled;
  ETtsChannel? get currentChannel => _current?.channel;

  /// TTS 활성화/비활성화 설정
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) stopAll();
  }

  /// 초기 설정: 언어, 속도, 볼륨, iOS 오디오 카테고리 등 (동기식 - fire and forget)
  void _initTtsSync() {
    if (_initialized) return;
    _initialized = true;

    if (_kTtsDebug) debugPrint('TtsService: initTts()');

    _tts.awaitSpeakCompletion(true);
    _tts.setVolume(1.0);

    _tts.setLanguage("ko-KR");
    if (Platform.isAndroid) {
      _tts.setSpeechRate(0.5);
    } else if (Platform.isIOS) {
      _tts.setSpeechRate(0.55);
    }

    if (Platform.isIOS) {
      _tts.setSharedInstance(true);
      _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
  }

  /// 재생 완료/취소/에러 핸들러 연결
  void _attachHandlers() {
    _tts.setCompletionHandler(() {
      if (_kTtsDebug) debugPrint('TtsService: completion');
      _onDoneOrError();
    });

    _tts.setCancelHandler(() {
      if (_kTtsDebug) debugPrint('TtsService: cancel');
      _onDoneOrError();
    });

    _tts.setErrorHandler((msg) {
      if (_kTtsDebug) debugPrint('TtsService: error => $msg');
      _onDoneOrError();
    });
  }

  void _onDoneOrError() {
    _isPlaying = false;
    _current = null;
    _playNextIfAny();
  }

  // =========================================================
  // 외부에 노출되는 API
  // =========================================================

  /// 단순 TTS (채널 신경 안 쓰고 NAVIGATE 채널로 보냄)
  Future<void> speak(
    String text, 
    ) async {
    return speakWithChannel(
      text,
      channel: ETtsChannel.NAVIGATE,
    );
  }

  /// 채널 + 우선순위 + 쿨다운까지 포함한 speak
  ///
  /// - [channel]: ALERT / FEEDBACK / SYSTEM_ANNOUNCE / NAVIGATE
  /// - [cooldownKey]: 같은 이벤트 그룹을 묶는 키 (예: "off_route", "turn_12")
  /// - [cooldown]: 이 키 기준으로 최소 재생 간격
  
  Future<void> speakWithChannel(
    String text, {
    required ETtsChannel channel,
    String? cooldownKey,
    Duration? cooldown,
    
  }) async {
    if (!_isEnabled) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final request = _TtsRequest(
      text: trimmed,
      channel: channel,
      createdAt: DateTime.now(),
      cooldownKey: cooldownKey,
      cooldown: cooldown,
    );

    // 쿨다운 체크
    if (_isUnderCooldown(request)) {
      if (_kTtsDebug) debugPrint('TtsService: under cooldown, skip => ${request.text}');
      return;
    }

    // 현재 재생 중이고, 우선순위 비교해서 인터럽트 여부 판단
    if (_isPlaying && _current != null) {
      final newPri = request.channel.priority;
      final curPri = _current!.channel.priority;

      // 새 요청이 더 높은 우선순위면 인터럽트
      if (newPri < curPri) {
        if (_kTtsDebug) {
          debugPrint(
            'TtsService: interrupt lower priority '
            '(new: ${request.channel}, cur: ${_current!.channel})',
          );
        }
        // 우선 새 요청을 큐의 제일 앞에 넣고
        _queue.insert(0, request);
        // 현재 재생 중단 (cancelHandler → _onDoneOrError → _playNextIfAny)
        try {
          await _tts.stop();
        } catch (e) {
          debugPrint('TtsService: stop error => $e');
          _isPlaying = false;
          _current = null;
        }
        return;
      }
    }

    // 일반적인 경우: 큐에 넣고 순차 재생
    _enqueueRequest(request);
    _playNextIfAny();
  }

  /// 현재 재생 중단 + 큐 비우기 + 쿨다운은 유지
  Future<void> stopAll() async {
    if (_kTtsDebug) debugPrint('TtsService: stopAll()');
    _queue.clear();
    _current = null;
    _isPlaying = false;
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TtsService: stopAll error => $e');
    }
  }

    void clearChannel(ETtsChannel channel) {
    _queue.removeWhere((r) => r.channel == channel);
  }
  // =========================================================
  // 내부 로직: 큐/쿨다운/우선순위 처리
  // =========================================================

  bool _isUnderCooldown(_TtsRequest req) {
    if (req.cooldown == null) return false;

    final key = req.cooldownKey ?? _defaultCooldownKey(req);
    final last = _cooldownMap[key];
    if (last == null) return false;

    final diff = DateTime.now().difference(last);
    return diff < req.cooldown!;
  }

  void _updateCooldown(_TtsRequest req) {
    if (req.cooldown == null) return;
    final key = req.cooldownKey ?? _defaultCooldownKey(req);
    _cooldownMap[key] = DateTime.now();
  }

  String _defaultCooldownKey(_TtsRequest req) {
    // 기본 정책: 채널 + 텍스트 조합
    return '${req.channel.name}_${req.text}';
  }

  void _enqueueRequest(_TtsRequest req) {
  // 1) 같은 channel + 같은 cooldownKey는 덮어쓰기
  if (req.cooldownKey != null) {
    _queue.removeWhere((r) =>
      r.channel == req.channel &&
      r.cooldownKey == req.cooldownKey,
    );
  }

  // 2) 큐에 추가
  _queue.add(req);

  // 3) 우선순위 정렬: 숫자 작을수록 우선, 같으면 최신(createdAt 늦은 것)이 앞으로
  _queue.sort((a, b) {
    final priorityCompare =
        a.channel.priority.compareTo(b.channel.priority);
    if (priorityCompare != 0) return priorityCompare;

    // 우선순위 같으면 최신이 앞으로 (내림차순)
    return b.createdAt.compareTo(a.createdAt);
  });

  // 4) 큐 길이 상한 적용:
  //    - 앞쪽: 중요/최신 보존
  //    - 뒤쪽: 덜 중요/오래된 항목부터 버림
  if (_queue.length > _kMaxQueueSize) {
    _queue.removeRange(_kMaxQueueSize, _queue.length);
  }
}

  void _playNextIfAny() {
    if (_isPlaying) return;
    if (_queue.isEmpty) return;

    final next = _queue.removeAt(0);
    _current = next;
    _isPlaying = true;
    _updateCooldown(next);

    if (_kTtsDebug) debugPrint('TtsService: speak => [${next.channel}] ${next.text}');

    try {
      _tts.speak(next.text);
    } catch (e) {
      debugPrint('TtsService: speak error => $e');
      _isPlaying = false;
      _current = null;
      // 에러 발생 시 다음 항목 시도
      Future.microtask(() => _playNextIfAny());
    }
  }



}