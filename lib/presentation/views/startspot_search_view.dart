part of '../../framework/ui.dart';

class StartSearch extends StatefulWidget {
  const StartSearch({
    super.key,
    required this.searchValue,
    this.isFavoriteMode = false,  // 즐겨찾기 모드 추가
    this.hintText = '출발지를 입력하세요.',  // 검색창 힌트 텍스트
    this.dialogTitle = '출발지 확인',  // 다이얼로그 제목
    this.dialogContentPrefix = '',  // 다이얼로그 내용 앞부분 (예: "")
    this.dialogContentSuffix = '에서 시작하시나요?',  // 다이얼로그 내용 뒷부분
  });

  final String searchValue;
  final bool isFavoriteMode;  // true면 SearchBloc 업데이트 안 함
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

  // TTS 서비스 (음성 안내용)
  final TtsService ttsService = DI.get<TtsService>();

  Future<void> speakText(String text) async {
    await ttsService.speak(text);
  }

  final FocusNode _focusNode = FocusNode();

  List<PlaceResult> places = []; // 전체 장소 검색 결과
  List<PlaceResult> _searchResults = []; // 현재 화면에 표시할 결과

  @override
  void initState() {
    super.initState();
    // 초기 검색어가 있을 경우 입력 필드에 설정
    if (widget.searchValue.isNotEmpty) {
      _searchController.text = widget.searchValue;
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
    // 디바운스 타이머를 취소
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 디바운스 타이머 설정
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

  /// TTS를 통해 안내 메시지를 출력하는 메서드.
  /// [message]: 출력할 메시지.

  // TTS로 안내 메시지 읽어줌
  Future<void> speakTTS(String message) async {
    ttsService.speak(message);
  }

  // Kakao API를 사용하여 장소 검색 요청
  Future<List<PlaceResult>> placeSearch(String query) async {
    debugPrint('장소검색 api 호출');
    const String apiKey = '93848fcc11798c6f48099dd2e2373263';
    final String apiUrl =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=$query';

    final Map<String, String> headers = {
      'Authorization': 'KakaoAK $apiKey',
    };

    final response = await http.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> documents = jsonResponse['documents'];

      debugPrint('documents : $documents');

      // 검색 결과가 없는 경우 이전 결과 리스트를 유지.
      // 검색 결과가 있는 경우 새로운 리스트 생성
      if (documents.isNotEmpty) {
        places = documents.map((doc) {
          // 도로명 주소가 있으면 우선 사용, 없으면 지번 주소 사용
          final addressName = doc['road_address_name']?.isNotEmpty == true
              ? doc['road_address_name']
              : doc['address_name'];
          return PlaceResult(
            name: doc['place_name'],
            address: addressName,
            geometry: LatLngGeometry(
              location: GeoLocation(
                lat: double.parse(doc['y']),
                lng: double.parse(doc['x']),
              ),
            ),
          );
        }).toList();
      }

      return places;
    } else {
      throw Exception('장소 검색 실패: ${response.statusCode}');
    }
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
          title: Text(widget.dialogTitle,style: TextStyle(color: Colors.black,)),
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
      body: Column(
        children: [
          // 상단 검색 입력창
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Row(
              children: [
                // 뒤로가기 버튼
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black,
                  ),
                ),
                // 검색 입력창
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.black),
                      onChanged: (query) {
                        if (query.isNotEmpty) {
                          _onSearchChanged();
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: AppSizes.scaledFont(20),
                          color: Color(0xff9E9E9E),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                alignment: Alignment.centerRight,
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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
                // IconButton(
                //   onPressed: () {},
                //   icon: Icon(Icons.mic),
                // ),
              ],
            ),
          ),
          Container(
            height: 1.0,
            width: double.infinity,
            color: Colors.grey,
          ),
          Expanded(
            child: Column(
              children: [
                // 검색 결과가 없을 경우 표시할 '지도에서 직접 선택' 버튼
                if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.map),
                      label: Text('지도에서 직접 선택'),
                      onPressed: () async {
                        // 출발지 선택 지도 화면으로 이동
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

                          // 선택된 위치를 검색창에서 반환
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
                    ),
                  ),

                // 검색 결과 리스트 표시
                Expanded(
                  child: ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                final result = _searchResults[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // 모서리를 둥글게 처리
                  ),
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    tileColor: Colors.white,
                    title: Text(result.name),
                    subtitle: Text(result.address),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      _searchController.text = result.name;
                      Future.microtask(() => speakTTS('${result.name}을 선택하셨습니다.'));

                      bool? results =
                          await showConfirmationDialog(context, result);

                      // result 값에 따라 확인 또는 취소에 따른 작업을 수행할 수 있습니다.
                      if (results != null && results) {
                        debugPrint('=== 출입구 정보 요청 시작 ===');
                        // EntranceBloc에 이벤트 발생
                        context.read<EntranceBloc>().add(
                          FetchBuildingEntrances(
                            address: result.address,
                            longitude: result.geometry.location.lng,
                            latitude: result.geometry.location.lat,
                          ),
                        );

                        // EntranceBloc의 상태 변화를 기다림
                        await for (final entranceState in context.read<EntranceBloc>().stream) {
                          debugPrint('=== EntranceBloc 상태 변화 감지 ===');
                          debugPrint('현재 상태: ${entranceState.runtimeType}');
                          
                          if (entranceState is EntranceLoaded) {
                            debugPrint('출입구 개수: ${entranceState.buildingResponse.entrances.length}');
                            if (entranceState.buildingResponse.entrances.isNotEmpty) {
                              debugPrint('출입구 선택 화면으로 이동');
                              // 출입구가 있는 경우 EntranceSelectionView로 전환
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EntranceSelectionView(
                                    buildingResponse: entranceState.buildingResponse,
                                    onEntranceSelected: (entrance) {
                                      debugPrint('선택된 출입구: ${entrance.entranceName}');
                                      debugPrint('출입구 좌표: ${entrance.location.latitude}, ${entrance.location.longitude}');
                                      
                                      // 출입구 선택 시 SearchBloc에 이벤트 발생 (즐겨찾기 모드가 아닐 때만)
                                      if (!widget.isFavoriteMode) {
                                        context.read<SearchBloc>().add(
                                          SearchStartLocationRequested(
                                            searchLocation: result.name,
                                            entrance: entrance,
                                          ),
                                        );
                                      }
                                      
                                      Future.microtask(() => speakTTS('${entrance.entranceName}으로 안내합니다.'));
                                      Navigator.pop(context); // EntranceSelectionView 닫기
                                      Navigator.pop(context, GeoLocation(
                                        lat: entrance.location.latitude,  // 위도
                                        lng: entrance.location.longitude, // 경도
                                      )); // StartSearch 닫기
                                    },
                                  ),
                                ),
                              );
                            } else {
                              // 출입구가 없는 경우 (API는 성공했으나 출입구 목록이 비어있는 경우-null)
                              debugPrint('출입구가 없어 바로 SearchBloc으로 진행 (EntranceLoaded, entrances empty)');
                              debugPrint('장소 좌표: ${result.geometry.location.lat}, ${result.geometry.location.lng}');
                              
                              if (!mounted) return;
                              // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                              if (!widget.isFavoriteMode) {
                                context.read<SearchBloc>().add(
                                  SearchStartLocationRequested(
                                    searchLocation: result.name,
                                  ),
                                );
                              }
                              
                              Future.microtask(() => speakTTS('${result.name}(으)로 안내합니다.'));
                              Navigator.pop(context, result.geometry.location); // StartSearch 닫고 카카오 API 좌표 반환
                            }
                            break; // 상태 처리 후 스트림 구독 종료
                          } else if (entranceState is EntranceError) {
                            // 서버 연결 실패 또는 출입구 정보 로드 실패 시 카카오 API 좌표 사용
                            debugPrint('에러 발생: EntranceError. 카카오 API 좌표로 경로 탐색합니다.');
                            debugPrint('장소 이름: ${result.name}');
                            debugPrint('카카오 API 좌표: ${result.geometry.location.lat}, ${result.geometry.location.lng}');
                            
                            if (!mounted) return;
                            // 즐겨찾기 모드가 아닐 때만 SearchBloc 업데이트
                            if (!widget.isFavoriteMode) {
                              context.read<SearchBloc>().add(
                                SearchStartLocationRequested(
                                  searchLocation: result.name, // 출입구 정보 없이 이름만 전달
                                ),
                              );
                            }
                            
                            Future.microtask(() => speakTTS('${result.name}(으)로 안내합니다.'));
                            Navigator.pop(context, result.geometry.location); // StartSearch 닫고 카카오 API 좌표 반환
                            break; // 상태 처리 후 스트림 구독 종료
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}