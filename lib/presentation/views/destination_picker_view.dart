part of '../../framework/ui.dart';

class DestinationPickerView extends StatefulWidget {
  @override
  State<DestinationPickerView> createState() => _DestinationPickerViewState();
}

class _DestinationPickerViewState extends State<DestinationPickerView> {
  final DestinationPickerController controller = Get.put(DestinationPickerController());

  final RxString _address = ''.obs;
  NCameraPosition? _currentCameraPosition;
  NaverMapController? _naverMapController;
  NLatLng? _lastQueriedLatLng; // 마지막 주소 요청 위치 저장
  final double _distanceThreshold = 0.0001; // 주소 요청을 위한 최소 거리 변화 기준

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  /// 현재 위치를 받아서 카메라 초기 위치 설정
  Future<void> _setInitialPosition() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        // 권한 거부 시 기본 위치로 설정 (가톨릭대학교)
        setState(() {
          _currentCameraPosition = const NCameraPosition(
            target: NLatLng(37.4865, 126.8018),
            zoom: 16,
          );
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
       locationSettings: const LocationSettings(
         accuracy: LocationAccuracy.high,
       ),
      );

      setState(() {
        _currentCameraPosition = NCameraPosition(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 16,
        );
      });
    } catch (e) {
      // 에러 발생 시에도 fallback 위치로
      setState(() {
        _currentCameraPosition = const NCameraPosition(
          target: NLatLng(37.4865, 126.8018),
          zoom: 16,
        );
      });
    }
  }

  /// 카카오 API를 통해 위경도로부터 주소 문자열을 얻음
  Future<void> _updateAddress(NLatLng latLng) async {
    final lat = latLng.latitude;
    final lng = latLng.longitude;

    try {
      final apiKey = '93848fcc11798c6f48099dd2e2373263';
      final url =
          'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK $apiKey'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final documents = jsonResponse['documents'];

        if (documents.isNotEmpty) {
          // 도로명 주소가 있으면 우선 사용, 없으면 지번 주소 사용
          final addressName = documents[0]['road_address']?['address_name']
            ?? documents[0]['address']['address_name'];
            
          _address.value = addressName;
          controller.updateAddress(addressName); // 컨트롤러에 주소 업데이트
        } else {
          _address.value = '주소를 찾을 수 없습니다';
        }
      } else {
        _address.value = '주소 요청 실패';
      }
    } catch (_) {
      _address.value = '주소 요청 오류';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기 위치가 정해지지 않았으면 로딩 스피너 표시
    if (_currentCameraPosition == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          /// 네이버 맵 뷰 - 중심 마커 방식 구현
          NaverMap(
            onMapReady: (controller) {
              _naverMapController = controller;
            },
            options: NaverMapViewOptions(
              initialCameraPosition: _currentCameraPosition!,
              locationButtonEnable: true,
            ),
            onCameraChange: (reason, isAnimated) async {
              // 카메라 이동 중 위치 갱신
              if (_naverMapController == null) return;
              final pos = await _naverMapController!.getCameraPosition();
              _currentCameraPosition = pos;
            },
            onCameraIdle: () async {
              // 카메라 이동이 끝난 뒤에만 주소 요청 수행
              if (_naverMapController == null) return;
              final pos = await _naverMapController!.getCameraPosition();
              final newTarget = pos.target;

              // 일정 거리 이상 이동한 경우에만 주소 요청
              if (_lastQueriedLatLng != null) {
                final dx = (_lastQueriedLatLng!.latitude - newTarget.latitude).abs();
                final dy = (_lastQueriedLatLng!.longitude - newTarget.longitude).abs();
                if (dx < _distanceThreshold && dy < _distanceThreshold) return;
              }

              _lastQueriedLatLng = newTarget;
              await _updateAddress(newTarget);
            },
          ),

          /// 중심에 고정된 마커 아이콘
          Center(
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
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _address.value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
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
            if (_currentCameraPosition == null) return; // 안전 체크
            final geoLocation = GeoLocation(
              lat: _currentCameraPosition!.target.latitude,
              lng: _currentCameraPosition!.target.longitude,
            );
            controller.updateLocation(geoLocation);
            Navigator.pop(context, {
              'location': geoLocation,
              'address': _address.value,
            });
          },
          child: Text('이 위치로 설정'),
        ),
      ),
    );
  }
}
