import 'package:safelight/domain/entities/auth.dart';

class AuthDataModel extends Auth {
  AuthDataModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthDataModel.fromMap(Map<String, dynamic> map) {
    return AuthDataModel(
      accessToken: map['accessToken'],
      refreshToken: map['refreshToken'],
    );
  }
}
