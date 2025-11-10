import 'package:latlong2/latlong.dart';

class BranchInfo {
  LatLng point; // 모든 경로값
  String description; // 각 분기의 경로값
  double bearingToPoint; // 다음 경로까지의 방향값
  bool crosswalk; // branch 좌표가 횡단보도면 true, 아니면 false
  bool branch; // 해당 point가 branch 좌표라면 true, 아니면 false
  bool waypoint=false; // 해당 point가 경유지 좌표라면 true, 아니면 false
  BranchInfo(
      // 생성자
      this.point,
      this.description,
      this.bearingToPoint,
      this.crosswalk,
      this.branch,
      this.waypoint);

  @override
  String toString() {
    return 'BranchInfo{point: $point, : $branch, description: $description, bearingToBranch: $bearingToPoint, crosswalk: $crosswalk, waypoint: $waypoint}';
  }
}