part of repository;

/// 사용자 권한 제어와 관련된 [PermissionRepository]의 구현부이다.
class PermissionRepositoryImpl implements PermissionRepository {
  /// 사용자 권한 제어를 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  PermissionNativeDataSource permissionDataSource;

  /// 사용자 권한 제어를 위한 Repository를 생성한다.
  ///
  /// 아래와 같이 [PermissionRepository] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// PermissionRepository repository = PermissionRepositoryImpl(datasource); // Create repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// PermissionRepository repository = DI.get<PermissionRepository>(); // Best practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// repository.getBluetoothPermissionStatus();
  /// repository.getLocationPermissionStatus();
  /// repository.setBluetoothPermission();
  /// repository.setLocationPermission();
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  ///
  /// ```dart
  /// PermissionRepository repository = PermissionRepositoryImpl(datasource); // Create repository.
  ///
  /// // Use DI.
  /// PermissionRepository repository = DI.get<PermissionRepository>(); // Best Practice.
  ///
  /// repository.getBluetoothPermissionStatus();
  /// repository.getLocationPermissionStatus();
  /// repository.setBluetoothPermission();
  /// repository.setLocationPermission();
  /// ```
  PermissionRepositoryImpl({required this.permissionDataSource});

  @override
  Future<Either<Failure, bool>> getBluetoothPermission() async {
    try {
      final status = await permissionDataSource.getBluetoothPermissionStatus();
      return Right(status);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> getLocationPermission() async {
    try {
      final status = await permissionDataSource.getLocationPermissionStatus();
      return Right(status);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> setBluetoothPermission() async {
    try {
      await permissionDataSource.setBluetoothPermission();
      return Right(Void());
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> setLocationPermission() async {
    try {
      await permissionDataSource.setLocationPermission();
      return Right(Void());
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> setCameraPermission() async {
    try {
      await permissionDataSource.setCameraPermission();
      return Right(Void());
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
