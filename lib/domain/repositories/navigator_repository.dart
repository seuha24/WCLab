part of repository;

/// 네비게이션(위치 기반 기능)과 관련된 Repository의 Interface이다.
///
/// 네비게이션, 또는 그 외의 모든 위치 기반 기능과 관련된 Usecase의 요청을 처리한다.
/// `사용자 위치 좌표 확인`과 같은 요청을 처리한다.
///
/// 해당 Interface의 구현부는 Data Layer의 [NavigatorRepositoryImpl]이다.
///
/// **Summary :**
///
///   {@macro repository_part2}
///
///     ```dart
///     NavigatorRepository repository = DI.get<NavigatorRepository>();
///     ```
///
///   - **DO**
///   네비게이션(위치 기반 서비스)와 관련된 요청은 NavigatorRepository를 통해 처리해야 한다.
///   또한, 실제 구현부([NavigatorRepositoryImpl])는 Data Layer에 위치해야 한다.
///
///   - **CONSIDER**
///   추가적인 서비스 확장 시, 위치와 관련된 주요 요청을 NavigatorRepository를 통해 처리할 것인지 적절히 판단해야 한다.
///
/// {@macro usecase_part2}
abstract class NavigatorRepository {
  /// 사용자 위치 좌표 확인 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [NavigateRemoteDataSource.getCurrentLatLng]를 호출하여 현재 사용자의 위치를 확인한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(LatLng(latitude, longitude))` :**
  ///   사용자 위치 확인 성공, 사용자의 위치(위도, 경도)를 [LatLng]을 통해 반환
  ///
  ///   - **`Left(FlashFailure())` :**
  ///   사용자 위치 확인 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   사용자 위치 확인 요청을 처리해야 한다면 getCurrentPosition를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, LatLng>> getCurrentPosition();
}
