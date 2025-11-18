part of '../../framework/controller.dart';

/// 지도 및 경로 관련 사용자 인터랙션을 담당하는 서비스 클래스
///
/// - 출발지/목적지 선택
/// - 커스텀 출발지 설정
/// - 지도 모드 토글 및 드래그 처리
/// - 경광등 토글
class UserInteraction {
  UserInteraction({
    required this.overlayController,
    required this.pdrCalculator,
    required this.flashOn,
    required this.flashOff,
  });

  final MapOverlayController overlayController;
  final PdrCalculator pdrCalculator;
  final ControlFlash flashOn;
  final ControlFlash flashOff;
  
  /// 출발지 선택 처리
  Future<void> handleStartLocationSelection({
    required GeoLocation newStart,
    required Rxn<GeoLocation> selectedStartLocation,
    required RxBool isStart,
    required RxBool isSetStartLocation,
  }) async {
    selectedStartLocation.value = newStart;
    isStart.value = true;
    isSetStartLocation.value = true;
    debugPrint('출발지가 설정되었습니다.');
  }

  /// 목적지 선택 처리
  Future<void> handleDestinationLocationSelection({
    required GeoLocation newDest,
    required Rxn<GeoLocation> selectedDestLocation,
    required Rxn<GeoLocation> selectedStartLocation,
    required RxBool isSetDestinationLocation,
    required RxBool isSetStartLocation,
    required RxDouble currentLatitude,
    required RxDouble currentLongitude,
  }) async {
    selectedDestLocation.value = newDest;
    isSetDestinationLocation.value = true;

    // 출발지가 설정되지 않은 경우 현재 위치를 출발지로 자동 설정
    if (!isSetStartLocation.value) {
      selectedStartLocation.value = GeoLocation(
        lat: currentLatitude.value,
        lng: currentLongitude.value,
      );
      isSetStartLocation.value = true;
      debugPrint(
        '출발지가 설정되지 않아 현위치를 출발지로 자동 설정됨: '
        '${selectedStartLocation.value!.lat}, ${selectedStartLocation.value!.lng}',
      );
    }

    debugPrint('목적지가 설정되었습니다. 경로 선택을 기다립니다.');
  }

  /// 지도 중심 좌표를 커스텀 출발지로 설정
  Future<void> setCustomStartLocationFromCamera({
    required bool isGps,
    required NaverMapController? mapController,
    required RxBool isCustomStartPoint,
    required RxDouble cameraStartLat,
    required RxDouble cameraStartLng,
    required RxDouble currentLatitude,
    required RxDouble currentLongitude,
    required Rxn<GeoLocation> selectedStartLocation,
    required RxBool isSetStartLocation,
    required RxDouble compassValue,
    required Rx<MapControlMode> mapMode,
  }) async {
    if (isGps) {
      debugPrint("GPS 사용 중이므로 수동 위치 설정 차단됨");
      return;
    }

    isCustomStartPoint.value = true; // 커스텀 출발지 플래그 설정

    if (mapController == null) {
      debugPrint('mapController가 아직 초기화되지 않았습니다.');
      return;
    }

    // 현재 카메라 중심을 가져와서 저장
    final cameraPosition = await mapController.getCameraPosition();
    final double targetLat = cameraPosition.target.latitude;
    final double targetLng = cameraPosition.target.longitude;

    cameraStartLat.value = targetLat;
    cameraStartLng.value = targetLng;

    // 상대좌표 계산 (IMU 위치 기준 → 사용자 선택 위치로 보정)
    pdrCalculator.updateRelativeCoordinates(
      currentLatitude.value,
      currentLongitude.value,
      cameraStartLat.value,
      cameraStartLng.value,
    );

    // 현재 위치를 카메라 중심값으로 갱신
    currentLatitude.value = targetLat;
    currentLongitude.value = targetLng;

    // 출발지로 고정
    selectedStartLocation.value = GeoLocation(lat: targetLat, lng: targetLng);
    isSetStartLocation.value = true;

    // 마커도 즉시 지도에 반영
    await overlayController.updateCurrentLocationMarker(
      targetLat,
      targetLng,
      compassValue.value,
      false,
      mapMode.value,
    );

    debugPrint("출발지 위치 수동 고정 완료: ($targetLat, $targetLng)");
  }

  /// 지도 모드 토글
  Future<void> toggleMapMode({
    required Rx<MapControlMode> mapMode,
  }) async {
    if (mapMode.value == MapControlMode.idle) {
      mapMode.value = MapControlMode.off;
    }

    int nextIndex = (mapMode.value.index + 1) % MapControlMode.values.length;

    // idle 모드는 스킵
    if (MapControlMode.values[nextIndex] == MapControlMode.idle) {
      nextIndex = (nextIndex + 1) % MapControlMode.values.length;
    }

    mapMode.value = MapControlMode.values[nextIndex];
    debugPrint("모드 전환: ${mapMode.value}");
  }

  /// 지도 드래그 처리
  void handleMapDrag({
    required Rx<MapControlMode> mapMode,
  }) {
    if (mapMode.value != MapControlMode.off) {
      mapMode.value = MapControlMode.off;
    }
  }

  /// 경광등 토글
  Future<void> toggleFlashlight({
    required RxBool isFlashOn,
    required Future<void> Function(String text) speakText,
  }) async {
    try {
      if (isFlashOn.value) {
        // 경광등이 켜져 있으면 끄기
        final result = await flashOff(NoParams());
        if (result.isLeft()) {
          await speakText('안전 경광등을 끌 수 없습니다.');
        } else {
          isFlashOn.value = false;
          await speakText('안전 경광등이 꺼졌습니다.');
        }
      } else {
        // 경광등이 꺼져 있으면 켜기
        final result = await flashOn(NoParams());
        if (result.isLeft()) {
          await speakText('안전 경광등을 켤 수 없습니다.');
        } else {
          isFlashOn.value = true;
          await speakText('안전 경광등이 켜졌습니다.');
        }
      }
    } catch (e) {
      debugPrint('경광등 제어 중 오류 발생: $e');
      await speakText('안전 경광등 제어 중 오류가 발생했습니다.');
    }
  }
}
