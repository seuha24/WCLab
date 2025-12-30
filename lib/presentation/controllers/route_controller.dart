part of '../../framework/controller.dart';

class RouteController {
  late NaverMapController? mapController;
  final NavigationApiService apiService;
  final PdrCalculator pdrCalculator;

  /// 경로의 좌표 리스트
  List<LatLng> paths = [];

  /// 분기(체크포인트) 정보를 담은 리스트
  List<BranchInfo> branchinfo = [];

  // List<LatLng> waypoints = [];


  
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

    // 경유지를 포함한 경로 API 호출 (public)
  Future<dynamic> loadPathDataWithWaypoints(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
    List<LatLng> waypoints,
    String chooseRoute,
  ) async {
    return await apiService.fetchPathDataWithWaypoints(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      chooseRoute: chooseRoute,
      waypoints: waypoints,
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
  void logLoadPathDataWithWayPoint(){
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

  /// 각 경유지에 대해 가장 가까운 분기점 하나만 경유지로 표시
  void checkWaypointsInBranchInfo(List<LatLng> waypoints) {
    for (final waypoint in waypoints) {
      BranchInfo? closestBranch;
      double minDistance = double.infinity;

      // 첫 번째와 마지막 분기점(출발지/목적지)은 제외
      for (int i = 1; i < branchinfo.length - 1; i++) {
        final branch = branchinfo[i];
        final distanceKm = Calculators.calculateDistance(
          branch.point.latitude,
          branch.point.longitude,
          waypoint.latitude,
          waypoint.longitude,
        );

        if (distanceKm < minDistance) {
          minDistance = distanceKm;
          closestBranch = branch;
        }
      }

      // 가장 가까운 분기점만 경유지로 표시
      if (closestBranch != null) {
        closestBranch.waypoint = true;
      }
    }
  }

  void resetDeviationYaw(int targetIndex, double compassValue) {
    if (branchinfo.isEmpty || targetIndex < 0 || targetIndex >= branchinfo.length) {
      debugPrint('resetDeviationYaw: 유효하지 않은 targetIndex=$targetIndex (branchinfo.length=${branchinfo.length})');
      return;
    }
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