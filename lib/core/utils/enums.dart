part of '../../framework/core.dart';

// 앱 내에서 사용하는 Enum 모음
// 모든 Enum 형 변수는 naming 시 E를 처음 글자로 갖도록 해야한다.
// ignore_for_file: constant_identifier_names

/// [ECrosswalk]는 횡단보도의 타입을 나타내는 [Enum]이다.
///
/// [Crosswalk] 객체의 필드에 필수로 포함되어야 하는 값이며, 해당 횡단보도가 어떤 종류인지를 의미한다.
///
/// ### 포함하는 정보
/// [ECrosswalk]는 아래의 3가지 정보를 나타낸다.
/// - [SINGLE_ROAD] : 단일 신호등 지역, index(0)
/// - [INTERSECTION] : 교차로 지역, index(1)
/// - [FLASH_CROSSING] : 점멸 신호등 지역, index(2)
enum ECrosswalk {
  /// [SINGLE_ROAD]는 단일 신호등 지역을 의미한다.
  ///
  /// 단일 신호등 지역이란, 횡단보도가 하나만 존재하며 단방향으로 나아갈 수 있는 지역을 의미한다.
  /// 일반적인 신호등이 있는 횡단보도가 [SINGLE_ROAD]에 속하게 된다.
  ///
  /// [SINGLE_ROAD]는 [ECrosswalk]에서 0번 인덱스에 위치한다.
  SINGLE_ROAD,

  /// [INTERSECTION]은 교차로 지역을 의미한다.
  ///
  /// 교차로 지역이란, 횡단보도가 하나 이상 존재하며 나아갈 수 있는 방향이 2가지 이상인 지역을 의미한다.
  /// 일반적인 신호등이 있는 교차로 지역이 [INTERSECTION]에 속하게 된다.
  ///
  /// [INTERSECTION]은 [ECrosswalk]에서 1번 인덱스에 위치한다.
  INTERSECTION,

  /// [FLASH_CROSSING]은 점멸 신호등 지역을 의미한다.
  ///
  /// 점멸 신호등 지역이란, [SINGLE_ROAD]와 형태는 동일하나 보행자가 직접 물리적(혹은 SW) 버튼을 눌러야 신호가 변화하는 지역을 의미한다.
  ///
  /// [FLASH_CROSSING]은 [ECrosswalk]에서 2번 인덱스에 위치한다.
  FLASH_CROSSING,

  /// [UNKNOWN]은 알 수 없는 지역을 의미한다.
  ///
  /// 알 수 없는 지역이란, [SINGLE_ROAD], [INTERSECTION], [FLASH_CROSSING] 중 하나로 확인할 수 없는 지역을 의미한다.
  /// 주로, Firebase DB를 통해 확인할 수 없는 지역이 이에 해당한다.
  ///
  /// [UNKNOWN]은 [ECrosswalk]에서 3번 인덱스에 위치한다.
  UNKNOWN,
}

/// [EBlueState]는 블루투스 통신 상태를 나타내는 [Enum]이다.
///
/// 앱 내에 불루트스 검색 및 연결 로직이 동작하게 되는 경우, 현재 동작 상태를 [EBlueState]를 통해 나타낸다.
///
///
/// ### 사용 시점 및 변수 사용 이유
/// [EBlueState]는 현재 디바이스의 블루투스 사용 여부를 판단하지는 않는다.
/// 즉, [EBlueState]는 블루투스 사용이 가능한 상태(Permission clear)일 때 사용하며
/// 블루투스 스캔, 연결 로직이 동작될 때 현재 상태를 나타내어 나타날 수 있는 버그를 최소화하는데 그 목적이 있다.
///
/// ### 포함하는 정보
/// [EBlueState]는 아래의 3가지 정보를 나타낸다.
/// - [ON] : 블루투스 스캔이 동작되고 있는 상태, index(0)
/// - [OFF] : 블루투스 스캔 및 연결이 완료된 상태, index(1)
/// - [CONNECT] : 블루투스 연결이 동작되고 있는 상태, index(2)
///
/// ### 일반적인 State 진행
/// 일반적인 상황에서 블루투스 연결 시 [EBlueState] 변경은 아래와 같이 진행된다.
///
/// *현재 상태를 `EBlueState state` 변수에 저장한다고 가정한다.*
///
/// |state 변수 상태|    |진행|
/// |-------------|----|---|
/// | [OFF]|
/// | [ON]||블루투스 스캔 시작|
/// | [OFF]||블루투스 스캔 종료|
/// | [OFF]||스캔 결과 선택|
/// | [CONNECT]||블루투스 연결 시작|
/// | [OFF]||블루투스 연결 종료|
enum EBlueState {
  /// [ON]은 블루투스 스캔이 동작되고 있는 상태를 나타낸다.
  ///
  /// 블루투스 스캔 로직이 시작될 때 상태를 [ON]으로 변경해주어야 하며, [ON] 상태일 경우 [CONNECT] 상태에서 진행할 수 있는 로직이 수행 불가능하다.
  /// [ON] 상태의 경우, [OFF]로의 전환만 가능하다. 즉, [ON] > [CONNECT] 로의 직접적인 전환은 불가능하다.
  ON,

