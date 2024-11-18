part of usecase;

/// 핵심 기능을 제외한 앱 내 모든 추가 기능(편의 기능)에 대한 비즈니스 로직의 상위 개념이다.
///
/// 앱 내 추가 기능과 관련된 비즈니스 로직은 ServiceUseCase의 자식 형태로 상속(Extends)되어야 하며
/// ServiceUseCase는 모든 인증(Auth) 시스템의 상위 클래스(Super class)로서 위치해야 한다.
///
/// 추가 기능이란, 시스템의 메인이 되는 기능을 제외한 서비스를 의미한다.
/// 로그인/로그아웃([AuthUseCase]), 네비게이션([NavUseCase])과 같이 독립적인 기능으로 구분된 비즈니스 로직은 ServiceUseCase에 속하지 않는다.
/// 제공하는 서비스가 시스템의 핵심 기능(또는 핵심 기능에 준하는 규모)이라 판단된다면 추가적인 [UseCase]로 분리하여야 한다.
/// 만약 추가적인 Usecase 분리가 필요하지 않는 서비스라면 ServiceUseCase에 위치하여야 한다.
///
/// **Summary :**
///
/// {@macro usecase_warning1}
///
///     ```dart
///     ServiceUseCase usecase = SubUsecase(); // Do not use this.
///     ```
///
///   - **CONSIDER**
///   ServiceUseCase는 메인 기능과 기타 서비스의 구분을 위해 존재하며, 이는 추후 개발 시 필요에 따라 변경할 수 있다.
///   제공하려는 서비스의 규모에 따라 서비스의 확장 시 ServiceUseCase를 상속받는 구조로 추가할 수 있다.
///
///
/// **See also :**
///
///   - 현재 ServiceUseCase를 상속받은 Interface는 안전 경광등 제어([ControlFlash])가 있다.
abstract class ServiceUseCase {}

/// 모든 안전 경광등 Usecase 로직들의 Interface이다.
///
/// 안전 경광등과 관련된 [UseCase]는 ControlFlash를 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// 안전 경광등이란 디바이스의 카메라 후래쉬를 켜고 끔으로서 사용자의 위치를 운전자에게 알려주는 기능을 의미한다.
///
/// {@macro usecase_part1}
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
///   - **DO**
///   구현이 필요한 클래스([UseCase])가 안전 경광등과 관련되어 있다면, ControlFlash를 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
abstract class ControlFlash extends ServiceUseCase
    implements UseCase<Void, NoParams> {}

/// 안전 경광등 끄기 비즈니스 로직이다.
///
/// ControlFlashOff는 안전 경광등을 꺼야하는 경우 사용된다. 카메라의 후래쉬를 끔으로서 안전 경광등을 종료한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [FlashRepository.turnOff]를 호출하여 안전 경광등 끄기를 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[Void] :**
///   안전 경광등 끄기 성공, 카메라 후래쉬가 꺼짐
///
///   - **[FlashFailure] :**
///   안전 경광등 끄기 실패
///
/// **Summary :**
///
/// {@macro usecase_part3}
///
///   - **DO**
///   안전 경광등을 꺼야 한다면, ControlFlashOff를 사용해야 한다.
class ControlFlashOff implements ControlFlash {
  /// 안전 경광등 끄기를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [FlashRepository.turnOff]를 사용되며 안전 경광등 끄기를 시도하게 된다.
  ///
  /// {@macro usecase_part2}
  final FlashRepository repository;

