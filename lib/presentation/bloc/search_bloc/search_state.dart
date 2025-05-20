part of '../../../framework/controller.dart';

/// 목적지 및 출발지 검색 상태를 표현하는 상태 클래스
class SearchState extends Equatable {
  /// 사용자가 선택한 출발지 (문자열)
  final String? searchStartLocation;

  /// 사용자가 선택한 목적지 (문자열)
  final String? searchDestinationLocation;

  /// 사용자가 선택한 목적지의 좌표 (지도 선택 기반)
  final GeoLocation? destinationGeoLocation;

  /// 생성자 - 모든 필드는 선택형
  const SearchState({
    this.searchStartLocation,
    this.searchDestinationLocation,
    this.destinationGeoLocation,
  });

  /// 상태 비교를 위한 Equatable 구현
  @override
  List<Object?> get props => [
    searchStartLocation,
    searchDestinationLocation,
    destinationGeoLocation,
  ];

  /// 상태 복사를 위한 copyWith 메서드
  /// 필요한 값만 변경하고 나머지는 기존 상태 유지
  SearchState copyWith({
    String? searchStartLocation,
    String? searchDestinationLocation,
    GeoLocation? destinationGeoLocation,
  }) {
    return SearchState(
      searchStartLocation: searchStartLocation ?? this.searchStartLocation,
      searchDestinationLocation: searchDestinationLocation ?? this.searchDestinationLocation,
      destinationGeoLocation: destinationGeoLocation ?? this.destinationGeoLocation,
    );
  }
}