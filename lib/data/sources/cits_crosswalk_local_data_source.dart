part of '../../framework/data_source.dart';

/// C-ITS 음향신호기 LocalDataSource
///
/// CSV 파일 저장/로드 및 메모리 캐싱
abstract class CitsCrosswalkLocalDataSource {
  /// 모든 음향신호기 데이터 로드
  Future<List<CitsCrosswalkModel>> loadAll();

  /// 반경 내 음향신호기 필터링
  Future<List<CitsCrosswalkModel>> getWithinRadius({
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

class CitsCrosswalkLocalDataSourceImpl implements CitsCrosswalkLocalDataSource {
  static const String _csvFileName = 'cits_crosswalks.csv';
  static const String _versionKey = 'cits_crosswalks_version';

  List<CitsCrosswalkModel>? _cache;

  @override
  Future<List<CitsCrosswalkModel>> loadAll() async {
    if (_cache != null) return _cache!;

    try {
      String csvString;
      if (await hasLocalCsv()) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_csvFileName');
        csvString = await file.readAsString();
      } else {
        csvString = await rootBundle.loadString('lib/assets/data/seoul_crosswalk.csv');
      }

      final crosswalks = _parseCsv(csvString);
      _cache = crosswalks;
      return crosswalks;
    } catch (e) {
      throw CacheException('음향신호기 CSV 로드 실패: $e');
    }
  }

  @override
  Future<List<CitsCrosswalkModel>> getWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    final all = await loadAll();
    return all.where((c) {
      return _isWithinRadius(
        lat1: latitude,
        lng1: longitude,
        lat2: c.latitude,
        lng2: c.longitude,
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
      throw CacheException('음향신호기 CSV 저장 실패: $e');
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

  List<CitsCrosswalkModel> _parseCsv(String csvString) {
    final lines = csvString.split('\n');
    final crosswalks = <CitsCrosswalkModel>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final columns = _parseCsvLine(line);
        if (columns.length >= 12) {
          crosswalks.add(CitsCrosswalkModel.fromCsvRow(columns));
        }
      } catch (e) {
        continue;
      }
    }

    return crosswalks;
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
