import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/injection.dart';
import 'package:safelight/main.dart';

/// HTTP 요청에 인증 토큰을 추가하고, 만료된 토큰을 갱신하는 인터셉터입니다.
///
/// 이 인터셉터는 Dio의 요청 전/후에 호출되어, 인증 관련 로직(토큰 추가, 갱신 및 로그아웃 처리)을 수행합니다.
class AuthInterceptor extends Interceptor {
  /// Dio 인스턴스
  final Dio dio;

  /// [AuthInterceptor] 생성자
  AuthInterceptor(this.dio);

  /// 요청을 가로채어 액세스 토큰을 헤더에 추가합니다.
  ///
  /// `/auth/refresh` 경로의 요청은 토큰 갱신 로직에서 제외합니다.
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // `/auth/refresh` 요청은 토큰 추가 없이 그대로 진행합니다.
    if (options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    // 로컬에 저장된 인증 데이터를 불러와 액세스 토큰을 헤더에 추가합니다.
    final authService = DI<AuthService>();
    final authData = await authService.loadAuthData();
    final accessToken = authData['accessToken'];

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  /// 요청 중 오류가 발생한 경우, 토큰 갱신을 시도합니다.
  ///
  /// 만약 401 Unauthorized 오류가 발생하면, 저장된 리프레시 토큰을 이용해 액세스 토큰을 갱신하고
  /// 실패 시 로그아웃 처리를 진행합니다.
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // 401 오류가 발생한 경우, Refresh Token 요청을 시도합니다.
      try {
        final newTokens = await _refreshAccessToken();
        final newAccessToken = newTokens['accessToken'];

        // 기존 요청의 헤더에 새 액세스 토큰을 추가한 후 재요청합니다.
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';

        final cloneReq = await dio.request(
          options.path,
          options: Options(
            method: options.method,
            headers: options.headers,
          ),
          data: options.data,
          queryParameters: options.queryParameters,
        );

        return handler.resolve(cloneReq); // 재요청 성공 시, 응답 반환
      } catch (e) {
        // 토큰 갱신도 실패한 경우, 로그아웃 처리를 진행합니다.
        if (e is DioException && e.response?.statusCode == 401) {
          await _handleLogout();
        }
        return handler.reject(err);
      }
    }
    return handler.next(err); // 401 이외의 오류는 그대로 전달
  }

  /// 저장된 리프레시 토큰을 이용해 새로운 액세스 토큰과 리프레시 토큰을 받아옵니다.
  ///
  /// 토큰 갱신에 성공하면, 새 토큰을 로컬에 저장하고 반환합니다.
  /// 갱신에 실패할 경우 예외를 발생시킵니다.
  Future<Map<String, String>> _refreshAccessToken() async {
    // 로컬 저장소에서 리프레시 토큰을 불러옵니다.
    final authService = AuthService();
    final authData = await authService.loadAuthData();
    final refreshToken = authData['refreshToken'];

    if (refreshToken == null) {
      throw DioException(requestOptions: RequestOptions(path: 'No Refresh Token'));
    }

    try {
      debugPrint('Bearer refreshToken : $refreshToken');

      // 리프레시 토큰을 이용해 새로운 토큰을 요청합니다.
      final response = await dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
          sendTimeout: const Duration(seconds: 10), // 데이터 전송 타임아웃
          receiveTimeout: const Duration(seconds: 10), // 응답 수신 타임아웃
        ),
      );

      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      // 새 토큰을 로컬 저장소에 저장합니다.
      await authService.saveAuthData(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return {
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        debugPrint('Timeout occurred: $e');
        await _handleLogout(); // 타임아웃 발생 시 로그아웃 처리
      } else {
        debugPrint('DioException: $e');
      }
      rethrow;
    }
  }

  /// 토큰 갱신 실패나 만료 시 로그아웃 처리를 수행합니다.
  ///
  /// 로컬에 저장된 인증 데이터를 초기화하고, Firebase 인증에서 로그아웃한 후
  /// 로그인 화면으로 전환합니다.
  Future<void> _handleLogout() async {
    final authService = DI<AuthService>();

    // 로컬 인증 데이터 초기화
    await authService.clearAuthData();
    // Firebase 로그아웃 처리
    FirebaseAuth.instance.signOut();

    debugPrint('User has been logged out due to expired tokens');

    // 로그인 화면으로 전환
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SignInView(),
      ),
    );
  }
}