part of '../../framework/controller.dart';

class RouteController {
  late NaverMapController? mapController;
  final NavigationApiService apiService;
  final PdrCalculator pdrCalculator;

  /// 경로의 좌표 리스트
  List<LatLng> paths = [];

  /// 분기(체크포인트) 정보를 담은 리스트
  List<BranchInfo> branchinfo = [];

  
  RouteController({
    required this.mapController,
    required this.apiService,
    required this.pdrCalculator,
  });

  /// 경로 API 요청만 수행하고 응답 반환
  Future<dynamic> loadPathData(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
    String chooseRoute,
  ) async {
    return await apiService.fetchPathData(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      chooseRoute: chooseRoute,
    );
  }

  /// 응답 데이터를 파싱하고 상태에 반영
  void applyParsePathData(dynamic responseData) {
    final parsed = apiService.parsePathData(responseData);
    paths = parsed['paths'] as List<LatLng>;
    branchinfo = parsed['branchInfo'] as List<BranchInfo>;
  }

  void logLoadPathData() {
    debugPrint('paths: $paths');
    debugPrint('branchInfoList: $branchinfo');
  }

  void calculatePathBearing() {
    if (branchinfo.isEmpty) {
      debugPrint('분기점 정보가 없습니다.');
      return;
    }
    for (int i = 0; i < branchinfo.length - 1; i++) {
      branchinfo[i].bearingToPoint = Calculators.calculateBearing(
        branchinfo[i].point.latitude,
        branchinfo[i].point.longitude,
        branchinfo[i + 1].point.latitude,
        branchinfo[i + 1].point.longitude,
      );
    }
  }

  void resetDeviationYaw(int targetIndex, double compassValue) {
    pdrCalculator.setDeviationYaw(
      Calculators.deg2rad(
        Calculators.calculateYawDeviationFromCompass(
          branchinfo[targetIndex].bearingToPoint,
          compassValue,
        ),
      ),
    );
  }


  void clearPathData() {
    paths.clear();
    branchinfo.clear();
  }
}