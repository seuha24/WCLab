part of '../../framework/core.dart';

class Calculators {


  /// deg2rad: 도(degree)를 라디안(radian)으로 변환합니다.
  static double deg2rad(double deg) => deg * (math.pi / 180);

  /// rad2deg: 라디안(radian)을 도(degree)로 변환합니다.
  static double rad2deg(double rad) => rad * (180 / math.pi);

  /// calculateDistance: 두 지점 간의 거리를 haversine 공식을 사용하여 계산합니다.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {

    const double earthRadius = 6371.0;

    double dLat = deg2rad(lat2 - lat1);
    double dLon = deg2rad(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(deg2rad(lat1)) *
            math.cos(deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

   ///계산 분리
  /// calculateBearing: 두 지점 간의 방향(베어링)을 계산합니다.
  static double calculateBearing(double currentLatitude, double currentLongitude,
      double targetLatitude, double targetLongitude) {
    double lat1 = currentLatitude * math.pi / 180;
    double lon1 = currentLongitude * math.pi / 180;
    double lat2 = targetLatitude * math.pi / 180;
    double lon2 = targetLongitude * math.pi / 180;
    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    double bearingDegrees = bearing * 180 / math.pi;
    if (bearingDegrees < 0) bearingDegrees += 360;
    return bearingDegrees;
  }


  
  /// 계산 분리
  /// _haversine: haversine 공식을 사용하여 두 지점 사이의 거리를 미터 단위로 계산합니다.
  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3;
    double dLat = deg2rad(lat2 - lat1);
    double dLon = deg2rad(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(deg2rad(lat1)) *
            math.cos(deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// 계산 분리
  /// pointLineDistance: 한 점과 선분 사이의 최단 거리를 계산합니다.
  static double pointLineDistance(double lat1, double lon1, double lat2, double lon2,
      double latP, double lonP) {
    double dist12 = haversine(lat1, lon1, lat2, lon2);
    double dist1P = haversine(lat1, lon1, latP, lonP);
    double dist2P = haversine(lat2, lon2, latP, lonP);
    double A = dist1P / 6371e3, B = dist2P / 6371e3, C = dist12 / 6371e3;
    double angleP12 = math.acos((math.cos(A) - math.cos(B) * math.cos(C)) /
        (math.sin(B) * math.sin(C)));
    return math.sin(angleP12) * dist1P;
  }

  
  /// 계산 분리
  /// sphericalDistance: 두 점 사이의 구면 거리를 계산합니다.
  /// (구면 삼각법을 사용하여 계산합니다.)
  static double sphericalDistance(
          double lat1, double lon1, double lat2, double lon2) =>
      math.acos(math.sin(lat1) * math.sin(lat2) +
          math.cos(lat1) * math.cos(lat2) * math.cos(lon2 - lon1));
  /// 계산 분리
  /// sphericalAngle: 구면 삼각법을 사용하여 세 변의 길이가 주어졌을 때 각도를 계산합니다.
  static double sphericalAngle(double a, double b, double c) => math.acos(
      (math.cos(a) - math.cos(b) * math.cos(c)) / (math.sin(b) * math.sin(c)));
  

  /// calculateYawDeviationFromCompass: 목표 방향과 현재 나침반 값의 차이를 계산하여 회전 보정 값을 구합니다.
  static double calculateYawDeviationFromCompass(double bearingToPoint, double compassValue) {
    return compassValue - bearingToPoint;
  }

    /// 계산 분리
  /// latLonToXY: 위도 및 경도 차이를 기반으로 x, y 거리(미터)를 계산합니다.
  /// (평균 위도를 이용하여 단순 근사 계산)
  static Map<String, double> latLonToXY(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude) {
    double deltaLat = targetIndexLatitude - currentIndexLatitude;
    double deltaLon = targetIndexLongitude - currentIndexLongitude;
    double avgLat = (currentIndexLatitude + targetIndexLatitude) / 2.0;
    double x = deltaLon * 111320 * math.cos(avgLat * math.pi / 180);
    double y = deltaLat * 111320;
    return {'x': x, 'y': y};
  }

  /// 계산 분리
  /// breakPoint: 현재 지점(브랜치), 현재 위치, 목표 지점으로 이루어진 삼각형의 각도를 계산합니다.
  /// 반환값은 'breakPointAngleA', 'breakPointAngleB', 'breakPointAngleC'라는 키를 갖는 Map입니다.
  static Map<String, double> breakPoint(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double currentLatitude,
      double currentLongitude) {
    double lat1 = deg2rad(currentIndexLatitude);
    double lon1 = deg2rad(currentIndexLongitude);
    double lat2 = deg2rad(currentLatitude);
    double lon2 = deg2rad(currentLongitude);
    double lat3 = deg2rad(targetIndexLatitude);
    double lon3 = deg2rad(targetIndexLongitude);
    double a = sphericalDistance(lat2, lon2, lat3, lon3);
    double b = sphericalDistance(lat3, lon3, lat1, lon1);
    double c = sphericalDistance(lat1, lon1, lat2, lon2);
    double A = sphericalAngle(a, b, c);
    double B = sphericalAngle(b, a, c);
    double C = sphericalAngle(c, a, b);
    return {
      'breakPointAngleA': A,
      'breakPointAngleB': B,
      'breakPointAngleC': C
    };
  }

  /// checkLateralDeviation: 현재 지점에서 목표 지점까지의 벡터와 현재 지점에서 현재 위치까지의 벡터의 외적을 통해
  /// 좌우 편차(측면 이탈)를 판단합니다.
  /// 외적 값이 양이면 왼쪽, 음이면 오른쪽, 0이면 일직선입니다.
  static int checkLateralDeviation(
      double currentIndexLatitude,
      double currentIndexLongitude,
      double targetIndexLatitude,
      double targetIndexLongitude,
      double currentLatitude,
      double currentLongitude) {
    Map<String, double> pathVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, targetIndexLatitude, targetIndexLongitude);
    Map<String, double> currentVector = latLonToXY(currentIndexLatitude,
        currentIndexLongitude, currentLatitude, currentLongitude);
    double crossProduct = pathVector['x']! * currentVector['y']! -
        pathVector['y']! * currentVector['x']!;
    if (crossProduct > 0) return -1;
    if (crossProduct < 0) return 1;
    return 0;
  }

  /// angleToTarget: 센서 데이터에 기반하여 목표 브랜치까지의 안내 각도를 계산합니다.
  /// [deviationYawTurn]: 센서 데이터에 의한 회전 보정 값.
  /// [bearingToPoint]: 현재 브랜치에서 목표 브랜치까지의 방향.
  /// [boundaryExit]: 측면 이탈 여부 (좌우 편차 결과).
  static double angleToTarget(
      double currentIndexLongitude,
      double currentIndexLatitude,
      double targetIndexLongitude,
      double targetIndexLatitude,
      double currentLatitude,
      double currentLongitude,
      double deviationYawTurn,
      double bearingToPoint,
      int boundaryExit) {
    Map<String, double> breakPointAngle = breakPoint(
        currentIndexLongitude,
        currentIndexLatitude,
        targetIndexLongitude,
        targetIndexLatitude,
        currentLatitude,
        currentLongitude);
    double guidanceAngle = 0.0;
    if (boundaryExit > 0) {
      double baseAngle = (rad2deg(breakPointAngle['breakPointAngleC']!));
      guidanceAngle = (baseAngle + deviationYawTurn) % 360;
    } else {
      double baseAngle = (rad2deg(breakPointAngle['breakPointAngleC']!));
      guidanceAngle = (baseAngle - deviationYawTurn) % 360;
    }
    return guidanceAngle;
  }
  /// 계산 분리
  /// _distanceBetweenBranch: 두 branch 정보 지점 사이의 거리를 계산합니다.
  static double distanceBetweenBranch(
      double currentIndexLatitude, double currentIndexLongitude, double targetIndexLatitude, double targetIndexLongitude) {

    return calculateDistance(currentIndexLatitude,currentIndexLongitude,
        targetIndexLatitude, targetIndexLongitude);
  }

  /// clockDirectionLabel: 상대 각도(0~360)를 "몇 시 방향" 문자열로 변환합니다.
  /// 12시 방향이 0도, 시계 방향으로 증가합니다.
  static String clockDirectionLabel(double relativeDeg) {
    final index = ((relativeDeg + 15.0) % 360.0 ~/ 30.0); // 0~11
    const labels = [
      "12시",
      "1시",
      "2시",
      "3시",
      "4시",
      "5시",
      "6시",
      "7시",
      "8시",
      "9시",
      "10시",
      "11시",
    ];
    return labels[index];
  }

  /// clockDirectionFromPositions: 현재 위치에서 타겟까지의 시계 방향을 계산합니다.
  /// [currentLatitude], [currentLongitude]: 현재 위치
  /// [targetLatitude], [targetLongitude]: 타겟 위치
  /// [compassValue]: 현재 나침반 값 (북쪽 기준 사용자가 바라보는 방향)
  /// 반환값: "12시", "3시" 등의 시계 방향 문자열
  static String clockDirectionFromPositions({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double compassValue,
  }) {
    final bearing = calculateBearing(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );
    final relative = (bearing - compassValue + 360.0) % 360.0;
    return clockDirectionLabel(relative);
  }
}