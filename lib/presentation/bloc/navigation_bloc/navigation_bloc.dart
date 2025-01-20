part of '../../../framework/controller.dart';

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
        .listen((data) {
      log('locationMarkerStream: $data');
      add(UpdateLocationMarker(
        latitude: data['latitude'],
        longitude: data['longitude'],
        compassValue: data['compassValue'],
        isGps: data['isGps'],
      ));
    });

    /// Map Position Stream
    navigationService.mapPositionStream
        .listen((data) {
      log('mapPositionStream: $data');
      add(UpdateMapPosition(
        latitude: data['latitude'],
        longitude: data['longitude'],
        compassValue: data['compassValue'],
        isGps: data['isGps'],
      ));
    });
  }

  // Get Map Data
  Map<String, dynamic> onGetMapData() {
    final latitude = navigationService.finalLatitude;
    final longitude = navigationService.finalLongitude;
    final compassValue = navigationService.compassValue;
    final remainDistance = navigationService.remainDistance;

    return {
      'latitude': latitude,
      'longitude': longitude,
      'compassValue': compassValue,
      'remainDistance': remainDistance,
    };
  }

  // Announce TTS
  Future<void> onSpeakTTS(String message) async {
    await navigationService.speakTTS(message);
  }

  void _onSetStartLocation(
      SetStartLocation event, Emitter<NavigationState> emit) {
    log('_onSetStartLocation: $event');
    navigationService.selectedStartLocation = event.startLocation;
    navigationService.isSetStart = true;

    // 경로 요청을 위해 시작 지점 좌표 설정
    // 목적지 지점이 설정되어 있으면 경로 요청
    if (navigationService.isSetDestination) {
      log(':::목적지가 설정되어 있으므로 경로 요청');
      navigationService.requestNewPath(
        startLat: event.startLocation.lat,
        startLng: event.startLocation.lng,
        endLat: navigationService.selectedDestinationLocation!.lat,
        endLng: navigationService.selectedDestinationLocation!.lng,
      );
    }

    emit(StartLocationSet(event.startLocation));
  }

  void _onSetDestinationLocation(
      SetDestinationLocation event, Emitter<NavigationState> emit) {
    log('_onSetDestinationLocation: $event');
    navigationService.selectedDestinationLocation = event.destinationLocation;
    navigationService.isSetDestination = true;

    // 경로 요청을 위해 시작 지점 좌표 설정
    // 시작 지점이 설정되어 있으면 경로 요청
    if (navigationService.isSetStart) {
      log(':::출발지가 설정되어 있으므로 경로 요청');
      navigationService.requestNewPath(
        startLat: navigationService.selectedStartLocation!.lat,
        startLng: navigationService.selectedStartLocation!.lng,
        endLat: event.destinationLocation.lat,
        endLng: event.destinationLocation.lng,
      );
    }

    emit(DestinationLocationSet(event.destinationLocation));
  }

  Future<void> _onLoadPath(
      LoadPath event, Emitter<NavigationState> emit) async {
    log('_onLoadPath: $event');
    emit(NavigationIdle());

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
      // 주기적으로 Timer를 실행하기 전에 먼저 방향값을 초기화 해준다.
      // branchinfo 배열을 순회하면서 bearingTobranch 값을 변경합니다.
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

  void _onCloseNavigation(
      CloseNavigation event, Emitter<NavigationState> emit) {
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
        compassValue: compassValue,
        isGps: isGps,
      ));

      emit(MapPositionUpdated(
        latitude: latitude,
        longitude: longitude,
        compassValue: compassValue,
        isGps: isGps,
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
      compassValue: event.compassValue,
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
      isGps: event.isGps,
    ));
  }
}
