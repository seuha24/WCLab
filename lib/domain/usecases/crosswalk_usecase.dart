part of '../../framework/usecase.dart';

/// 횡단보도를 제어하는 모든 비즈니스 로직의 상위 개념이다.
///
/// 횡단보도의 스마트 압버튼에 대한 검색 및 연결에 대한 제어는 CrosswalkUseCase의 하위 객체(Usecase)를 통해 정의되어야 한다.
/// 블루투스를 활용한 횡단보도의 검색 및 연결, 또는 그 외의 모든 횡단보도와 관련된 핵심 비즈니스 로직은 CrosswalkUseCase의 자식 형태로 상속(Extends)되어야 하며,
/// CrosswalkUseCase는 모든 횡단보도 제어 시스템의 상위 클래스(Super class)로서 위치해야 한다.
///
/// 횡단보도를 제어하는 로직이란 블루투스를 활용한 스마트 압버튼 제어를 의미한다.
/// 단, 블루투스를 이용한 제어가 아니여도 횡단보도와 관련된 로직 중 시스템 내 핵심 기능이라 할 수 있는 로직은 CrosswalkUseCase에 속할 수 있다.
///
/// **Summary :**
///
///   - **DO**
///   구현이 필요한 Interface가 횡단보도 제어와 관련되어 있다면, CrosswalkUseCase를 상속(Extends) 받아야 한다.
///
/// {@macro usecase_warning1}
///
///     ```dart
///     CrosswalkUseCase usecase = SubUsecase(); // Do not use this.
///     ```
///
/// **See also :**
///
///   - 현재 CrosswalkUseCase를 상속받은 Interface는 횡단보도 찾기[SearchCrosswalk], 횡단보도 연결[ConnectCrosswalk]이 있다.
abstract class CrosswalkUseCase {}

/// 횡단보도를 찾는 Usecase 로직들의 Interface이다.
///
/// 횡단보도 찾기와 관련된 [UseCase]는 SearchCrosswalk를 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// {@macro usecase_part1}
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
/// - **DO**
///   구현이 필요한 클래스([UseCase])가 횡단보도 찾기와 관련되어 있다면, SearchCrosswalk를 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
///
/// - **CONSIDER**
///   블루투스 외에도 다른 기술 스택을 사용하여 횡단보도를 찾는 로직이 필요한 경우, SearchCrosswalk를 통한 비즈니스 로직 구현을 고려해야 한다.
abstract class SearchCrosswalk extends CrosswalkUseCase
    implements UseCase<List<Crosswalk>?, NoParams> {}

/// 횡단보도에 연결하는 Usecase 로직들의 Interface이다.
///
/// 횡단보도 연결과 관련된 [UseCase]는 ConnectCrosswalk을 구현(implements)하여야 한다.
/// 해당 Interface를 구현한 하위 클래스는 [UseCase]로서 실질적인 비즈니스 로직으로 사용된다.
///
/// [call] 메소드의 Argument로 `Crosswalk`를 사용하여 연결하고자 하는 횡단보도 객체를 담아야 한다.
///
/// ```dart
/// Crosswalk crosswalk = Crosswalk(); // Crosswalk you want to connect.
/// SomeConnectCrosswalkImpl(crosswalk); // Use call method.
/// ```
///
/// **Summary :**
///
/// {@macro usecase_warning2}
///
///   - **DO**
///   구현이 필요한 클래스([UseCase])가 횡단보도 연결과 관련되어 있다면, ConnectCrosswalk를 구현(Implements)하여야 한다.
///   구현(Implements)을 통해 하위 클래스를 실질적인 비즈니스 로직으로 사용할 수 있다.
///
///   - **CONSIDER :**
///   블루투스 외에도 다른 기술 스택을 사용하여 횡단보도에 연결하는 로직이 필요한 경우,
///   ConnectCrosswalk를 통한 비즈니스 로직 구현을 고려해야 한다.
abstract class ConnectCrosswalk extends CrosswalkUseCase
    implements UseCase<Void, Crosswalk> {}

