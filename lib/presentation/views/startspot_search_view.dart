part of '../../framework/ui.dart';

class StartSearch extends StatefulWidget {
  const StartSearch({
    super.key,
    required this.searchValue,
    this.isFavoriteMode = false, // 즐겨찾기 모드 추가
    this.hintText = '출발지를 입력하세요.', // 검색창 힌트 텍스트
    this.dialogTitle = '출발지 확인', // 다이얼로그 제목
    this.dialogContentPrefix = '', // 다이얼로그 내용 앞부분 (예: "")
    this.dialogContentSuffix = '에서 시작하시나요?', // 다이얼로그 내용 뒷부분
  });

  final String searchValue;
  final bool isFavoriteMode; // true면 SearchBloc 업데이트 안 함
  final String hintText;
  final String dialogTitle;
  final String dialogContentPrefix;
  final String dialogContentSuffix;

  @override
  State<StartSearch> createState() => _StartSearchState();
}

class _StartSearchState extends State<StartSearch> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final TtsService ttsService = DI.get<TtsService>();
  final KakaoRepository kakaoRepository = DI.get<KakaoRepository>();
  final FocusNode _focusNode = FocusNode();

  List<PlaceResult> places = [];
  List<PlaceResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.searchValue.isNotEmpty) {
      _searchController.text = widget.searchValue;
    }
    // 검색 결과 초기화
    _searchResults = [];
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> speakText(String text) async {
    await ttsService.speak(text);
  }

  Future<void> speakTTS(String message) async {
    ttsService.speak(message);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<List<PlaceResult>> placeSearch(String query) async {
    final result = await kakaoRepository.searchPlaces(query);

    return result.fold(
      (failure) => places,
      (newPlaces) {
        if (newPlaces.isNotEmpty) {
          places = newPlaces;
        }
        return places;
      },
    );
  }

  void _performSearch(String query) async {
    List<PlaceResult> results = await placeSearch(query);
    setState(() {
      _searchResults = results;
    });
  }

  Future<bool?> showConfirmationDialog(
      BuildContext context, PlaceResult result) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(widget.dialogTitle,
              style: TextStyle(
                color: Colors.black,
              )),
          content: Text(
            '${widget.dialogContentPrefix}${result.name}${widget.dialogContentSuffix}',
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('출발지 검색하기'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 검색창 영역
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
                    hintText: widget.hintText,
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

            // 검색 결과 리스트
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
                          final stopwatch = Stopwatch()..start(); // 시간 측정 시작

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
                                '[Entrance Lookup] 타임아웃 발생 (조회 시간: ${stopwatch.elapsedMilliseconds} ms)',
                              );
                              if (!mounted) return;
                              // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                              if (!widget.isFavoriteMode) {
                                context.read<SearchBloc>().add(
                                      SearchStartLocationRequested(
                                        searchLocation: result.name,
                                      ),
                                    );
                              }
                              Future.microtask(
                                  () => speakTTS('${result.name}(으)로 안내합니다.'));
                              Navigator.pop(context, result.geometry.location);
                              sink.close();
                            },
                          )) {
                            stopwatch.stop();
                            debugPrint(
                              '[Entrance Lookup] 성공 (소요 시간: ${stopwatch.elapsedMilliseconds} ms)',
                            );
                            debugPrint('=== EntranceBloc 상태 변화 감지 ===');
                            if (entranceState is EntranceLoaded) {
                              if (entranceState
                                  .buildingResponse.entrances.isNotEmpty) {
                                if (!mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EntranceSelectionView(
                                      buildingResponse:
                                          entranceState.buildingResponse,
                                      onEntranceSelected: (entrance) {
                                        // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                                        if (!widget.isFavoriteMode) {
                                          context.read<SearchBloc>().add(
                                                SearchStartLocationRequested(
                                                  searchLocation: result.name,
                                                  entrance: entrance,
                                                ),
                                              );
                                        }
                                        speakTTS(
                                            '${entrance.entranceName}으로 안내합니다.');
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
                                // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                                if (!widget.isFavoriteMode) {
                                  context.read<SearchBloc>().add(
                                        SearchStartLocationRequested(
                                          searchLocation: result.name,
                                        ),
                                      );
                                }
                                speakTTS('${result.name}(으)로 안내합니다.');
                                Navigator.pop(
                                    context, result.geometry.location);
                              }
                            } else if (entranceState is EntranceError) {
                              if (!mounted) return;
                              // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                              if (!widget.isFavoriteMode) {
                                context.read<SearchBloc>().add(
                                      SearchStartLocationRequested(
                                        searchLocation: result.name,
                                      ),
                                    );
                              }
                              speakTTS('${result.name}(으)로 안내합니다.');
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // 현재 위치로 설정하기 버튼
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          LocationPermission permission =
                              await Geolocator.requestPermission();
                          if (permission == LocationPermission.deniedForever ||
                              permission == LocationPermission.denied) {
                            speakTTS('위치 권한이 필요합니다.');
                            return;
                          }

                          final position = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.high,
                            ),
                          );

                          final currentLocation = GeoLocation(
                            lat: position.latitude,
                            lng: position.longitude,
                          );

                          // 현재 위치의 주소를 가져오기 (역지오코딩)
                          final addressResult =
                              await kakaoRepository.getAddressFromCoordinates(
                            latitude: position.latitude,
                            longitude: position.longitude,
                          );

                          final currentAddress = addressResult.fold(
                            (failure) => '현재 위치',
                            (address) => address,
                          );

                          _searchController.text = currentAddress;
                          speakTTS('현재 위치로 설정하셨습니다.');

                          // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                          if (!widget.isFavoriteMode) {
                            context.read<SearchBloc>().add(
                                  SearchStartLocationRequested(
                                    searchLocation: currentAddress,
                                  ),
                                );
                          }

                          Navigator.pop(context, currentLocation);
                        } catch (e) {
                          speakTTS('현재 위치를 가져올 수 없습니다.');
                        }
                      },
                      icon: Icon(Icons.location_pin,
                          color: Colors.grey[600], size: 20),
                      label: Text(
                        '현재 위치로 설정하기',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[600],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                          // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                          if (!widget.isFavoriteMode) {
                            context.read<SearchBloc>().add(
                                  SearchStartLocationRequested(
                                    searchLocation: pickedAddress,
                                  ),
                                );
                          }
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
