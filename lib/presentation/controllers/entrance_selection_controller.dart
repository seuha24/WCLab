part of '../../framework/controller.dart';

/// 출입구 선택 패널을 제어하는 Controller
class EntranceSelectionController extends GetxController {
  /// SlidingPanelController
  late SlidingPanelController slidingController;

  /// 선택된 출입구
  final Rxn<Entrance> selectedEntrance = Rxn<Entrance>();

  /// 건물 응답 데이터
  final BuildingResponse buildingResponse;

  /// 출입구 선택 콜백
  final Function(Entrance) onEntranceSelected;

  EntranceSelectionController({
    required this.buildingResponse,
    required this.onEntranceSelected,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// 컨트롤러를 초기화합니다
  void _initializeController() {
    slidingController = Get.find<SlidingPanelController>();

    // 출입구 선택 패널을 표시합니다
    slidingController.showEntranceSelectionPanel();
  }

  /// 출입구를 선택합니다
  void selectEntrance(Entrance entrance) {
    selectedEntrance.value = entrance;
    onEntranceSelected(entrance);

    // 선택 후 패널을 접습니다
    slidingController.collapseSlidingBar('entrance_selection_panel');
  }

  /// 출입구가 있는지 확인합니다
  bool get hasEntrances => buildingResponse.entrances.isNotEmpty;

  /// 출입구 목록을 반환합니다
  List<Entrance> get entrances => buildingResponse.entrances;

  /// 건물 이름을 반환합니다
  String get buildingName => buildingResponse.buildingName;
}
