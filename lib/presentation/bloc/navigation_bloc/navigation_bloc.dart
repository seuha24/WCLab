import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';
import 'package:safelight/data/services/navigation_api_service.dart';
import 'package:safelight/domain/entities/branch_info.dart';
import 'package:safelight/framework/ui.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// 이 파일은 NavigationBloc을 구현하며, 내비게이션 관련 상태 전환을 관리합니다.
/// Flutter Bloc 아키텍처를 사용하여 비즈니스 로직을 처리합니다.
///
/// 역할:
/// - TMAP API를 사용하여 내비게이션 경로를 가져옵니다 (`LoadPath` 이벤트 처리).
/// - 이동 중 내비게이션 진행 상태를 관리합니다 (`UpdateNavigation` 이벤트 처리).
/// - 작업의 성공 또는 실패에 따라 적절한 상태를 방출합니다.
///
/// 의존성:
/// - TMAP API의 인증 키와 엔드포인트 구성이 필요합니다.
/// - `navigation_event.dart`와 `navigation_state.dart` 파일에 정의된 이벤트와 상태를 사용합니다.
///
/// 처리 이벤트:
/// - `LoadPath`: 내비게이션 경로를 가져오고 경로 및 분기점 정보를 포함한 상태를 업데이트합니다.
/// - `UpdateNavigation`: 이동 중 남은 거리 및 경계 이탈 여부 등을 포함하여 내비게이션 진행 상태를 업데이트합니다.
///
/// 방출 상태:
/// - `NavigationInitial`, `NavigationLoading`, `NavigationReady`, `NavigationInProgress`, `NavigationFailure`.
///
/// 참고:
/// - 이 Bloc은 DI(의존성 주입, 예: GetIt)를 통해 애플리케이션의 메인에 등록해야 합니다.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  late final NavigationApiService apiService;
  late final NavigationService navigationService;

  NavigationBloc(this.apiService, this.navigationService)
      : super(NavigationInitial()) {
    on<InitNavigation>(_onInitNavigation);
    on<CloseNavigation>(_onCloseNavigation);
    on<OnMapReady>(_onMapReady);
    on<StartLoading>((event, emit) => emit(NavigationLoading()));
    on<StopLoading>((event, emit) => emit(NavigationReady()));
    on<SetStartLocation>(_onSetStartLocation);
    on<SetDestinationLocation>(_onSetDestinationLocation);
    on<LoadPath>(_onLoadPath);
    on<UpdateLocationMarker>(_onUpdateLocationMarker);
    on<UpdateMapPosition>(_onUpdateMapPosition);

    /// Service 의 Stream 구독
    ///
    /// Loading Stream
    navigationService.loadingStream.listen((isLoading) {
      if (isLoading) {
        add(StartLoading());
      } else {
        add(StopLoading());
      }
    });

    /// Path Stream
    navigationService.pathStream.listen((data) {
      log('pathStream: $data');
      add(LoadPath(
        startLatitude: data['startLatitude'],
        startLongitude: data['startLongitude'],
        endLatitude: data['endLatitude'],
        endLongitude: data['endLongitude'],
      ));
    });

    /// Location Marker Stream
    navigationService.locationMarkerStream
        .throttleTime(Duration(milliseconds: 200))
        .listen((data) {
      log('locationMarkerStream: $data');
      add(UpdateLocationMarker(
        latitude: data['latitude'],
        longitude: data['longitude'],
        isGps: data['isGps'],
      ));
    });

    /// Map Position Stream
    navigationService.mapPositionStream
        .throttleTime(Duration(milliseconds: 200))
        .listen((data) {
      log('mapPositionStream: $data');
      add(UpdateMapPosition(
        latitude: data['latitude'],
        longitude: data['longitude'],
        compassValue: data['compassValue'],
      ));
    });
  }

  void _onSetStartLocation(
      SetStartLocation event, Emitter<NavigationState> emit) {
    log('_onSetStartLocation: $event');
    navigationService.startSelectedLocation = event.startLocation;
    navigationService.isStart = true;

    emit(StartLocationSet());
  }

  void _onSetDestinationLocation(
      SetDestinationLocation event, Emitter<NavigationState> emit) {
    log('_onSetDestinationLocation: $event');
    navigationService.selectedLocation = event.destinationLocation;

    // 경로 요청을 위해 시작 지점 좌표 설정
    // final startLat = navigationService.isStart
    //     ? navigationService.startSelectedLocation!.lat
    //     : navigationService.finalLatitude;
    // final startLng = navigationService.isStart
    //     ? navigationService.startSelectedLocation!.lng
    //     : navigationService.finalLongitude;
    //
    // // NavigationService를 통해 Bloc에 경로 요청
    // navigationService.requestNewPath(
    //   startLat: startLat,
    //   startLng: startLng,
    //   endLat: event.destinationLocation.lat,
    //   endLng: event.destinationLocation.lng,
    // );


    emit(DestinationLocationSet());
  }

  Future<void> _onLoadPath(
      LoadPath event, Emitter<NavigationState> emit) async {
    log('_onLoadPath: $event');
    emit(NavigationLoading());

    try {
      // API 호출
      final responseData = await apiService.fetchPathData(
        startLatitude: event.startLatitude,
        startLongitude: event.startLongitude,
        endLatitude: event.endLatitude,
        endLongitude: event.endLongitude,
      );

      // 데이터 파싱
      final parsedData = apiService.parsePathData(responseData);
      final paths = parsedData['paths'] as List<LatLng>;
      final branchInfoList = parsedData['branchInfo'] as List<BranchInfo>;

      /// 데이터 로깅
      log('paths: $paths');
      log('branchInfoList: $branchInfoList');

      // 브랜치 정보 업데이트 (각 브랜치 간의 방향 계산)
      for (int i = 0; i < branchInfoList.length - 1; i++) {
        double newBearingValue = navigationService.calculateBearing(
          branchInfoList[i].point.latitude,
          branchInfoList[i].point.longitude,
          branchInfoList[i + 1].point.latitude,
          branchInfoList[i + 1].point.longitude,
        );
        branchInfoList[i].bearingToPoint = newBearingValue;
      }

      // 경로 및 브랜치 정보를 내비게이션 서비스에 업데이트
      navigationService.paths = paths;
      navigationService.branchInfoList = branchInfoList;

      // 내비게이션 타이머 시작
      navigationService.startNavigationTimer();

      // BloC 상태 갱신
      emit(NavigationPathLoaded(paths, branchInfoList));
    } catch (error) {
      // 에러 상태 처리
      emit(NavigationFailure(error.toString()));
    }
  }

  void _onInitNavigation(InitNavigation event, Emitter<NavigationState> emit) {
    log('_onInitNavigation: $event');
    try {
      emit(NavigationLoading()); // 로딩 상태 방출
      navigationService.init(); // NavigationService 초기화 호출
    } catch (e) {
      emit(NavigationFailure(e.toString()));
    }
  }

  void _onCloseNavigation(CloseNavigation event, Emitter<NavigationState> emit) {
    log('_onCloseNavigation: $event');
    navigationService.dispose();
  }

  void _onMapReady(OnMapReady event, Emitter<NavigationState> emit) {
    log('_onMapReady: $event');
    try {
      emit(NavigationLoading());

      // Service에서 초기 데이터 가져오기
      final latitude = navigationService.finalLatitude;
      final longitude = navigationService.finalLongitude;
      final compassValue = navigationService.compassValue;
      final isGps = navigationService.isGps;

      emit(LocationMarkerUpdated(
        latitude: latitude,
        longitude: longitude,
        isGps: isGps,
      ));

      emit(MapPositionUpdated(
        latitude: latitude,
        longitude: longitude,
        compassValue: compassValue,
      ));
    } catch (error) {
      // 오류 발생 상태 방출
      emit(NavigationFailure(error.toString()));
    }
  }

  void _onUpdateLocationMarker(
      UpdateLocationMarker event, Emitter<NavigationState> emit) {
    log('_onUpdateLocationMarker: $event');

    // Location Marker 업데이트
    emit(LocationMarkerUpdated(
      latitude: event.latitude,
      longitude: event.longitude,
      isGps: event.isGps,
    ));
  }

  void _onUpdateMapPosition(
      UpdateMapPosition event, Emitter<NavigationState> emit) {
    log('_onUpdateMapPosition: $event');

    // Map Position 업데이트
    emit(MapPositionUpdated(
      latitude: event.latitude,
      longitude: event.longitude,
      compassValue: event.compassValue,
    ));
  }
}
