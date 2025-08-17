import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:safelight/data/models/favorite_point_model.dart';
import 'package:safelight/data/models/favorite_route_model.dart';
import 'package:safelight/data/network/api_endpoints.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/framework/core.dart';

abstract class FavoriteRemoteDataSource {
  Future<List<FavoritePointModel>> getFavoritePoints({
    required String loginMethod,
    required String userId,
  });

  Future<List<FavoriteRouteModel>> getFavoriteRoutes({
    required String loginMethod,
    required String userId,
  });

  Future<FavoritePointModel> addFavoritePoint({
    required String loginMethod,
    required String userId,
    required String name,
    required double longitude,
    required double latitude,
  });

  Future<bool> addFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String name,
    required RoutePoint? startPoint,
    required RoutePoint? finishPoint,
    required List<RoutePoint?> stopovers,
  });
}

class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final DioClient dioClient;

  FavoriteRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<FavoritePointModel>> getFavoritePoints({
    required String loginMethod,
    required String userId,
  }) async {
    try {
      final url = ApiEndpoints.getFavoritePoints(loginMethod, userId);
      
      // GET 요청 로깅
      debugPrint('=== 즐겨찾기 지점 조회 요청 ===');
      debugPrint('URL: $url');
      debugPrint('Login Method: $loginMethod');
      debugPrint('User ID: $userId');
      debugPrint('===================================');
      
      final response = await dioClient.dio.get(url);

      if (response.data['error'] != null) {
        throw ServerException();
      }

      // 서버 응답 로깅
      debugPrint('지점 조회 응답: ${response.data}');
      
      final list = response.data['list'] as List? ?? [];
      if (list.isEmpty) {
        debugPrint('빈 즐겨찾기 리스트');
        return [];
      }
      
      debugPrint('즐겨찾기 지점 개수: ${list.length}');
      return list.map((json) => FavoritePointModel.fromJson(json)).toList();
    } on DioException {
      throw ServerException();
    }
  }

  @override
  Future<List<FavoriteRouteModel>> getFavoriteRoutes({
    required String loginMethod,
    required String userId,
  }) async {
    try {
      final url = ApiEndpoints.getFavoriteRoutes(loginMethod, userId);
      
      // GET 요청 로깅
      debugPrint('=== 즐겨찾기 경로 조회 요청 ===');
      debugPrint('URL: $url');
      debugPrint('Login Method: $loginMethod');
      debugPrint('User ID: $userId');
      debugPrint('===================================');
      
      final response = await dioClient.dio.get(url);

      if (response.data['error'] != null) {
        throw ServerException();
      }

      final list = response.data['list'] as List;
      return list.map((json) => FavoriteRouteModel.fromJson(json)).toList();
    } on DioException {
      throw ServerException();
    }
  }

  @override
  Future<FavoritePointModel> addFavoritePoint({
    required String loginMethod,
    required String userId,
    required String name,
    required double longitude,
    required double latitude,
  }) async {
    try {
      final requestData = {
        'login_method': loginMethod,
        'ID': userId,
        'new_fav_point': {
          'name': name,
          'lon': longitude,
          'lat': latitude,
        },
      };
      
      // JSON 데이터 로깅
      debugPrint('=== 즐겨찾기 지점 추가 요청 데이터 ===');
      debugPrint('URL: ${ApiEndpoints.addFavoritePoint}');
      debugPrint('JSON 데이터:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(requestData));
      debugPrint('=====================================');
      
      final response = await dioClient.dio.post(
        ApiEndpoints.addFavoritePoint,
        data: requestData,
      );

      if (response.data['success'] != true) {
        throw ServerException();
      }

      final entrancePoint = response.data['entrance_point'];
      return FavoritePointModel(
        name: name,
        longitude: longitude,
        latitude: latitude,
        entranceLongitude: entrancePoint != null 
            ? (entrancePoint['lon'] as num).toDouble() 
            : null,
        entranceLatitude: entrancePoint != null 
            ? (entrancePoint['lat'] as num).toDouble() 
            : null,
      );
    } on DioException {
      throw ServerException();
    }
  }

  @override
  Future<bool> addFavoriteRoute({
    required String loginMethod,
    required String userId,
    required String name,
    required RoutePoint? startPoint,
    required RoutePoint? finishPoint,
    required List<RoutePoint?> stopovers,
  }) async {
    try {
      final requestData = {
        'login_method': loginMethod,
        'ID': userId,
        'list': {
          'name': name,
          'start_point': startPoint != null
              ? {
                  'lon': startPoint.longitude,
                  'lat': startPoint.latitude,
                }
              : null,
          'finish_point': finishPoint != null
              ? {
                  'lon': finishPoint.longitude,
                  'lat': finishPoint.latitude,
                }
              : null,
          'stopovers': stopovers.map((point) {
            if (point == null) return null;
            return {
              'lon': point.longitude,
              'lat': point.latitude,
            };
          }).toList(),
        },
      };
      
      // JSON 데이터 로깅
      debugPrint('=== 즐겨찾기 경로 추가 요청 데이터 ===');
      debugPrint('URL: ${ApiEndpoints.addFavoriteRoute}');
      debugPrint('JSON 데이터:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(requestData));
      debugPrint('=====================================');
      
      final response = await dioClient.dio.post(
        ApiEndpoints.addFavoriteRoute,
        data: requestData,
      );

      return response.data['success'] == true;
    } on DioException {
      throw ServerException();
    }
  }
}