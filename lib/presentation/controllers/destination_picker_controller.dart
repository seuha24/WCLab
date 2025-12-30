part of '../../framework/controller.dart';

class DestinationPickerController extends GetxController {
  final KakaoRepository _kakaoRepository = DI.get<KakaoRepository>();

  /// 선택된 목적지 위치 (위경도)
  final Rx<GeoLocation?> selectedLocation = Rx<GeoLocation?>(null);

  /// 선택된 목적지 주소 문자열
  final RxString selectedAddress = ''.obs;

  /// 현재 카메라 위치
  final Rx<NCameraPosition?> currentCameraPosition = Rx<NCameraPosition?>(null);

  /// 마지막 주소 요청 위치
  NLatLng? _lastQueriedLatLng;

  /// 주소 요청을 위한 최소 거리 변화 기준
  final double _distanceThreshold = 0.0001;

  /// 초기화 상태
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setInitialPosition();
  }

  /// 현재 위치를 받아서 카메라 초기 위치 설정
  Future<void> _setInitialPosition() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // 권한 거부 시 기본 위치로 설정 (가톨릭대학교)
        currentCameraPosition.value = const NCameraPosition(
          target: NLatLng(37.4865, 126.8018),
          zoom: 16,
        );
        isInitialized.value = true;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentCameraPosition.value = NCameraPosition(
        target: NLatLng(position.latitude, position.longitude),
        zoom: 16,
      );
      isInitialized.value = true;
    } catch (e) {
      // 에러 발생 시에도 fallback 위치로
      currentCameraPosition.value = const NCameraPosition(
        target: NLatLng(37.4865, 126.8018),
        zoom: 16,
      );
      isInitialized.value = true;
    }
  }

  /// 카메라 위치 업데이트
  void updateCameraPosition(NCameraPosition position) {
    currentCameraPosition.value = position;
  }

  /// 카메라 이동이 끝났을 때 주소 업데이트 (거리 체크 포함)
  Future<void> onCameraIdle(NLatLng newTarget) async {
    // 일정 거리 이상 이동한 경우에만 주소 요청
    if (_lastQueriedLatLng != null) {
      final dx = (_lastQueriedLatLng!.latitude - newTarget.latitude).abs();
      final dy = (_lastQueriedLatLng!.longitude - newTarget.longitude).abs();
      if (dx < _distanceThreshold && dy < _distanceThreshold) return;
    }

    _lastQueriedLatLng = newTarget;
    await _updateAddress(newTarget);
  }

  /// 카카오 API를 통해 위경도로부터 주소 문자열을 얻음
  Future<void> _updateAddress(NLatLng latLng) async {
    final result = await _kakaoRepository.getAddressFromCoordinates(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    result.fold(
      (failure) {
        selectedAddress.value = '주소 요청 실패';
      },
      (address) {
        selectedAddress.value = address;
      },
    );
  }

  /// 위치 업데이트 (지도에서 선택 시)
  void updateLocation(GeoLocation location) {
    selectedLocation.value = location;
  }

  /// 초기화 (다시 선택하거나 취소 시)
  void reset() {
    selectedLocation.value = null;
    selectedAddress.value = '';
    _lastQueriedLatLng = null;
  }
}