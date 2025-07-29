part of '../../framework/ui.dart';

class WaypointNavigationView extends StatefulWidget {
  const WaypointNavigationView({super.key});

  @override
  State<WaypointNavigationView> createState() => _WaypointNavigationViewState();
}

class _WaypointNavigationViewState extends State<WaypointNavigationView> {
  final _formKey = GlobalKey<FormState>();
  
  // 출발지, 목적지 컨트롤러
  final TextEditingController _startLatController = TextEditingController();
  final TextEditingController _startLngController = TextEditingController();
  final TextEditingController _endLatController = TextEditingController();
  final TextEditingController _endLngController = TextEditingController();
  
  // 경유지 컨트롤러 리스트
  List<Map<String, TextEditingController>> _waypointControllers = [];
  
  // 경로 옵션
  String _selectedRoute = "0";
  final Map<String, String> _routeOptions = {
    "0": "추천",
    "4": "추천+대로우선", 
    "10": "최단",
    "30": "최단거리+계단제외"
  };

  @override
  void initState() {
    super.initState();
    // 기본적으로 경유지 1개 추가
    _addWaypoint();
  }

  @override
  void dispose() {
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    
    for (var controllers in _waypointControllers) {
      controllers['lat']?.dispose();
      controllers['lng']?.dispose();
    }
    super.dispose();
  }

  void _addWaypoint() {
    setState(() {
      _waypointControllers.add({
        'lat': TextEditingController(),
        'lng': TextEditingController(),
      });
    });
  }

