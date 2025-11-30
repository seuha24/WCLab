import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safelight/core/utils/status_enum.dart';
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/framework/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인증 데이터 관리 서비스를 제공하는 클래스입니다.
///
/// 이 클래스는 액세스 토큰, 리프레시 토큰, 사용자 이름 및 로그인 타입을
/// SharedPreferences를 이용하여 로컬에 저장, 로드, 삭제하는 기능을 제공합니다.
class AuthService {
  /// 액세스 토큰 저장을 위한 키 값입니다.
  static const String _accessTokenKey = 'accessToken';

  /// 리프레시 토큰 저장을 위한 키 값입니다.
  static const String _refreshTokenKey = 'refreshToken';

  /// 로그인 타입 저장을 위한 키 값입니다.
  static const String _authTypeTokenKey = 'authTypeToken';

  /// 사용자 이름 저장을 위한 키 값입니다.
  static const String _userNameKey = 'userName';

  /// 서버 사용자 ID 저장을 위한 키 값입니다.
  static const String _serverUserIdKey = 'serverUserId';

  /// 인증 데이터를 저장합니다.
  ///
  /// [accessToken]과 [refreshToken]은 필수로 저장되며,
  /// [userName]과 [serverUserId]는 선택적으로 저장됩니다.
  /// 만약 [userName]이나 [serverUserId]가 null인 경우, 저장된 값을 삭제합니다.
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    String? userName,
    String? serverUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    } else {
      await prefs.remove(_userNameKey);
    }

    if (serverUserId != null) {
      await prefs.setString(_serverUserIdKey, serverUserId);
    } else {
      await prefs.remove(_serverUserIdKey);
    }
  }

  /// 저장된 인증 데이터를 로드합니다.
  ///
  /// 반환되는 [Map]에는 'accessToken', 'refreshToken', 'userName', 'serverUserId' 키가 포함되며,
  /// 각 값은 저장된 문자열이나 값이 없을 경우 null입니다.
  Future<Map<String, String?>> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'accessToken': prefs.getString(_accessTokenKey),
      'refreshToken': prefs.getString(_refreshTokenKey),
      'userName': prefs.getString(_userNameKey),
      'serverUserId': prefs.getString(_serverUserIdKey),
    };
  }

  /// 저장된 모든 인증 데이터를 삭제합니다.
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 로그인 타입을 저장합니다.
  ///
  /// [authType]은 [AuthType] 열거형 값이며, 해당 타입의 라벨을 문자열로 변환하여 저장합니다.
  Future<void> saveAuthType({
    required AuthType authType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authString = AuthTypeExtension.getLabel(authType);
    await prefs.setString(_authTypeTokenKey, authString);
  }

  /// 저장된 로그인 타입을 로드합니다.
  ///
  /// 저장된 문자열을 [AuthType]으로 변환하여 반환합니다.
  Future<AuthType> loadAuthType() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthTypeExtension.getType(prefs.getString(_authTypeTokenKey));
  }

  /// 서버 사용자 ID를 저장합니다.
  Future<void> saveServerUserId(String serverUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUserIdKey, serverUserId);
  }

  /// 저장된 서버 사용자 ID를 로드합니다.
  Future<String?> loadServerUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUserIdKey);
  }

  /// 즐겨찾기 API 호출에 필요한 인증 정보를 가져옵니다.
  ///
  /// [user]: Firebase User 객체
  /// 반환: (loginMethod: 'google'|'apple', userId: 서버UUID) 또는 null
  Future<({String loginMethod, String userId})?> getFavoriteCredentials({
    required User user,
  }) async {
    // 1. authType 로드
    AuthType authType = await loadAuthType();

    // 2. anonymous면 Firebase provider로 판단하여 저장
    if (authType == AuthType.anonymous) {
      final providerData = user.providerData;
      if (providerData.isNotEmpty) {
        final providerId = providerData.first.providerId;
        if (providerId == 'google.com') {
          authType = AuthType.google;
          await saveAuthType(authType: AuthType.google);
        } else if (providerId == 'apple.com') {
          authType = AuthType.apple;
          await saveAuthType(authType: AuthType.apple);
        }
      }
    }

    final loginMethod = authType == AuthType.google ? 'google' : 'apple';

    // 3. 서버 UUID 가져오기
    final serverUserId = await loadServerUserId();
    if (serverUserId == null) {
      return null;
    }

    return (loginMethod: loginMethod, userId: serverUserId);
  }

  /// 서버 ID를 확보합니다. 없으면 AuthBloc을 통해 조회 후 반환합니다.
  ///
  /// [authBloc]: AuthBloc 인스턴스
  /// [timeout]: 최대 대기 시간 (기본 10초)
  /// 반환: 서버 UUID 또는 null (타임아웃/실패)
  Future<String?> ensureServerUserId({
    required AuthBloc authBloc,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 1. 먼저 로컬에서 확인
    String? serverUserId = await loadServerUserId();
    if (serverUserId != null) return serverUserId;

    // 2. 없으면 AuthBloc 호출
    authBloc.add(GetUserInfoEvent());

    // 3. 성공 상태 대기 (Future.delayed 대신)
    try {
      await authBloc.stream
          .firstWhere((state) =>
              state.getUserInfoStatus == Status.success ||
              state.getUserInfoStatus == Status.failure)
          .timeout(timeout);

      return await loadServerUserId();
    } catch (e) {
      return null;
    }
  }
}