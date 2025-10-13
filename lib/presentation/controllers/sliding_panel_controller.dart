part of '../../framework/controller.dart';

/// 패널 설정 클래스
class PanelConfig {
  final double minHeight;
  final double maxHeight;
  final double defaultHeight;
  final Duration animationDuration;
  final Curve animationCurve;

  const PanelConfig({
    this.minHeight = 0.0,
    this.maxHeight = 1.0,
    this.defaultHeight = 0.4,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });
}

class SlidingPanelController extends GetxController {
  /// 현재 활성화된 패널 ID를 추적하는 observable
  final RxString activePanelId = ''.obs;

  /// 각 화면별로 독립적인 DraggableScrollableController 관리
  final Map<String, DraggableScrollableController> _controllers = {};

  /// 패널 상태를 추적하는 Map (0.0 ~ 1.0)
  final Map<String, double> _panelStates = {};

  /// 패널 타입별 기본 설정
  final Map<String, PanelConfig> _panelConfigs = {};

  /// 특정 화면의 컨트롤러와 설정을 함께 등록
  void registerPanel(
    String screenTag,
    DraggableScrollableController controller, {
    PanelConfig? config,
  }) {
    _controllers[screenTag] = controller;
    _panelStates[screenTag] = 0.0;
    _panelConfigs[screenTag] = config ?? const PanelConfig();

    // 컨트롤러 리스너 추가
    controller.addListener(() {
      _panelStates[screenTag] = controller.size;
    });
  }

  /// 패널이 등록되어 있지 않으면 자동으로 등록합니다
  DraggableScrollableController getOrCreatePanel(
    String screenTag, {
    PanelConfig? config,
  }) {
    if (!_controllers.containsKey(screenTag)) {
      final controller = DraggableScrollableController();
      registerPanel(screenTag, controller, config: config);
    }
    return _controllers[screenTag]!;
  }

  /// 특정 화면의 컨트롤러 가져오기
  DraggableScrollableController? getDraggableController(String screenTag) {
    return _controllers[screenTag];
  }

  /// 패널을 활성화하고 특정 높이로 애니메이션
  void showPanel(String panelId, {double? height}) {
    activePanelId.value = panelId;

    final controller = _controllers[panelId];
    final config = _panelConfigs[panelId];

    if (controller != null && config != null) {
      final targetHeight = height ?? config.defaultHeight;
      final clampedHeight =
          targetHeight.clamp(config.minHeight, config.maxHeight);

      // 컨트롤러가 아직 attached 되지 않았을 수 있으므로
      // 다음 프레임까지 기다린 후 애니메이션 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // 컨트롤러가 여전히 유효한지 재확인
          if (_controllers[panelId] != null) {
            controller
                .animateTo(
              clampedHeight,
              duration: config.animationDuration,
              curve: config.animationCurve,
            )
                .catchError((error) {
              // animateTo가 실패하면 로그만 남기고 앱이 크래시되지 않도록 함
              print('Failed to show panel $panelId: $error');
              return 0.0;
            });
          }
        } catch (e) {
          print('Failed to show panel $panelId: $e');
        }
      });
    }
  }

  /// 패널을 특정 높이로 애니메이션
  void animatePanelTo(String screenTag, double height) {
    final controller = _controllers[screenTag];
    final config = _panelConfigs[screenTag];

    if (controller != null && config != null) {
      final targetHeight = height.clamp(config.minHeight, config.maxHeight);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (_controllers[screenTag] != null) {
            controller
                .animateTo(
              targetHeight,
              duration: config.animationDuration,
              curve: config.animationCurve,
            )
                .catchError((error) {
              print('Failed to animate panel $screenTag: $error');
              return 0.0;
            });
          }
        } catch (e) {
          print('Failed to animate panel $screenTag: $e');
        }
      });
    }
  }

  /// 특정 화면의 슬라이딩바를 40% 높이로 올리는 메서드
  void expandSlidingBar(String screenTag) {
    showPanel(screenTag, height: 0.4);
  }

  /// 출입구 선택 패널을 표시하는 메서드
  void showEntranceSelectionPanel() {
    showPanel('entrance_selection_panel', height: 0.4);
  }

  /// 지도 패널을 표시하는 메서드
  void showMapPanel() {
    showPanel('map_panel', height: 0.4);
  }

  /// 특정 화면의 슬라이딩바를 완전히 내리는 메서드
  void collapseSlidingBar(String screenTag) {
    final controller = _controllers[screenTag];
    final config = _panelConfigs[screenTag];

    if (controller != null && config != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (_controllers[screenTag] != null) {
            controller
                .animateTo(
              config.minHeight,
              duration: config.animationDuration,
              curve: config.animationCurve,
            )
                .catchError((error) {
              print('Failed to collapse panel $screenTag: $error');
              return 0.0;
            });
          }
        } catch (e) {
          print('Failed to collapse panel $screenTag: $e');
        }
      });
    }
  }

  /// 패널을 기본 높이로 확장
  void expandPanel(String screenTag) {
    final config = _panelConfigs[screenTag];
    if (config != null) {
      animatePanelTo(screenTag, config.defaultHeight);
    }
  }

  /// 패널을 최대 높이로 확장
  void expandPanelToMax(String screenTag) {
    final config = _panelConfigs[screenTag];
    if (config != null) {
      animatePanelTo(screenTag, config.maxHeight);
    }
  }

  /// 패널 상태 가져오기
  double getPanelState(String screenTag) {
    return _panelStates[screenTag] ?? 0.0;
  }

  /// 패널이 열려있는지 확인
  bool isPanelExpanded(String screenTag) {
    final state = _panelStates[screenTag] ?? 0.0;
    final config = _panelConfigs[screenTag];
    if (config != null) {
      return state > config.minHeight;
    }
    return state > 0.0;
  }

  /// 모든 패널 접기
  void collapseAllPanels() {
    for (String screenTag in _controllers.keys) {
      collapseSlidingBar(screenTag);
    }
    activePanelId.value = '';
  }

  /// 특정 화면의 컨트롤러 제거
  void removeController(String screenTag) {
    _controllers.remove(screenTag);
    _panelStates.remove(screenTag);
    _panelConfigs.remove(screenTag);

    // 현재 활성화된 패널이 제거된 경우 activePanelId 초기화
    if (activePanelId.value == screenTag) {
      activePanelId.value = '';
    }
  }

  /// BottomNavigationBar 변경 시 패널 초기화
  void clearActivePanel() {
    activePanelId.value = '';
  }

  @override
  void onClose() {
    // 모든 컨트롤러 정리
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _panelStates.clear();
    _panelConfigs.clear();
    super.onClose();
  }
}
