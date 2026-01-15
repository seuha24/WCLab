part of '../../framework/controller.dart';

// 방향 라벨(시계방향, 반시계방향)
const List<String> labelsClock = [
  '12시',
  '1시',
  '2시',
  '3시',
  '4시',
  '5시',
  '6시',
  '7시',
  '8시',
  '9시',
  '10시',
  '11시',
];
const List<String> labelsCounterClock = [
  '12시',
  '11시',
  '10시',
  '9시',
  '8시',
  '7시',
  '6시',
  '5시',
  '4시',
  '3시',
  '2시',
  '1시',
];

/// 경계 평가 결과 DTO
class BoundaryEvalResult {
  final double minDistanceMeters; // 경로까지 최소거리(m)
  final bool outOfBound; // boundary 초과 여부
  final bool searchNewPath; // 재탐색 임계 초과 여부
  final String condition; // "직선" | "브랜치"

  const BoundaryEvalResult(
      {required this.minDistanceMeters,
      required this.outOfBound,
      required this.searchNewPath,
      required this.condition});
}

/// Guidance 계산 모듈
class GuidanceCalculator {
  /// 안내 각도를 기반으로 방향 라벨(예: "12시 방향")을 반환합니다.
  ///
  /// //current,target Lng,Lat 순서 통일
  String getGuidanceDirection(
    double currentIndexLongitude,
    double currentIndexLatitude,
    double targetIndexLongitude,
    double targetIndexLatitude,
    double currentLatitude,
    double currentLongitude,
    double deviationYawTurn,
    double bearingToPoint,
  ) {
    //current,target Lat,Lng 순서
    final boundaryExit = Calculators.checkLateralDeviation(
      currentIndexLatitude,
      currentIndexLongitude,
      targetIndexLatitude,
      targetIndexLongitude,
      currentLatitude,
      currentLongitude,
    );
    //current,target Lng,Lat 순서
    double guidanceAngle = Calculators.angleToTarget(
      currentIndexLongitude,
      currentIndexLatitude,
      targetIndexLongitude,
      targetIndexLatitude,
      currentLatitude,
      currentLongitude,
      deviationYawTurn,
      bearingToPoint,
      boundaryExit,
    );

    //
    if (guidanceAngle > 180) guidanceAngle -= 360;
    final direction = ((guidanceAngle + 15) % 360) ~/ 30;

    // 방향 라벨 선택 (시계방향/반시계방향)
    // boundaryExit > 0 이면 반시계 방향 라벨 선택, < 0 이면 시계방향 라벨 선택
    final directionLabels =
        (boundaryExit > 0) ? labelsCounterClock : labelsClock;
    return directionLabels[direction];
  }

  /// checkBoundary의 핵심 계산 함수
  BoundaryEvalResult evaluateBoundary({
    required List<WindowEntry> window,
    required double currentLat,
    required double currentLon,
    required double boundary,
    required double searchNewPathBoundary,
  }) {
    if (window.length < 2) {
      return const BoundaryEvalResult(
        minDistanceMeters: double.infinity,
        outOfBound: false,
        searchNewPath: false,
        condition: "직선",
      );
    }

    double minDistance = double.infinity;
    String conditionAtMin = "직선";

    for (int i = 0; i < window.length - 1; i++) {
      final (_, cur) = window[i];
      final (_, next) = window[i + 1];

      double distanceToPath;
      String condition;

      final linear = Calculators.pointLineDistance(
        cur.point.latitude,
        cur.point.longitude,
        next.point.latitude,
        next.point.longitude,
        currentLat,
        currentLon,
      );

      //m,km단위 통일
      if (cur.branch == true) {
        final circular = Calculators.calculateDistance(
              cur.point.latitude,
              cur.point.longitude,
              currentLat,
              currentLon,
            ) *
            1000.0;

        distanceToPath = math.min(circular, linear);
        condition = "브랜치";
      } else {
        distanceToPath = linear;
        condition = "직선";
      }

      if (distanceToPath < minDistance) {
        minDistance = distanceToPath;
        conditionAtMin = condition;
      }
    }

    final out = minDistance > boundary;
    final re = minDistance > searchNewPathBoundary;

    return BoundaryEvalResult(
      minDistanceMeters: minDistance,
      outOfBound: out,
      searchNewPath: re,
      condition: conditionAtMin,
    );
  }
}
