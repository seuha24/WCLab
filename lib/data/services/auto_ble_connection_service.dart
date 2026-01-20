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
  final GetNearbySignalDevices _getNearbySignalDevices;
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
    required GetNearbySignalDevices getNearbySignalDevices,
    required SearchCrosswalk searchCrosswalk,
    required ConnectCrosswalk sendAcousticSignal,
    required TtsService ttsService,
    required AutoConnectCooldownManager cooldownManager,
  })  : _getNearbySignalDevices = getNearbySignalDevices,
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

      // 1. 30m 이내 SignalDevice 조회
      final result = await _getNearbySignalDevices(
        NearbySignalDevicesParams(
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: triggerDistance,
        ),
      );

      final nearbyDevices = result.fold(
        (failure) => <SignalDevice>[],
        (devices) => devices,
      );

      // 2. 범위 이탈한 기기들 쿨다운 해제
      _cooldownManager.updateCooldowns(nearbyDevices);

      // 3. 연결 가능한 기기 찾기 (쿨다운 아닌 것)
      final targetDevice = _firstWhereOrNull(
        nearbyDevices,
        (device) => !_cooldownManager.isInCooldown(device.managementId),
      );

      if (targetDevice == null) return;

      debugPrint('📍 자동 연결 대상 발견: ${targetDevice.managementId}');

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
      final targetCrosswalk = sortedDevices.first;

      debugPrint('📍 자동 연결 시도: ${targetCrosswalk.name}');

      // 6. 자동 연결 및 신호안내 전송
      await _sendAcousticSignal(targetCrosswalk);

      _ttsService.speakAutoConnectSuccess();

      // 7. 쿨다운 등록
      _cooldownManager.addCooldown(targetDevice.managementId);

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
