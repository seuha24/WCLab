import 'package:safelight/framework/object.dart';

/// 자동 연결 쿨다운 관리
///
/// 30m 범위 내에 있는 동안 재연결 방지
/// 범위를 벗어나면 쿨다운 해제
class AutoConnectCooldownManager {
  final Set<String> _activeConnections = {};

  /// 쿨다운 등록 (연결 성공 시)
  void addCooldown(String signalDeviceId) {
    _activeConnections.add(signalDeviceId);
  }

  /// 쿨다운 해제 (범위 이탈 시)
  void removeCooldown(String signalDeviceId) {
    _activeConnections.remove(signalDeviceId);
  }

  /// 쿨다운 상태 확인
  bool isInCooldown(String signalDeviceId) {
    return _activeConnections.contains(signalDeviceId);
  }

  /// 범위 이탈한 SignalDevice들의 쿨다운 해제
  ///
  /// [nearbyDevices]: 현재 30m 이내 SignalDevice 목록
  void updateCooldowns(List<SignalDevice> nearbyDevices) {
    final nearbyIds = nearbyDevices.map((d) => d.managementId).toSet();
    _activeConnections.removeWhere((id) => !nearbyIds.contains(id));
  }

  /// 전체 초기화
  void clearAll() {
    _activeConnections.clear();
  }
}
