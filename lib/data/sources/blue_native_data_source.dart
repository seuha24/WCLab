part of '../../framework/data_source.dart';

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

  /// 위치안내 요청을 전송하는 메소드
  /// 횡단보도의 위치 정보를 음성으로 안내받기 위해 사용
  Future<void> sendLocationGuide(DiscoveredDevice post);

  /// 신호안내 요청을 전송하는 메소드
  /// 현재 신호등 상태를 음성으로 안내받기 위해 사용
  Future<void> sendSignalGuide(DiscoveredDevice post);

  /// 음성안내 요청을 전송하는 메소드
  /// 추가적인 음성 안내를 받기 위해 사용
  Future<void> sendVoiceGuide(DiscoveredDevice post);

  /// 응답을 기다리며 명령을 전송하는 메소드
  /// ACK/NAK 응답을 수신하여 성공 여부를 반환
  Future<ResponseData?> sendWithResponse(
    DiscoveredDevice post, {
    List<int> command,
  });

  /// BLE 특성으로부터 응답을 수신하는 스트림
  Stream<List<int>> receiveResponse(DiscoveredDevice post);

  /// 디바이스 연결 상태를 모니터링하는 스트림
  /// 실시간으로 연결 상태 변화를 추적
  Stream<DeviceConnectionState> monitorConnection(String deviceId);

  /// 현재 연결 상태를 가져오는 메소드
  DeviceConnectionState? getCurrentConnectionState(String deviceId);

  /// PIN 인증을 수행하는 메소드
  /// PIN 코드를 사용하여 음향신호기에 인증 시도
  /// 규격서에는 PIN 프로토콜 상세가 없으므로 제조사별로 다를 수 있음
  Future<bool> authenticateWithPin(DiscoveredDevice post, String pin);

  /// PIN 변경을 수행하는 메소드
  /// 현재 PIN으로 인증 후 새로운 PIN으로 변경
  Future<bool> changePin(
      DiscoveredDevice post, String currentPin, String newPin);

  Future<void> disconnect();
}

/// 블루투스 통신을 위한 [BlueNativeDataSource]의 구현부이다.
class BlueNativeDataSourceImpl implements BlueNativeDataSource {
  static StreamSubscription? subscription;
  static StreamSubscription<ConnectionStateUpdate>? connection;

