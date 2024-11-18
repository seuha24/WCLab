part of usecase;

/// 사용자의 인증(Auth)을 제어하는 모든 비즈니스 로직의 상위 개념이다.
///
/// 시스템을 사용하는 사용자는 AuthUsecase의 하위 객체(Usecase)를 통해 인증받을 수 있다.
/// 로그인/로그아웃 또는 그 외의 모든 인증과 관련된 비즈니스 로직은 AuthUseCase의 자식 형태로 상속(Extends)되어야 하며
/// AuthUseCase는 모든 인증(Auth) 시스템의 상위 클래스(Super class)로서 위치해야 한다.
///
/// 세이프라이트에서 인증(Authentication)이란, 시스템을 사용하는 사용자의 상태를 확인하고 제어하는 모든 행위를 의미한다.
/// 로그인/로그아웃과 같이 사용자의 상태를 확인하거나 제어해야하는 모든 로직이 인증(Auth)에 해당한다.
///
/// **Summary :**
///
///   - **DO**
///   구현이 필요한 Interface가 사용자의 인증(Auth)과 관련되어 있다면, AuthUseCase를 상속(Extends) 받아야 한다.
///
/// {@template usecase_warning1}
///   - **DON'T**
///   해당 객체는 데이터 타입으로 직접 사용되어서는 안된다.
///   하위 Interface의 부모 클래스(Super class)로서 이러한 Interface가
///   상위 개념과 관련되어 있다는 것을 알려주는 역할만을 수행한다.
/// {@endtemplate}
///
///     ```dart
///     AuthUsecase usecase = SubUsecase(); // Do not use this.
///     ```
///
/// **See also :**
///
///   - 현재 AuthUsecase를 상속받은 Interface는 로그인([SignIn]), 로그아웃([SignOut])이 있다.
///   - `version 1.*` 에서는 모든 사용자 인증은 `FirebaseAuth`를 사용하고 있다.
abstract class AuthUseCase {}

/// 모든 로그인 Usecase 로직들의 Interface이다.
///
/// 사용자 로그인과 관련된 [UseCase]는 SignIn을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// [call] 메소드의 Argument로 `Map<String, dynamic>?`를 사용하여 사용자 정보를 담아야한다.
/// 단, 사용자 정보가 필요하지 않는 경우 `null`을 사용한다.
///
///   - 사용자 정보를 사용하는 경우
///     ```dart
///     // Use this if you have a user info.
///     Map<String, dynamic> user = {
///       'name' : '홍길동',
///       'id' : xxx@email.com,
///       'pw' : q1w2e3r4!,
///       //some user info...
///     };
///     SomeSignInUsecase(user); // Use call method.
///     ```
///
///   - 사용자 정보를 사용하지 않는 경우
///     ```dart
///     // Use this if you don't hava a user info.
///     SomeSignInUsecase(null); // Use call method.
///     ```
///
/// **Summary :**
///
///   - **DO**
///   구현이 필요한 클래스([UseCase])가 사용자의 로그인과 관련되어 있다면, SignIn을 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
///
/// {@template usecase_warning2}
///   - **PREFER**
///   해당 Interface는 하위 클래스([UseCase]) 사용 시, 데이터 타입으로 사용할 것을 권장한다.
///     ```dart
///     ThisInterface foo = SomeImplClass(); // Use this.
///     SomeImplClass foo = SomeImplClass(); // Do not use this.
///     ```
/// {@endtemplate}
///
///   - **DON’T**
///   SignIn을 구현한 하위 클래스는 사용자가 로그인 상태일 때 사용되어서는 안된다.
///   즉, 사용자가 로그아웃 상태일 경우에만 사용해야 한다.
///
/// **See also :**
///
///   - 사용자를 로그아웃 상태로 만들고 싶다면, [SignOut] Interface의 하위 클래스를 사용한다.
abstract class SignIn extends AuthUseCase
    implements UseCase<Void, Map<String, dynamic>?> {}

/// 모든 로그아웃 Usecase 로직들의 Interface이다.
///
/// 사용자 로그아웃과 관련된 [UseCase]는 SignOut을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// {@template usecase_part1}
/// [call] 메소드의 Argument로 [NoParams]를 사용한다.
///
/// ```dart
/// final usecase = SomeUsecaseImpl();
/// usecase(NoParams()); // Use call method.
/// ```
/// {@endtemplate}
///
/// **Summary :**
///
///   - **DO**
///   구현이 필요한 클래스([UseCase])가 사용자의 로그아웃과 관련되어 있다면, SignOut을 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
///
/// {@macro usecase_warning2}
///
///   - **DON’T**
///   SignOut을 구현한 하위 클래스는 사용자가 로그아웃 상태일 때 사용되어서는 안된다.
///   즉, 사용자가 로그인 상태일 경우에만 사용해야 한다.
///
/// **See also :**
///
///   - 사용자를 로그인 상태로 만들고 싶다면, [SignIn] Interface의 하위 클래스를 사용한다.
abstract class SignOut extends AuthUseCase implements UseCase<Void, NoParams> {}

