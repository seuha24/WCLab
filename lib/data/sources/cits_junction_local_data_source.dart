part of '../../framework/data_source.dart';

/// C-ITS 교차로 LocalDataSource
///
/// CSV 파일 저장/로드 및 메모리 캐싱
abstract class CitsJunctionLocalDataSource {
  /// 모든 교차로 데이터 로드
  Future<List<CitsJunctionModel>> loadAll();

  /// 반경 내 교차로 필터링
  Future<List<CitsJunctionModel>> getWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  });

  /// CSV 저장
  Future<void> saveCsv(String csvData, int version);

  /// 로컬 CSV 파일 존재 여부
  Future<bool> hasLocalCsv();

  /// 로컬 CSV 버전 조회
  Future<int?> getLocalVersion();

  /// 캐시 초기화
  void clearCache();
}

class CitsJunctionLocalDataSourceImpl implements CitsJunctionLocalDataSource {
  static const String _csvFileName = 'cits_junctions.csv';
  static const String _versionKey = 'cits_junctions_version';

  List<CitsJunctionModel>? _cache;

  @override
  Future<List<CitsJunctionModel>> loadAll() async {
    if (_cache != null) return _cache!;

    try {
      String csvString;
      if (await hasLocalCsv()) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_csvFileName');
        csvString = await file.readAsString();
      } else {
        csvString = await rootBundle.loadString('lib/assets/data/seoul_junction.csv');
      }

      final junctions = _parseCsv(csvString);
      _cache = junctions;
      return junctions;
    } catch (e) {
      throw CacheException('교차로 CSV 로드 실패: $e');
    }
  }

  @override
  Future<List<CitsJunctionModel>> getWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    final all = await loadAll();
    return all.where((j) {
      return _isWithinRadius(
        lat1: latitude,
        lng1: longitude,
        lat2: j.latitude,
        lng2: j.longitude,
        radiusM: radiusInMeters,
      );
    }).toList();
  }

  @override
  Future<void> saveCsv(String csvData, int version) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_csvFileName');
      await file.writeAsString(csvData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_versionKey, version);

      clearCache();
    } catch (e) {
      throw CacheException('교차로 CSV 저장 실패: $e');
    }
  }

  @override
  Future<bool> hasLocalCsv() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_csvFileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int?> getLocalVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_versionKey);
    } catch (e) {
      return null;
    }
  }

  @override
  void clearCache() {
    _cache = null;
  }

  List<CitsJunctionModel> _parseCsv(String csvString) {
    final lines = csvString.split('\n');
    final junctions = <CitsJunctionModel>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final columns = _parseCsvLine(line);
        if (columns.length >= 9) {
          junctions.add(CitsJunctionModel.fromCsvRow(columns));
        }
      } catch (e) {
        continue;
      }
    }

    return junctions;
  }

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

  bool _isWithinRadius({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
    required double radiusM,
  }) {
    const meterPerLat = 111000.0;
    const meterPerLng = 88000.0;

    final dLat = (lat2 - lat1) * meterPerLat;
    final dLng = (lng2 - lng1) * meterPerLng;

    return (dLat * dLat + dLng * dLng) <= (radiusM * radiusM);
  }
}
