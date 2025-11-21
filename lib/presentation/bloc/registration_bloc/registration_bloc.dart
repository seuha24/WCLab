part of '../../../framework/controller.dart';

/// bloc: Event를 받고, State를 바꾸는 중재자-
/// 이벤트를 감지하고, 비즈니스 로직(UseCase호출, API요청 등)을 처리한 뒤 상태 업데이트

/// 출입구 등록을 위한 Bloc 클래스.
/// 사용자의 지도 상 위치 선택과 출입구 등록 요청을 처리한다.
class EntranceRegistrationBloc
    extends Bloc<EntranceRegistrationEvent, EntranceRegistrationState> {
  /// 출입구 등록 UseCase. 서버에 출입구 데이터를 전송하는 역할을 한다.
  final SendCustomStartPointUseCase sendCustomStartPointUseCase;

  /// 카카오 로컬 API Repository (역지오코딩)
  final KakaoRepository kakaoRepository;

  /// Bloc 초기화. 초기 상태 설정 및 이벤트 핸들러 등록.
  EntranceRegistrationBloc({
    required this.sendCustomStartPointUseCase,
    required this.kakaoRepository,
  }) : super(RegistrationInitial()) {
    on<AddressUpdated>(_onAddressUpdated); // 위치 갱신 이벤트 처리
    on<SubmitEntranceData>(_onSubmitEntranceData); // 출입구 등록 이벤트 처리
  }

  /// 현재 선택된 위치(지도에서 사용자가 지정한 좌표)
  NLatLng? _selectedLocation;

  /// 카카오 API를 통해 좌표로부터 도로명 주소를 가져오는 함수
  /// 성공 시 [RegistrationLoaded] 상태로 변경, 실패 시 [RegistrationFailure] 상태로 변경
  Future<void> _onAddressUpdated(
    AddressUpdated event,
    Emitter<EntranceRegistrationState> emit,
  ) async {
    _selectedLocation = event.latLng;
    try {
      final address = await _fetchAddress(event.latLng);
      emit(
          RegistrationLoaded(address: address, selectedLocation: event.latLng));
    } catch (_) {
      emit(RegistrationFailure("주소 요청 오류"));
    }
  }

  /// 출입구 등록 요청을 처리하는 이벤트 핸들러.
  /// 서버로 데이터를 전송하며, 상태를 로딩 및 성공/실패로 업데이트한다.
  Future<void> _onSubmitEntranceData(
    SubmitEntranceData event,
    Emitter<EntranceRegistrationState> emit,
  ) async {
    // 위치 또는 주소가 없는 경우 예외 처리
    if (_selectedLocation == null || state is! RegistrationLoaded) {
      emit(RegistrationFailure("위치 또는 주소 정보가 없습니다."));
      return;
    }

    // 등록 처리 중임을 알리기 위한 상태
    emit(RegistrationLoading());

    // UseCase 실행 및 결과 처리
    final result = await sendCustomStartPointUseCase.call(event.params);

    result.fold(
      (failure) =>
          emit(RegistrationFailure("저장 실패: ${failure.runtimeType}")), // 실패 상태
      (_) => emit(EntranceSubmissionSuccess()), // 성공 상태
    );
  }

  /// 좌표를 기반으로 주소를 요청하는 내부 함수.
  Future<String> _fetchAddress(NLatLng latLng) async {
    final result = await kakaoRepository.getAddressFromCoordinates(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    return result.fold(
      (failure) => "주소를 찾을 수 없습니다",
      (address) => address,
    );
  }
}