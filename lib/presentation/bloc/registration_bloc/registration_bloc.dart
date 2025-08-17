part of '../../../framework/controller.dart';

/// bloc: Event를 받고, State를 바꾸는 중재자-
/// 이벤트를 감지하고, 비즈니스 로직(UseCase호출, API요청 등)을 처리한 뒤 상태 업데이트

/// 출입구 등록을 위한 Bloc 클래스.
/// 사용자의 지도 상 위치 선택과 출입구 등록 요청을 처리한다.
class EntranceRegistrationBloc
    extends Bloc<EntranceRegistrationEvent, EntranceRegistrationState> {
  /// 출입구 등록 UseCase. 서버에 출입구 데이터를 전송하는 역할을 한다.
  final SendCustomStartPointUseCase sendCustomStartPointUseCase;

  /// Bloc 초기화. 초기 상태 설정 및 이벤트 핸들러 등록.
  EntranceRegistrationBloc({required this.sendCustomStartPointUseCase})
      : super(RegistrationInitial()) {
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

  /// 좌표를 기반으로 도로명 주소를 요청하는 내부 함수.
  /// 도로명 주소가 없거나 오류가 발생할 경우 기본 메시지를 반환한다.
  Future<String> _fetchAddress(NLatLng latLng) async {
    final url =
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=${latLng.longitude}&y=${latLng.latitude}';
    debugPrint('\n=== 카카오 API 요청 ===');
    debugPrint('요청 URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'KakaoAK 93848fcc11798c6f48099dd2e2373263'},
    );

    final jsonResponse = jsonDecode(response.body);
    debugPrint('\n=== 카카오 API 응답 ===');
    debugPrint('전체 응답: ${jsonEncode(jsonResponse)}');

    final docs = jsonResponse['documents'];
    debugPrint('\n문서 개수: ${docs.length}');

    if (docs.isNotEmpty) {
      final roadAddress = docs[0]['road_address']?['address_name'];

      if (roadAddress != null && roadAddress.isNotEmpty) {
        debugPrint('\n도로명 주소 찾음: $roadAddress');
        debugPrint('현재 위치: 위도 ${latLng.latitude}, 경도 ${latLng.longitude}');
        return roadAddress;
      }

      debugPrint('\n도로명 주소를 찾을 수 없음');
      debugPrint('현재 위치: 위도 ${latLng.latitude}, 경도 ${latLng.longitude}');
      return "도로명 주소 없음";
    }

    debugPrint('\n문서가 없음');
    return "주소를 찾을 수 없습니다";
  }
}