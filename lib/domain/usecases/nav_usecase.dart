part of usecase;

/// 네비게이션(위치)과 완련된 모든 비즈니스 로직의 상위 개념이다.
///
/// 일반적인 네비게이션 뿐만 아니라 앱 내 위치와 관련된 기능은 NavUseCase의 하위 객체(Usecase)로 위치해야 한다.
/// 현재 사용자 위치 확인 또는 그 외의 모든 네비게이션과 관련된 비즈니스 로직은 NavUseCase의 자식 형태로 상속(Extends)되어야 하며
/// NavUseCase는 모든 네비게이션 시스템의 상위 클래스(Super class)로서 위치해야 한다.
///
/// **Summary :**
///
///   - **DO**
///   구현이 필요한 Interface가 네비게이션(위치 기반 서비스)과 관련되어 있다면, NavUseCase를 상속(Extends) 받아야 한다.
///
/// {@macro usecase_warning1}
///
///     ```dart
///     NavUseCase usecase = SubUsecase(); // Do not use this.
///     ```
///
/// **See also :**
///
///   - 현재 NavUseCase를 상속받은 Interface는 위치 반환([GetPosition])이 있다.
abstract class NavUseCase {}

/// 모든 위치 반환 Usecase 로직들의 Interface이다.
///
/// 특정 위치 반환과 관련된 [UseCase]는 GetPosition을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// {@macro usecase_part1}
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
///   - **DO**
///   구현이 필요한 클래스([UseCase])가 특정 위치 반환과 관련되어 있다면, GetPosition을 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
abstract class GetPosition extends NavUseCase
    implements UseCase<LatLng, NoParams> {}

/// 현재 사용자 위치를 반환하는 비즈니스 로직이다.
///
/// GetCurrentPosition은 현재 사용자의 위치(위도, 경도)를 알아야 하는 경우 사용된다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [NavigatorRepository.getCurrentPosition]를 호출하여 현재 사용자의 위치 반환을 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[LatLng] :**
///   현재 위치 확인 성공, 사용자의 현재 위치(위도, 경도)를 반환
///
///   - **[ServerFailure] :**
///   사용자 현재 위치 파악 실패
///
/// **Summary :**
///
/// {@macro usecase_part3}
///
///   - **DO**
///   현재 사용자의 위치를 알아야 한다면, GetCurrentPosition를 사용해야 한다.
///
///   - **DON'T**
///   GetCurrentPosition 사용 시, `사용자 위치 정보 제공 허가`, `인터넷 연결`이 선행되지 않으면 사용할 수 없다.
class GetCurrentPosition implements GetPosition {
  /// 사용자 위치 확인을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  NavigatorRepository repository;

  /// 현재 사용자 위치 반환 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// GetCurrentPosition getCurrentPosition = GetCurrentPosition(repository);
  /// ```
  ///
  /// 단, [NavUseCase]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use NavUseCase Type.
  /// NavUseCase getCurrentPosition = GetCurrentPosition(repository);
  ///
  /// // Use DI.
  /// NavUseCase getCurrentPosition = DI.get<NavUseCase>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// getCurrentPosition(NoParams()); // Use call method.
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// GetCurrentPosition getCurrentPosition = GetCurrentPosition(repository); // Do not use this.
  /// NavUseCase getCurrentPosition = GetCurrentPosition(repository);
  /// NavUseCase getCurrentPosition = DI.get<NavUseCase>(); // Best Practice.
  ///
  /// getCurrentPosition(NoParams()); // Use call method.
  /// ```
  GetCurrentPosition({required this.repository});

  @override
  Future<Either<Failure, LatLng>> call(NoParams params) async {
    return await repository.getCurrentPosition();
  }
}
