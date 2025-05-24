part of '../../../framework/controller.dart';

abstract class EntranceEvent extends Equatable {
  const EntranceEvent();

  @override
  List<Object?> get props => [];
}

/// 출입구 정보 요청 이벤트
class FetchBuildingEntrances extends EntranceEvent {
  final String address;
  final double longitude;
  final double latitude;

  const FetchBuildingEntrances({
    required this.address,
    required this.longitude,
    required this.latitude,
  });

  @override
  List<Object?> get props => [address, longitude, latitude];
}
/// 출입구 선택 이벤트
class SelectEntrance extends EntranceEvent {
  final double longitude;
  final double latitude;

  const SelectEntrance({
    required this.longitude,
    required this.latitude,
  });

  @override
  List<Object?> get props => [longitude, latitude];
}

