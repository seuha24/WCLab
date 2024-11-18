part of usecase;

/// 디바이스의 권한 설정과 관련된 모든 비즈니스 로직의 상위 개념이다.
///
/// 디바이스 내 기능(블루투스, 위치 등)을 사용하기 위한 권한 설정 및 확인은 PermissionUseCase의 하위 객체(Usecase)를 통해 정의되어야 한다.
/// 블루투스 권한 요청/확인 또는 그 외의 권한 관련된 비즈니스 로직은 PermissionUseCase의 자식 형태로 상속(Extends)되어야 하며,
/// PermissionUseCase는 모든 권한 설정 시스템의 상위 클래스(Super class)로서 위치해야 한다.
///
/// 디바이스의 센서를 사용하고 싶은 경우, 또는 사용자의 허가가 필요한 기능을 수행해야 하는 경우 권한 요청 창을 통해 허가를 받아야 한다.
/// 대표적으로 블루투스 센서 사용, 카메라 접근, 사용자 위치 접근과 같은 기능들이 사용자에 의해 권한 허가 후 사용할 수 있는 기능들이다.
///
/// **Summary :**
///
/// {@macro usecase_warning1}
///
///     ```dart
///     PermissionUseCase usecase = SubUsecase(); // Do not use this.
///     ```
///
///   - **DO**
///   구현이 필요한 Interface가 디바이스 권한과 관련되어 있다면, PermissionUseCase를 상속(Extends) 받아야 한다.
///   또한, 각 권한은 OS에 맞는 환경 설정이 되어 있어야 한다.
///   ios의 경우 `ios/Runner/Info.plist`, aos의 경우 `android/app/src/main/AndroidManifest.xml`에 각 권한에 맞는 설정을 해주어야 한다.
///
///
/// **See also :**
///
///   - 현재 CrosswalkUseCase를 상속받은 Interface는 권한 부여 상태 확인[GetPermission], 권한 설정[SetPermission]이 있다.
///   - [Flutter Permission Handler - OS 권한 설정](https://pub.dev/packages/permission_handler)을 통해 각 OS 별 권한 설정 방법에 대해 확인할 수 있다.
abstract class PermissionUseCase {}

/// 권한 부여 상태를 확인하는 Usecase 로직들의 Interface이다.
///
/// 현재 부여된 권한 상태 확인과 관련된 [UseCase]는 GetPermission을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// {@macro usecase_part1}
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
/// - **DO**
///   구현이 필요한 클래스([UseCase])가 권한 부여 상태 확인과 관련되어 있다면, GetPermission을 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
abstract class GetPermission extends PermissionUseCase
    implements UseCase<bool, NoParams> {}

/// 권한 설정과 관련된 Usecase 로직들의 Interface이다.
///
/// 각 OS 별 권한 부여 창을 띄워 사용자로부터 권한을 부여받는 로직과 관련된 [UseCase]는 SetPermission을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// {@macro usecase_part1}
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
/// - **DO**
///   구현이 필요한 클래스([UseCase])가 권한 설정과 관련되어 있다면, SetPermission을 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
abstract class SetPermission extends PermissionUseCase
    implements UseCase<Void, NoParams> {}

/// 앱 내 블루투스 권한 부여 상태를 확인하는 비즈니스 로직이다.
///
/// GetBluetoothPermission는 블루투스 권한 부여 상태 확인에 사용된다.
/// 해당 로직은 현재 사용자로부터 부여된 블루투스 권한 부여 상태를 [bool]로 반환한다.
///
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [PermissionRepository.getBluetoothPermission]를 호출하여
/// 현재 부여된 블루투스 권한 상태를 확인한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[bool] :**
///   권한 확인 성공, `true` 일 경우 권한 부여가 정상적으로 된 상태 / `false` 인 경우 권한 부여가 거절된 상태
///
///   - **[CacheFailure] :**
///   블루투스 권한 확인 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   앱 내 블루투스 권한 부여 상태를 확인하고 싶다면 GetBluetoothPermission을 사용해야 한다.
class GetBluetoothPermission implements GetPermission {
  /// 블루투스 권한 상태 확인을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [PermissionRepository.getBluetoothPermission]를 사용되며 현재 블루투스 권한 부여 상태를 확인한다.
  ///
  /// {@macro usecase_part2}
  PermissionRepository repository;

  /// 앱 내 블루투스 권한 부여 상태 확인 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// GetBluetoothPermission getBluetoothPermission = GetBluetoothPermission(repository);
  /// ```
  ///
  /// 단, [GetPermission]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use GetPermission Type.
  /// GetPermission getBluetoothPermission = GetBluetoothPermission(repository);
  ///
  /// // Use DI.
  /// GetPermission getBluetoothPermission = DI.get<GetPermission>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// getBluetoothPermission(NoParams()); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// GetBluetoothPermission getBluetoothPermission = GetBluetoothPermission(repository); // Do not use this.
  /// GetPermission getBluetoothPermission = GetBluetoothPermission(repository);
  /// GetPermission getBluetoothPermission = DI.get<GetPermission>(); // Best Practice.
  ///
  /// getBluetoothPermission(NoParams()); // Use call method.
  /// ```
  GetBluetoothPermission({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.getBluetoothPermission();
  }
}

/// 앱 내 사용자 위치 권한 부여 상태를 확인하는 비즈니스 로직이다.
///
/// GetLocationPermission은 사용자 위치 권한 부여 상태 확인에 사용된다.
/// 해당 로직은 현재 사용자로부터 부여된 위치 권한 부여 상태를 [bool]로 반환한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [PermissionRepository.getLocationPermission]를 호출하여
/// 현재 부여된 사용자 위치 권한 상태를 확인한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[bool] :**
///   권한 확인 성공, `true` 일 경우 권한 부여가 정상적으로 된 상태 / `false` 인 경우 권한 부여가 거절된 상태
///
///   - **[CacheFailure] :**
///   사용자 위치 권한 확인 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   앱 내 사용자 위치 권한 부여 상태를 확인하고 싶다면 GetLocationPermission을 사용해야 한다.
class GetLocationPermission implements GetPermission {
  /// 사용자 위치 권한 상태 확인을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [PermissionRepository.getLocationPermission]를 사용되며 현재 사용자 위치 권한 부여 상태를 확인한다.
  ///
  /// {@macro usecase_part2}
  PermissionRepository repository;

