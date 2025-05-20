part of '../../framework/controller.dart';

class DestinationPickerController extends GetxController {
  /// 선택된 목적지 위치 (위경도)
  final Rx<GeoLocation?> selectedLocation = Rx<GeoLocation?>(null);

  /// 선택된 목적지 주소 문자열
  final RxString selectedAddress = ''.obs;

  /// 위치 업데이트 (지도에서 선택 시)
  void updateLocation(GeoLocation location) {
    selectedLocation.value = location;
  }

  /// 주소 업데이트 (카카오 API 등으로 변환한 주소)
  void updateAddress(String address) {
    selectedAddress.value = address;
  }

  /// 초기화 (다시 선택하거나 취소 시)
  void reset() {
    selectedLocation.value = null;
    selectedAddress.value = '';
  }
}