import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/infrastructure/services/auth_service.dart';
import 'package:safelight/injection.dart';
import 'package:safelight/main.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Access Token 추가
    final authService = DI<AuthService>();
    final authData = await authService.loadAuthData();
    final accessToken = authData['accessToken'];

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Refresh Token 요청
      try {
        final newTokens = await _refreshAccessToken();
        final newAccessToken = newTokens['accessToken'];

        // 기존 요청에 새 토큰 추가 후 재요청
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

        return handler.resolve(cloneReq); // 원래 요청 성공 처리
      } catch (e) {
        // Refresh Token도 실패한 경우 로그아웃 처리
        if (e is DioException && e.response?.statusCode == 401) {
          await _handleLogout();
        }
        return handler.reject(err); // 실패 처리
      }
    }
    return handler.next(err); // 다른 에러 처리
  }

  Future<Map<String, String>> _refreshAccessToken() async {
    // Refresh Token 로직
    final authService = AuthService();
    final authData = await authService.loadAuthData();
    final refreshToken = authData['refreshToken'];

    dio.options.headers['Authorization'] = 'Bearer $refreshToken';


    if (refreshToken == null) {
      throw DioException(requestOptions: RequestOptions(path: 'No Refresh Token'));
    }

    try {
      final response = await dio.post(
        '/auth/refresh',
      );

      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      // 새 토큰 저장
      await authService.saveAuthData(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return {
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      };
    } catch (e) {
      throw DioException(requestOptions: RequestOptions(path: 'Refresh Token Expired'), error: e);
    }
  }

  /// 로그아웃
  Future<void> _handleLogout() async {
    final authService = DI<AuthService>();

    // Auth 데이터 초기화
    await authService.clearAuthData();
    // Firebase 로그아웃
    FirebaseAuth.instance.signOut();

    debugPrint('User has been logged out due to expired tokens');

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SignInView(),
      ),
    );
  }
}