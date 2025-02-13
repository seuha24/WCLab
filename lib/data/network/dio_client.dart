import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:safelight/data/network/api_endpoints.dart';
import 'dio_interceptor.dart';

/// API 호출을 위한 Dio 클라이언트를 설정하는 싱글톤 클래스입니다.
///
/// 이 클래스는 Dio 인스턴스를 생성하고 기본 옵션 및 인터셉터(인증 인터셉터와 PrettyDioLogger)를 추가하여
/// 네트워크 요청의 공통 설정을 관리합니다.
class DioClient {
  // 싱글톤 인스턴스 생성
  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  /// [DioClient] 팩토리 생성자.
  ///
  /// 항상 동일한 싱글톤 인스턴스를 반환합니다.
  factory DioClient() {
    return _instance;
  }

  /// 내부 생성자.
  ///
  /// Dio 인스턴스를 초기화하고, 기본 옵션 및 인터셉터를 설정합니다.
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10), // 연결 타임아웃 설정
        receiveTimeout: const Duration(seconds: 10), // 응답 타임아웃 설정
        contentType: 'application/json', // 기본 콘텐츠 타입 설정
      ),
    );

    // 인증 인터셉터 추가: 모든 요청에 인증 토큰을 추가하고, 토큰 갱신을 처리합니다.
    _dio.interceptors.add(AuthInterceptor(_dio));

    // PrettyDioLogger 추가: 디버그 모드에서 요청 및 응답 로그를 출력합니다.
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseHeader: kDebugMode,
        compact: !kDebugMode,
      ),
    );
  }

  /// 구성된 Dio 인스턴스를 반환합니다.
  Dio get dio => _dio;
}