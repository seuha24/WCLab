import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'dio_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://backend.catholicuniv.pillowstudio.kr',
        connectTimeout: const Duration(seconds: 10), // 연결 타임아웃
        receiveTimeout: const Duration(seconds: 10), // 응답 타임아웃
        contentType: 'application/json',
      ),
    );

    // Interceptors 추가
    _dio.interceptors.add(AuthInterceptor(_dio));

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseHeader: kDebugMode,
        compact: !kDebugMode,
      ),
    );
  }

  Dio get dio => _dio; // Dio 인스턴스 반환
}