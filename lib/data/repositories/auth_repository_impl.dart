part of repository;

/// 사용자 인증(Auth)과 관련된 [AuthRepository]의 구현부이다.
class AuthRepositoryImpl implements AuthRepository {
  /// 사용자 인증 제어(Auth)를 위한 DataSource를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// {@macro usecase_part2}
  AuthRemoteDataSource authDataSource;

  /// 사용자 인증(Auth) 제어를 위한 Repository를 생성한다.
  ///
  /// 아래와 같이 [AuthRepository] 타입으로 객체를 생성해야 한다.
  ///
  /// ```dart
  /// AuthRepository repository = AuthRepositoryImpl(datasource); // Create Repository.
  /// ```
  ///
  /// 또한 외부에서 의존성을 주입하여 객체를 생성하는 것을 권장한다.
  ///
  /// ```dart
  /// // Use DI.
  /// AuthRepository repository = DI.get<AuthRepository>(); // Best Practice.
  /// ```
  ///
  /// 객체의 생성이 끝난 다음 아래와 같이 메소드를 호출한다.
  ///
  /// ```dart
  /// repository.signInAnonymously();
  /// repository.signOutAnonymously();
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// AuthRepository repository = AuthRepositoryImpl(datasource); // Create Repository.
  ///
  /// // Use DI.
  /// AuthRepository repository = DI.get<AuthRepository>(); // Best Practice.
  ///
  /// repository.signInAnonymously();
  /// repository.signOutAnonymously();
  /// ```
  AuthRepositoryImpl({required this.authDataSource});

  @override
  Future<Either<Failure, Void>> signInAnonymously() async {
    try {
      await authDataSource.signInAnonymously();
      return Right(Void());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> signOutAnonymously() async {
    try {
      await authDataSource.signOutAnonymously();
      return Right(Void());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> signInWithGoogle() async {
    try {
      await authDataSource.signInWithGoogle();
      return Right(Void());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Void>> signOutWithGoogle() async {
    try {
      await authDataSource.signOutWithGoogle();
      return Right(Void());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
