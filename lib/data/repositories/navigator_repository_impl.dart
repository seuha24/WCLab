part of repository;

/// 네비게이션(위치 기반 서비스)와 관련된 [NavigatorRepository]의 구현부이다.
class NavigatorRepositoryImpl implements NavigatorRepository {
  /// 현재 사용자 위치 확인을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  NavigateRemoteDataSource navDataSource;

  /// 네비게이션(위치 기반 서비스)를 위한 Repository를 생성한다.
  ///
  /// 아래와 같이 [NavigatorRepository] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// NavigatorRepository repository = NavigatorRepositoryImpl(datasource); // Create repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// NavigatorRepository repository = DI.get<NavigatorRepository>(); // Best Practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// repository.getCurrentLatLng();
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// NavigatorRepository repository = NavigatorRepositoryImpl(datasource); // Create repository.
  ///
  /// // Use DI.
  /// NavigatorRepository repository = DI.get<NavigatorRepository>(); // Best Practice.
  ///
  /// repository.getCurrentLatLng();
  /// ```
  NavigatorRepositoryImpl({required this.navDataSource});

  @override
  Future<Either<Failure, LatLng>> getCurrentPosition() async {
    try {
      final position = await navDataSource.getCurrentLatLng();
      return Right(position);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
