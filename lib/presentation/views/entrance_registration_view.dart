part of '../../framework/ui.dart';

class EntranceRegistrationView extends StatefulWidget {
  const EntranceRegistrationView({super.key});

  @override
  State<EntranceRegistrationView> createState() =>
      _EntranceRegistrationViewState();
}

class _EntranceRegistrationViewState extends State<EntranceRegistrationView> {
  final TextEditingController roadAddressController = TextEditingController();
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController buildingDetailController =
      TextEditingController();
  final TextEditingController entranceNameController = TextEditingController();

  late EntranceRegistrationBloc bloc;
  NaverMapController? _mapController;
  NLatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    bloc = EntranceRegistrationBloc(
      sendCustomStartPointUseCase: DI.get<SendCustomStartPointUseCase>(),
    );
  }

  @override
  void dispose() {
    roadAddressController.dispose();
    buildingNameController.dispose();
    buildingDetailController.dispose();
    entranceNameController.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text("출입구 등록")),
        body: BlocConsumer<EntranceRegistrationBloc, EntranceRegistrationState>(
          listener: (context, state) {
            if (state is RegistrationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is EntranceSubmissionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("출입구 정보가 저장되었습니다.")),
              );
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            final address = (state is RegistrationLoaded) ? state.address : '';
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      NaverMap(
                        onMapReady: (controller) => _mapController = controller,
                        options: const NaverMapViewOptions(
                          locationButtonEnable: true,
                          initialCameraPosition: NCameraPosition(
                            target: NLatLng(37.4865, 126.8018),
                            zoom: 16,
                          ),
                        ),
                        onCameraIdle: () async {
                          if (_mapController == null) return;
                          final pos = await _mapController!.getCameraPosition();
                          _selectedLocation = pos.target;
                          context
                              .read<EntranceRegistrationBloc>()
                              .add(AddressUpdated(pos.target));
                        },
                      ),
                      const Center(
                        child: Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      ),
                      Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Text(address, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: buildingNameController,
                          decoration: const InputDecoration(
                            labelText: '건물 이름',
                            hintText: '예: 가톨릭대학교 성심교정',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: buildingDetailController,
                          decoration: const InputDecoration(
                            labelText: '건물 상세정보',
                            hintText: '예: 다솔관',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: entranceNameController,
                          decoration: const InputDecoration(
                            labelText: '출입구 이름',
                            hintText: '예: 정문, 후문, 측문',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (state is RegistrationLoading ||
                                  state is! RegistrationLoaded ||
                                  entranceNameController.text.isEmpty ||
                                  _selectedLocation == null)
                              ? null
                              : () {
                                  final currentState = state;
                                  final singleEntrance = EntranceInfo(
                                    entranceName:
                                        entranceNameController.text.trim(),
                                    location: LatLng(
                                      _selectedLocation!.longitude,
                                      _selectedLocation!.latitude,
                                    ),
                                  );

                                  final params = SendPointParams(
                                    roadAddress: currentState.address,
                                    buildingName:
                                        buildingNameController.text.trim(),
                                    buildingDetail:
                                        buildingDetailController.text.trim(),
                                    longitude: _selectedLocation!.longitude,
                                    latitude: _selectedLocation!.latitude,
                                    entrances: [singleEntrance],
                                  );

                                  debugPrint('\n=== 서버로 전송될 JSON 데이터 ===');
                                  final model = SendStartPointModel(params);
                                  debugPrint(jsonEncode(model.toJson()));
                                  debugPrint(
                                      '===============================\n');

                                  context
                                      .read<EntranceRegistrationBloc>()
                                      .add(SubmitEntranceData(params));
                                },
                          child: (state is RegistrationLoading)
                              ? const CircularProgressIndicator()
                              : const Text('저장'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}