  void _removeWaypoint(int index) {
    if (_waypointControllers.length > 1) {
      setState(() {
        _waypointControllers[index]['lat']?.dispose();
        _waypointControllers[index]['lng']?.dispose();
        _waypointControllers.removeAt(index);
      });
    }
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // 출발지, 목적지 검증
    if (_startLatController.text.isEmpty || _startLngController.text.isEmpty ||
        _endLatController.text.isEmpty || _endLngController.text.isEmpty) {
      _showErrorSnackBar('출발지와 목적지를 모두 입력해주세요.');
      return false;
    }

    // 경위도 범위 검증
    try {
      double startLat = double.parse(_startLatController.text);
      double startLng = double.parse(_startLngController.text);
      double endLat = double.parse(_endLatController.text);
      double endLng = double.parse(_endLngController.text);

      if (!_isValidCoordinate(startLat, startLng) || !_isValidCoordinate(endLat, endLng)) {
        _showErrorSnackBar('올바른 좌표 범위를 입력해주세요. (위도: -90~90, 경도: -180~180)');
        return false;
      }

      // 경유지 검증
      for (var controllers in _waypointControllers) {
        String latText = controllers['lat']!.text;
        String lngText = controllers['lng']!.text;
        
        if (latText.isNotEmpty || lngText.isNotEmpty) {
          if (latText.isEmpty || lngText.isEmpty) {
            _showErrorSnackBar('경유지 좌표를 완전히 입력하거나 비워주세요.');
            return false;
          }
          
          double lat = double.parse(latText);
          double lng = double.parse(lngText);
          
          if (!_isValidCoordinate(lat, lng)) {
            _showErrorSnackBar('경유지 좌표가 올바르지 않습니다.');
            return false;
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('숫자 형식이 올바르지 않습니다.');
      return false;
    }

    return true;
  }

  bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  void _showErrorSnackBar(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      debugPrint('에러 메시지: $message');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      debugPrint('성공 메시지: $message');
    }
  }

  Future<void> _startBasicNavigation() async {
    if (!_validateInputs()) return;

    try {
      double startLat = double.parse(_startLatController.text);
      double startLng = double.parse(_startLngController.text);
      double endLat = double.parse(_endLatController.text);
      double endLng = double.parse(_endLngController.text);

      final waypoints = [
        LatLng(startLat, startLng), // 출발지
        LatLng(endLat, endLng),     // 목적지
      ];

      // 컨트롤러가 등록되어 있는지 확인
      if (!Get.isRegistered<NaverMapViewController>()) {
        _showErrorSnackBar('지도 화면으로 이동합니다...');
        
        // 지도 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NaverMapView()),
        );
        
        // 지도 로드 후 네비게이션 시작을 위한 스케줄링
        Future.delayed(Duration(seconds: 3), () async {
          if (Get.isRegistered<NaverMapViewController>()) {
            final controller = Get.find<NaverMapViewController>();
            try {
              await controller.startNavigationWithWaypoints(waypoints, routeOption: _selectedRoute);
            } catch (e) {
              debugPrint('지도 이동 후 기본 네비게이션 시작 실패: $e');
            }
          }
        });
        
        return;
      }
      
      final controller = Get.find<NaverMapViewController>();

      _showSuccessSnackBar('기본 경로 안내를 시작합니다...');
      
      await controller.startNavigationWithWaypoints(waypoints, routeOption: _selectedRoute);
      
      // 네비게이션 시작 후 화면 닫기
      Navigator.of(context).pop();
      
    } catch (e) {
      debugPrint('기본 네비게이션 시작 실패: $e');
      String errorMessage = '경로 안내 시작에 실패했습니다.';
      
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = '지도 플러그인 오류입니다. 앱을 다시 시작해주세요.';
      } else if (e.toString().contains('API')) {
        errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      } else if (e.toString().contains('ArgumentError')) {
        errorMessage = '입력된 좌표에 문제가 있습니다. 다시 확인해주세요.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _startWaypointNavigation() async {
    if (!_validateInputs()) return;

    try {
      double startLat = double.parse(_startLatController.text);
      double startLng = double.parse(_startLngController.text);
      double endLat = double.parse(_endLatController.text);
      double endLng = double.parse(_endLngController.text);

      List<LatLng> waypoints = [LatLng(startLat, startLng)]; // 출발지

      // 경유지 추가 (입력된 것만)
      for (var controllers in _waypointControllers) {
        String latText = controllers['lat']!.text;
        String lngText = controllers['lng']!.text;
        
        if (latText.isNotEmpty && lngText.isNotEmpty) {
          double lat = double.parse(latText);
          double lng = double.parse(lngText);
          waypoints.add(LatLng(lat, lng));
        }
      }

      waypoints.add(LatLng(endLat, endLng)); // 목적지

      if (waypoints.length < 3) {
        _showErrorSnackBar('경유지를 최소 1개 이상 입력해주세요.');
        return;
      }

      // 컨트롤러가 등록되어 있는지 확인
      if (!Get.isRegistered<NaverMapViewController>()) {
        _showErrorSnackBar('지도 화면으로 이동합니다...');
        
        // 지도 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NaverMapView()),
        );
        
        // 지도 로드 후 네비게이션 시작을 위한 스케줄링
        Future.delayed(Duration(seconds: 3), () async {
          if (Get.isRegistered<NaverMapViewController>()) {
            final controller = Get.find<NaverMapViewController>();
            try {
              await controller.startNavigationWithWaypoints(waypoints, routeOption: _selectedRoute);
            } catch (e) {
              debugPrint('지도 이동 후 경유지 네비게이션 시작 실패: $e');
            }
          }
        });
        
        return;
      }
      
      final controller = Get.find<NaverMapViewController>();

      _showSuccessSnackBar('경유지 포함 경로 안내를 시작합니다...');
      
      await controller.startNavigationWithWaypoints(waypoints, routeOption: _selectedRoute);
      
      // 네비게이션 시작 후 화면 닫기
      Navigator.of(context).pop();
      
    } catch (e) {
      debugPrint('경유지 네비게이션 시작 실패: $e');
      String errorMessage = '경유지 경로 안내 시작에 실패했습니다.';
      
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = '지도 플러그인 오류입니다. 앱을 다시 시작해주세요.';
      } else if (e.toString().contains('API')) {
        errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      } else if (e.toString().contains('ArgumentError')) {
        errorMessage = '입력된 좌표에 문제가 있습니다. 다시 확인해주세요.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  Widget _buildCoordinateInput({
    required String label,
    required TextEditingController latController,
    required TextEditingController lngController,
    bool isRequired = true,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '위도',
                      hintText: '37.55677',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: isRequired ? (value) {
                      if (value == null || value.isEmpty) {
                        return '위도를 입력하세요';
                      }
                      try {
                        double lat = double.parse(value);
                        if (lat < -90 || lat > 90) {
                          return '위도 범위: -90~90';
                        }
                      } catch (e) {
                        return '숫자를 입력하세요';
                      }
                      return null;
                    } : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lngController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '경도',
                      hintText: '126.92365',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: isRequired ? (value) {
                      if (value == null || value.isEmpty) {
                        return '경도를 입력하세요';
                      }
                      try {
                        double lng = double.parse(value);
                        if (lng < -180 || lng > 180) {
                          return '경도 범위: -180~180';
                        }
                      } catch (e) {
                        return '숫자를 입력하세요';
                      }
                      return null;
                    } : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('경로 안내 설정'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 텍스트
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 경로 안내 설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 기본 안내: 출발지 → 목적지\n• 경유지 포함: 출발지 → 경유지들 → 목적지\n• 지도가 로드되지 않은 경우 자동으로 지도 화면으로 이동합니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 출발지 입력
              _buildCoordinateInput(
                label: '🚀 출발지',
                latController: _startLatController,
                lngController: _startLngController,
              ),
              SizedBox(height: 16),

              // 경유지 입력
              Text(
                '🔄 경유지',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              ...List.generate(_waypointControllers.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '경유지 ${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              if (_waypointControllers.length > 1)
                                IconButton(
                                  onPressed: () => _removeWaypoint(index),
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  tooltip: '경유지 삭제',
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _waypointControllers[index]['lat']!,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: '위도',
                                    hintText: '37.55395',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _waypointControllers[index]['lng']!,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: '경도',
                                    hintText: '126.92775',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // 경유지 추가 버튼
              OutlinedButton.icon(
                onPressed: _addWaypoint,
                icon: Icon(Icons.add),
                label: Text('경유지 추가'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 16),

              // 목적지 입력
              _buildCoordinateInput(
                label: '🏁 목적지',
                latController: _endLatController,
                lngController: _endLngController,
              ),
              SizedBox(height: 20),

              // 경로 옵션 선택
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚙️ 경로 옵션',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRoute,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _routeOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRoute = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // 실행 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startBasicNavigation,
                      icon: Icon(Icons.navigation),
                      label: Text('기본 경로 안내'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startWaypointNavigation,
                      icon: Icon(Icons.route),
                      label: Text('경유지 포함 안내'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 