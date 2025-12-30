part of '../../framework/ui.dart';

class DestinationPickerView extends StatefulWidget {
  const DestinationPickerView({super.key});

  @override
  State<DestinationPickerView> createState() => _DestinationPickerViewState();
}

class _DestinationPickerViewState extends State<DestinationPickerView> {
  final DestinationPickerController controller =
      Get.put(DestinationPickerController());

  NaverMapController? _naverMapController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 초기 위치가 정해지지 않았으면 로딩 스피너 표시
      if (!controller.isInitialized.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: Stack(
          children: [
            /// 네이버 맵 뷰 - 중심 마커 방식 구현
            NaverMap(
              onMapReady: (mapController) {
                _naverMapController = mapController;
              },
              options: NaverMapViewOptions(
                initialCameraPosition: controller.currentCameraPosition.value!,
                locationButtonEnable: true,
              ),
              onCameraChange: (reason, isAnimated) async {
                // 카메라 이동 중 위치 갱신
                if (_naverMapController == null) return;
                final pos = await _naverMapController!.getCameraPosition();
                controller.updateCameraPosition(pos);
              },
              onCameraIdle: () async {
                // 카메라 이동이 끝난 뒤에만 주소 요청 수행
                if (_naverMapController == null) return;
                final pos = await _naverMapController!.getCameraPosition();
                await controller.onCameraIdle(pos.target);
              },
            ),

            /// 중심에 고정된 마커 아이콘
            const Center(
              child: Icon(
                Icons.location_pin,
                size: 40,
                color: Colors.red,
              ),
            ),

            /// 주소 표시 영역 (Obx로 reactive UI 구성)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Obx(() => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.selectedAddress.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  )),
            ),
          ],
        ),

        /// 하단 버튼 - 현재 카메라 위치를 선택 위치로 저장 후 반환
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              final cameraPosition = controller.currentCameraPosition.value;
              if (cameraPosition == null) return;
              final geoLocation = GeoLocation(
                lat: cameraPosition.target.latitude,
                lng: cameraPosition.target.longitude,
              );
              controller.updateLocation(geoLocation);
              Navigator.pop(context, {
                'location': geoLocation,
                'address': controller.selectedAddress.value,
              });
            },
            child: const Text('이 위치로 설정'),
          ),
        ),
      );
    });
  }
}