  /// [OFF]는 블루투스 스캔 및 연결이 종료된 상태를 나타낸다.
  ///
  /// [OFF]상태는 가장 기본적인 상태로 모든 블루투스 로직이 시작될 수 있는 상태를 의미한다.
  /// 블루투스 스캔이 종료되었을 때와 블루투스 연결이 종료되었을 때 상태를 [OFF]로 변경해주어야 하며, [OFF] 상태일 경우 [ON], [CONNECT]로의 전환이 가능하다.
  OFF,

  /// [CONNECT]는 불루투스 연결이 동작되고 있는 상태를 의미한다.
  ///
  /// 블루투스 연결 로직이 시작될 때 상태를 [CONNECT]로 변경해주어야 하며, [CONNECT] 상태일 경우 [ON] 상태로의 직접적인 전환이 불가능하다.
  /// 즉, [CONNECT] > [OFF] 로의 전환만 가능하다.
  CONNECT,
}

/// [EPanelType]은 슬라이딩 패널의 타입을 나타내는 [Enum]이다.
///
/// 메인 뷰에서 하단 네비게이션에 따라 표시되는 패널의 종류를 의미한다.
enum EPanelType {
  /// [none]은 패널이 표시되지 않는 상태를 의미한다.
  none,

  /// [favorite]은 즐겨찾기 패널을 의미한다.
  favorite,

  /// [crosswalk]은 횡단보도 패널을 의미한다.
  crosswalk,

  /// [entrance]은 출입구 등록 패널을 의미한다.
  entrance,

  /// [setting]은 설정 패널을 의미한다.
  setting,
}

/// [EBluetoothServiceType]은 블루투스 서비스 타입을 나타내는 [Enum]이다.
///
/// 음향신호기에서 지원하는 서비스 타입을 구분하여 적절한 통신 방식을 선택할 수 있도록 한다.
///
/// ### 포함하는 정보
/// [EBluetoothServiceType]은 아래의 2가지 정보를 나타낸다.
/// - [UART] : UART 서비스를 통한 데이터 통신, index(0)
/// - [PIN] : PIN 서비스를 통한 제어 통신, index(1)
enum EBluetoothServiceType {
  /// [UART]는 UART 서비스를 통한 데이터 통신을 의미한다.
  ///
  /// 일반적인 데이터 송수신에 사용되며, TX/RX 특성을 통해 통신한다.
  /// 음성 메시지나 음향 메시지 전송에 주로 사용된다.
  UART,

  /// [PIN]은 PIN 서비스를 통한 제어 통신을 의미한다.
  ///
  /// 디바이스의 설정 변경이나 특별한 제어 명령 전송에 사용된다.
  /// PIN 변경이나 디바이스 설정 수정에 주로 사용된다.
  PIN,
}

/// [EBluetoothConnectionMethod]는 음향신호기 연결 방법을 나타내는 [Enum]이다.
///
/// 다양한 음향신호기 구현에 대응하기 위해 여러 연결 방식을 지원한다.
///
/// ### 포함하는 정보
/// [EBluetoothConnectionMethod]는 아래의 3가지 정보를 나타낸다.
/// - [STRICT_UUID] : 엄격한 UUID 검증 기반 연결, index(0)
/// - [FLEXIBLE] : 유연한 연결 (UUID 실패 시 일반 연결), index(1)
/// - [SIMPLE] : 단순 연결 (첫 번째 서비스/특성 사용), index(2)
enum EBluetoothConnectionMethod {
  /// [STRICT_UUID]는 엄격한 UUID 검증 기반 연결을 의미한다.
  ///
  /// 반드시 지정된 서비스 UUID와 특성 UUID를 찾아서 연결한다.
  /// 가장 안전하지만 호환성이 제한될 수 있다.
  STRICT_UUID,