/// 익명 로그인을 수행하는 비즈니스 로직이다.
///
/// SignInAnonymously는 사용자가 익명으로 로그인하는 경우 사용된다. 익명 로그인은 사용자의 정보를 받지 않고 로그인하는 기능을 의미한다.
/// 익명 로그인의 경우 사용자 정보가 필요하지 않으므로, [call]의 `user` Parameter에 `null`을 Argument로 넘겨야 한다.
///
/// ```dart
/// SignIn signIn = SignInAnonymously(); // Create usecase object.
/// signIn(null); // Use call method.
/// ```
///
/// [call] 메소드를 통해 [AuthRepository.signInAnonymously]를 호출하여 익명 로그인을 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[ServerFailure] :**
///   인터넷 연결 불안정 및 로그인 로직 수행 중 오류 발생
///
///   - **[Void] :**
///   익명 로그인 성공
///
/// **Summary :**
///
///   - **DO**
///   사용자 정보없이 로그인해야 한다면, SignInAnonymously를 사용해야 한다.
///   SignInAnonymously는 Safelight에서 Default로 사용된다.
///
/// {@template usecase_part3}
///   - **PREFER**
///   외부 DI를 통해 객체를 생성하는 것을 권장한다.
///   또한, 생성된 객체는 되도록 상위 Interface를 데이터 타입으로 가지도록 해야 한다.
/// {@endtemplate}
///
/// **See also :**
///
///   - SignInAnonymously는 [SignIn]에 속하기 때문에 사용자가 로그아웃된 상태에서만 사용되어야 한다.
///     (자세한 사항은 `SignIn > Summary`을 참고)
///   - 현재 익명 로그인은 UI에서 `로그인 없이 이용하기` 버튼을 누를 경우 동작되게 된다.
class SignInAnonymously implements SignIn {
  /// 익명 로그인을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [AuthRepository.signInAnonymously]를 사용되며 익명 로그인을 시도하게 된다.
  ///
  /// {@template usecase_part2}
  /// **See also :**
  ///
  ///  - DI에 대한 자세한 설명은 `injection.dart` 파일에서 확인할 수 있다.
  /// {@endtemplate}
  AuthRepository repository;

  /// 익명 로그인 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SignInAnonymously signInAnonymously = SignInAnonymously(repository);
  /// ```
  ///
  /// 단, [SignIn]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SignIn Type
  /// SignIn signInAnonymously = SignInAnonymously(repository);
  /// ```
  ///
  /// ```dart
  /// // Use DI
  /// SignIn signInAnonymously = DI.get<SignIn>(); // Best Practice.
  /// ```
  ///
  /// **Example :**
  /// ```dart
  /// SignInAnonymously signInAnonymously = SignInAnonymously(repository); // Do not use this.
  /// SignIn signInAnonymously = SignInAnonymously(repository);
  /// SignIn signInAnonymously = DI.get<SignIn>(); // Best Practice.
  /// signInAnonymously(null); // Use call method.
  /// ```
  SignInAnonymously({required this.repository});

  @override
  Future<Either<Failure, Void>> call(Map<String, dynamic>? user) async {
    return await repository.signInAnonymously();
  }
}

/// 익명 로그인 상태 사용자의 로그아웃을 수행하는 비즈니스 로직이다.
///
/// SignOutAnonymously는 익명 로그인([SignInAnonymously])된 사용자가 로그아웃하는 경우 사용된다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [AuthRepository.signOutAnonymously]를 호출하여 익명 로그아웃을 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[Void] :**
///   익명 로그아웃 성공
///
///   - **[ServerFailure] :**
///   인터넷 연결 불안정 및 로그아웃 로직 수행 중 오류 발생
///
/// **Summary :**
///
/// {@macro usecase_part3}
///
///   - **DO**
///   익명 로그인된 사용자가 로그아웃을 해야 한다면, SignOutAnonymously를 사용해야 한다.
///
/// **See also :**
///
///   - SignOutAnonymously는 [SignOut]에 속하기 때문에 사용자가 익명 로그인된 상태에서만 사용되어야 한다.
///     (자세한 사항은 `SignOut > Summary`을 참고)
///   - 현재 익명 로그아웃은 설정 화면 UI에서 `사용자 정보` 버튼을 누를 경우 동작되게 된다.
class SignOutAnonymously implements SignOut {
  /// 익명 로그아웃을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [AuthRepository.signOutAnonymously]를 사용되며 익명 로그아웃을 시도하게 된다.
  ///
  /// {@macro usecase_part2}
  AuthRepository repository;

  /// 익명 로그아웃 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SignOutAnonymously signOutAnonymously = SignOutAnonymously(repository);
  /// ```
  ///
  /// 단, [SignOut]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SignOut Type
  /// SignOut signOutAnonymously = SignOutAnonymously(repository);
  /// ```
  ///
  /// ```dart
  /// // Use DI
  /// SignOut signOutAnonymously = DI.get<SignOut>(); // Best Practice.
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// SignOutAnonymously signOutAnonymously = SignOutAnonymously(repository); // Do not use this.
  /// SignOut signOutAnonymously = SignOutAnonymously(repository);
  /// SignOut signOutAnonymously = DI.get<SignOut>(); // Best Practice.
  /// signInAnonymously(NoParams()); // Use call method.
  /// ```
  SignOutAnonymously({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.signOutAnonymously();
  }
}

class SignInWithGoogle implements SignIn {
  AuthRepository repository;
  SignInWithGoogle({required this.repository});

  @override
  Future<Either<Failure, Void>> call(Map<String, dynamic>? user) async {
    return await repository.signInWithGoogle();
  }
}

class SignOutWithGoogle implements SignOut {
  AuthRepository repository;
  SignOutWithGoogle({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.signOutWithGoogle();
  }
}