/// 제한된 시간 내 블루투스를 통한 주변 횡단보도를 검색하는 비즈니스 로직이다.
///
/// Search2FiniteTimes는 수동 스캔 시 사용된다.
/// 수동 스캔이란 1초 동안 주변 횡단보도의 블루투스 압버튼(비콘 포스트)을 스캔하고 그 결과([Crosswalk])를 리스트 형태로 반환하는 것을 의미한다.
/// 해당 로직은 블루투스 스캔, DB에 횡단보도 정보 요청, 사용자 현재 위치 파악을 수행하기 때문에 사용자 권한 요청 및 인터넷 연결이 선행되어야 한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [CrosswalkRepository.getCrosswalkFiniteTimes]를 호출하여 횡단보도 검색을 시도한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **`List<Crosswalk>` :**
///   횡단보도 검색 성공, 검색된 횡단보도([Crosswalk])를 [List]형태로 반환
///
///   - **[BlueFailure] :**
///   블루투스 스캔 실패
///
///   - **[ServerFailure] :**
///   DB를 통한 횡단보도 정보 요청 실패 및 사용자 현재 위치 파악 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   지정된 시간 내(1초) 블루투스를 이용한 주변 횡단보도 스캔이 필요할 경우 Search2FiniteTimes를 사용해야 한다.
///
///   - **DON'T**
///   `블루투스 권한 허가`, `사용자 위치 정보 제공 허가`, `인터넷 연결`이 선행되어 있지 않다면 Search2FiniteTimes를 사용할 수 없다.
class Search2FiniteTimes implements SearchCrosswalk {
  /// 횡단보도 검색을 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [CrosswalkRepository.getCrosswalkFiniteTimes]를 사용되며 횡단보도 검색을 시도한다.
  ///
  /// {@macro usecase_part2}
  final CrosswalkRepository repository;

  /// 블루투스를 통한 주변 횡단보도 검색(수동 스캔) Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// Search2FiniteTimes search2FiniteTimes = Search2FiniteTimes(repository);
  /// ```
  ///
  /// 단, [SearchCrosswalk]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SearchCrosswalk Type.
  /// SearchCrosswalk search2FiniteTimes = Search2FiniteTimes(repository);
  /// ```
  ///
  /// ```dart
  /// // Use DI.
  /// SearchCrosswalk search2FiniteTimes = DI.get<SearchCrosswalk>();
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// Search2FiniteTimes search2FiniteTimes = Search2FiniteTimes(repository); // Do not use this.
  /// SearchCrosswalk search2FiniteTimes = Search2FiniteTimes(repository);
  /// SearchCrosswalk search2FiniteTimes = DI.get<SearchCrosswalk>(); // Best Practice.
  ///
  /// search2FiniteTimes(NoParams()); // Use call method.
  /// ```
  Search2FiniteTimes({required this.repository});

  @override
  Future<Either<Failure, List<Crosswalk>?>> call(NoParams params) async {
    return await repository.getCrosswalkFiniteTimes();
  }
}

/// 무한한 시간동안 주변 횡단보도(비콘 포스트)를 검색하고 즉시 연결하는 비즈니스 로직이다.
///
/// Search2InfiniteTimes는 자동 스캔 시 사용된다.
/// 자동 스캔이란 무한한 시간동안 주변 횡단보도의 블루투스 압버튼(비콘 포스트)을 스캔하고 스캔된 비콘 포스트에 연결 후 유도 신호를 전송하는 로직이다.
/// 해당 로직은 블루투스 스캔 및 연결을 수행하기 때문에 사용자 권한(블루투스) 설정이 선행되어야 한다.
///
/// {@macro usecase_part1}
///
/// [call] 메소드를 통해 [CrosswalkRepository.getCrosswalkInfiniteTimes]를 호출하여
/// 주변 횡단보도의 블루투스 압버튼을 스캔하고 스캔된 비콘 포스트에 즉시 연결한다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **`null` :**
///   주변 횡단보도 검색 및 연결/데이터 전송 성공
///
///   - **[BlueFailure] :**
///   블루투스 스캔 및 연결/데이터 전송 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   무한한 시간 동안 블루투스를 이용한 주변 횡단보도 유도가 필요할 경우 Search2InfiniteTimes를 사용해야 한다.
///
///   - **DON'T**
///   `블루투스 권한 허가`가 선행되어 있지 않다면 Search2InfiniteTimes를 사용할 수 없다.
class Search2InfiniteTimes implements SearchCrosswalk {
  /// 횡단보도 검색 및 유도를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [CrosswalkRepository.getCrosswalkInfiniteTimes]를 사용되며 횡단보도 검색을 시도한다.
  ///
  /// {@macro usecase_part2}
  final CrosswalkRepository repository;

