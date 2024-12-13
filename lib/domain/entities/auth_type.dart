enum AuthType {
  google,
  apple,
  anonymous,
}

extension AuthTypeExtension on AuthType {
  static String getLabel(AuthType type) {
    switch (type) {
      case AuthType.google:
        return 'google';
      case AuthType.apple:
        return 'apple';
      case AuthType.anonymous:
        return 'anonymous';
      default:
        return 'anonymous';
    }
  }

  static AuthType getType(String? type) {
    switch (type) {
      case 'google':
        return AuthType.google;
      case 'apple':
        return AuthType.apple;
      case 'anonymous':
        return AuthType.anonymous;
      default:
        return AuthType.anonymous;
    }
  }
}