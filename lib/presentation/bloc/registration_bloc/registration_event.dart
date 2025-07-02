
part of '../../../framework/controller.dart';

/// event: 사용자의 의도/행동을 표현하는 클래스

/// 출입구 등록과 관련된 Bloc 이벤트의 추상 클래스.
/// 모든 출입구 등록 이벤트 클래스들은 이 클래스를 상속받아 정의됨.
abstract class EntranceRegistrationEvent {}

/// 지도에서 사용자가 위치를 선택하거나 카메라 이동이 멈췄을 때 발생하는 이벤트.
/// 이 이벤트를 통해 선택된 좌표(latLng)를 기반으로 주소를 요청하게 됨.

/// [latLng] : 사용자가 지도에서 선택한 좌표 (위도, 경도)
class AddressUpdated extends EntranceRegistrationEvent {
  final NLatLng latLng;
  AddressUpdated(this.latLng);
}

/// 출입구 등록을 서버에 요청할 때 사용하는 이벤트.
/// 사용자가 입력한 건물 정보와 출입구 정보를 포함하여 서버 전송용 데이터를 전달함.

class SubmitEntranceData extends EntranceRegistrationEvent {
  final SendPointParams params;

  SubmitEntranceData(this.params);
}