  /// 블루투스를 통한 주변 횡단보도 검색 및 유도(자동 스캔) Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// Search2InfiniteTimes search2InfiniteTimes = Search2InfiniteTimes(repository);
  /// ```
  ///
  /// 단, [SearchCrosswalk]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use SearchCrosswalk Type.
  /// SearchCrosswalk search2InfiniteTimes = Search2InfiniteTimes(repository);
  /// ```
  ///
  /// ```dart
  /// // Use DI.
  /// SearchCrosswalk search2InfiniteTimes = DI.get<SearchCrosswalk>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [NoParams]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// search2InfiniteTimes(NoParams());
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// Search2InfiniteTimes search2InfiniteTimes = Search2InfiniteTimes(repository); // Do not use this.
  /// SearchCrosswalk search2InfiniteTimes = Search2InfiniteTimes(repository);
  /// SearchCrosswalk search2InfiniteTimes = DI.get<SearchCrosswalk>(); // Best Practice.
  ///
  /// search2InfiniteTimes(NoParams()); // Use call method.
  /// ```
  Search2InfiniteTimes({required this.repository});

  @override
  Future<Either<Failure, List<Crosswalk>?>> call(NoParams params) async {
    return await repository.getCrosswalkInfiniteTimes();
  }
}

/// 검색된 횡단보도(비콘 포스트)에 연결 후 유도 신호를 보내는 비즈니스 로직이다.
///
/// SendAcousticSignal는 유도 신호 전송에 사용된다.
/// 해당 로직은 연결 및 데이터 전송을 수행하기 때문에 사용자 권한(블루투스) 설정이 선행되어야 한다.
///
/// 선택된 횡단보도 하나에 유도 신호를 보내기 때문에 사용 시 [call]의 parameter에 [Crosswalk] 객체를 Argument로 넘겨주어야 한다.
///
/// ```dart
/// Crosswalk crosswalk = Crosswalk(...);
///
/// ConnectCrosswalk connectCrosswalk = SendAcousticSignal(); // Create usecase object.
/// connectCrosswalk(crosswalk); // Use call method.
/// ```
///
/// [call] 메소드를 통해 [CrosswalkRepository.sendCommand2Crosswalk]를 호출하여
/// 연결하고자 하는 신호등에 음성 유도 커맨드([0x31, 0x00, 0x02])를 보내게 된다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[Void] :**
///   비콘 포스트 연결 및 음성 유도 커맨드 발송 성공
///
///   - **[BlueFailure] :**
///   블루투스 연결 및 데이터 전송 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   특정 횡단보도에 대한 음성 유도 커맨드 발송 시, SendAcousticSignal를 사용해야 한다. 이때 연결하고자 하는 횡단보도의 비콘 포스트 정보가 있어야 한다.
///
///   - **DON'T**
///   `블루투스 권한 허가`가 선행되어 있지 않다면 SendAcousticSignal를 사용할 수 없다.
class SendAcousticSignal implements ConnectCrosswalk {
  /// 스마트 압버튼에 전송하는 음성 유도 커맨드이다.
  ///
  /// 해당 커맨드를 비콘 포스트에 전송하여 시각장애인에게 현재 횡단보도의 위치를 알려주는 음성 유도 기능을 수행할 수 있다.
  ///
  /// **See also :**
  ///
  ///   - 블루투스 압버튼의 데이터 통신과 관련된 경찰청 제공 프로토콜(2021년 개정)을 따른다.
  final List<int> _command = [0x31, 0x00, 0x02];

  /// 횡단보도 유도를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [CrosswalkRepository.sendCommand2Crosswalk]를 사용되며 유도 신호 발송을 시도한다.
  ///
  /// {@macro usecase_part2}
  CrosswalkRepository repository;

  /// 블루투스를 통한 횡단보도 유도 신호 발송 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SendAcousticSignal sendAcousticSignal = SendAcousticSignal(repository);
  /// ```
  ///
  /// 단, [ConnectCrosswalk]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use ConnectCrosswalk Type.
  /// ConnectCrosswalk sendAcousticSignal = SendAcousticSignal(repository);
  ///
  /// // Use DI.
  /// ConnectCrosswalk sendAcousticSignal = DI.get<ConnectCrosswalk>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [Crosswalk]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// sendAcousticSignal(Crosswalk(...)); // Use call method.
  /// ```
  ///
  /// **Example :**
  ///
  /// ```dart
  /// SendAcousticSignal sendAcousticSignal = SendAcousticSignal(repository); // Do not use this.
  /// ConnectCrosswalk sendAcousticSignal = SendAcousticSignal(repository);
  /// ConnectCrosswalk sendAcousticSignal = DI.get<ConnectCrosswalk>(); // Best Practice.
  ///
  /// sendAcousticSignal(Crosswalk(...)); // Use call method.
  /// ```
  SendAcousticSignal({required this.repository});

  @override
  Future<Either<Failure, Void>> call(Crosswalk params) async {
    return await repository.sendCommand2Crosswalk(params, _command);
  }
}

