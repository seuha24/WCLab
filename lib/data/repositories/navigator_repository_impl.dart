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

  /// 출발지(건물 및 출입구 정보) 등록 요청
  @override
  Future<Either<Failure, void>> sendCustomStartPointParams(
      SendPointParams params) async {
    try {
      // Model을 사용하여 데이터 변환
      final model = SendStartPointModel(params);
      final json = model.toJson();

      // DataSource 호출
      await navDataSource.sendCustomStartPoint(
        roadAddress: json['roadAddress'] as String,
        buildingName: json['buildingName'] as String,
        buildingDetail: json['buildingDetail'] as String,
        buildingPoint: json['buildingPoint'] as Map<String, double>,
        entrances: json['entrances'] as List<Map<String, dynamic>>,
      );

      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  /// 특정 주소, 위도, 경도로 입구 목록을 서버에서 요청  
  @override
  Future<Either<Failure, BuildingResponse>> getBuildingEntrances({
    required String encodedAddr,
    required double longitude,
    required double latitude,
  }) async {
    try {
      final response = await navDataSource.getBuildingEntrances(
        encodedAddr: encodedAddr,
        longitude: longitude,
        latitude: latitude,
      );

      return Right(response.toEntity());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}