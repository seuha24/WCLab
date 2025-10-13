part of '../../../framework/ui.dart';

class EntrancePanelView extends StatefulWidget {
  const EntrancePanelView({super.key});

  @override
  State<EntrancePanelView> createState() => _EntrancePanelViewState();
}

class _EntrancePanelViewState extends State<EntrancePanelView> {
  final TextEditingController roadAddressController = TextEditingController();
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController buildingDetailController =
      TextEditingController();
  final TextEditingController entranceNameController = TextEditingController();

  late EntranceRegistrationBloc bloc;
  late DraggableScrollableController _controller;
  late SlidingPanelController _slidingController;
  NaverMapController? _mapController;
  final Rx<NLatLng?> _selectedLocation = Rx<NLatLng?>(null);

  // 디바운스를 위한 타이머
  Timer? _debounceTimer;

  // 마지막으로 처리된 위치를 저장하여 중복 처리 방지
  NLatLng? _lastProcessedLocation;

  // 카메라 이동 중인지 확인하는 플래그
  bool _isCameraMoving = false;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _slidingController = Get.find<SlidingPanelController>();

    // 출입구 등록 화면용 컨트롤러 등록
    _slidingController.registerPanel(
      'entrance_panel',
      _controller,
      config: PanelConfig(
        minHeight: 0.0,
        maxHeight: 0.9,
        defaultHeight: 0.4,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
      ),
    );

    bloc = EntranceRegistrationBloc(
      sendCustomStartPointUseCase: DI.get<SendCustomStartPointUseCase>(),
    );

    // bloc을 GetX로 등록하여 다른 곳에서 찾을 수 있도록 함
    Get.put(bloc);

    final mapController = Get.find<NaverMapViewController>();

    // 초기 위치 설정
    if (mapController.current_latitude.value != null &&
        mapController.current_longitude.value != null) {
      final initialLatLng = NLatLng(
        mapController.current_latitude.value,
        mapController.current_longitude.value,
      );
      _selectedLocation.value = initialLatLng;
      _lastProcessedLocation = initialLatLng;
      bloc.add(AddressUpdated(initialLatLng));
    }

    // bloc 상태 변화 리스너 (기존과 동일)
    bloc.stream.listen((state) {
      if (state is RegistrationLoaded) {
        // 블록 상태가 업데이트되면 현재 선택된 위치도 업데이트
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // 타이머 정리
    _controller.dispose();
    roadAddressController.dispose();
    buildingNameController.dispose();
    buildingDetailController.dispose();
    entranceNameController.dispose();

    // GetX에서 bloc 제거 후 close
    try {
      Get.delete<EntranceRegistrationBloc>();
    } catch (e) {
      debugPrint('Failed to remove EntranceRegistrationBloc from GetX: $e');
    }
    bloc.close();
    super.dispose();
  }

  // 디바운스가 적용된 위치 업데이트 메서드
  void updateSelectedLocationWithDebounce(NLatLng newLocation) {
    // 같은 위치면 무시
    if (_lastProcessedLocation != null &&
        _isSameLocation(_lastProcessedLocation!, newLocation)) {
      return;
    }

    _selectedLocation.value = newLocation;

    // 기존 타이머 취소
    _debounceTimer?.cancel();

    // 1000ms 후에 주소 업데이트 실행
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && !_isCameraMoving && !bloc.isClosed) {
        _lastProcessedLocation = newLocation;
        bloc.add(AddressUpdated(newLocation));
      }
    });
  }

  // 카메라 이동 시작을 알리는 메서드 (map_view.dart에서 호출)
  void onCameraIdle() {
    _isCameraMoving = false;
    if (_selectedLocation.value != null) {
      updateSelectedLocationWithDebounce(_selectedLocation.value!);
    }
  }

  // 카메라 이동 시작을 알리는 메서드 (map_view.dart에서 호출)
  void onCameraMoveStarted() {
    _isCameraMoving = true;
    _debounceTimer?.cancel(); // 카메라 이동 중에는 주소 업데이트 중단
  }

  // 위치가 같은지 확인하는 헬퍼 메서드 (작은 차이는 무시)
  bool _isSameLocation(NLatLng location1, NLatLng location2) {
    const double tolerance = 0.000001; // 약 10cm 정도의 차이
    return (location1.latitude - location2.latitude).abs() < tolerance &&
        (location1.longitude - location2.longitude).abs() < tolerance;
  }

  // 즉시 위치 업데이트 메서드 (필요한 경우에만 사용)
  void updateSelectedLocationImmediately(NLatLng newLocation) {
    if (!bloc.isClosed) {
      _selectedLocation.value = newLocation;
      _lastProcessedLocation = newLocation;
      bloc.add(AddressUpdated(newLocation));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.9,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BlocProvider(
            create: (_) => bloc,
            child: BlocConsumer<EntranceRegistrationBloc,
                EntranceRegistrationState>(
              listener: (context, state) {
                if (state is RegistrationFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is EntranceSubmissionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("출입구 정보가 저장되었습니다.")),
                  );
                  _controller.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              builder: (context, state) {
                final address =
                    (state is RegistrationLoaded) ? state.address : '';
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        '등록',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Gap(height: 15),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildRoundedField(
                            controller: buildingNameController,
                            label: '건물 이름',
                            hint: '예: 가톨릭대학교 성심교정',
                          ),
                          const Gap(height: 15),
                          _buildRoundedField(
                            controller: buildingDetailController,
                            label: '건물 상세정보',
                            hint: '예: 다솔관',
                          ),
                          const Gap(height: 15),
                          _buildRoundedField(
                            controller: entranceNameController,
                            label: '출입구 이름',
                            hint: '예: 주출입구',
                          ),
                          const Gap(height: 28),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (state is RegistrationLoading ||
                                      state is! RegistrationLoaded ||
                                      entranceNameController.text.isEmpty ||
                                      _selectedLocation.value == null)
                                  ? null
                                  : () {
                                      final currentState =
                                          state as RegistrationLoaded;
                                      final singleEntrance = EntranceInfo(
                                        entranceName:
                                            entranceNameController.text.trim(),
                                        location: LatLng(
                                          _selectedLocation.value!.longitude,
                                          _selectedLocation.value!.latitude,
                                        ),
                                      );
                                      final params = SendPointParams(
                                        roadAddress: currentState.address,
                                        buildingName:
                                            buildingNameController.text.trim(),
                                        buildingDetail: buildingDetailController
                                            .text
                                            .trim(),
                                        longitude:
                                            _selectedLocation.value!.longitude,
                                        latitude:
                                            _selectedLocation.value!.latitude,
                                        entrances: [singleEntrance],
                                      );
                                      context
                                          .read<EntranceRegistrationBloc>()
                                          .add(SubmitEntranceData(params));
                                    },
                              icon: const Icon(Icons.map,
                                  color: Colors.white, size: 20),
                              label: const Text(
                                '등록하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoundedField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
