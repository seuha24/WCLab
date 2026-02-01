import 'package:flutter/foundation.dart';
import 'package:safelight/core/utils/auto_connect_cooldown_manager.dart';
import 'package:safelight/data/services/tts_service.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/usecase.dart';

/// 자동 BLE 연결 서비스
///
/// GPS 위치 업데이트 시 호출되어 주변 음향신호기에 자동 연결
class AutoBleConnectionService {
  final GetNearbyCitsCrosswalks _getNearbyCrosswalks;
  final SearchCrosswalk _searchCrosswalk;
  final ConnectCrosswalk _sendAcousticSignal;
  final TtsService _ttsService;
  final AutoConnectCooldownManager _cooldownManager;

  /// 자동 연결 활성화 여부
  bool isEnabled = true;

  /// 현재 연결 중인지 여부 (중복 연결 방지)
  bool _isConnecting = false;

  /// 트리거 거리 (미터)
  static const double triggerDistance = 30.0;

  AutoBleConnectionService({
    required GetNearbyCitsCrosswalks getNearbyCrosswalks,
    required SearchCrosswalk searchCrosswalk,
    required ConnectCrosswalk sendAcousticSignal,
    required TtsService ttsService,
    required AutoConnectCooldownManager cooldownManager,
  })  : _getNearbyCrosswalks = getNearbyCrosswalks,
        _searchCrosswalk = searchCrosswalk,
        _sendAcousticSignal = sendAcousticSignal,
        _ttsService = ttsService,
        _cooldownManager = cooldownManager;

  /// GPS 위치 업데이트 시 호출
  ///
  /// [latitude], [longitude]: 현재 위치
  Future<void> checkAndConnect(double latitude, double longitude) async {
    if (!isEnabled) return;
    if (_isConnecting) return;

    try {
      _isConnecting = true;

      // 1. 30m 이내 음향신호기 조회
      final result = await _getNearbyCrosswalks(
        NearbyCitsCrosswalksParams(
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: triggerDistance,
        ),
      );

      final nearbyCrosswalks = result.fold(
        (failure) => <CitsCrosswalk>[],
        (crosswalks) => crosswalks,
      );

      // 2. 범위 이탈한 기기들 쿨다운 해제
      _cooldownManager.updateCooldowns(nearbyCrosswalks);

      // 3. 연결 가능한 기기 찾기 (쿨다운 아닌 것, ID가 있는 것)
      final targetCrosswalk = _firstWhereOrNull(
        nearbyCrosswalks,
        (crosswalk) {
          final id = crosswalk.cwMgmtKey;
          return id != null && !_cooldownManager.isInCooldown(id);
        },
      );

      if (targetCrosswalk == null) return;

      debugPrint('📍 자동 연결 대상 발견: ${targetCrosswalk.cwMgmtKey}');

      // 4. BLE 스캔 (1회)
      _ttsService.speakAutoConnectStarted();

      final scanResult = await _searchCrosswalk(NoParams());
      final List<Crosswalk> scannedDevices = scanResult.fold(
        (failure) => <Crosswalk>[],
        (devices) => devices ?? <Crosswalk>[],
      );

      if (scannedDevices.isEmpty) {
        debugPrint('📍 BLE 스캔 결과 없음');
        return;
      }

      // 5. 가장 강한 신호의 기기 선택
      final sortedDevices = List<Crosswalk>.from(scannedDevices)
        ..sort((a, b) => b.post.rssi.compareTo(a.post.rssi));
      final targetBleDevice = sortedDevices.first;

      debugPrint('📍 자동 연결 시도: ${targetBleDevice.name}');

      // 6. 자동 연결 및 위치안내 전송
      await _sendAcousticSignal(targetBleDevice);

      _ttsService.speakAutoConnectSuccess();

      // 7. 쿨다운 등록 (C-ITS API 기준)
      if (targetCrosswalk.cwMgmtKey != null) {
        _cooldownManager.addCooldown(targetCrosswalk.cwMgmtKey!);
      }

      debugPrint('✅ 자동 연결 성공');
    } catch (e) {
      debugPrint('❌ 자동 연결 실패: $e');
      _ttsService.speakAutoConnectFailed();
    } finally {
      _isConnecting = false;
    }
  }

  /// List에서 조건에 맞는 첫 번째 요소 찾기 (없으면 null)
  T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final element in list) {
      if (test(element)) return element;
    }
    return null;
  }
}
