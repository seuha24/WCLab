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

  final FlutterTts tts = FlutterTts();
  final FocusNode _focusNode = FocusNode();

  List<PlaceResult> places = [];
  List<PlaceResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.destinationValue.isNotEmpty) {
      _searchController.text = widget.destinationValue;
    }
    _focusNode.requestFocus();
    _initTTS();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    debugPrint('debounce timer : ${_debounce?.isActive}');
    // 디바운스 타이머를 취소
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 디바운스 타이머 설정
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      debugPrint('검색어 : $query');
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _initTTS() async {
    await tts.setLanguage("ko-KR");
  }

  Future<void> _speakText(String text) async {
    await tts.speak(text);
  }

  Future<List<PlaceResult>> placeSearch(String query) async {
    final String apiKey = '93848fcc11798c6f48099dd2e2373263'; // 실제 API 키로 교체
    final String apiUrl =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=$query';

    final Map<String, String> headers = {
      'Authorization': 'KakaoAK $apiKey',
    };

    final response = await http.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode == 200) {
      print('장소검색 api 통신성공');
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> documents = jsonResponse['documents'];

      // 검색 결과가 없는 경우 이전 결과 리스트를 유지.
      // 검색 결과가 있는 경우 새로운 리스트 생성
      if(documents.isNotEmpty) {
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
          title: Text('목적지 확인'),
          content: Text(
            '${result.name}(으)로 안내할까요?',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // 확인 버튼을 눌렀을 때 수행할 작업
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                  ),
                ),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? Container(
                                child: IconButton(
                                  alignment: Alignment.centerRight,
                                  icon: Icon(
                                    Icons.close,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchResults.clear();
                                    setState(() {});
                                  },
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1.0,
            width: double.infinity,
            color: Colors.grey,
          ),
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
                      _speakText('${result.name}을 선택하셨습니다.');
                      bool? results =
                          await showConfirmationDialog(context, result);

                      // result 값에 따라 확인 또는 취소에 따른 작업을 수행할 수 있습니다.
                      if (results != null && results) {
                        // 확인 버튼이 눌렸을 때의 작업
                        _speakText('${result.name}으로 안내합니다.');
                        Navigator.pop(context, result.geometry.location);
                        context.read<SearchBloc>().add(
                            SearchDestinationRequested(
                                searchDestination: result.name));
                      } else {
                        _speakText('취소');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

class GeoLocation {
  final double lat;
  final double lng;

  GeoLocation({
    required this.lat,
    required this.lng,
  });
}

class LatLngGeometry {
  final GeoLocation location;

  LatLngGeometry({
    required this.location,
  });
}