  /// 앱 내 사용자 위치 권한 부여 상태 확인 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// GetLocationPermission getLocationPermission = GetLocationPermission(repository);
  /// ```
  ///
  /// 단, [GetPermission]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use GetPermission Type.
  /// GetPermission getLocationPermission = GetLocationPermission(repository);
  ///
  /// // Use DI.
  /// GetPermission getLocationPermission = DI.get<GetPermission>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// getLocationPermission(NoParams()); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// GetLocationPermission getLocationPermission = GetLocationPermission(repository); // Do not use this.
  /// GetPermission getLocationPermission = GetLocationPermission(repository);
  /// GetPermission getLocationPermission = DI.get<GetPermission>(); // Best Practice.
  ///
  /// getLocationPermission(NoParams()); // Use call method.
  /// ```
  GetLocationPermission({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.getLocationPermission();
  }
}

/// 앱 내 블루투스 권한 설정을 하는 비즈니스 로직이다.
///
/// SetBluetoothPermission은 블루투스 권한을 설정할 때 사용된다.
/// 해당 로직은 각 OS 별 블루투스 권한 창을 출력하여 사용자로부터 블루투스 권한 설정을 유도한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [PermissionRepository.setBluetoothPermission]를 호출하여 블루투스 권한 설정을 유도한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[Void] :**
///   블루투스 권한 설정 성공, 권한 설정 창이 출력됨
///
///   - **[CacheFailure] :**
///   블루투스 권한 설정 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   앱 내 블루투스 권한 설정을 하고 싶다면 SetBluetoothPermission을 사용해야 한다.
class SetBluetoothPermission implements SetPermission {
  /// 블루투스 권한 설정을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [PermissionRepository.setBluetoothPermission]를 사용되며 블루투스 권한 설정을 확인한다.
  ///
  /// {@macro usecase_part2}
  PermissionRepository repository;

  /// 앱 내 블루투스 권한 설정 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SetBluetoothPermission setBluetoothPermission = SetBluetoothPermission(repository);
  /// ```
  ///
  /// 단, [SetPermission]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SetPermission Type.
  /// SetPermission setBluetoothPermission = SetBluetoothPermission(repository);
  ///
  /// // Use DI.
  /// SetPermission setBluetoothPermission = DI.get<SetPermission>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// setBluetoothPermission(NoParams()); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// SetBluetoothPermission setBluetoothPermission = SetBluetoothPermission(repository); // Do not use this.
  /// SetPermission setBluetoothPermission = SetBluetoothPermission(repository);
  /// SetPermission setBluetoothPermission = DI.get<SetPermission>(); // Best Practice.
  ///
  /// setBluetoothPermission(NoParams()); // Use call method.
  /// ```
  SetBluetoothPermission({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.setBluetoothPermission();
  }
}

/// 앱 내 사용자 위치 권한 설정을 하는 비즈니스 로직이다.
///
/// SetLocationPermission은 사용자 위치 권한을 설정할 때 사용된다.
/// 해당 로직은 각 OS 별 사용자 위치 권한 창을 출력하여 사용자로부터 위치 권한 설정을 유도한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [PermissionRepository.setLocationPermission]를 호출하여 사용자 위치 권한 설정을 유도한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[Void] :**
///   사용자 위치 권한 설정 성공, 권한 설정 창이 출력됨
///
///   - **[CacheFailure] :**
///   사용자 위치 권한 설정 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   앱 내 사용자 위치 권한 설정을 하고 싶다면 SetLocationPermission을 사용해야 한다.
class SetLocationPermission implements SetPermission {
  /// 사용자 위치 권한 설정을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [PermissionRepository.setLocationPermission]를 사용되며 사용자 위치 권한 설정을 확인한다.
  ///
  /// {@macro usecase_part2}
  PermissionRepository repository;

  /// 앱 내 사용자 위치 권한 설정 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SetLocationPermission setLocationPermission = SetLocationPermission(repository);
  /// ```
  ///
  /// 단, [SetPermission]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SetPermission Type.
  /// SetPermission setLocationPermission = SetLocationPermission(repository);
  ///
  /// // Use DI.
  /// SetPermission setLocationPermission = DI.get<SetPermission>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// setLocationPermission(NoParams()); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// SetLocationPermission setLocationPermission = SetLocationPermission(repository); // Do not use this.
  /// SetPermission setLocationPermission = SetLocationPermission(repository);
  /// SetPermission setLocationPermission = DI.get<SetPermission>(); // Best Practice.
  ///
  /// setLocationPermission(NoParams()); // Use call method.
  /// ```
  SetLocationPermission({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.setLocationPermission();
  }
}

class SetCameraPermission implements SetPermission {
  PermissionRepository repository;
  SetCameraPermission({required this.repository});

  @override
  Future<Either<Failure, Void>> call(NoParams params) async {
    return await repository.setLocationPermission();
  }
}
