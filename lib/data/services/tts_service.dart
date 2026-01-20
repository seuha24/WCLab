import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:safelight/core/utils/tts_messages.dart';

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

  // =========================================================
  // Convenience 메서드: 경로 안내
  // =========================================================

  /// 목적지 도착 안내
  void speakArrivedAtDestination() {
    speakWithChannel(
      TtsMessages.arrivedAtDestination,
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'arrive_destination',
      cooldown: const Duration(seconds: 20),
    );
  }

  /// 출발지로 이동 안내
  void speakMoveToStartPoint() {
    speakWithChannel(
      TtsMessages.moveToStartPoint,
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'move_to_startpoint',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 분기점 안내
  void speakBranchInstruction(String message) {
    speakWithChannel(
      TtsMessages.branchInstruction(message),
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'branch_instruction',
      cooldown: const Duration(seconds: 10),
    );
  }

  /// 경로 재탐색 완료 안내
  void speakRerouteComplete() {
    speakWithChannel(
      TtsMessages.rerouteComplete,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'reroute_done',
      cooldown: const Duration(seconds: 10),
    );
  }

  /// 출발지 이탈로 인한 재탐색 안내
  void speakRerouteFromDeviation() {
    speakWithChannel(
      TtsMessages.rerouteFromDeviation,
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'research_out_of_start',
      cooldown: const Duration(seconds: 10),
    );
  }

  /// 남은 거리 안내
  void speakRemainingDistance(int meters) {
    speakWithChannel(
      TtsMessages.remainingDistance(meters),
      channel: ETtsChannel.FEEDBACK,
      cooldownKey: 'on_tap_remain_distance',
      cooldown: Duration.zero,
    );
  }

  /// 주변 POI 안내
  void speakNearbyPoi(List<String> descriptions, {String? lastPoiName}) {
    speakWithChannel(
      TtsMessages.nearbyPoiSummary(descriptions, lastPoiName: lastPoiName),
      channel: ETtsChannel.NAVIGATE,
      cooldownKey: 'nearby_poi',
      cooldown: const Duration(seconds: 10),
    );
  }

  // =========================================================
  // Convenience 메서드: 안전 경고
  // =========================================================

  /// 횡단보도 접근 경고
  void speakCrosswalkAhead() {
    speakWithChannel(
      TtsMessages.crosswalkAhead,
      channel: ETtsChannel.ALERT,
      cooldownKey: 'crosswalk_alert',
      cooldown: const Duration(seconds: 2),
    );
  }

  /// 경로 이탈 안내 (시계 방향)
  void speakOutOfBound(String clockDirection) {
    speakWithChannel(
      TtsMessages.outOfBound(clockDirection),
      channel: ETtsChannel.ALERT,
      cooldownKey: 'out_of_bound',
      cooldown: const Duration(seconds: 10),
    );
  }

  // =========================================================
  // Convenience 메서드: 경광등 제어
  // =========================================================

  /// 경광등 켜짐 안내
  void speakFlashTurnedOn() {
    speakWithChannel(
      TtsMessages.flashTurnedOn,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'flashlight_on_success',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 경광등 꺼짐 안내
  void speakFlashTurnedOff() {
    speakWithChannel(
      TtsMessages.flashTurnedOff,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'flashlight_off_success',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 경광등 켜기 실패 안내
  void speakCannotTurnOnFlash() {
    speakWithChannel(
      TtsMessages.cannotTurnOnFlash,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'flashlight_on_fail',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 경광등 끄기 실패 안내
  void speakCannotTurnOffFlash() {
    speakWithChannel(
      TtsMessages.cannotTurnOffFlash,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'flashlight_off_fail',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 경광등 제어 오류 안내
  void speakFlashControlError() {
    speakWithChannel(
      TtsMessages.flashControlError,
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
      cooldownKey: 'flashlight_control_error',
      cooldown: const Duration(seconds: 5),
    );
  }

  /// 경광등 현재 켜져있음 안내 (주기적)
  void speakFlashLightCurrentlyOn() {
    speak(TtsMessages.flashLightCurrentlyOn);
  }

  // =========================================================
  // Convenience 메서드: UI 피드백
  // =========================================================

  /// 패널 토글 안내
  void speakPanelToggle(String menu, String state) {
    speakWithChannel(
      TtsMessages.panelToggle(menu, state),
      channel: ETtsChannel.FEEDBACK,
      cooldownKey: 'panel_action',
      cooldown: Duration.zero,
    );
  }

  /// 패널 전환 안내
  void speakPanelSwitch(String menu) {
    speakWithChannel(
      TtsMessages.panelSwitch(menu),
      channel: ETtsChannel.FEEDBACK,
      cooldownKey: 'panel_action',
      cooldown: Duration.zero,
    );
  }

  /// 즐겨찾기 지점 안내 선택
  void speakNavigateToFavoritePoint(String name) {
    speakWithChannel(
      TtsMessages.navigateToFavoritePoint(name),
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
    );
  }

  /// 즐겨찾기 경로 안내 선택
  void speakNavigateToFavoriteRoute(String name) {
    speakWithChannel(
      TtsMessages.navigateToFavoriteRoute(name),
      channel: ETtsChannel.SYSTEM_ANNOUNCE,
    );
  }

  // =========================================================
  // Convenience 메서드: BLE/스마트 압버튼
  // =========================================================

  /// BLE 찾기 안내 (초기 화면)
  void speakBleScanPrompt() {
    speak(TtsMessages.bleScanPrompt);
  }

  /// BLE 스캔 중 안내
  void speakBleScanning() {
    speak(TtsMessages.bleScanning);
  }

  /// BLE 찾지 못함 안내
  void speakBleNotFound() {
    speak(TtsMessages.bleNotFound);
  }

  /// 자동 스캔 시작 안내
  void speakAutoScanStarted() {
    speak(TtsMessages.autoScanStarted);
  }

  /// 스마트 압버튼 발견 안내
  void speakSmartButtonsFound(int count) {
    speak(TtsMessages.smartButtonsFound(count));
  }

  /// 신호안내 요청 안내
  void speakRequestSignalGuide(String name) {
    speak(TtsMessages.requestSignalGuide(name));
  }

  /// 명령 전송 완료 안내
  void speakCommandSent() {
    speak(TtsMessages.commandSent);
  }

  /// 연결 실패 안내
  void speakConnectionFailed() {
    speak(TtsMessages.connectionFailed);
  }

  /// 연결 중 안내
  void speakConnectingTo(String name) {
    speak(TtsMessages.connectingTo(name));
  }

  /// 진동 방향 안내
  void speakWalkTowardsNoVibration() {
    speak(TtsMessages.walkTowardsNoVibration);
  }

  /// 음성안내 요청 안내
  void speakRequestVoiceGuide(String name) {
    speak(TtsMessages.requestVoiceGuide(name));
  }

  /// 음향신호기 위치 안내
  void speakSignalDeviceLocationInfo() {
    speak(TtsMessages.signalDeviceLocationInfo);
  }

  /// 블루투스 꺼짐 안내
  void speakBluetoothOff() {
    speak(TtsMessages.bluetoothOff);
  }

  // =========================================================
  // Convenience 메서드: 검색/장소 선택
  // =========================================================

  /// 장소 선택됨 안내
  void speakPlaceSelected(String name) {
    speak(TtsMessages.placeSelected(name));
  }

  /// 장소로 안내 시작
  void speakNavigatingTo(String name) {
    speak(TtsMessages.navigatingTo(name));
  }

  /// 출입구로 안내 시작
  void speakNavigatingToEntrance(String entranceName) {
    speak(TtsMessages.navigatingToEntrance(entranceName));
  }

  /// 취소 안내
  void speakCancelled() {
    speak(TtsMessages.cancelled);
  }

  /// 위치 권한 필요 안내
  void speakLocationPermissionRequired() {
    speak(TtsMessages.locationPermissionRequired);
  }

  /// 현재 위치 설정됨 안내
  void speakCurrentLocationSet() {
    speak(TtsMessages.currentLocationSet);
  }

  /// 현재 위치 가져오기 실패 안내
  void speakCannotGetCurrentLocation() {
    speak(TtsMessages.cannotGetCurrentLocation);
  }

  /// 지도에서 위치 선택됨 안내
  void speakLocationSelected(String address) {
    speak(TtsMessages.locationSelected(address));
  }

  /// 안전 나침반 켜짐 안내
  void speakSafetyCompassOn() {
    speak(TtsMessages.safetyCompassOn);
  }
}