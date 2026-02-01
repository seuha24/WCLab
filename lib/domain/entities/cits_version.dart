part of '../../framework/object.dart';

/// C-ITS 데이터 버전 정보 엔티티
///
/// API 2-3 `/api/location/sync` 응답
/// 교차로와 음향신호기 버전을 한번에 관리
class CitsVersion extends Equatable {
  /// 교차로 데이터 버전
  final int junctionsVersion;

  /// 음향신호기 데이터 버전
  final int crosswalkVersion;

  const CitsVersion({
    required this.junctionsVersion,
    required this.crosswalkVersion,
  });

  @override
  List<Object?> get props => [junctionsVersion, crosswalkVersion];

  @override
  String toString() {
    return 'CitsVersion(junctions: $junctionsVersion, crosswalk: $crosswalkVersion)';
  }
}
