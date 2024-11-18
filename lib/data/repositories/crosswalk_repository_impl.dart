part of repository;

/// 횡단보도 제어와 관련된 [CrosswalkRepository]의 구현부이다.
class CrosswalkRepositoryImpl implements CrosswalkRepository {
  /// 스마트 압버튼(비콘 포스트) 스캔/연결(데이터 송신)을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  BlueNativeDataSource blueDataSource;

  /// 사용자 위치 확인을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  NavigateRemoteDataSource navDataSource;

  /// DB(Firestore)에 횡단보도 정보 요청을 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  CrosswalkRemoteDataSource crosswalkDataSource;

  /// 횡단보도 제어를 위한 Repository를 생성한다.
  ///
  /// 아래와 같이 [CrosswalkRepository] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// CrosswalkRepository repository = CrosswalkRepositoryImpl(datasource); // Create Repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// CrosswalkRepository repository = DI.get<CrosswalkRepository>(); // Best Practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// repository.getCrosswalkFiniteTimes();
  /// repository.getCrosswalkInfiniteTimes();
  /// repository.sendCommand2Crosswalk(crosswalk, command);
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// CrosswalkRepository repository = CrosswalkRepositoryImpl(datasource); // Create Repository.
  ///
  /// // Use DI.
  /// CrosswalkRepository repository = DI.get<CrosswalkRepository>(); // Best Practice.
  ///
  /// repository.getCrosswalkFiniteTimes();
  /// repository.getCrosswalkInfiniteTimes();
  /// repository.sendCommand2Crosswalk(crosswalk, command);
  /// ```
  CrosswalkRepositoryImpl({
    required this.blueDataSource,
    required this.navDataSource,
    required this.crosswalkDataSource,
  });

  @override
  Future<Either<Failure, List<Crosswalk>>> getCrosswalkFiniteTimes() async {
    try {
      final blueResults = await blueDataSource.scan();
      final position = await navDataSource.getCurrentLatLng();
      final results = await crosswalkDataSource.getCrosswalks(
        blueResults,
        position,
      );

      return Right(results);
    } on BlueException {
      return Left(BlueFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Crosswalk>?>> getCrosswalkInfiniteTimes() async {
    try {
      final blueResults = await blueDataSource.scan();
      for (DiscoveredDevice result in blueResults) {
        await blueDataSource.send(result);
      }
    } on BlueException {
      return Left(BlueFailure());
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, Void>> sendCommand2Crosswalk(
    Crosswalk crosswalk,
    List<int> command,
  ) async {
    try {
      await blueDataSource.send(crosswalk.post, command: command);
      return Right(Void());
    } on BlueException {
      return Left(BlueFailure());
    }
  }
}