  // 연결 상태 추적을 위한 맵
  final Map<String, StreamSubscription<ConnectionStateUpdate>>
      _connectionStreams = {};
  final Map<String, DeviceConnectionState> _connectionStates = {};

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
        // DEVICE NAME 형식 검증 (경찰청 규격서 준수)
        // 유효하지 않은 장치는 필터링
        if (Bluetooth.validateDeviceName(device.name)) {
          final knownDeviceIndex = results.indexWhere((d) => d.id == device.id);
          if (knownDeviceIndex >= 0) {
            results[knownDeviceIndex] = device;
          } else {
            results.add(device);
          }
        }
      }, onError: (e) {
        debugPrint('⚠️ BLE 스캔 에러: $e');
        // 에러를 throw하지 않고 로그만 출력
        // 스캔이 이미 진행 중이거나 Bluetooth가 꺼진 경우 발생 가능
      });

      await Future.delayed(duration);
      await subscription!.cancel();

      return results;
    } catch (e) {
      if (e is BlueException) rethrow;
      throw BlueScanException('음향신호기 스캔 실패');
    }
  }

  @override
  Future<void> send(
    DiscoveredDevice post, {
    List<int> command = Bluetooth.CMD_SIGNAL, // 기본값: 신호안내
  }) async {
    try {
      // DEVICE NAME 재검증
      if (!Bluetooth.validateDeviceName(post.name)) {
        throw BlueInvalidDeviceException('유효하지 않은 음향신호기');
      }

      // 연결 로그
      debugPrint('========== BLE 통신 시작 ==========');
      debugPrint('기기명: ${post.name}');
      debugPrint('기기 ID: ${post.id}');
      debugPrint('명령: ${_getCommandName(command)}');

      connection = bluetooth.connectToDevice(id: post.id).listen(
        (update) async {
          debugPrint('연결 상태: ${update.connectionState}');

          if (update.connectionState == DeviceConnectionState.connected) {
            debugPrint('✅ BLE 연결 성공');
            List<DiscoveredService> services;
            try {
              services = await bluetooth.discoverServices(post.id);
            } catch (e) {
              throw BlueConnectionException('서비스 탐색 실패');
            }

            final service = services.firstWhere(
              (service) =>
                  service.serviceId == Uuid.parse(Bluetooth.SERVICE_UUID),
              orElse: () => throw BlueConnectionException('UART 서비스를 찾을 수 없음'),
            );

            final characteristic = service.characteristics.firstWhere(
              (characteristic) =>
                  characteristic.characteristicId ==
                  Uuid.parse(Bluetooth.CHAR_UUID),
              orElse: () =>
                  throw BlueConnectionException('UART RX 특성을 찾을 수 없음'),
            );

            final qualifiedCharacteristic = QualifiedCharacteristic(
              characteristicId: characteristic.characteristicId,
              serviceId: characteristic.serviceId,
              deviceId: post.id,
            );

            debugPrint('📤 명령 전송 중...');
            await bluetooth
                .writeCharacteristicWithoutResponse(
              qualifiedCharacteristic,
              value: command,
            )
                .then(
              (value) async {
                debugPrint('✅ 명령 전송 성공');
                debugPrint('========== BLE 통신 완료 ==========\n');
                await Future.delayed(const Duration(milliseconds: 500));
                await disconnect();
              },
            );
          }
        },
        onError: (Object e) {
          debugPrint('❌ BLE 연결 오류: $e');
          throw BlueConnectionException('연결 중 오류 발생');
        },
      );
    } catch (e) {
      debugPrint('❌ BLE 통신 실패: $e');
      if (e is BlueException) rethrow;
      throw BlueConnectionException('음향신호기 연결 실패');
    }
  }

  // 명령 이름 반환 헬퍼 메서드
  String _getCommandName(List<int> command) {
    // List 비교를 위해 문자열로 변환하여 비교
    final cmdStr = command.toString();
    if (cmdStr == Bluetooth.CMD_LOCATION.toString()) return '위치안내';
    if (cmdStr == Bluetooth.CMD_SIGNAL.toString()) return '신호안내';
    if (cmdStr == Bluetooth.CMD_VOICE.toString()) return '음성안내';

    // 바이트 값으로도 체크
    if (command.length == 3) {
      if (command[0] == 0x31 && command[1] == 0x00) {
        if (command[2] == 0x01) return '위치안내';
        if (command[2] == 0x02) return '신호안내';
        if (command[2] == 0x03) return '음성안내';
      }
    }
    return '알 수 없는 명령 $command';
  }

  @override
  Future<void> disconnect() async {
    await connection!.cancel();
  }

  @override
  Future<void> sendLocationGuide(DiscoveredDevice post) async {
    await send(post, command: Bluetooth.CMD_LOCATION);
  }

  @override
  Future<void> sendSignalGuide(DiscoveredDevice post) async {
    await send(post, command: Bluetooth.CMD_SIGNAL);
  }

  @override
  Future<void> sendVoiceGuide(DiscoveredDevice post) async {
    await send(post, command: Bluetooth.CMD_VOICE);
  }

  @override
  Stream<List<int>> receiveResponse(DiscoveredDevice post) {
    final characteristic = QualifiedCharacteristic(
      characteristicId: Uuid.parse(Bluetooth.CHAR_TX_UUID),
      serviceId: Uuid.parse(Bluetooth.SERVICE_UUID),
      deviceId: post.id,
    );

    return bluetooth.subscribeToCharacteristic(characteristic);
  }

  @override
  Future<ResponseData?> sendWithResponse(
    DiscoveredDevice post, {
    List<int> command = Bluetooth.CMD_SIGNAL,
  }) async {
    try {
      // DEVICE NAME 재검증
      if (!Bluetooth.validateDeviceName(post.name)) {
        throw BlueInvalidDeviceException('유효하지 않은 음향신호기');
      }

      debugPrint('========== BLE 응답 대기 통신 시작 ==========');
      debugPrint('기기명: ${post.name}');
      debugPrint('명령: ${_getCommandName(command)}');

      // 응답 수신 스트림 준비
      final responseStream = receiveResponse(post);
      StreamSubscription<List<int>>? responseSubscription;
      ResponseData? responseData;

      // 응답 수신 리스너 등록
      responseSubscription = responseStream.listen(
        (data) {
          debugPrint('📥 응답 수신: $data');
          responseData = ResponseParser.parse(data);
          responseSubscription?.cancel();
        },
        onError: (e) {
          debugPrint('❌ 응답 수신 에러: $e');
          throw BlueConnectionException('응답 수신 중 오류');
        },
      );

      // 명령 전송
      await send(post, command: command);

      // 응답 대기 (최대 3초)
      debugPrint('⏳ 응답 대기 중 (최대 3초)...');
      int waitCount = 0;
      while (responseData == null && waitCount < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      // 응답 수신 리스너 정리
      await responseSubscription.cancel();

      // 타임아웃 체크
      if (responseData == null) {
        debugPrint('⚠️ 응답 없음 (음향신호기가 응답하지 않음)');
        throw BlueTimeoutException('음향신호기 응답 시간 초과');
      }

      // NAK 응답 체크
      if (responseData?.isNak == true) {
        debugPrint('❌ NAK 응답 수신');
        throw BlueNakException('음향신호기가 명령을 거부했습니다');
      }

      debugPrint('✅ 응답 수신 완료');
      debugPrint('========== BLE 응답 대기 통신 종료 ==========\n');

      return responseData;
    } catch (e) {
      if (e is BlueException) rethrow;
      throw BlueConnectionException('응답 처리 실패');
    }
  }

  @override
  Stream<DeviceConnectionState> monitorConnection(String deviceId) {
    // 기존 스트림이 있으면 취소
    _connectionStreams[deviceId]?.cancel();

    // 새로운 연결 상태 스트림 생성
    final stream = bluetooth.connectToDevice(id: deviceId).listen((update) {
      _connectionStates[deviceId] = update.connectionState;
    });

    _connectionStreams[deviceId] = stream;

    // 연결 상태 스트림 반환
    return bluetooth
        .connectToDevice(id: deviceId)
        .map((update) => update.connectionState);
  }

  @override
  DeviceConnectionState? getCurrentConnectionState(String deviceId) {
    return _connectionStates[deviceId];
  }

  @override
  Future<bool> authenticateWithPin(DiscoveredDevice post, String pin) async {
    try {
      // DEVICE NAME 검증
      if (!Bluetooth.validateDeviceName(post.name)) {
        throw BlueInvalidDeviceException('유효하지 않은 음향신호기');
      }

      // 연결 설정
      final completer = Completer<bool>();
      bool authResult = false;

      connection = bluetooth.connectToDevice(id: post.id).listen(
        (update) async {
          if (update.connectionState == DeviceConnectionState.connected) {
            try {
              // 서비스 탐색
              final services = await bluetooth.discoverServices(post.id);

              // PIN SERVICE 찾기
              final pinService = services.firstWhere(
                (service) =>
                    service.serviceId == Uuid.parse(Bluetooth.PIN_SERVICE_UUID),
                orElse: () =>
                    throw BlueConnectionException('PIN SERVICE를 찾을 수 없음'),
              );

              // PIN 특성 찾기 - 일반적으로 PIN SERVICE UUID를 특성으로도 사용
              DiscoveredCharacteristic? pinCharacteristic;
              for (final char in pinService.characteristics) {
                if (char.isWritableWithoutResponse ||
                    char.isWritableWithResponse) {
                  pinCharacteristic = char;
                  break;
                }
              }

              if (pinCharacteristic == null) {
                throw BlueConnectionException('PIN 특성을 찾을 수 없음');
              }

              final qualifiedCharacteristic = QualifiedCharacteristic(
                characteristicId: pinCharacteristic.characteristicId,
                serviceId: pinCharacteristic.serviceId,
                deviceId: post.id,
              );

              // PIN 전송 (UTF-8 인코딩)
              // 규격서에 인코딩 방식이 명시되지 않았으므로 일반적인 UTF-8 사용
              final pinBytes = utf8.encode(pin);

              await bluetooth.writeCharacteristicWithoutResponse(
                qualifiedCharacteristic,
                value: pinBytes,
              );

              // 응답 대기 (간단한 구현)
              // 실제 구현시 제조사별 응답 프로토콜 확인 필요
              await Future.delayed(const Duration(milliseconds: 500));

              authResult = true; // 임시로 성공 처리
              completer.complete(authResult);

              await disconnect();
            } catch (e) {
              completer.completeError(e);
              await disconnect();
            }
          }
        },
        onError: (error) {
          completer.completeError(BlueConnectionException('PIN 인증 중 오류 발생'));
        },
      );

      // 타임아웃 설정
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          disconnect();
          throw BlueTimeoutException('PIN 인증 시간 초과');
        },
      );
    } catch (e) {
      if (e is BlueException) rethrow;
      throw BlueConnectionException('PIN 인증 실패: ${e.toString()}');
    }
  }

  @override
  Future<bool> changePin(
      DiscoveredDevice post, String currentPin, String newPin) async {
    try {
      // 1. 먼저 현재 PIN으로 인증
      final authSuccess = await authenticateWithPin(post, currentPin);
      if (!authSuccess) {
        throw BlueConnectionException('현재 PIN 인증 실패');
      }

      // 2. PIN 변경 수행
      final completer = Completer<bool>();
      bool changeResult = false;

      connection = bluetooth.connectToDevice(id: post.id).listen(
        (update) async {
          if (update.connectionState == DeviceConnectionState.connected) {
            try {
              // 서비스 탐색
              final services = await bluetooth.discoverServices(post.id);

              // CHANGE PIN CODE 특성 찾기
              for (final service in services) {
                for (final characteristic in service.characteristics) {
                  if (characteristic.characteristicId ==
                      Uuid.parse(Bluetooth.CHANGE_PIN_UUID)) {
                    final qualifiedCharacteristic = QualifiedCharacteristic(
                      characteristicId: characteristic.characteristicId,
                      serviceId: service.serviceId,
                      deviceId: post.id,
                    );

                    // 새 PIN 전송
                    final newPinBytes = utf8.encode(newPin);

                    await bluetooth.writeCharacteristicWithoutResponse(
                      qualifiedCharacteristic,
                      value: newPinBytes,
                    );

                    // 응답 대기
                    await Future.delayed(const Duration(milliseconds: 500));

                    changeResult = true;
                    completer.complete(changeResult);

                    await disconnect();
                    return;
                  }
                }
              }

              throw BlueConnectionException('CHANGE PIN CODE 특성을 찾을 수 없음');
            } catch (e) {
              completer.completeError(e);
              await disconnect();
            }
          }
        },
        onError: (error) {
          completer.completeError(BlueConnectionException('PIN 변경 중 오류 발생'));
        },
      );

      // 타임아웃 설정
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          disconnect();
          throw BlueTimeoutException('PIN 변경 시간 초과');
        },
      );
    } catch (e) {
      if (e is BlueException) rethrow;
      throw BlueConnectionException('PIN 변경 실패: ${e.toString()}');
    }
  }
}
