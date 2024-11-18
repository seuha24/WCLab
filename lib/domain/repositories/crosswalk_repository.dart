part of repository;

/// 횡단보도 제어와 관련된 Repository의 Interface이다.
///
/// 블루투스를 활용한 횡단보도의 검색 및 연결, 또는 그 외의 모든 횡단보도와 관련된 Usecase의 요청을 처리한다.
/// `수동/자동 스캔`, `유도/압버튼 누르기 신호 전송`과 같은 요청을 처리한다.
/// 블루투스를 활용하지 않더라도 횡단보도와 관련된 Usecase의 요청은 CrossalkRepository를 통해 처리되어야 한다.
///
/// 해당 Interface의 구현부는 Data Layer의 [CrosswalkRepositoryImpl]이다.
///
/// **Summary :**
///
///   {@macro repository_part2}
///
///     ```dart
///     CrosswalkRepository repository = DI.get<CrosswalkRepository>();
///     ```
///
///   - **DO**
///   횡단보도 제어(검색/전송)와 관련된 요청은 CrosswalkRepository를 통해 처리해야 한다.
///   또한, 실제 구현부([CrosswalkRepositoryImpl])는 Data Layer에 위치해야 한다.
///
///   - **CONSIDER**
///   추가적인 서비스 확장 시, 횡단보도와 관련된 주요 요청을 CrosswalkRepository를 통해 처리할 것인지 적절히 판단해야 한다.
///
/// {@macro usecase_part2}
abstract class CrosswalkRepository {
  /// 수동 스캔 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [BlueNativeDataSource.scan]를 호출하여
  /// 제한된 시간(1초) 동안 Bluetooth 스캔을 통해 주변 스마트 압버튼의 비콘 포스트를 찾는다.
  /// 이후, [NavigateRemoteDataSource.getCurrentLatLng]을 호출하여 사용자의 위치 좌표를 확인하고
  /// [CrosswalkRemoteDataSource.getCrosswalks]를 통해 Firestore에 등록된 횡단보도 정보를 매칭하여
  /// 검색된 횡단보도 정보를 반환한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(List<Crosswalk>)` :**
  ///   횡단보도 검색 성공, 검색된 결과([Crosswalk])를 [List]형태로 반환
  ///
  ///   - **`Left(BlueFailure())` :**
  ///   블루투스 스캔 실패로 인한 횡단보도 검색 실패
  ///
  ///   - **`Left(ServerFailure())` :**
  ///   Firestore를 통한 횡단보도 정보 요청 실패 및 사용자 현재 위치 파악 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   수동 스캔 요청을 처리해야 한다면 getCrosswalkFiniteTimes를 사용해야 한다.
  ///
  ///   - **DON'T**
  ///   사용자 권한 설정이 선행되어 있지 않으면 getCrosswalkFiniteTimes를 사용할 수 없다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, List<Crosswalk>>> getCrosswalkFiniteTimes();

  /// 자동 스캔 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [BlueNativeDataSource.scan]를 호출하여
  /// 제한된 시간(1초) 동안 Bluetooth 스캔을 통해 주변 스마트 압버튼의 비콘 포스트를 찾는다.
  /// 이후, 검색된 모든 비콘 포스트에 [BlueNativeDataSource.send]를 통해 연결 후 유도 커맨드를 전송한다.
  ///
  /// 지속적으로 스캔-연결-전송을 수행하고 싶다면(즉, 자동 스캔), getCrosswalkInfiniteTimes 메소드를 주기적으로 호출해야 한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(null)` :**
  ///   횡단보도 자동 스캔-연결 성공
  ///
  ///   - **`Left(BlueFailure())` :**
  ///   블루투스 스캔-연결 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   익명 로그아웃 요청을 처리해야 한다면 signOutAnonymously를 사용해야 한다.
  ///   또한, 지속적인 스캔-연결(즉, 자동스캔)을 구현하기 위해서는 signOutAnonymously를 주기적으로 호출해주어야 한다.
  ///
  ///   - **DON'T**
  ///   사용자 권한 설정이 선행되어 있지 않으면 getCrosswalkInfiniteTimes를 사용할 수 없다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, List<Crosswalk>?>> getCrosswalkInfiniteTimes();

  /// 횡단보도 연결(데이터 송신) 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [BlueNativeDataSource.send]를 통해
  /// [crosswalk]에 연결 후 [command]를 전송한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   횡단보도 연결 성공
  ///
  ///   - **`Left(BlueFailure())` :**
  ///   블루투스 연결 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   횡단보도 연결 요청을 처리해야 한다면 sendCommand2Crosswalk를 사용해야 한다.
  ///   이때, 연결하고자 하는 횡단보도([crosswalk])와 전송하고자 하는 커맨드([command])를
  ///   Argument로 넘겨야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> sendCommand2Crosswalk(
    Crosswalk crosswalk,
    List<int> command,
  );
}
