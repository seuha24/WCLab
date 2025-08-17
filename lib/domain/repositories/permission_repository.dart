part of '../../framework/repository.dart';

/// 사용자 권한 제어과 관련된 Repository의 Interface이다.
///
/// 사용자 권한 확인/설정과 관련된 Usecase의 요청을 처리한다.
/// `사용자 위치 권한 설정`, `블루투스 권한 설정`과 같은 요청을 처리한다.
///
/// 해당 Interface의 구현부는 Data Layer의 [PermissionRepositoryImpl]이다.
///
/// **Summary :**
///
///   {@macro repository_part2}
///
///     ```dart
///     PermissionRepository repository = DI.get<PermissionRepository>();
///     ```
///
///   - **DO**
///   사용자 권한 제어와 관련된 요청은 PermissionRepository를 통해 처리해야 하고,
///   실제 구현부([PermissionRepositoryImpl])는 Data Layer에 위치해야 한다.
///   또한, 각 권한은 OS에 맞는 환경 설정이 되어 있어야 한다.
///   ios의 경우 `ios/Runner/Info.plist`, aos의 경우 `android/app/src/main/AndroidManifest.xml`에 각 권한에 맞는 설정을 해주어야 한다.
///
/// {@macro usecase_part2}
///
///   - [Flutter Permission Handler - OS 권한 설정](https://pub.dev/packages/permission_handler)을 통해
///     각 OS 별 권한 설정 방법에 대해 확인할 수 있다.
abstract class PermissionRepository {
  /// 블루투스 권한 상태 확인 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [PermissionNativeDataSource.getBluetoothPermissionStatus]를 호출하여
  /// 현재 블루투스 권한 상태를 확인한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(bool)` :**
  ///   블루투스 권한 부여 상태 확인 성공, `true : 권한 부여됨` `false : 권한 부여 안됨`
  ///
  ///   - **`Left(CacheFailure())` :**
  ///   블루투스 권한 부여 상태 확인 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   블루투스 권한 확인 요청을 처리해야 한다면 getBluetoothPermission를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, bool>> getBluetoothPermission();

  /// 사용자 위치 권한 상태 확인 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [PermissionNativeDataSource.getLocationPermissionStatus]를 호출하여
  /// 현재 사용자 위치 권한 상태를 확인한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(bool)` :**
  ///   사용자 위치 권한 부여 상태 확인 성공, `true : 권한 부여됨` `false : 권한 부여 안됨`
  ///
  ///   - **`Left(CacheFailure())` :**
  ///   사용자 위치 권한 부여 상태 확인 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   사용자 위치 권한 확인 요청을 처리해야 한다면 getLocationPermission를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, bool>> getLocationPermission();

  /// 블루투스 권한 설정 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [PermissionNativeDataSource.setBluetoothPermission]를 호출하여
  /// 각 OS 별 블루투스 권한 창을 출력하여 사용자로부터 블루투스 권한 설정을 유도한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   블루투스 권한 요청 성공, `요청 창을 띄울 수 있는 경우 > 요청 창 출력`, `요청 창을 띄울 수 없는 경우 > 설정 앱 전환`
  ///
  ///   - **`Left(CacheFailure())` :**
  ///   블루투스 권한 요청 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   블루투스 권한 설정 요청을 처리해야 한다면 setBluetoothPermission를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> setBluetoothPermission();

  /// 사용자 위치 권한 설정 요청을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [PermissionNativeDataSource.setLocationPermission]를 호출하여
  /// 각 OS 별 사용자 위치 권한 창을 출력하여 사용자로부터 사용자 위치 권한 설정을 유도한다.
  ///
  /// {@macro repository_part1}
  ///
  ///   - **`Right(Void())` :**
  ///   사용자 위치 권한 요청 성공, `요청 창을 띄울 수 있는 경우 > 요청 창 출력`, `요청 창을 띄울 수 없는 경우 > 설정 앱 전환`
  ///
  ///   - **`Left(CacheFailure())` :**
  ///   사용자 위치 권한 요청 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   사용자 위치 권한 설정 요청을 처리해야 한다면 setLocationPermission를 사용해야 한다.
  ///
  /// {@macro repository_part3}
  Future<Either<Failure, Void>> setLocationPermission();
  Future<Either<Failure, Void>> setCameraPermission();
}
