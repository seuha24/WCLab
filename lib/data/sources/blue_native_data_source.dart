part of data_source;

/// 블루투스 통신을 위한 Interface이다.
///
/// 블루투스 통신과 관련된 직접적인 처리를 수행한다.
/// [FlutterReactiveBle]를 통해 블루투스 스캔([scan]), 연결 및 데이터 전송([send]), 연결 끊기([disconnect])를 수행한다.
///
/// FlutterReactiveBle를 사용하기 위해서는
/// 각 OS에 맞는 블루투스 권한 설정([aos](https://pub.dev/packages/flutter_reactive_ble#android),
/// [ios](https://pub.dev/packages/flutter_reactive_ble#ios))이 필요하다.
///
/// 스마트 IOT 음향 신호기에 관한 경찰청 제공 프로토콜(2021 개정판)을 기준으로 블루투스 통신을 수행한다.
///
/// 해당 Interface의 구현부는 [AuthRemoteDataSourceImpl]이다.
///
/// **Summary :**
///
///   - **DO**
///   [FlutterReactiveBle]를 통해 블루투스와 관련된 요청을 처리한다.
///   BLE 연결, 데이터 전송, 연결 끊기가 필요할 경우 사용한다.
///
///   {@macro data_part1}
///
///     ```dart
///     BlueNativeDataSource datasource = DI.get<BlueNativeDataSource>();
///     ```
///
///   - **DON'T**
///   각 OS에 맞는 블루투스 권한 설정이 선행되지 않으면 사용할 수 없다.
///
///   - **CONSIDER**
///   블루투스와 관련된 로직이 추가되어야 한다면 BlueNativeDataSource에 구현하는 것을 고려해야 한다.
///   데이터 읽기와 같은 로직이 추가될 수 있다.
///
///   - **RREFER**
///   스마트 IOT 음향신호기와 관련된 기능이 추가될 경우 경찰청 제공 프로토콜을 따르는 것을 권장한다.
///
/// {@macro usecase_part2}
///
///   - 블루투스와 관련된 3rd party에 대한 자세한 설명은 [FlutterReactiveBLE](https://pub.dev/packages/flutter_reactive_ble)에서 확인할 수 있다.
///   - 스마트 IOT와 관련된 프로토콜은 [시각장애인용 음향신호기 규격서](https://www.police.go.kr/component/file/ND_fileDownload.do?q_fileSn=154401&q_fileId=57f13a5b-e714-47e7-837b-75de9985faee)에서 확인할 수 있다.
abstract class BlueNativeDataSource {
  /// 블루투스 스캔을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FlutterReactiveBle.scanForDevices]를 [StreamSubscription]에 등록하여 블루투스 스캔을 수행한다.
  /// 이후, StreamSubscription에 등록된 시간만큼 스캔이 수행되게 된다.
  ///
  /// 스마트 음향 신호기는 [Bluetooth.SERVICE_UUID]를 UUID로 가진다. 따라서 해당 UUID를 가진 비콘 포스트만 스캔하도록 한다.
  ///
  /// ```dart
  /// bluetooth.scanForDevices(
  ///   withServices: [Uuid.parse(Bluetooth.SERVICE_UUID)], // Check UUID.
  /// )
  /// ```
  ///
  /// 스캔된 결과는 `listen`을 통하여 확인한다. 이때 중복된 포스트 정보가 있는지 확인하고, 중복된 값은 등록하지 않는다.
  /// 블루투스 스캔에서 중복된 값이란 동일 횡단보도에 부착된 비콘 포스트를 의미한다.
  /// 하나의 횡단보도에 2개 이상의 포스트가 스캔되기 때문에 동일한 횡단보도가 2개 이상 출력되게 된다.
  /// 이러한 문제를 방지하고자 동일한 횡단보도를 제어하는 포스트 정보가 2개 이상 스캔될 경우 하나만 List에 추가된다.
  ///
  /// ```dart
  /// List<DiscoveredDevice> results = []; // List of scanned beacon post results.
  ///
  /// final knownDeviceIndex = results.indexWhere((d) => d.id == device.id); // Returns the index if you are checking for the same value.
  /// if (knownDeviceIndex >= 0) {
  ///   results[knownDeviceIndex] = device; // If there are duplicate values, the index will overwrite the currently scanned results (same crosswalk).
  /// } else {
  ///   results.add(device); // If there are no duplicate values, add it to the List.
  /// }
  /// ```
  ///
  /// 이후 duration(1s) 만큼 딜레이를 주고, [StreamSubscription]의 등록을 취소(cancel)하여 블루투스 스캔을 종료한다.
  /// 스캔 종료 후 스캔 된 포스트를 [DiscoveredDevice] 객체로 담아 [List] 형태로 반환한다.
  ///
  /// ```dart
  /// await Future.delayed(duration); // 1 second delay.
  /// await subscription!.cancel(); // End Bluetooth Scan.
  /// return results; // Return scan results.
  /// ```
  ///
  /// 블루투스 스캔을 하기 위해서는
  /// 각 OS에 맞는 블루투스 권한 설정([aos](https://pub.dev/packages/flutter_reactive_ble#android),
  /// [ios](https://pub.dev/packages/flutter_reactive_ble#ios))이 필요하다.
  ///
  /// 블루투스 스캔 수행에 따른 예외는 아래와 같이 처리된다.
  ///
  ///   - **[BlueException] :**
  ///   블루투스 스캔 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   [FlutterReactiveBle.scanForDevices]를 통한 블루투스 스캔을 수행한다. 스캔 시 [StreamSubscription]를 사용하며
  ///   Stream 등록을 취소(cancel)하여 스캔을 종료한다. 스캔 종료 후 스캔 결과를 [List]형태로 반환한다.
  ///
  ///   - **DON'T**
  ///   각 OS에 맞는 블루투스 권한 설정이 선행되지 않으면 사용할 수 없다.
  ///
  /// **See also :**
  ///
  ///   - 블루투스와 관련된 3rd party에 대한 자세한 설명은 [FlutterReactiveBLE](https://pub.dev/packages/flutter_reactive_ble)에서 확인할 수 있다.
  ///   - UUID와 관련된 내용은 [시각장애인용 음향신호기 규격서](https://www.police.go.kr/component/file/ND_fileDownload.do?q_fileSn=154401&q_fileId=57f13a5b-e714-47e7-837b-75de9985faee)에서 확인할 수 있다.
  ///   - duration(1s) 만큼 딜레이는 (주)한길HC의 기술 자문을 통해 파악한 내용이다. 하드웨어가 데이터를 처리할 시간을 주기 위해 의도적으로 최소 1초의 딜레이를 부과한다.
  Future<List<DiscoveredDevice>> scan();

