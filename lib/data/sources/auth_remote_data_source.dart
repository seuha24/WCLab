part of '../../framework/data_source.dart';

/// Auth 데이터 처리를 위한 Interface이다.
///
/// 사용자 인증(Authentication)과 관련된 직접적인 처리를 수행한다.
/// [FirebaseAuth]에 로그인, 로그아웃과 같은 시스템 내 사용자의 권한을 정보를 요청한다.
///
/// [Firebase SDK 설치](https://firebase.google.com/docs/flutter/setup?hl=ko&platform=ios)가 선행되어야 하며,
/// [FirebaseAuth의 초기 설정](https://firebase.google.com/docs/auth/flutter/start?hl=ko#add_firebase_authentication_to_your_app)이 되어 있어야 한다.
///
/// 해당 Interface의 구현부는 [AuthRemoteDataSourceImpl]이다.
///
/// **Summary :**
///
///   - **DO**
///   [FirebaseAuth]를 활용하여 사용자 인증(로그인/로그아웃)과 관련된 로직을 수행한다.
///
///   {@template data_part1}
///   - **PREFER**
///   외부 DI를 통해 객체를 생성하는 것을 권장한다.
///   {@endtemplate}
///
///     ```dart
///     AuthRemoteDataSource datasource = DI.get<AuthRemoteDataSource>();
///     ```
///
///   - **DON'T**
///   Firebased SDK 설정과 [FirebaseAuth] 설정이 선행되지 않으면 사용할 수 없다.
///
/// {@macro usecase_part2}
///
///   - Auth 처리를 위한 패키지로 [Firebase](https://firebase.google.com/docs/flutter/setup?hl=ko&platform=ios)를 사용하였다.
abstract class AuthRemoteDataSource {
  /// 익명 로그인을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FirebaseAuth.signInAnonymously]를 호출하여 익명 로그인을 요청한다.
  /// 익명 로그인 사용을 위한 FirebaseAuth의 초기 설정](https://firebase.google.com/docs/auth/flutter/anonymous-auth?hl=ko#before_you_begin)이 필요하다.
  ///
  /// 익명 로그인에 성공할 경우 FirebaseAuth Console에 해당 익명 계정이 등록된다.
  /// 이후 별다른 호출이 없더라도 [signOutAnonymously]를 호출하기 전까지 자동 로그인이 수행되게 된다.
  ///
  /// 익명 로그인 수행에 따른 예외는 아래와 같이 처리된다.
  ///
  ///   - **[ServerException] :**
  ///   익명 로그인 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   [FirebaseAuth]를 통한 익명 로그인을 수행한다.
  ///
  ///   - **DON'T**
  ///   익명 로그인 사용을 위한 [FirebaseAuth] 초기 설정 없이 사용할 수 없다.
  ///
  /// **See also :**
  ///
  ///   - Google이 제안하는 익명 로그인 예시가 궁금하다면,
  ///     [FirebaseAuth를 통한 익명 로그인 Best practice](https://firebase.google.com/docs/auth/flutter/anonymous-auth?hl=ko#authenticate_with_firebase_anonymously_2)에서 확인할 수 있다.
  Future<void> signInAnonymously();

  /// 익명 로그아웃을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FirebaseAuth.signOut]를 호출하여 익명 로그아웃을 요청한다.
  /// [FirebaseAuth의 초기 설정](https://firebase.google.com/docs/auth/flutter/anonymous-auth?hl=ko#before_you_begin)이 필요하다.
  ///
  /// 로그아웃이 수행되게 되면 [signInAnonymously]을 수행하기 전까지 로그아웃 상태로 앱이 실행되게 된다.
  ///
  /// 익명 로그아웃 수행에 따른 예외는 아래와 같이 처리된다.
  ///
  ///   - **[ServerException] :**
  ///   익명 로그아웃 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   [FirebaseAuth]를 통한 익명 로그아웃을 수행한다.
  ///
  ///   - **DON'T**
  ///   [FirebaseAuth] 초기 설정 없이 사용할 수 없다.
  ///
  /// **See also :**
  ///
  ///   - Google이 제안하는 로그아웃에 대한 예시가 궁금하다면,
  ///     [FirebaseAuth를 통한 로그아웃 Best practice](https://firebase.google.com/docs/auth/flutter/anonymous-auth?hl=ko#next_steps)를 확인할 수 있다.
  Future<void> signOutAnonymously();

  Future<void> signInWithGoogle();
  Future<void> signOutWithGoogle();

  Future<Response<Map<String, dynamic>>> sendGoogleOAuthTokenToServer(String token);
  Future<Response<Map<String, dynamic>>> sendAppleOAuthTokenToServer(String token);
}

/// Auth 데이터 처리를 위한 [AuthRemoteDataSource]의 구현부이다.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// 사용자 인증 제어(Auth)를 위한 FirebaseAuth 객체를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  FirebaseAuth auth;
  final Dio dio;

  /// 사용자 인증(Auth)을 위한 Datasource를 생성한다.
  ///
  /// 아래와 같이 [AuthRemoteDataSource] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// AuthRemoteDataSource datasource = AuthRemoteDataSourceImpl(auth); // Create Repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// AuthRemoteDataSource repository = DI.get<AuthRemoteDataSource>(); // Best Practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 다음 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// datasource.signInAnonymously();
  /// datasource.signOutAnonymously();
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// AuthRemoteDataSource datasource = AuthRemoteDataSourceImpl(auth); // Create Repository.
  ///
  /// // Use DI.
  /// AuthRemoteDataSource repository = DI.get<AuthRemoteDataSource>(); // Best Practice.
  ///
  /// datasource.signInAnonymously();
  /// datasource.signOutAnonymously();
  /// ```
  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.dio,
  });

  @override
  Future<void> signInAnonymously() async {
    try {
      await auth.signInAnonymously();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> signOutAnonymously() async {
    try {
      await auth.currentUser?.delete();
      await auth.signOut();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  // if (googleUser == null) {}
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await auth.signInWithCredential(credential);
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> signOutWithGoogle() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw ServerException();
    }
  }


  @override
  Future<Response<Map<String, dynamic>>> sendGoogleOAuthTokenToServer(String token) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'https://backend.catholicuniv.pillowstudio.kr/auth/google/token',
        data: {
          'token': token,
        },
      );

      return response;
    } catch (e) {
      throw ServerException(); // 실패 시 예외 처리
    }
  }

  @override
  Future<Response<Map<String, dynamic>>> sendAppleOAuthTokenToServer(String token) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'https://backend.catholicuniv.pillowstudio.kr/auth/apple/login',
        data: {
          'token': token,
        },
      );

      return response;
    } catch (e) {
      throw ServerException(); // 실패 시 예외 처리
    }
  }
}
