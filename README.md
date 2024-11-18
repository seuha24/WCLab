# safelight

SafeLight는 교통 약자 및 일반인들의 위험 지역 횡단을 돕는 소프트웨어 압버튼입니다.

교통 약자(시각장애)에게 맞춤형 보행 보조 도구로서 기존의 압버튼 사용시 불편함 해소를 목표로 개발 중입니다.

https://dart.dev/guides/language/effective-dart

# 들어가기 앞서...
해당 프로젝트는 `Flutter`로 작성되었습니다.

먼저 Flutter에 대해 알아보고 해당 프로젝트를 살펴보는 것을 권장합니다.

#### [Flutter 공식 문서](https://flutter.dev/)

# 진행

* ~~[2022 배리어프리 공모전](https://www.autoeverapp.kr/) 예선 1차 합격~~

* ~~[2022 배리어프리 공모전](https://www.autoeverapp.kr/) 예선 심사 최종 합격(~2022.08.19)~~

* [2022 배리어프리 공모전](https://www.autoeverapp.kr/) 본선 진출(14팀)

# 의존 라이브러리
<details><summary>get</summary>

### [get: ^4.6.5](https://pub.dev/packages/get)
- Flutter App 내 State 관리
- App Navigator (route 관리)

</details>

<details><summary>flutter_blue</summary>

### [flutter_blue: ^0.8.0](https://pub.dev/packages/flutter_blue)
- App Bluetooth 통신
- SafeLight 페어링

</details>

<details><summary>http</summary>

### [http: ^0.13.5](https://pub.dev/packages/http)
- http 통신(get / post)

</details>

<details><summary>sqflite</summary>

### [sqflite: ^2.0.3](https://pub.dev/packages/sqflite)
- SafeLight와 신호등 압버튼의 관계 저장
- 신호등 압버튼 정보 저장

</details>

<details><summary>shared_preferences</summary>

### [shared_preferences: ^2.0.15](https://pub.dev/packages/shared_preferences)
- 사용자 상태(교통 약자 타입) 관리
- App 최신 버전 관리

</details>

<details><summary>flutter_local_notifications</summary>

### [flutter_local_notifications: ^9.7.0](https://pub.dev/packages/flutter_local_notifications)
- 자동 스캔 시, SafeLight Search 알림
- SAFELIGHT_SafeLightScan usecase에서 사용

</details>

<details><summary>flutter_tts</summary>

### [flutter_tts: ^3.5.0](https://pub.dev/packages/flutter_tts)
- 시각 장애 사용자를 위한 tts 서비스

</details>

# Bluetooth Core
Safelight의 블루투스 핵심 로직은 크게 검색(Search)과 연결(Connect)로 나뉩니다.
각 로직에 대한 설명은 아래와 같습니다.

## Bluetooth Search
블루투스 압버튼을 검색(Search)하는 로직입니다.
신호등의 압버튼 포스트를 Scan하고 해당 결과를 홈화면(HomeView)에 출력합니다.

실제 블루투스 검색 로직은 아래와 같이 사용합니다.

*View(ui) Layer에서의 사용 예시*
```dart
// 1. Bluetooth searchCMD 설정
_blueController.blueHandler.searchCMD = DefaultSearch();

// 2. Bluetooth reset 후 search
_blueController.blueHandler
               ..reset()
               ..search();
```

### 1. Bluetooth searchCMD 설정
BlueController Class(위 예시에서는 _blueController 변수에 할당함)의 blueHandler 변수로 접근(`getter`)합니다.

```dart
_blueController.blueHandler
```

해당 변수(`_blueController.blueHandler`)는 BlueHandler Class 를 Singleton 객체(단일 인스턴스 변수)로 할당받고 있습니다.

```dart
// Part of lib/view_model/controller/blue_controller.dart
// Line 13 in BlueController Class

BlueHandler get blueHandler => _blueHandler;
```
    
이후 searchCMD setter를 통해 검색 설정(어떻게 검색할 것인가?)를 setting 합니다.

*해당 부분은 v1.0 이후 검색 설정이 추가될 경우를 대비한 설계입니다. 현재 v1.0에서는 해당 setting이 필요없지만(검색 설정이 1가지 방법 뿐이므로) 이후 `서비스의 확장성`을 고려하여 `검색 설정을 setting하고 검색`이 이루어지도록 설정하였습니다.*

```dart
// Part of lib/view_model/handler/blue_handler.dart
// Line 12:23 in BlueHandler Class

// search 설정에 대한 setting 값을 담는 변수(private)
ISearchCommandStrategy? _searchCMD; 

// searchCMD 변수의 getter
ISearchCommandStrategy get searchCMD => _searchCMD!;

// searchCMD 변수의 setter
set searchCMD(ISearchCommandStrategy command) => _searchCMD = command;
```
해당 변수로 searchCMD(검색 설정)을 결정합니다.
실제 검색 로직(search())가 수행되기 이전에 검색 설정(searchCMD)의 할당이 무조건 선행되어야 합니다.

searchCMD는 ISearchCommandStrategy interface를 implements 해야합니다.
ISearchCommandStrategy interface는 아래와 같습니다.
```dart
// Part of lib/view_model/interface/search_command_strategy_interface.dart
// Line * in ISearchCommandStrategy Interface

import 'dart:async';

abstract class ISearchCommandStrategy {
  // searchCMD 객체는 무조건 각 search 설정에 맞는 rssi 값을 가져야합니다.
  abstract int rssi;

  // searchCMD 객체는 무조건 각 search 설정에 맞는 duration(검색 시간)을 가져야합니다.
  abstract Duration duration;

  // 실제 search에 사용하는 로직입니다.
  // 모든 searchCMD 객체는 search Method를 가져야 합니다.
  // 실제 search 로직은 각 searchCMD 객체에서 구현됩니다.
  Future search(StreamController stream);
}
```
v1.0에서 제공하는 searchCMD는 아래와 같습니다.
#### DefaultSearch
기본적인 검색 설정입니다.
* rssi : -100
* duration : 1s

```dart
// Part of lib/view_model/implement/bluetooth/default_search_impl.dart
// Line 8:49 in DefaultSearch Class

class DefaultSearch implements ISearchCommandStrategy {
  @override
  int rssi = -100;

  @override
  Duration duration = const Duration(seconds: 1);

  @override
  Future search(StreamController stream) async {
    List<CrosswalkVO> results = [];

    try {
      await FlutterBluePlus.instance.startScan(
        timeout: duration, // 설정된 duration 변수값만큼 수행
      ); // 검색 시작
    } catch (e) {
      throw Exception(e); // 예외 처리
    } finally {
      FlutterBluePlus.instance.scanResults.listen(
        (posts) {
            // stream 을 활용한 스캔 결과 처리
          Iterator<ScanResult> post = posts.iterator;

          while (post.moveNext()) {
            if (post.current.device.name.startsWith('AHG001+')) {
              results.add(
                // CrosswalkVO 클래스에 결과값 할당 후 add
                CrosswalkVO(
                  post: post.current.device,
                  name: '가톨릭대 앞 횡단보도',
                  direction: '역곡역 방향',
                  areaType: post.current.device.name.isEmpty
                      ? AreaType.INTERSECTION
                      : AreaType.SINGLE_ROAD,
                ),
              );
            }
          }
        },
      );
      // stream에 최종 결과값 add 후 종료
      stream.add(results);
    }
  }
}

```

### 2. Bluetooth reset 후 search
검색 설정(searchCMD)의 setting이 종료되면, BlueController Class의 blueHandler 변수로 접근합니다.
    
이후 BlueHandler Class의 reset() 메서드 를 수행하고, search() 메서드를 절차적으로 수행합니다.
    
##### *`..Function1()..Function2()` 문법을 통해 절차적으로 수행하게 합니다.*
    
```dart
_blueController.blueHandler
               ..reset()
               ..search();
```

### reset()
BlueHandler Class의 reset 메서드는 현재 가지고 있는 Legacy data를 초기화하는 로직을 수행합니다.

```dart
// Part of lib/view_model/handler/blue_handler.dart
// Line 49:53 in BlueHandler Class
Future<void> reset() async {
    _results.add(<CrosswalkVO>[]);
    BlueController.isDone.value = false;
    BlueController.status.value = StatusType.STAND_BY;
  } 
```

### search()
실제 블루투스 압버튼을 찾는 `core 로직`은 앞서 설명한 `searchCMD 객체`에 속해있는 `search Method`에서 수행되게 됩니다.

하지만, 해당 로직을 바로 사용하게 될 경우 `다른 searchCMD`가 적용되었을 떄 `매번 할당을 해줘야 하는 문제점`이 발생합니다(SOLID 원칙 위반)

따라서 `BlueHandler Class`에 `search Method`를 만들고 해당 Method에서 `searchCMD 객체`의 `search Method`를 수행하게 합니다.

```dart
// Part of lib/view_model/handler/blue_handler.dart
// Line 25:43 in BlueHandler Class
Future<void> search() async {
    UserController userController = Get.find<UserController>();
    Stream<bool> permisson = userController.auth.checkBluePermission(); // Permission check
    permisson.listen((isGranted) async {
      if (isGranted) {
        // Bluetooth Permission Authorized
        try {
          BlueController.isDone.value = true;
          BlueController.status.value = StatusType.IS_SCANNING;
          await _searchCMD!.search(_results); // searchCMD 객체의 search Method 수행
        } catch (e) {
          throw (Exception(e));
        } finally {
          BlueController.status.value = StatusType.COMPLETE;
        }
      } else {
        Get.snackbar('블루투스 권한을 확인하세요.', '스마트 압버튼 스캔을 위해 앱 내 블루투스 권한을 허가해야합니다.');
      }
    });
  }
```

## Bluetooth Connect
블루투스 연결 로직은 연결 후 데이터 전송까지의 과정을 의미합니다.

search 와 동일하게 sendCMD 변수가 존재하고 ISendCommandStrategy abstract class를 extends 하는 구조를 가집니다.

ISendCommandStrategy abstract class를 상속받는 클래스는 아래와 같습니다.

Location : `lib/view_model/implement/bluetooth/..`
* AcoustricSignal Class
* VoiceInductor Class

searchCMD와 동일하게 sendCMD를 설정해주어야 합니다.
```dart
_blueController
            .blueHandler
            .sendCMD = VoiceInductor(
                crosswalks: [
                    snapshot.data![index],
                ],
            ); // 음성유도를 하고 싶다.

// or

_blueController
            .blueHandler
            .sendCMD = AcousticSignal(
                crosswalks: [
                    snapshot.data![index],
                ],
            ); // 압버튼을 누르고 싶다.
```

이후 데이터를 보내기 위해 연결을 해주어야 합니다.

블루투스 연결(connect) 로직은 아래와 같습니다.

```dart
// Part of lib/view_model/interface/send_command_strategy_interface.dart
// Line 11:36 in ISendCommandStrategy abstract Class

Future<void> connect(List<int> command) async {
    for (int i = 0; i < _crosswalks.length; i++) {
      try {
        // 1. 포스트에 연결합니다.
        await _crosswalks[i].post.connect();
        
        // 2. 연결된 포스트에 접근 가능한 서비스가 있는지 알아봅니다.
        List<BluetoothService> services =
            await _crosswalks[i].post.discoverServices();

        // 3-1. 앞서 찾은 서비스에서 uid가 경찰청 프로토콜에서 제시하는 uid와 동일한 서비스를 찾습니다.    
        await services
            .firstWhere(
              (service) =>
                  service.uuid == Guid('0003cdd0-0000-1000-8000-00805f9b0131'),
            )
            // 3-2. 이후 동일한 uid를 가지는 서비스가 가지는 특성값 중 경찰청 프로토콜에서 제시하는 uid와 동일한 값을 찾습니다.
            .characteristics
            .firstWhere(
              (characteristic) =>
                  characteristic.uuid ==
                  Guid('0003cdd2-0000-1000-8000-00805f9b0131'),
            )
            // 4. 마지막으로 찾은 특성값에 command를 전송합니다.
            .write(command, withoutResponse: true);
      } catch (e) {
        throw Exception(e);
      } finally {
        await Future.delayed(const Duration(seconds: 2));

        // 5. 연결을 해지합니다.
        await _crosswalks[i].post.disconnect();
      }
    }
  }
```

블루투스 연결 방법은 2가지 경우가 존재합니다.
두가지 방법 모두 send() Method를 사용합니다.

### 압버튼 누르기
블루투스 압버튼을 누르는 커맨드를 전송합니다.

```dart
// Part of lib/view_model/implement/bluetooth/acoustic_signal_impl.dart
// Line * in AcousticSignal
import 'package:safelight/model/vo/crosswalk_vo.dart';
import 'package:safelight/view_model/interface/send_command_strategy_interface.dart';

class AcousticSignal extends ISendCommandStrategy {
  static const List<int> _command = [0x31, 0x00, 0x02]; // 경찰청 프로토콜에 따른 커맨드 값

  AcousticSignal({required List<CrosswalkVO> crosswalks}) : super(crosswalks);

  @override
  Future<void> send() async {
    await super.connect(_command);
  }
}

```

### 음성 유도
블루투스 압버튼이 있는 방향으로 유도합니다.

```dart
// Part of lib/view_model/implement/bluetooth/voice_inductor_impl.dart
// Line * in VoiceInductor
import 'package:safelight/model/vo/crosswalk_vo.dart';
import 'package:safelight/view_model/interface/send_command_strategy_interface.dart';

class VoiceInductor extends ISendCommandStrategy {
  static const List<int> _command = [0x31, 0x00, 0x01]; // 경찰청 프로토콜에 따른 커맨드 값

  VoiceInductor({required List<CrosswalkVO> crosswalks}) : super(crosswalks);

  @override
  Future<void> send() async {
    await super.connect(_command);
  }
}

```

---
## Trigger
| *2가지의 핵심 로직(Search, Connect)로 분리하여 문서화되었습니다.*

앞선 블루투스 핵심 로직이 실제 수행되는 시점은 아래와 같습니다.


### Bluetooth Search
v1.0 에서 블루투스 검색(Search)는 아래의 시점(Trigger)에서 사용됩니다.

- **홈 화면(HomeView) 접근 시**
    
    홈화면 접근, 즉 앱을 키고 처음 홈화면이 켜지는 순간 HomeView 클래스의 아래의 로직이 수행되며 주변 압버튼을 스캔합니다.

    ```dart
    // Part of `lib/ui/view/home_view.dart`
    // Line 33:39 in HomeView Class

    @override
    void initState() {
      super.initState();
      _blueController.blueHandler.searchCMD = DefaultSearch();
      _blueController.blueHandler
                     ..reset() // 1. Remove legacy data
                     ..search(); // 2. Search Bluetooth
  }
    ```

- **홈 화면의 블루투스 압버튼 찾기 버튼 클릭 시**

    홈화면에서 블루투스 압버튼 찾기 버튼을 클릭 시 아래의 로직이 수행되며 주변 압버튼을 스캔합니다.

    ```dart
    // Part of `lib/ui/view/home_view.dart`
    // Line 86:91 in HomeView Class

    onPressed: () async {
      _blueController.blueHandler.searchCMD = DefaultSearch();
      _blueController.blueHandler
                     ..reset() // 1. Remove legacy data
                     ..search(); // 2. Search Bluetooth
          },
    ```

### Bluetooth Connect
v1.0 에서 블루투스 연결(Connect)는 아래의 시점(Trigger)에서 사용됩니다.

- **검색된 압버튼 결과 중 하나를 클릭 후, 출력되는 ActionSheet에서 연결 타입 선택 시**

    홈화면에서 블루투스 검색 후, 출력되는 압버튼 결과 중 하나를 선택하면 연결 타입을 결정하는 `ActionSheet`이 출력됩니다.

    #### *ActionSheet*
    ```dart
    // Part of `lib/ui/view/home_view.dart`
    // Line 250:292 in HomeView Class

    return CupertinoActionSheet(
        ...
    );
    ```

    해당 `ActionSheet`에서 희망하는 연결 타입을 선택하면 해당 타입에 맞는 `Bluetooth Connect` 로직이 수행됩니다.

    #### *음성 유도*
    ```dart
    // Part of `lib/ui/view/home_view.dart`
    // Line 254:265 in HomeView Class

    onPressed: () async {
         // 1. Close ActionSheet
         Navigator.pop(context);

         // 2. Setting VoiceInductor(음성유도)
        _blueController
            .blueHandler
            .sendCMD = VoiceInductor(
                crosswalks: [
                    snapshot.data![index],
                ],
            );

        // 3. Send Command         
        _blueController.blueHandler.send(); 

        // 4. Remove Legacy Data
        _blueController.blueHandler.reset();
    },
    ```

     #### *압버튼 누르기*
    ```dart
    // Part of `lib/ui/view/home_view.dart`
    // Line 270:282 in HomeView Class
    onPressed: () async {
         // 1. Close ActionSheet
        Navigator.pop(context);

        // 2. Setting AcousticSignal(압버튼 누르기)
        _blueController
            .blueHandler
            .sendCMD = AcousticSignal(
                crosswalks: [
                    snapshot.data![index],
                ],
            );

        // 3. Send Command 
        _blueController.blueHandler.send();

        // 4. Remove Legacy Data
        _blueController.blueHandler.reset();
    },
    ```
    
    # Android
    기존 안드로이드에서 Bluetooth Core 로직입니다.

    안드로이드 코드에 익숙한 사용자라면, 아래의 문서를 참고하여 위의 Flutter 버전을 확인하면 됩니다.
    
    [java android BLE 코드 참고]<https://developer.android.com/guide/topics/connectivity/bluetooth-le?hl=ko>
    
    ##### 1. start scan
    
    스캔 시작 전,
    Central 장치에 블루투스 어탭터 설정이 되어 있는지, 해당 장치 블루투스가 Enable 되어 있는지,
    이미 스캔중인지, Find_Location의 사용허가가 되어 있는지를 확인합니다.
    
    `ScanSettings`, `ScanFilter`, `scanResults`, `scanCallback`을 생성한 후 스캔을 시작합니다.
    
    ```java
    
    private void startScan(View v) {
        Tv_status.setText(".....");
        Tv_read.setText(".....");
        //Btn_send.setEnabled(false);

        // check if location permission
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestLocationPermission();
            Tv_status.setText("Scanning Failed: no fine location permission");
            return;
        }
        // disconnect gatt server
        disconnectGattServer();

        Tv_status.setText(R.string.bt_scan);
        //// set scan filters
        // create scan filter list
        List<ScanFilter> filters = new ArrayList<>();

        // set low power scan mode
        ScanSettings settings = new ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                .setReportDelay(0)
                .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
                .build();

        // create a scan filter with device UUID
        ScanFilter scan_filter = new ScanFilter.Builder()
                .setServiceUuid(new ParcelUuid(UUID_TDCS_SERVICE))
                .build();

        filters.add(scan_filter);

        scanResults = new HashMap<>();
        scanCallback = new BLEScanCallback(scanResults);


        //up is the permission code for the code below
        bluetoothLeScanner.startScan(filters, settings, scanCallback);
        is_scanning_ = true;

        scanHandler = new Handler();
        scanHandler.postDelayed(this::stopScan, SCAN_PERIOD);
        }
    ```
    
    ##### 2. stop scan
    
    스캔을 종료합니다.
    
    ```java
    private void stopScan() {
        if (is_scanning_ && bluetoothAdapter != null && bluetoothAdapter.isEnabled() && bluetoothLeScanner != null) {
            // stop scanning

            bluetoothLeScanner.stopScan(scanCallback);  //red line v2 - perm

            scanComplete();
        }
        // reset flags
        scanCallback= null;
        is_scanning_= false;
        scanHandler= null;
        // update the status
       // Tv_status.setText( "scanning stopped" );

    }
    ```
    
    ##### 3. scan complete
    
    스캔을 완료하면 스캔 결과를 화면에 표시합니다.
    
    ```java
    private void scanComplete() {
        // check if nothing found
        if( scanResults.isEmpty() ) {
            Tv_status.setText( "scan results is empty" );
            Log.d( TAG, "scan results is empty" );
            return;
        }
        // loop over the scan results and connect to them
        for( String deviceAddr : scanResults.keySet() ) {
            Log.d( TAG, "Found device: " + deviceAddr );
            // get device instance using its MAC address
            BluetoothDevice device= scanResults.get( deviceAddr );
            if( MAC_ADDR.equals( deviceAddr) ) {
                Log.d( TAG, "connecting device: " + deviceAddr );
                // connect to the device
                connectDevice(device);
                PopUp();
            }
        }
    }
    ```
    
    ##### 4. connect Device
    
    Mac address를 이용하여 일치하는 기기를 연결합니다.
    
    ```java
    //Connect to the ble device
    private void connectDevice( BluetoothDevice device_ ) {
        // update the status
        Tv_read.setText( "Connecting to " + device_.getAddress() );
        GattClientCallback gatt_client_cb= new GattClientCallback();
        bluetoothGatt = device_.connectGatt( this, false, gatt_client_cb );  //red line v2 - perm
    }
    ```
    
    ##### 5. GATT
    
    GATT 서버와의 연결 과정입니다.
    
    ```java
    private class GattClientCallback extends BluetoothGattCallback {
        @Override
        public void onConnectionStateChange( BluetoothGatt gatt_, int status_, int new_state_ ) {
            super.onConnectionStateChange( gatt_, status_, new_state_ );  //check if the connection is stable
            if( status_ == BluetoothGatt.GATT_FAILURE ) {
                count = 0;
                disconnectGattServer();
                return;
            } else if( status_ != BluetoothGatt.GATT_SUCCESS ) {
                count = 0;
                disconnectGattServer();
                return;
            }
            if( new_state_ == BluetoothProfile.STATE_CONNECTED ) {
                // update the connection status message
                //Tv_status.setText( "Connected" );  //if error occur, then delete this code
                // set the connection flag
                connected_= true;
                Log.d( TAG, "Connected to the GATT server" );
                Log.d(TAG, String.valueOf(connected_)+" first");
                gatt_.discoverServices();  //red line v3 - perm / characteristics ans descriptors를 제공하는 함수
            } else if ( new_state_ == BluetoothProfile.STATE_DISCONNECTED ) {
                count = 0;
                disconnectGattServer();
            }
        }

        // callback function if there is an action about write/read/state change in data

        @Override
        public void onServicesDiscovered( BluetoothGatt gatt_, int status_ ) {
            super.onServicesDiscovered( gatt_, status_ );
            // check if the discovery failed
            if( status_ != BluetoothGatt.GATT_SUCCESS ) {
                Log.e( TAG, "Device service discovery failed, status: " + status_ );
                return;
            }
            // find discovered characteristics
            List<BluetoothGattCharacteristic> matching_characteristics= BluetoothUtils.findBLECharacteristics( gatt_ );
            if( matching_characteristics.isEmpty() ) {
                Log.e( TAG, "Unable to find characteristics" );
                return;
            }
            // log for successful discovery
            Log.d( TAG, "Services discovery is successful" );
            Log.d(TAG, String.valueOf(connected_) + " Second");  //검출에 성공하면 getServices() 함수를 사용하여 remote service를 취득
            Log.d(TAG, String.valueOf(status_));


        }

        @Override
        public void onCharacteristicChanged( BluetoothGatt gatt_, BluetoothGattCharacteristic characteristic_ ) {
            super.onCharacteristicChanged( gatt_, characteristic_ );

            Log.d( TAG, "characteristic changed: " + characteristic_.getUuid().toString() );
            readCharacteristic( characteristic_ );
        }

        @Override
        public void onCharacteristicWrite( BluetoothGatt gatt_, BluetoothGattCharacteristic characteristic_, int status_ ) {
            super.onCharacteristicWrite( gatt_, characteristic_, status_ );
            if( status_ == BluetoothGatt.GATT_SUCCESS ) {
                Log.d( TAG, "Characteristic written successfully" );
                Log.d(TAG, String.valueOf(connected_)+ " third");
                Log.d(TAG, String.valueOf(status_));
            } else {
                Log.e( TAG, "Characteristic write unsuccessful, status: " + status_) ;
                Log.d(TAG, String.valueOf(status_));
                count = 0;
                disconnectGattServer();
            }
        }

        @Override
        public void onCharacteristicRead(BluetoothGatt gatt_, BluetoothGattCharacteristic characteristic_, int status_) {
            super.onCharacteristicRead(gatt_, characteristic_, status_);
            if (status_ == BluetoothGatt.GATT_SUCCESS) {
                Log.d (TAG, "Characteristic read successfully" );
                Log.d(TAG, String.valueOf(connected_)+ "fourth");
                readCharacteristic(characteristic_);
            } else {
                Log.e( TAG, "Characteristic read unsuccessful, status: " + status_);
                // Trying to read from the Time Characteristic? It doesn't have the property or permissions
                // set to allow this. Normally this would be an error and you would want to:
                // disconnectGattServer();
            }
        }

        /*
        Log the value of the characteristic
        @param characteristic
         */
        private void readCharacteristic( BluetoothGattCharacteristic characteristic_ ) {
            byte[] msg= characteristic_.getValue();
            Log.d( TAG, "read: " + msg.toString() );
        }

    }
    ```
    
    ##### 6. disconnect GATT Server
    
    GATT 서버와 연결을 끊습니다.
    
    ```java
    //Disconnect Gatt Server
    public void disconnectGattServer() {
        Log.d( TAG, "Closing Gatt connection" );
        // reset the connection flag
        connected_= false;
        // disconnect and close the gatt
        if( bluetoothGatt != null ) {
            if(count >1)
                count = 0;
            Tv_status.setText(".....");
            bluetoothGatt.disconnect();  //red line v2
            bluetoothGatt.close();  //red line v2
        }
    }
    ```
    
    ##### 7. Scan Call Back
    
    스캔 결과를 반환하는 함수입니다.
    
    ```java
    private class BLEScanCallback extends ScanCallback {
        private Map<String, BluetoothDevice> cb_scan_results_;

        BLEScanCallback(Map<String, BluetoothDevice> _scan_results) {
            cb_scan_results_ = _scan_results;
        }

        //Callback when a BLE advertisement has been found.
        @Override
        public void onScanResult(int callbackType, ScanResult _result) {
            super.onScanResult(callbackType, _result);

            Log.d(TAG, "onScanResult" );
            addScanResult( _result );
        }

        //Callback when batch results are delivered.
        @Override
        public void onBatchScanResults(List<ScanResult> _results) {
            super.onBatchScanResults(_results);
            for( ScanResult result: _results ) {
                addScanResult( result );
            }
        }

        //Callback when scan could not be started.
        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
            Log.e( TAG, "BLE scan failed with code " +errorCode );
        }

        private void addScanResult( ScanResult _result ) {
            // get scanned device
            BluetoothDevice device= _result.getDevice();
            // get scanned device MAC address
            String device_address= device.getAddress();
            // add the device to the result list
            int device_rssi = _result.getRssi();  // add for rssi
            Rssi = device_rssi;
            cb_scan_results_.put( device_address, device );
            // log
            Log.d( TAG, "scan results device: " + device );
            Log.d( TAG, "scan results device rssi: " + Rssi );

            Tv_status.setText( "add scanned device: " + device_address + " / " + Rssi);
        }
    }
    ```
    
    
    ##### etc
    
    OnResume은 BLE 기능을 지원하지 않을 경우 앱 종료 기능입니다.
    
    ```java
    @Override
    protected void onResume() {
        super.onResume();

        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Toast.makeText(this, R.string.ble_not_supported, Toast.LENGTH_SHORT).show();
            finish();
        } //BLE기능을 지원하지 않을 경우 앱 종료
    }
    ```
    
