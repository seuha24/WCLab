part of '../../framework/controller.dart';

typedef WindowEntry = (int idx, BranchInfo info);

class IndexController {
  IndexController({
    required this.routeController,
    required this.pdrCalculator,
    required this.sensorStreams,
    required this.getCurrentLatitude,   // 현재 사용자 위도
    required this.getCurrentLongitude,  // 현재 사용자 경도
    required this.getCompassDeg,        // 현재 나침반 각(도)
    this.progressGuardFactor = 0.95,    
    this.debug = false,
    
  });

  final RouteController routeController; 
  final SensorStreams sensorStreams;
  final double Function() getCurrentLatitude;
  final double Function() getCurrentLongitude;
  final double Function() getCompassDeg;
  
  
  final PdrCalculator pdrCalculator;
  
  final double progressGuardFactor;

  final bool debug;

  
  int _currentIndex = 0;
  int _targetIndex  = 0;

  
  int get currentIndex => _currentIndex;
  int get targetIndex  => _targetIndex;

  
  // 경로 바뀔 때 호출
  void reset({int startIndex = 0}) {
    final all = routeController.branchinfo;
    if (all.isEmpty) {
      _currentIndex = 0;
      _targetIndex  = 0;
      return;
    }
    final last = all.length - 1;
    _currentIndex = startIndex.clamp(0, last);
    _targetIndex  = (_currentIndex + 1 <= last) ? _currentIndex + 1 : _currentIndex;
    if (debug) {
      // ignore: avoid_print
      debugPrint('IndexController.reset → cur=$_currentIndex, tgt=$_targetIndex');
    }
  }

  /// 현재 인덱스를 중심으로 윈도우를 (원본 인덱스, BranchInfo) 레코드로 반환
  List<WindowEntry> getCurrentWindowRecords(
    List<BranchInfo> all,
    int currentIndex,
    int windowSize,
  ) {
    final half = (windowSize - 1) ~/ 2;
    final start = (currentIndex - half).clamp(0, all.length - 1);
    final end   = (currentIndex + half).clamp(0, all.length - 1);

    return [
      for (int i = start; i <= end; i++) (i, all[i]),
    ];
  }
/// moveIndex: 현재 위치와 윈도우 내 분기점 간의 거리를 계산하여 가장 가까운 분기점의 인덱스를 반환합니다.
int moveIndex(List<WindowEntry> window) {
  if (window.isEmpty) return _currentIndex;

  final List<BranchInfo> all = routeController.branchinfo;
  if (all.isEmpty) return _currentIndex;

  final last = all.length - 1;
  final cur  = _currentIndex.clamp(0, last);
  final tgt  = _targetIndex.clamp(0, last);

  
  final distCT = Calculators.distanceBetweenBranch(
    all[cur].point.latitude, all[cur].point.longitude,
    all[tgt].point.latitude, all[tgt].point.longitude,
  );

  
  int    nearestIndex   = (distCT == 0) ? _targetIndex : cur;
  double minDistance    = double.infinity;

  
  double bestDistFromMe = Calculators.calculateDistance(
    all[nearestIndex].point.latitude, all[nearestIndex].point.longitude,
    getCurrentLatitude(), getCurrentLongitude(),
  );

  
  final double guard = distCT * progressGuardFactor;

  for (final (idx, info) in window) {
    final d = Calculators.calculateDistance(
      info.point.latitude, info.point.longitude,
      getCurrentLatitude(), getCurrentLongitude(),
    );
    if (!d.isFinite) continue;

    
    if (d < minDistance && bestDistFromMe >= guard) {
      minDistance    = d;
      nearestIndex   = idx;
      bestDistFromMe = d;
    }
  }
  return nearestIndex;
}

/// indexUpdate: 현재 위치를 기반으로 인덱스를 갱신하고, targetIndex 및 yaw를 초기화합니다.
void indexUpdate() {
  final List<BranchInfo> all = routeController.branchinfo;
  if (all.isEmpty) return; // (5) 빈 경로 가드

  final window = getCurrentWindowRecords(all, _currentIndex, 5);
  if(debug)debugPrint('window idx: ${window.map((e) => e.$1).toList()}');

  final nextIndex = moveIndex(window);
  if(debug)debugPrint('moveIndex 결과: $nextIndex');

  if (nextIndex >= 0 && nextIndex < all.length && nextIndex != _currentIndex) {
    _currentIndex = nextIndex;

    // targetIndex 중앙 갱신
    final last = all.length - 1;
    _targetIndex = (_currentIndex + 1 <= last) ? _currentIndex + 1 : _currentIndex;

    // yaw 초기화 (현 구조 유지)
    final bearing = all[_targetIndex].bearingToPoint;
    debugPrint("Compass: ${getCompassDeg()}");
    final devDeg  = Calculators.calculateYawDeviationFromCompass(bearing, getCompassDeg());
    pdrCalculator.setDeviationYaw(Calculators.deg2rad(devDeg));
    if(debug)debugPrint("각도 초기화: $devDeg 도");

    
    }
  }

}