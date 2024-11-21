part of '../../framework/ui.dart';

class StartSearch extends StatefulWidget {
  const StartSearch({
    super.key,
    required this.searchValue,
  });
  final String searchValue;
  @override
  State<StartSearch> createState() => _StartSearchState();
}

class _StartSearchState extends State<StartSearch> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final FlutterTts tts = FlutterTts();
  final FocusNode _focusNode = FocusNode();
  List<PlaceResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if(widget.searchValue.isNotEmpty){
      _searchController.text = widget.searchValue;
    }
    _searchController.addListener(_onSearchChanged);
    _focusNode.requestFocus();
    _initTTS();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _initTTS() async {
    await tts.setLanguage("ko-KR");
  }

  Future<void> _speakText(String text) async {
    await tts.speak(text);
  }

  Future<List<PlaceResult>> placeSearch(String query) async {
    const String apiKey = '93848fcc11798c6f48099dd2e2373263';
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

      List<PlaceResult> places = documents.map((doc) {
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
          title: Text('출발지 확인'),
          content: Text(
            '${result.name}에서 시작하시나요?',
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

  @override
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
                    margin: EdgeInsets.symmetric(horizontal: 10),
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
                          _performSearch(query);
                        } else {
                          setState(() {
                            _searchResults = [];
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '출발지를 입력하세요.',
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
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
                        _speakText('${result.name}를 출발지로 선택하셨습니다.');
                        Navigator.pop(context, result.geometry.location);
                        context.read<SearchBloc>().add(SearchStartLocationRequested(searchLocation: result.name));
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
// class PlaceResult {
//   final String name;
//   final String address;
//   final LatLngGeometry geometry;

//   PlaceResult({
//     required this.name,
//     required this.address,
//     required this.geometry,
//   });
// }

// class GeoLocation {
//   final double lat;
//   final double lng;

//   GeoLocation({
//     required this.lat,
//     required this.lng,
//   });
// }

// class LatLngGeometry {
//   final GeoLocation location;

//   LatLngGeometry({
//     required this.location,
//   });
// }