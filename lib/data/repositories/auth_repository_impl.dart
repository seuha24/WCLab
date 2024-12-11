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
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Response<Map<String, AuthDataModel>>> signInWithGoogle() async {
    try {
      return await authDataSource.signInWithGoogle();
    } catch (e) {
      throw Exception('Failed to process sign-in');
    }
  }

  @override
  Future<Response<Map<String, AuthDataModel>>> signInWithApple() async {
    try {
      return await authDataSource.signInWithApple();
    } catch (e) {
      throw Exception('Failed to process sign-in');
    }
  }

  @override
  Future<Either<Failure, Void>> signOutAnonymously() async {
    try {
      await authDataSource.signOutAnonymously();
      return Right(Void());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Void>> signOutWithGoogle() async {
    try {
      await authDataSource.signOutWithGoogle();
      return Right(Void());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Void>> signOutWithApple() async {
    try {
      await authDataSource.signOutWithApple();
      return Right(Void());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Void>> signOutAll() async {
    try {
      await authDataSource.signOutAll();
      return Right(Void());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, AuthDataModel>> sendGoogleOAuthTokenToServer(
      String token) async {
    try {
      final response = await authDataSource.sendGoogleOAuthTokenToServer(token);
      return _processAuthResponse(response);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, AuthDataModel>> sendAppleOAuthTokenToServer(
      String token) async {
    try {
      final response = await authDataSource.sendAppleOAuthTokenToServer(token);
      return _processAuthResponse(response);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Void>> patchUserInfo(String userName) async {
    try {
      final response = await authDataSource.patchUserInfo(userName);
      return _processVoidResponse(response);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserInfo() async {
    try {
      final response = await authDataSource.getUserInfo();
      return _processDataResponse(response);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  // Helper Methods

  Either<Failure, AuthDataModel> _processAuthResponse(
      Response<Map<String, dynamic>> response) {
    final responseData = response.data ?? {};
    if (responseData['success'] == true) {
      final authData = AuthDataModel.fromMap(responseData['data']);
      return Right(authData);
    } else {
      return Left(ServerFailure());
    }
  }

  Either<Failure, Void> _processVoidResponse(
      Response<Map<String, dynamic>> response) {
    final responseData = response.data ?? {};
    if (responseData['success'] == true) {
      return Right(Void());
    } else {
      return Left(ServerFailure());
    }
  }

  Either<Failure, Map<String, dynamic>> _processDataResponse(
      Response<Map<String, dynamic>> response) {
    final responseData = response.data ?? {};
    if (responseData['success'] == true) {
      return Right(responseData['data']);
    } else {
      return Left(ServerFailure());
    }
  }

  Failure _handleError(Object e) {
    debugPrint('Error: $e');
    return ServerFailure();
  }
}