  /// 블루투스를 통한 데이터 송신을 처리하는 메소드이다.
  ///
  /// 해당 메소드를 수행하면 [FlutterReactiveBle.scanForDevices]를 [StreamSubscription]에 등록하여 블루투스 스캔을 수행한다.
  /// 이후, StreamSubscription에 등록된 시간만큼 스캔이 수행되게 된다.
  ///
  /// 스마트 음향 신호기는 [Bluetooth.SERVICE_UUID]를 UUID로 가진다. 따라서 해당 UUID를 가진 비콘 포스트만 스캔하도록 한다.
  ///
  /// ```dart
  /// bluetooth.scanForDevices(
  ///   withServices: [Uuid.parse(Bluetooth.SERVICE_UUID)], // Check UUID.
  /// )
  /// ```
  ///
  /// 스캔된 결과는 `listen`을 통하여 확인한다. 이때 중복된 포스트 정보가 있는지 확인하고, 중복된 값은 등록하지 않는다.
  /// 블루투스 스캔에서 중복된 값이란 동일 횡단보도에 부착된 비콘 포스트를 의미한다.
  /// 하나의 횡단보도에 2개 이상의 포스트가 스캔되기 때문에 동일한 횡단보도가 2개 이상 출력되게 된다.
  /// 이러한 문제를 방지하고자 동일한 횡단보도를 제어하는 포스트 정보가 2개 이상 스캔될 경우 하나만 List에 추가된다.
  ///
  /// ```dart
  /// List<DiscoveredDevice> results = []; // List of scanned beacon post results.
  ///
  /// final knownDeviceIndex = results.indexWhere((d) => d.id == device.id); // Returns the index if you are checking for the same value.
  /// if (knownDeviceIndex >= 0) {
  ///   results[knownDeviceIndex] = device; // If there are duplicate values, the index will overwrite the currently scanned results (same crosswalk).
  /// } else {
  ///   results.add(device); // If there are no duplicate values, add it to the List.
  /// }
  /// ```
  ///
  /// 이후 duration(1s) 만큼 딜레이를 주고, [StreamSubscription]의 등록을 취소(cancel)하여 블루투스 스캔을 종료한다.
  /// 스캔 종료 후 스캔 된 포스트를 [DiscoveredDevice] 객체로 담아 [List] 형태로 반환한다.
  ///
  /// ```dart
  /// await Future.delayed(duration); // 1 second delay.
  /// await subscription!.cancel(); // End Bluetooth Scan.
  /// return results; // Return scan results.
  /// ```
  ///
  /// 블루투스 스캔을 하기 위해서는
  /// 각 OS에 맞는 블루투스 권한 설정([aos](https://pub.dev/packages/flutter_reactive_ble#android),
  /// [ios](https://pub.dev/packages/flutter_reactive_ble#ios))이 필요하다.
  ///
  /// 블루투스 스캔 수행에 따른 예외는 아래와 같이 처리된다.
  ///
  ///   - **[BlueException] :**
  ///   블루투스 스캔 실패
  ///
  /// **Summary :**
  ///
  ///   - **DO**
  ///   [FlutterReactiveBle.scanForDevices]를 통한 블루투스 스캔을 수행한다. 스캔 시 [StreamSubscription]를 사용하며
  ///   Stream 등록을 취소(cancel)하여 스캔을 종료한다. 스캔 종료 후 스캔 결과를 [List]형태로 반환한다.
  ///
  ///   - **DON'T**
  ///   각 OS에 맞는 블루투스 권한 설정이 선행되지 않으면 사용할 수 없다.
  ///
  /// **See also :**
  ///
  ///   - 블루투스와 관련된 3rd party에 대한 자세한 설명은 [FlutterReactiveBLE](https://pub.dev/packages/flutter_reactive_ble)에서 확인할 수 있다.
  ///   - UUID와 관련된 내용은 [시각장애인용 음향신호기 규격서](https://www.police.go.kr/component/file/ND_fileDownload.do?q_fileSn=154401&q_fileId=57f13a5b-e714-47e7-837b-75de9985faee)에서 확인할 수 있다.
  ///   - duration(1s) 만큼 딜레이는 (주)한길HC의 기술 자문을 통해 파악한 내용이다. 하드웨어가 데이터를 처리할 시간을 주기 위해 의도적으로 최소 1초의 딜레이를 부과한다.
  Future<void> send(
    DiscoveredDevice post, {
    List<int> command = const [0x31, 0x00, 0x02],
  });
  Future<void> disconnect();
}

