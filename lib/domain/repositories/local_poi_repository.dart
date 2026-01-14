import 'package:safelight/domain/entities/place_result.dart';

/// 로컬 POI(관심지점) Repository 인터페이스
///
/// 로컬 JSON 파일에서 POI 데이터를 로드하고 관리합니다.
/// 역곡 지역의 횡단보도, 버스정류장, 사거리, 건물 정보를 제공합니다.
abstract class LocalPoiRepository {
  /// 모든 로컬 POI를 로드합니다.
  ///
  /// 앱 시작 시 한 번 호출하여 메모리에 캐싱합니다.
  Future<List<PlaceResult>> loadAllPois();

  /// 특정 좌표 주변의 POI를 검색합니다.
  ///
  /// [latitude], [longitude]: 중심 좌표
  /// [radiusMeters]: 검색 반경 (미터)
  ///
  /// 반환: 반경 내 POI 목록 (거리순 정렬되지 않음)
  List<PlaceResult> searchNearbyPois({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  });

  /// 캐시된 POI 개수를 반환합니다.
  int get cachedPoiCount;
}
