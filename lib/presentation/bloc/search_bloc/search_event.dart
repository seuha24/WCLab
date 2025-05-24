part of '../../../framework/controller.dart';

/// 검색 관련 이벤트의 추상 클래스 (모든 이벤트의 부모)
abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => []; // Equatable로 비교 가능하게 설정
}

/// 출발지 설정 이벤트
/// 사용자가 출발지를 입력하거나 선택했을 때 발생
class SearchStartLocationRequested extends SearchEvent {
  final String searchLocation; // 출발지 문자열
  final Entrance? entrance; // 선택된 출입구 (건물인 경우)

  SearchStartLocationRequested({
    required this.searchLocation,
    this.entrance,
  });

  @override
  List<Object?> get props => [searchLocation, entrance]; // 비교 시 사용
}

/// 목적지 설정 이벤트
/// 사용자가 목적지를 입력하거나 지도에서 선택했을 때 발생
class SearchDestinationRequested extends SearchEvent {
  final String searchDestination;      // 목적지 문자열
  final GeoLocation? geoLocation;      // 선택된 위치 좌표 (지도 선택 시 사용)
  final Entrance? entrance;            // 선택된 출입구 (건물인 경우)

  SearchDestinationRequested({
    required this.searchDestination,
    this.geoLocation, // null 가능 → 텍스트 검색 결과만 선택 시
    this.entrance,    // 출입구 정보 (건물 선택 시)
  });

  @override
  List<Object?> get props => [searchDestination, geoLocation, entrance];
}