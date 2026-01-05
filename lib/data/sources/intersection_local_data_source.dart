part of '../../framework/data_source.dart';

/// 서울시 공공데이터 교차로 LocalDataSource
///
/// CSV 파일을 파싱하여 Intersection 목록을 제공한다.
/// 앱 시작 시 한 번 로드하여 메모리에 캐싱한다.
abstract class IntersectionLocalDataSource {
  /// CSV 파일에서 모든 교차로 데이터 로드
  Future<List<IntersectionModel>> loadAllIntersections();

  /// 현재 위치 기준 반경 내 교차로 필터링
  Future<List<IntersectionModel>> getIntersectionsWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  });

  /// 데이터가 로드되었는지 확인
  bool get isLoaded;
}

/// IntersectionLocalDataSource 구현체
class IntersectionLocalDataSourceImpl implements IntersectionLocalDataSource {
  List<IntersectionModel>? _cachedIntersections;

  @override
  bool get isLoaded => _cachedIntersections != null;

  @override
  Future<List<IntersectionModel>> loadAllIntersections() async {
    if (_cachedIntersections != null) {
      return _cachedIntersections!;
    }

    try {
      // assets에서 CSV 파일 로드
      final csvString = await _loadCsvFromAssets();
      final intersections = _parseCsv(csvString);
      _cachedIntersections = intersections;
      return intersections;
    } catch (e) {
      throw CacheException('교차로 CSV 데이터 로드 실패: $e');
    }
  }

  /// assets에서 CSV 파일 읽기
  Future<String> _loadCsvFromAssets() async {
    return await rootBundle.loadString('lib/assets/data/seoul_intersection.csv');
  }

  /// CSV 문자열 파싱
  List<IntersectionModel> _parseCsv(String csvString) {
    final lines = csvString.split('\n');
    final intersections = <IntersectionModel>[];

    // 헤더 스킵 (첫 번째 줄)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final columns = _parseCsvLine(line);
        if (columns.length >= 9) {
          intersections.add(IntersectionModel.fromCsvRow(columns));
        }
      } catch (e) {
        // 파싱 실패한 행은 스킵
        continue;
      }
    }

    return intersections;
  }

  /// CSV 라인 파싱 (쉼표 구분, 따옴표 처리)
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());

    return result;
  }

  @override
  Future<List<IntersectionModel>> getIntersectionsWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    final allIntersections = await loadAllIntersections();

    return allIntersections.where((intersection) {
      return _isWithinRadius(
        lat1: latitude,
        lng1: longitude,
        lat2: intersection.latitude,
        lng2: intersection.longitude,
        radiusM: radiusInMeters,
      );
    }).toList();
  }

  /// 반경 내 여부 확인 (간이 거리 계산 - 한국 기준 최적화)
  ///
  /// Haversine 공식 대신 직교 좌표계 근사값 사용으로 성능 최적화
  bool _isWithinRadius({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
    required double radiusM,
  }) {
    // 한국 위도 기준 1도당 미터
    const meterPerLat = 111000.0; // 위도 1도 ≈ 111km
    const meterPerLng = 88000.0; // 경도 1도 ≈ 88km (한국 위도 37도 기준)

    final dLat = (lat2 - lat1) * meterPerLat;
    final dLng = (lng2 - lng1) * meterPerLng;

    // 피타고라스 정리로 거리 계산 (제곱 비교로 sqrt 연산 생략)
    return (dLat * dLat + dLng * dLng) <= (radiusM * radiusM);
  }
}
