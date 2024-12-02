part of '../../framework/repository.dart';

/// 사용자 인증(Auth)과 관련된 Repository의 Interface이다.
///
/// 로그인/로그아웃 또는 그 외의 모든 인증과 관련된 Usecase의 요청을 처리한다.
///
/// 인증(Authentication)이란, 시스템을 사용하는 사용자의 상태를 확인하고 제어하는 모든 행위를 의미한다.
/// 로그인/로그아웃과 같이 사용자의 상태를 확인하거나 제어해야 하는 모든 요청이 인증(Auth)에 해당한다.
///
/// 해당 Interface의 구현부는 Data Layer의 [AuthRepositoryImpl]이다.
///
/// **Summary :**
///
///   - **DO**
///   사용자 인증(로그인/로그아웃)과 관련된 요청은 AuthRepository를 통해 처리해야 한다.
///   또한, 실제 구현부([AuthRepositoryImpl])는 Data Layer에 위치해야 한다.
///
///   {@template repository_part2}
///   - **PREFER**
///   외부 DI를 통해 객체를 생성하는 것을 권장한다.
///   {@endtemplate}
///
///     ```dart
///     AuthRepository repository = DI.get<AuthRepository>();
///     ```
///
/// {@macro usecase_part2}
abstract class AuthRepository {
  /// 익명 로그인 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [AuthRemoteDataSource.signInAnonymously]를 호출하여 익명 로그인을 시도한다.
  ///
  /// {@template repository_part1}
  /// [Either]로서 `<Left, Right>`의 형태로 반환되며,
  /// 경우에 따라 아래와 같이 결과가 반환된다.
  /// {@endtemplate}
  ///
  ///   - **`Left(ServerFailure())` :**
  ///   인터넷 연결 불안정 및 로그인 로직 수행 중 오류 발생
  ///
  ///   - **`Right(Void())` :**
  ///   익명 로그인 성공
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   익명 로그인 요청을 처리해야 한다면 signInAnonymously를 사용해야 한다.
  ///
  /// {@template repository_part3}
  /// **See also :**
  ///
  ///   - [Blog | Either란 무엇일까?](https://velog.io/@tygerhwang/Flutter-Dartz)에서
  ///     [Flutter : 함수형 프로그래밍 Dartz](https://pub.dev/packages/dartz)에 대한 자세한 설명을 확인할 수 있다.
  /// {@endtemplate}
  Future<Either<Failure, Void>> signInAnonymously();
  Future<Either<Failure, Void>> signInWithGoogle();

  /// 익명 로그아웃 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [AuthRemoteDataSource.signOutAnonymously]를 호출하여 익명 로그아웃을 시도한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   익명 로그아웃 성공
  ///
  ///   - **`Left(ServerFailure())` :**
  ///   인터넷 연결 불안정 및 로그아웃 로직 수행 중 오류 발생
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   익명 로그아웃 요청을 처리해야 한다면 signOutAnonymously를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> signOutAnonymously();
  Future<Either<Failure, Void>> signOutWithGoogle();

  /// 구글 또는 애플 로그인 이후 획득한 OAuth Access Token을 서버로 전송하기 위한 메서드
  /// OAuth Access Token으로 서버에서 각 구글 또는 애플 서버로 인증 검사를 수행한다.
  /// 수행이 정상적으로 종료되면 response로 앱에서 사용가능한 Access Token 을 획득한다.
  Future<Either<Failure, AuthDataModel>> sendGoogleOAuthTokenToServer(String token);
  Future<Either<Failure, AuthDataModel>> sendAppleOAuthTokenToServer(String token);
}