  /// [FLEXIBLE]는 유연한 연결 방식을 의미한다.
  ///
  /// 먼저 UUID 기반 연결을 시도하고, 실패하면 일반 연결로 fallback한다.
  /// 안정성과 호환성의 균형을 제공한다.
  FLEXIBLE,

  /// [SIMPLE]는 단순 연결 방식을 의미한다.
  ///
  /// UUID 검증 없이 첫 번째 서비스와 쓰기 가능한 특성을 사용한다.
  /// 가장 빠르고 호환성이 높지만 안정성이 낮을 수 있다.
  SIMPLE,
}

/// [EBluetoothScanMethod]는 블루투스 스캔 방법을 나타내는 [Enum]이다.
///
/// 다양한 음향신호기 환경에 대응하기 위해 여러 스캔 방식을 지원한다.
///
/// ### 포함하는 정보
/// [EBluetoothScanMethod]는 아래의 3가지 정보를 나타낸다.
/// - [SERVICE_UUID] : 서비스 UUID 기반 스캔, index(0)
/// - [DEVICE_NAME] : 디바이스 이름 기반 스캔, index(1)
/// - [HYBRID] : 두 방식을 모두 활용한 하이브리드 스캔, index(2)
enum EBluetoothScanMethod {
  /// [SERVICE_UUID]는 서비스 UUID를 기반으로 한 스캔을 의미한다.
  ///
  /// 특정 서비스 UUID를 광고하는 디바이스만 탐지한다.
  /// 정확하지만 UUID를 광고하지 않는 디바이스는 놓칠 수 있다.
  SERVICE_UUID,

  /// [DEVICE_NAME]은 디바이스 이름을 기반으로 한 스캔을 의미한다.
  ///
  /// 모든 디바이스를 스캔한 후 이름 패턴으로 필터링한다.
  /// 더 넓은 범위를 커버하지만 스캔 시간이 길어질 수 있다.
  DEVICE_NAME,

  /// [HYBRID]는 두 방식을 모두 활용한 하이브리드 스캔을 의미한다.
  ///
  /// 먼저 서비스 UUID로 스캔하고, 추가로 디바이스 이름으로 스캔한다.
  /// 가장 포괄적이지만 시간이 가장 오래 걸린다.
  HYBRID,
}

/// [EBluetoothMessageType]은 음향신호기로 전송할 메시지 타입을 나타내는 [Enum]이다.
///
/// 규격서에 정의된 명령 프로토콜에 따른 메시지 타입을 구분한다.
///
/// ### 포함하는 정보
/// [EBluetoothMessageType]은 아래의 3가지 정보를 나타낸다.
/// - [LOCATION] : 위치 안내 메시지 유형, index(0)
/// - [ACOUSTIC] : 음향 신호 메시지 유형, index(1)
/// - [VOICE] : 음성 안내 메시지 유형, index(2)
enum EBluetoothMessageType {
  /// [LOCATION]는 위치 안내 메시지 유형을 의미한다.
  ///
  /// 명령 코드: [0x31, 0x00, 0x01]
  /// 현재 위치 안내 메시지 재생을 요청한다.
  LOCATION,

  /// [ACOUSTIC]는 음향 신호 메시지 유형을 의미한다.
  ///
  /// 명령 코드: [0x31, 0x00, 0x02]
  /// 음향 신호(비프음 등) 재생을 요청한다.
  ACOUSTIC,

  /// [VOICE]는 음성 안내 메시지 유형을 의미한다.
  ///
  /// 명령 코드: [0x31, 0x00, 0x03]
  /// 음성 안내 메시지 재생을 요청한다.
  VOICE,
}

/// [EBluetoothMessageType]의 확장 기능을 제공하는 Extension이다.
///
/// 각 메시지 타입에 대응하는 실제 명령 코드를 반환한다.
extension EBluetoothMessageTypeExtension on EBluetoothMessageType {
  /// 메시지 타입에 대응하는 명령 코드를 반환한다.
  ///
  /// ### 반환값
  /// - [LOCATION]: [0x31, 0x00, 0x01]
  /// - [ACOUSTIC]: [0x31, 0x00, 0x02]
  /// - [VOICE]: [0x31, 0x00, 0x03]
  List<int> get commandCode {
    switch (this) {
      case EBluetoothMessageType.LOCATION:
        return [0x31, 0x00, 0x01];
      case EBluetoothMessageType.ACOUSTIC:
        return [0x31, 0x00, 0x02];
      case EBluetoothMessageType.VOICE:
        return [0x31, 0x00, 0x03];
    }
  }
}
