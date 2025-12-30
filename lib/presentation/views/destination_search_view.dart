part of '../../framework/ui.dart';

class DesSearch extends StatefulWidget {
  const DesSearch({
    super.key,
    required this.destinationValue,
  });

  final String destinationValue;

  @override
  State<DesSearch> createState() => _DesSearchState();
}

class _DesSearchState extends State<DesSearch> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // TTS 서비스 (음성 안내용)
  final TtsService ttsService = DI.get<TtsService>();

  // Kakao Repository (장소 검색)
  final KakaoRepository kakaoRepository = DI.get<KakaoRepository>();

  final FocusNode _focusNode = FocusNode();

  List<PlaceResult> places = []; // 전체 장소 검색 결과
  List<PlaceResult> _searchResults = []; // 현재 화면에 표시할 결과

  @override
  void initState() {
    super.initState();
    // 초기 검색어가 있을 경우 입력 필드에 설정
    if (widget.destinationValue.isNotEmpty) {
      _searchController.text = widget.destinationValue;
    }
    // 앱 시작 시 입력창에 자동 포커스
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 검색어 입력 시 디바운싱 적용 (0.5초 후 실행)
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 디바운스 타이머 설정
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // TTS로 안내 메시지 읽어줌
  Future<void> speakTTS(String message) async {
    ttsService.speak(message);
  }

  // Kakao API를 사용하여 장소 검색 요청
  Future<List<PlaceResult>> placeSearch(String query) async {
    final result = await kakaoRepository.searchPlaces(query);

    return result.fold(
      (failure) {
        // 검색 실패 시 기존 결과 유지
        return places;
      },
      (newPlaces) {
        // 검색 성공 시 결과가 있으면 업데이트
        if (newPlaces.isNotEmpty) {
          places = newPlaces;
        }
        return places;
      },
    );
  }

  // 입력된 검색어로 장소 검색 실행
  void _performSearch(String query) async {
    List<PlaceResult> results = await placeSearch(query);
    setState(() {
      _searchResults = results;
    });
  }

  // 장소를 선택했을 때 확인 다이얼로그 표시
  Future<bool?> showConfirmationDialog(
      BuildContext context, PlaceResult result) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('목적지 확인', style: TextStyle(color: Colors.black)),
          content: Text(
            '${result.name}(으)로 안내할까요?',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // 확인 버튼을 눌렀을 때 수행할 작업
                debugPrint('선택된 장소: ${result.name}');
                debugPrint('전송되는 주소: ${result.address}');
                Navigator.pop(context, true); // true는 확인을 의미합니다.
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () {
                // 취소 버튼을 눌렀을 때 수행할 작업
                Navigator.pop(context, false); // false는 취소를 의미합니다.
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('목적지 검색하기'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F5),
                  borderRadius: BorderRadius.circular(28.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (query) {
                    if (query.isNotEmpty) _onSearchChanged();
                  },
                  decoration: InputDecoration(
                    hintText: '도착지 장소 및 주소 검색',
                    hintStyle: TextStyle(
                      fontSize: AppSizes.scaledFont(20),
                      color: const Color(0xff9E9E9E),
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: '검색어 삭제',
                            onPressed: () {
                              _searchController.clear();
                              _searchResults.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      tileColor: Colors.white,
                      title: Text(result.name),
                      subtitle: Text(result.address),
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        _searchController.text = result.name;
                        Future.microtask(
                            () => speakTTS('${result.name}을 선택하셨습니다.'));
                        bool? confirmed =
                            await showConfirmationDialog(context, result);
                        if (confirmed == true) {
                          debugPrint('=== 출입구 정보 요청 시작 ===');
                          final stopwatch = Stopwatch()..start();
                          context.read<EntranceBloc>().add(
                                FetchBuildingEntrances(
                                  address: result.address,
                                  longitude: result.geometry.location.lng,
                                  latitude: result.geometry.location.lat,
                                ),
                              );
                          await for (final entranceState
                              in context.read<EntranceBloc>().stream.timeout(
                            const Duration(seconds: 10),
                            onTimeout: (sink) {
                              stopwatch.stop();
                              debugPrint(
                                  '[Entrance Lookup] 타임아웃 발생 (조회 시간: ${stopwatch.elapsedMilliseconds} ms)');
                              if (!mounted) return;
                              context.read<SearchBloc>().add(
                                    SearchDestinationRequested(
                                      searchDestination: result.name,
                                      geoLocation: result.geometry.location,
                                    ),
                                  );
                              Future.microtask(
                                  () => speakTTS('${result.name}(으)로 안내합니다.'));
                              Navigator.pop(context, result.geometry.location);
                              sink.close();
                            },
                          )) {
                            stopwatch.stop();
                            debugPrint(
                                '[Entrance Lookup] 성공 (소요 시간: ${stopwatch.elapsedMilliseconds} ms)');
                            debugPrint('=== EntranceBloc 상태 변화 감지 ===');
                            if (entranceState is EntranceLoaded) {
                              if (entranceState
                                  .buildingResponse.entrances.isNotEmpty) {
                                if (!mounted) return;
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => EntranceSelectionView(
                                      buildingResponse:
                                          entranceState.buildingResponse,
                                      onEntranceSelected: (entrance) {
                                        context.read<SearchBloc>().add(
                                              SearchDestinationRequested(
                                                searchDestination: result.name,
                                                entrance: entrance,
                                              ),
                                            );
                                        Future.microtask(() => speakTTS(
                                            '${entrance.entranceName}으로 안내합니다.'));
                                        Navigator.pop(context);
                                        Navigator.pop(
                                          context,
                                          GeoLocation(
                                            lat: entrance.location.latitude,
                                            lng: entrance.location.longitude,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                context.read<SearchBloc>().add(
                                      SearchDestinationRequested(
                                        searchDestination: result.name,
                                        geoLocation: result.geometry.location,
                                      ),
                                    );
                                Future.microtask(() =>
                                    speakTTS('${result.name}(으)로 안내합니다.'));
                                Navigator.pop(
                                    context, result.geometry.location);
                              }
                            } else if (entranceState is EntranceError) {
                              if (!mounted) return;
                              context.read<SearchBloc>().add(
                                    SearchDestinationRequested(
                                      searchDestination: result.name,
                                      geoLocation: result.geometry.location,
                                    ),
                                  );
                              Future.microtask(
                                  () => speakTTS('${result.name}(으)로 안내합니다.'));
                              Navigator.pop(context, result.geometry.location);
                            }
                          }
                        } else {
                          speakTTS('취소');
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // 버튼 영역 (키보드 바로 위)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(children: [
                  // 지도에서 직접 검색 버튼
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationPickerView(),
                          ),
                        );
                        // 선택 완료 후 결과 처리
                        if (result != null && result is Map) {
                          final GeoLocation pickedLocation = result['location'];
                          final String pickedAddress = result['address'];
                          _searchController.text = pickedAddress;
                          speakTTS('$pickedAddress 위치를 선택하셨습니다.');
                          Navigator.pop(context, pickedLocation);
                          context.read<SearchBloc>().add(
                                SearchDestinationRequested(
                                  searchDestination: pickedAddress,
                                  geoLocation: pickedLocation,
                                ),
                              );
                        }
                      },
                      icon: Icon(Icons.map, color: Colors.white, size: 20),
                      label: Text(
                        '지도에서 직접 검색',
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
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ]))
          ],
        ),
      ),
    );
  }
}

// 장소 검색 결과를 담는 모델 클래스
