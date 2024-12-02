import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userNameKey = 'userName';

  /// 인증 데이터 저장
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    } else {
      await prefs.remove(_userNameKey);
    }
  }

  /// 인증 데이터 로드
  Future<Map<String, String?>> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': prefs.getString(_accessTokenKey),
      'refreshToken': prefs.getString(_refreshTokenKey),
      'userName': prefs.getString(_userNameKey),
    };
  }

  /// 인증 데이터 삭제
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userNameKey);
  }
}