import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:safelight/data/services/kakao_local_api_service.dart';
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/domain/repositories/local_poi_repository.dart';
import 'package:safelight/framework/core.dart';

/// 로컬 POI Repository 구현체
///
/// JSON 파일에서 POI 데이터를 로드하여 메모리에 캐싱합니다.
class LocalPoiRepositoryImpl implements LocalPoiRepository {
  static const String _jsonPath = 'lib/assets/jsons/yeokgok_poi.json';

  bool _isInitialized = false;

  /// 캐시된 POI 목록
  List<PlaceResult> _cachedPois = [];

  @override
  int get cachedPoiCount => _cachedPois.length;

  @override
  Future<List<PlaceResult>> loadAllPois() async {
    if (_isInitialized && _cachedPois.isNotEmpty) {
      return _cachedPois;
    }

    try {
      final jsonString = await rootBundle.loadString(_jsonPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedPois = jsonList.map((json) => _fromJson(json)).toList();
      _isInitialized = true;

      debugPrint('[LocalPoiRepository] ✅ 로컬 POI ${_cachedPois.length}개 로드 완료');

      return _cachedPois;
    } catch (e) {
      debugPrint('[LocalPoiRepository] ❌ 로컬 POI 로드 실패: $e');
      return [];
    }
  }

  @override
  List<PlaceResult> searchNearbyPois({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    // 초기화 안됐으면 빈 리스트 반환 (비동기 로드는 initializeLocalPois에서)
    if (!_isInitialized || _cachedPois.isEmpty) {
      debugPrint('[LocalPoiRepository] ⚠️ POI 미초기화 상태 - 먼저 loadAllPois() 호출 필요');
      return [];
    }

    final List<PlaceResult> nearbyPois = [];

    for (final poi in _cachedPois) {
      final distanceKm = Calculators.calculateDistance(
        latitude,
        longitude,
        poi.geometry.location.lat,
        poi.geometry.location.lng,
      );
      final distanceMeters = distanceKm * 1000;

      if (distanceMeters <= radiusMeters) {
        nearbyPois.add(poi);
      }
    }

    return nearbyPois;
  }

  /// JSON 데이터를 PlaceResult로 변환
  PlaceResult _fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String;
    final category = _parseCategory(code);
    final name = _buildDisplayName(json['name'] as String, category);

    return PlaceResult(
      name: name,
      address: '',
      geometry: LatLngGeometry(
        location: GeoLocation(
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lon'] as num).toDouble(),
        ),
      ),
      category: category,
    );
  }

  /// 코드 문자열을 KakaoCategoryCode로 변환
  KakaoCategoryCode _parseCategory(String code) {
    switch (code) {
      case 'CSW':
        return KakaoCategoryCode.CSW;
      case 'BST':
        return KakaoCategoryCode.BST;
      case 'CSR':
        return KakaoCategoryCode.CSR;
      case 'SC4':
        return KakaoCategoryCode.SC4;
      default:
        return KakaoCategoryCode.CSW;
    }
  }

  /// 카테고리에 따른 표시 이름 생성
  ///
  /// 횡단보도는 그대로, 버스정류장은 "정거장" 제거
  String _buildDisplayName(String name, KakaoCategoryCode category) {
    if (category == KakaoCategoryCode.BST) {
      // "OOO 정거장" → "OOO 버스정류장"
      return name.replaceAll(' 정거장', ' 버스정류장');
    }
    return name;
  }
}
