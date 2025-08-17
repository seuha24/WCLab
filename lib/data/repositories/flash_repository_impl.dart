part of '../../framework/repository.dart';

/// 안전 경광등과 관련된 [FlashRepository]의 구현부이다.
class FlashRepositoryImpl implements FlashRepository {
  /// 안전 경광등 제어(켜기/끄기)을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  FlashNativeDataSource flashDataSource;

  /// 현재 날씨 상태 요청을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  WeatherRemoteDataSource weatherDataSource;

  /// 현재 사용자 위치 확인을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  NavigateRemoteDataSource navDataSource;

  /// 조도
  AmbientLightLevelDataSource allevelDataSource;

  /// 안전 경광등을 켜야 하는 날씨인지를 판단하기 위한 Validator를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  WeatherValidator validator;

  /// 안전 경광등 제어를 위한 Repository를 생성한다.
  ///
  /// 아래와 같이 [FlashRepository] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// FlashRepository repository = FlashRepositoryImpl(datasource, validator); // Create repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// FlashRepository repository = DI.get<FlashRepository>(); // Best practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// repository.turnOn();
  /// repository.turnOnWithWeather();
  /// repository.turnOff();
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// FlashRepository repository = FlashRepositoryImpl(datasource, validator); // Create repository.
  ///
  /// // Use DI.
  /// FlashRepository repository = DI.get<FlashRepository>(); // Best Practice.
  ///
  /// repository.turnOn();
  /// repository.turnOnWithWeather();
  /// repository.turnOff();
  /// ```
  FlashRepositoryImpl({
    required this.flashDataSource,
    required this.navDataSource,
    required this.weatherDataSource,
    required this.allevelDataSource,
    required this.validator,
  });

  @override
  Future<Either<Failure, Void>> turnOn() async {
    try {
      await flashDataSource.on(infinite: true);
      return Right(Void());
    } on FlashException {
      return Left(FlashFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> turnOnWithWeather() async {
    try {
      final position = await navDataSource.getCurrentLatLng();
      final weather = await weatherDataSource.getCurrentWeather(position);
      // print("flashrepo");
      final AmbientLightLevelModel ambientLightLevel =
          await allevelDataSource.getCurrentAmbientLightLevel();
      // print("repo ${ambientLightLevel.ambientLightLevel}");
      // print("repo2 ${ambientLightLevel}");
      final enable = validator.checkFlashEnabled(weather, ambientLightLevel);

      enable.fold(
        (failure) {
          throw ValidateFailure();
        },
        (enable) async {
          if (enable) {
            await flashDataSource.on();
          }
        },
      );
      return Right(Void());
    } on FlashException {
      return Left(FlashFailure());
    } on ValidateFailure {
      return Left(ValidateFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> turnOff() async {
    try {
      await flashDataSource.off();
      return Right(Void());
    } on FlashException {
      return Left(FlashFailure());
    }
  }
}