/// 검색된 횡단보도(비콘 포스트)에 연결 후 압버튼 누르기 신호를 보내는 비즈니스 로직이다.
///
/// SendVoiceInductor는 압버튼 누르기 신호 전송에 사용된다.
/// 해당 로직은 연결 및 데이터 전송을 수행하기 때문에 사용자 권한(블루투스) 설정이 선행되어야 한다.
///
/// 선택된 횡단보도 하나에 압버튼 누르기 신호를 보내기 때문에 사용 시 [call]의 parameter에 [Crosswalk] 객체를 Argument로 넘겨주어야 한다.
///
/// ```dart
/// Crosswalk crosswalk = Crosswalk(...);
///
/// ConnectCrosswalk connectCrosswalk = SendVoiceInductor(); // Create usecase object.
/// connectCrosswalk(crosswalk); // Use call method.
/// ```
///
/// [call] 메소드를 통해 [CrosswalkRepository.sendCommand2Crosswalk]를 호출하여
/// 연결하고자 하는 신호등에 압버튼 누르기 커맨드([0x31, 0x00, 0x01])를 보내게 된다.
///
/// 해당 메소드를 수행하면 아래와 같이 결과가 반환된다.
///
///   - **[Void] :**
///   비콘 포스트 연결 및 압버튼 누르기 커맨드 발송 성공
///
///   - **[BlueFailure] :**
///   블루투스 연결 및 데이터 전송 실패
///
/// **Summary :**
///
///   {@macro usecase_part3}
///
///   - **DO**
///   특정 횡단보도에 대한 압버튼 누르기 커맨드 발송 시, SendVoiceInductor를 사용해야 한다. 이때 연결하고자 하는 횡단보도의 비콘 포스트 정보가 있어야 한다.
///
///   - **DON'T**
///   `블루투스 권한 허가`가 선행되어 있지 않다면 SendVoiceInductor를 사용할 수 없다.
class SendVoiceInductor implements ConnectCrosswalk {
  /// 스마트 압버튼에 전송하는 압버튼 누르기 커맨드이다.
  ///
  /// 해당 커맨드를 전송하여 시각장애인에게 현재 횡단보도의 압버튼을 누르는 압버튼 누르기 기능을 수행할 수 있다.
  ///
  /// **See also :**
  ///
  ///   - 블루투스 압버튼의 데이터 통신과 관련된 경찰청 제공 프로토콜(2021년 개정)을 따른다.
  static const List<int> _command = [0x31, 0x00, 0x01];

  /// 횡단보도 유도를 위한 Repository를 담는 변수로서 외부에서 DI되어 사용된다.
  ///
  /// [call] 메소드 내에서 [CrosswalkRepository.sendCommand2Crosswalk]를 사용되며 압버튼 누르기 신호 발송을 시도한다.
  ///
  /// {@macro usecase_part2}
  CrosswalkRepository repository;

  /// 블루투스를 통한 횡단보도 압버튼 누르기 신호 발송 Usecase를 생성한다.
  ///
  /// 아래와 같이 직접 클래스를 생성하고 의존성을 주입하여 객체를 생성할 수 있다.
  ///
  /// ```dart
  /// SendVoiceInductor sendVoiceInductor = SendVoiceInductor(repository);
  /// ```
  ///
  /// 단, [ConnectCrosswalk]을 변수형으로 선언하고, 되도록 외부에서 의존성을 주입하는 방식을 권장한다.
  ///
  /// ```dart
  /// // Use ConnectCrosswalk Type.
  /// ConnectCrosswalk sendVoiceInductor = SendVoiceInductor(repository);
  ///
  /// // Use DI.
  /// ConnectCrosswalk sendVoiceInductor = DI.get<ConnectCrosswalk>();
  /// ```
  ///
  /// 객체의 생성이 끝난 경우 아래의 방법으로 [call] 메소드를 호출한다.
  /// 이때 argument는 [Crosswalk]이므로 아래와 같이 사용한다.
  ///
  /// ```dart
  /// sendVoiceInductor(Crosswalk(...)); // Use call method.
  /// ```
  ///
  /// 아래는 위 과정에 대한 전문이다.
  /// ```dart
  /// SendVoiceInductor sendVoiceInductor = SendVoiceInductor(repository); // Do not use this.
  /// ConnectCrosswalk sendVoiceInductor = SendVoiceInductor(repository);
  /// ConnectCrosswalk sendVoiceInductor = DI.get<ConnectCrosswalk>(); // Best Practice.
  ///
  /// sendVoiceInductor(Crosswalk(...)); // Use call method.
  /// ```
  SendVoiceInductor({required this.repository});

  @override
  Future<Either<Failure, Void>> call(Crosswalk params) async {
    return await repository.sendCommand2Crosswalk(params, _command);
  }
}
