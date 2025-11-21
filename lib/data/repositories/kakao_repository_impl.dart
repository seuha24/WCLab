import 'package:dartz/dartz.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/data/services/kakao_local_api_service.dart';
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/domain/repositories/kakao_repository.dart';

/// KakaoRepository 구현체
///
/// **의존성:**
/// - KakaoLocalApiService (HTTP 통신 담당)
///
/// **책임:**
/// - 카카오 API 응답을 PlaceResult Entity로 변환
/// - 에러를 Failure로 변환
/// - Either 패턴으로 성공/실패 반환
class KakaoRepositoryImpl implements KakaoRepository {
  final KakaoLocalApiService apiService;

  KakaoRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, List<PlaceResult>>> searchPlaces(
    String query, {
    double? x,
    double? y,
  }) async {
    try {
      // 1. API 호출
      final response = await apiService.searchPlaces(
        query,
        x: x,
        y: y,
      );

      // 2. JSON 파싱
      final List<dynamic> documents = response['documents'];

      // 3. PlaceResult 변환
      final places = documents.map((doc) {
        // 도로명 주소 우선, 없으면 지번 주소 사용
        final addressName = doc['road_address_name']?.isNotEmpty == true
            ? doc['road_address_name']
            : doc['address_name'];

        return PlaceResult(
          name: doc['place_name'],
          address: addressName,
          geometry: LatLngGeometry(
            location: GeoLocation(
              lat: double.parse(doc['y']),
              lng: double.parse(doc['x']),
            ),
          ),
        );
      }).toList();

      return Right(places);
    } on Exception catch (e) {
      // 네트워크 에러
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // API 호출 (KakaoLocalApiService에서 이미 에러 처리됨)
      final address = await apiService.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      return Right(address);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlaceResult>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50,
  }) async {
    try {
      // 1. API 호출
      final documents = await apiService.searchNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      // 2. PlaceResult 변환 (distance 필드 포함)
      final places = documents.map((doc) {
        // 도로명 주소 우선, 없으면 지번 주소 사용
        final addressName = doc['road_address_name']?.toString().isNotEmpty == true
            ? doc['road_address_name']
            : doc['address_name'] ?? '';

        return PlaceResult(
          name: doc['place_name'] as String,
          address: addressName,
          geometry: LatLngGeometry(
            location: GeoLocation(
              lat: double.parse(doc['y'] as String),
              lng: double.parse(doc['x'] as String),
            ),
          ),
          distance: int.tryParse(doc['distance']?.toString() ?? '0'),
        );
      }).toList();

      return Right(places);
    } on Exception catch (e) {
      // 네트워크 에러
      return Left(NetworkFailure(e.toString()));
    }
  }
}
