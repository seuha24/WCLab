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
    final String apiKey = '93848fcc11798c6f48099dd2e2373263';
    final String apiUrl =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=$query';

    final Map<String, String> headers = {
      'Authorization': 'KakaoAK $apiKey',
    };

    final response = await http.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> documents = jsonResponse['documents'];

      // 검색 결과를 PlaceResult 형태로 파싱
      if (documents.isNotEmpty) {
        places = documents.map((doc) {
          return PlaceResult(
            name: doc['place_name'],
            address: doc['address_name'],
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
          title: Text('목적지 확인', style: TextStyle(color: Colors.black)),
          content: Text(
            '${result.name}(으)로 안내할까요?',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // 확인
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // 취소
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
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black),
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
                        } else {
                          setState(() {
                            _searchResults = [];
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        hintText: '목적지를 입력하세요.',
                        hintStyle: TextStyle(
                          fontSize: AppSizes.scaledFont(20),
                          color: Color(0xff9E9E9E),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
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
              ],
            ),
          ),
          // 구분선
          Container(
            height: 1.0,
            width: double.infinity,
            color: Colors.grey,
          ),

          // 검색 결과 영역
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
                        // 목적지 선택 지도 화면으로 이동
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

                          // Bloc 이벤트로 목적지 반영
                          context.read<SearchBloc>().add(
                            SearchDestinationRequested(
                              searchDestination: pickedAddress,
                              geoLocation: pickedLocation,
                            ),
                          );
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          tileColor: Colors.white,
                          title: Text(result.name),
                          subtitle: Text(result.address),
                          onTap: () async {
                            // 장소 선택 시 TTS 안내 및 확인 다이얼로그 표시
                            FocusScope.of(context).unfocus();
                            _searchController.text = result.name;
                            Future.microtask(() => speakTTS('${result.name}을 선택하셨습니다.'));
                            bool? results = await showConfirmationDialog(context, result);

                            if (results != null && results) {
                              // 선택 확인 시: 안내 후 위치 반환 + Bloc 이벤트 발생
                              Future.microtask(() => speakTTS('${result.name}으로 안내합니다.'));
                              Navigator.pop(context, result.geometry.location);
                              context.read<SearchBloc>().add(
                                SearchDestinationRequested(
                                  searchDestination: result.name,
                                  geoLocation: result.geometry.location,
                                ),
                              );
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

// 장소 검색 결과를 담는 모델 클래스
class PlaceResult {
  final String name;
  final String address;
  final LatLngGeometry geometry;

  PlaceResult({
    required this.name,
    required this.address,
    required this.geometry,
  });
}

// 위경도 정보 모델 클래스
class GeoLocation {
  final double lat;
  final double lng;

  GeoLocation({
    required this.lat,
    required this.lng,
  });
}

// LatLng 포맷을 GeoLocation으로 감싼 구조
class LatLngGeometry {
  final GeoLocation location;

  LatLngGeometry({
    required this.location,
  });
}