  /// 안전 경광등 끄기 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// ControlFlashOff controlFlashOff = ControlFlashOff(repository);
  /// ```
  ///
  /// 단, [ControlFlash]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use ControlFlash Type.
  /// ControlFlash controlFlashOff = ControlFlashOff(repository);
  ///
  /// // Use DI.
  /// ControlFlash controlFlashOff = DI.get<ControlFlash>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// controlFlashOff(NoParams()); // Use call method.
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// ControlFlashOff controlFlashOff = ControlFlashOff(repository); // Do not use this.
  /// ControlFlash controlFlashOff = ControlFlashOff(repository);
  /// ControlFlash controlFlashOff = DI.get<ControlFlash>(); // Best Practice.
  ///
  /// controlFlashOff(NoParams()); // Use call method.
  /// ```
  ControlFlashOff({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.turnOff();
  }
}

/// 날씨에 따른 안전 경광등 켜기 비즈니스 로직이다.
///
/// ControlFlashOnWithWeather는 사용자의 위치를 기반으로 현재 날씨에 따라 안전 경광등을 켜야하는 경우 사용된다.
/// 사용자의 위치를 기반으로 Open Weather API를 호출하여 날씨 정보를 받는다.
/// 날씨 정보를 기반으로 운전자의 시야가 확보되지 않는 상황이라 판단된다면 카메라 후래쉬를 켜 안전 경광등 기능을 수행한다.
/// 따라서, 사용자의 위치 권한 허가 및 인터넷 연결이 되어 있어야 정상적으로 동작하게 된다.
///
/// 안전 경광등이 켜지게 되면 주기적으로 ON-OFF 를 반복하여 카메라 후래쉬가 깜빡이게 된다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [FlashRepository.turnOnWithWeather]를 호출하여 날씨에 따른 안전경광등 켜기를 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[Void] :**
///   날씨에 따른 안전 경광등 켜기 성공, 카메라 후래쉬가 켜짐
///
///   - **[ValidateFailure] :**
///   현재 날씨 상태가 안전 경광등을 켜지 않아도 되는 상태, 안전 경광등이 켜지지 않음
///
///   - **[FlashFailure] :**
///   안전 경광등 켜기 실패
///
///   - **[ServerFailure] :**
///   날씨 정보 요청 및 사용자 위치 정보 확인 불가로 인한 안전 경광등 켜기 실패
///
/// **Summary :**
///
/// {@macro usecase_part3}
///
///   - **DO**
///   날씨에 따라 안전 경광등을 꺼야 한다면, ControlFlashOnWithWeather를 사용해야 한다.
///
///   - **DON'T**
///   `사용자 위치 권한 허가`가 선행되어 있지 않다면 ControlFlashOnWithWeather를 사용할 수 없다. 또한 인터넷 연결이 되어 있어야 한다.
///
/// **See also :**
///
///   - [Open Weather API](https://openweathermap.org/api)를 사용하여 날씨 정보를 요청한다.
///   - [SetLocationPermission]을 사용하여 사용자 위치 권한 설정을 할 수 있다.
class ControlFlashOnWithWeather implements ControlFlash {
  /// 날씨에 따른 안전 경광등 켜기를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [FlashRepository.turnOnWithWeather]를 사용되며 날씨에 따른 안전 경광등 켜기를 시도하게 된다.
  ///
  /// {@macro usecase_part2}
  final FlashRepository repository;

  /// 날씨에 따른 안전 경광등 켜기 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// ControlFlashOnWithWeather controlFlashOnWithWeather = ControlFlashOnWithWeather(repository);
  /// ```
  ///
  /// 단, [ControlFlash]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use ControlFlash Type.
  /// ControlFlash controlFlashOnWithWeather = ControlFlashOnWithWeather(repository);
  ///
  /// // Use DI.
  /// ControlFlash controlFlashOnWithWeather = DI.get<ControlFlash>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// controlFlashOnWithWeather(NoParams()); // Use call method.
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// ControlFlashOnWithWeather controlFlashOnWithWeather = ControlFlashOnWithWeather(repository); // Do not use this.
  /// ControlFlash controlFlashOnWithWeather = ControlFlashOnWithWeather(repository);
  /// ControlFlash controlFlashOnWithWeather = DI.get<ControlFlash>(); // Best Practice.
  ///
  /// controlFlashOnWithWeather(NoParams()); // Use call method.
  /// ```
  ControlFlashOnWithWeather({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.turnOnWithWeather();
  }
}

/// 안전 경광등 켜기 비즈니스 로직이다.
///
/// ControlFlashOn는 안전 경광등을 켜야하는 경우 사용된다.
/// 안전 경광등이 켜지게 되면 주기적으로 ON-OFF 를 반복하여 카메라 후래쉬가 깜빡이게 된다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [FlashRepository.turnOn]를 호출하여 날씨에 따른 안전경광등 켜기를 시도한다.
/// 해당 메소드를 수행하면 아래와 같은 경우에 따라 결과가 반환된다.
///
///   - **[Void] :**
///   안전 경광등 켜기 성공, 카메라 후래쉬가 켜짐
///
///   - **[FlashFailure] :**
///   안전 경광등 켜기 실패
///
/// **Summary :**
///
/// {@macro usecase_part3}
///
///   - **DO**
///   안전 경광등을 꺼야 한다면, ControlFlashOn을 사용해야 한다.
class ControlFlashOn implements ControlFlash {
  /// 안전 경광등 켜기를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [FlashRepository.turnOn]를 사용되며 안전 경광등 켜기를 시도하게 된다.
  ///
  /// {@macro usecase_part2}
  final FlashRepository repository;

  /// 안전 경광등 켜기 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// ControlFlashOn controlFlashOn = ControlFlashOn(repository);
  /// ```
  ///
  /// 단, [ControlFlash]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use ControlFlash Type.
  /// ControlFlash controlFlashOn = ControlFlashOn(repository);
  ///
  /// // Use DI.
  /// ControlFlash controlFlashOn = DI.get<ControlFlash>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// controlFlashOn(NoParams()); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// ControlFlashOn controlFlashOn = ControlFlashOn(repository); // Do not use this.
  /// ControlFlash controlFlashOn = ControlFlashOn(repository);
  /// ControlFlash controlFlashOn = DI.get<ControlFlash>(); // Best Practice.
  ///
  /// controlFlashOn(NoParams()); // Use call method.
  /// ```
  ControlFlashOn({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.turnOn();
  }
}
