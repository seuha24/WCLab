import 'package:flutter/foundation.dart';
import 'package:safelight/core/utils/tts_messages.dart';
import 'package:safelight/data/services/kakao_local_api_service.dart';
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/repository.dart';

const _kCrosswalkPoiDebug = true;

/// 음향신호기-교차로 POI 서비스
///
/// C-ITS API 음향신호기와 교차로를 매칭하여
/// POI 안내에 활용할 수 있는 PlaceResult로 변환합니다.
///
/// **핵심 로직:**
/// 1. 음향신호기 위치에서 30m 반경 내 교차로 검색
/// 2. 교차로 발견 시: "{교차로명} 횡단보도"
/// 3. 교차로 없을 시: "횡단보도"
/// 4. 같은 위치(10m 반경) 음향신호기는 가장 가까운 것만 반환
class CrosswalkPoiService {
  final CitsCrosswalkRepository citsCrosswalkRepository;
  final CitsJunctionRepository citsJunctionRepository;

  /// 음향신호기-교차로 매칭 반경 (미터)
  static const double matchingRadiusMeters = 30.0;

  /// 중복 음향신호기 그룹화 반경 (미터)
  static const double groupingRadiusMeters = 10.0;

  /// 캐시된 모든 교차로 (앱 시작 시 로드)
  List<CitsJunction> _cachedJunctions = [];

  /// 캐시된 모든 음향신호기 (앱 시작 시 로드)
  List<CitsCrosswalk> _cachedCrosswalks = [];

  /// 초기화 여부
  bool _isInitialized = false;

  CrosswalkPoiService({
    required this.citsCrosswalkRepository,
    required this.citsJunctionRepository,
  });

  /// 데이터 초기화 (앱 시작 시 호출)
  ///
  /// 음향신호기와 교차로 데이터를 메모리에 로드합니다.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 병렬로 데이터 로드
    final results = await Future.wait([
      citsCrosswalkRepository.loadAllCrosswalks(),
      citsJunctionRepository.loadAllJunctions(),
    ]);

    results[0].fold(
      (failure) => _log('음향신호기 로드 실패: $failure'),
      (crosswalks) {
        _cachedCrosswalks = crosswalks as List<CitsCrosswalk>;
        _log('음향신호기 ${_cachedCrosswalks.length}개 로드 완료');
      },
    );

    results[1].fold(
      (failure) => _log('교차로 로드 실패: $failure'),
      (junctions) {
        _cachedJunctions = junctions as List<CitsJunction>;
        _log('교차로 ${_cachedJunctions.length}개 로드 완료');
      },
    );

    _isInitialized = true;
  }

  /// 주변 음향신호기 POI 검색
  ///
  /// [latitude], [longitude]: 중심 좌표
  /// [radiusMeters]: 검색 반경 (미터)
  ///
  /// 반환: PlaceResult 목록 (교차로 매칭 + 중복 제거 완료)
  List<PlaceResult> searchNearbyCrosswalkPois({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    if (!_isInitialized || _cachedCrosswalks.isEmpty) {
      _log('데이터 미초기화 상태');
      return [];
    }

    // 1. 반경 내 음향신호기 필터링
    final nearbyCrosswalks = _filterByRadius(
      _cachedCrosswalks,
      latitude,
      longitude,
      radiusMeters.toDouble(),
    );

    if (nearbyCrosswalks.isEmpty) return [];

    _log('반경 ${radiusMeters}m 내 음향신호기 ${nearbyCrosswalks.length}개 발견');

    // 2. 중복 제거 (가장 가까운 것만 선택)
    final uniqueCrosswalks = _removeDuplicates(
      nearbyCrosswalks,
      latitude,
      longitude,
    );

    _log('중복 제거 후 ${uniqueCrosswalks.length}개');

    // 3. 교차로 매칭 및 PlaceResult 변환
    final results = <PlaceResult>[];

    for (final crosswalk in uniqueCrosswalks) {
      final matchedJunction = _findNearestJunction(
        crosswalk.latitude,
        crosswalk.longitude,
      );

      final name = (matchedJunction != null && matchedJunction.name != null)
          ? TtsMessages.crosswalkWithIntersection(matchedJunction.name!)
          : TtsMessages.crosswalkOnly;

      results.add(PlaceResult(
        name: name,
        address: '',
        geometry: LatLngGeometry(
          location: GeoLocation(
            lat: crosswalk.latitude,
            lng: crosswalk.longitude,
          ),
        ),
        category: KakaoCategoryCode.CSW,
      ));
    }

    return results;
  }

  /// 반경 내 음향신호기 필터링
  List<CitsCrosswalk> _filterByRadius(
    List<CitsCrosswalk> crosswalks,
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) {
    return crosswalks.where((crosswalk) {
      final distanceKm = Calculators.calculateDistance(
        centerLat,
        centerLng,
        crosswalk.latitude,
        crosswalk.longitude,
      );
      return distanceKm * 1000 <= radiusMeters;
    }).toList();
  }

  /// 중복 음향신호기 제거 (그룹화 반경 내 가장 가까운 것만 선택)
  List<CitsCrosswalk> _removeDuplicates(
    List<CitsCrosswalk> crosswalks,
    double userLat,
    double userLng,
  ) {
    if (crosswalks.isEmpty) return [];

    // 거리순 정렬
    final sorted = List<CitsCrosswalk>.from(crosswalks);
    sorted.sort((a, b) {
      final distA = Calculators.calculateDistance(
        userLat,
        userLng,
        a.latitude,
        a.longitude,
      );
      final distB = Calculators.calculateDistance(
        userLat,
        userLng,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });

    // 그룹화 반경 내 중복 제거
    final unique = <CitsCrosswalk>[];
    final usedIndices = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (usedIndices.contains(i)) continue;

      unique.add(sorted[i]);
      usedIndices.add(i);

      // 이 음향신호기와 가까운 다른 음향신호기들을 사용됨으로 표시
      for (int j = i + 1; j < sorted.length; j++) {
        if (usedIndices.contains(j)) continue;

        final distanceKm = Calculators.calculateDistance(
          sorted[i].latitude,
          sorted[i].longitude,
          sorted[j].latitude,
          sorted[j].longitude,
        );

        if (distanceKm * 1000 <= groupingRadiusMeters) {
          usedIndices.add(j);
        }
      }
    }

    return unique;
  }

  /// 음향신호기 위치에서 가장 가까운 교차로 찾기
  ///
  /// 매칭 반경(30m) 내 교차로가 없으면 null 반환
  CitsJunction? _findNearestJunction(double crosswalkLat, double crosswalkLng) {
    if (_cachedJunctions.isEmpty) return null;

    CitsJunction? nearest;
    double minDistance = double.infinity;

    for (final junction in _cachedJunctions) {
      final distanceKm = Calculators.calculateDistance(
        crosswalkLat,
        crosswalkLng,
        junction.latitude,
        junction.longitude,
      );
      final distanceMeters = distanceKm * 1000;

      if (distanceMeters <= matchingRadiusMeters && distanceMeters < minDistance) {
        minDistance = distanceMeters;
        nearest = junction;
      }
    }

    if (nearest != null) {
      _log('교차로 매칭: ${nearest.name} (${minDistance.toStringAsFixed(1)}m)');
    }

    return nearest;
  }

  void _log(String message) {
    if (_kCrosswalkPoiDebug) {
      debugPrint('[CrosswalkPoiService] $message');
    }
  }
}
