part of repository;

/// 안전 경광등과 관련된 Repository의 Interface이다.
///
/// 카메라 후래쉬를 이용한 안전 경광등 제어와 관련된 Usecase의 요청을 처리한다.
/// `안전 경광등 켜기/끄기`, `날씨에 따른 안전 경광등 켜기`와 같은 요청을 처리한다.
///
/// 해당 Interface의 구현부는 Data Layer의 [FlashRepositoryImpl]이다.
///
/// **Summary :**
///
///   {@macro repository_part2}
///
///     ```dart
///     FlashRepository repository = DI.get<FlashRepository>();
///     ```
///
///   - **DO**
///   안전 경광등 제어와 관련된 요청은 FlashRepository를 통해 처리해야 한다.
///   또한, 실제 구현부([FlashRepositoryImpl])는 Data Layer에 위치해야 한다.
///
///   - **DON'T**
///   안전 경광등이 켜진 이후 반드시 경광등을 꺼주어야 한다. 안전 경광등 끄기 없이 단순히 켜기만 해서는 안된다.
///
/// {@macro usecase_part2}
abstract class FlashRepository {
  /// 안전 경광등 켜기 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FlashNativeDataSource.on]를 호출하여 안전 경광등을 켜게 된다.
  /// 이때, `flashDataSource.on(infinite: true);`과 같이 Argument를 넘겨
  /// [turnOff]를 통해 종료되기 전까지 무한하게 켜지게 된다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   안전 경광등 켜기 성공
  ///
  ///   - **`Left(FlashFailure())` :**
  ///   안전 경광등 켜기 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   안전 경광등 켜기 요청을 처리해야 한다면 turnOn를 사용해야 한다.
  ///
  ///   - **DON'T**
  ///   단순히 turnOn만 사용하여 안전 경광등을 제어해서는 안된다.
  ///   반드시 사용 후 turnOff를 통해 안전 경광등을 종료해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> turnOn();

  /// 날씨에 따른 안전 경광등 켜기 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [NavigateRemoteDataSource.getCurrentLatLng]를 호출하여 현재 사용자의 위치를 확인한다.
  /// 이후, [WeatherRemoteDataSource.getCurrentWeather]를 통해 확인된 위치의 날씨 정보를 파악한다.
  /// [WeatherValidator.checkFlashEnabled]를 통해 확인된 날씨 정보가 경광등을 켜도 되는 상황인지 판단한다.
  /// 만약 경광등을 켜야 할 정도로 시야가 확보되지 않는다고 판단된다면
  /// [FlashNativeDataSource.on]을 호출하여 안전 경광등을 켜게 된다.
  ///
  /// 일정 시간이 지나면 안전 경광등이 꺼지게 되지만, [turnOff]를 통해 종료하는 것을 권장한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   날씨에 따른 안전 경광등 켜기 성공
  ///
  ///   - **`Left(FlashFailure())` :**
  ///   안전 경광등 켜기 실패
  ///
  ///   - **`Left(ValidateFailure())` :**
  ///   안전 경광등 켜지지 않음, 날씨 상태가 안전 경광등을 켜지 않아도 되는 상태
  ///
  ///   - **`Left(ServerFailure())` :**
  ///   안전 경광등 켜기 실패, 현재 사용자 위치 파악 불가
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   날씨에 따른 안전 경광등 켜기 요청을 처리해야 한다면 turnOnWithWeather를 사용해야 한다.
  ///
  ///   - **PREFER**
  ///   사용 후 turnOff를 통해 안전 경광등을 종료하는 것을 권장한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> turnOnWithWeather();

  /// 안전 경광등 끄기 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FlashNativeDataSource.off]를 호출하여 안전 경광등을 끄게 된다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   안전 경광등 끄기 성공
  ///
  ///   - **`Left(FlashFailure())` :**
  ///   안전 경광등 끄기 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   안전 경광등 끄기 요청을 처리해야 한다면 turnOff를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> turnOff();
}