/// 블루투스 통신을 위한 [BlueNativeDataSource]의 구현부이다.
class BlueNativeDataSourceImpl implements BlueNativeDataSource {
  static StreamSubscription? subscription;
  static StreamSubscription<ConnectionStateUpdate>? connection;

  static const Duration duration = Duration(seconds: 1);
  final FlutterReactiveBle bluetooth;

  BlueNativeDataSourceImpl({required this.bluetooth});

  @override
  Future<List<DiscoveredDevice>> scan() async {
    List<DiscoveredDevice> results = [];
    try {
      subscription = bluetooth.scanForDevices(
        withServices: [Uuid.parse(Bluetooth.SERVICE_UUID)],
      ).listen((device) {
        final knownDeviceIndex = results.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          results[knownDeviceIndex] = device;
        } else {
          results.add(device);
        }
      }, onError: (e) {
        throw BlueException();
      });

      await Future.delayed(duration);
      await subscription!.cancel();

      return results;
    } catch (e) {
      throw BlueException();
    }
  }

  @override
  Future<void> send(
    DiscoveredDevice post, {
    List<int> command = Bluetooth.CMD_VOICE,
  }) async {
    try {
      connection = bluetooth.connectToDevice(id: post.id).listen(
        (update) async {
          if (update.connectionState == DeviceConnectionState.connected) {
            List<DiscoveredService> services =
                await bluetooth.discoverServices(post.id);

            final characteristic = services
                .firstWhere(
                  (service) =>
                      service.serviceId == Uuid.parse(Bluetooth.SERVICE_UUID),
                )
                .characteristics
                .firstWhere(
                  (characteristic) =>
                      characteristic.characteristicId ==
                      Uuid.parse(Bluetooth.CHAR_UUID),
                );

            final qualifiedCharacteristic = QualifiedCharacteristic(
              characteristicId: characteristic.characteristicId,
              serviceId: characteristic.serviceId,
              deviceId: post.id,
            );

            await bluetooth
                .writeCharacteristicWithoutResponse(
              qualifiedCharacteristic,
              value: command,
            )
                .then(
              (value) async {
                await Future.delayed(const Duration(milliseconds: 500));
                await disconnect();
              },
            );
          }
        },
        onError: (Object e) {
          throw BlueException();
        },
      );
    } catch (e) {
      throw BlueException();
    }
  }

  @override
  Future<void> disconnect() async {
    await connection!.cancel();
  }
}
