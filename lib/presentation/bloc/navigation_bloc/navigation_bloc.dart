import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  NavigationBloc(this.apiService, this.navigationService) : super(NavigationInitial()) {
    on<LoadPath>(_onLoadPath);
    on<UpdateNavigation>(_onUpdateNavigation);

    /// Service의 Stream 구독

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

    /// Navigation Stream
    navigationService.navigationStream.listen((data) {
      log('navigationStream: $data');
      add(UpdateNavigation(
        remainDistance: data['remainDistance'],
        outOfBound: data['outOfBound'],
        currentIndex: data['currentIndex'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        compassValue: data['compassValue'],
        isGps: data['isGps'],
      ));
    });
  }

  late final NavigationApiService apiService;
  late final NavigationService navigationService;
  late final StreamSubscription _sensorSubscription;

  late final StreamSubscription<Position> _positionSubscription;



  // void _subscribeToPositionStream() {
  //   _positionSubscription =
  //       navigationService.positionStream.listen((Position position) {
  //         // 위치 데이터를 기반으로 Bloc 이벤트를 추가
  //         add(UpdateNavigationEvent(
  //           latitude: position.latitude,
  //           longitude: position.longitude,
  //           isGps: position.accuracy <= 10, // GPS 여부를 정확도로 판단
  //           compassValue: 0.0, // 나침반 값은 추후 추가 가능
  //         ));
  //       });
  // }


  Future<void> _onLoadPath(LoadPath event, Emitter<NavigationState> emit) async {
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
      final branchInfo = parsedData['branchInfo'] as List<BranchInfo>;

      /// 데이터 로깅
      // log('paths: $paths');
      // log('branchInfo: $branchInfo');

      // BloC 상태 갱신
      emit(NavigationReady(paths, branchInfo));
    } catch (error) {
      // 에러 상태 처리
      emit(NavigationFailure(error.toString()));
    }
  }

  void _onUpdateNavigation(
      UpdateNavigation event, Emitter<NavigationState> emit) {
    log('_onUpdateNavigation: $event');
    // NavigationInProgress 상태 업데이트
    // emit(NavigationInProgress(
    //   remainDistance: event.remainDistance,
    //   outOfBound: event.outOfBound,
    //   currentIndex: event.currentIndex,
    //   latitude: event.latitude,
    //   longitude: event.longitude,
    //   compassValue: event.compassValue,
    //   isGps: event.isGps,
    // ));
  }
}
