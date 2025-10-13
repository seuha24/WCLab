part of '../../framework/ui.dart';

class MapPanelView extends StatefulWidget {
  const MapPanelView({super.key});

  @override
  State<MapPanelView> createState() => _MapPanelViewState();
}

class _MapPanelViewState extends State<MapPanelView> {
  late DraggableScrollableController _controller;
  late SlidingPanelController _slidingController;
  late MapPanelController _mapPanelController;

  @override
  void initState() {
    super.initState();

    // MapPanelController 초기화 (이미 있으면 재사용)
    if (!Get.isRegistered<MapPanelController>()) {
      _mapPanelController = Get.put(MapPanelController());
    } else {
      _mapPanelController = Get.find<MapPanelController>();
    }

    // DraggableScrollableController 생성
    _controller = DraggableScrollableController();

    // SlidingPanelController 가져오기
    _slidingController = Get.find<SlidingPanelController>();

    // 이미 등록된 패널이 있는지 확인
    final existingController = _slidingController.getDraggableController('map_panel');

    if (existingController != null) {
      // 이미 등록된 컨트롤러가 있으면 재사용
      _controller = existingController;
    } else {
      // 없으면 새로 등록
      _slidingController.registerPanel(
        'map_panel',
        _controller,
        config: const PanelConfig(
          minHeight: 0.0,
          maxHeight: 0.8,
          defaultHeight: 0.4,
          animationDuration: Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    // SlidingPanelController가 관리하므로 여기서 dispose하지 않음
    // 패널 재사용 시 문제가 발생할 수 있음
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.8,
      controller: _controller,
      builder: (context, scrollController) {
        return BlocBuilder<SearchBloc, SearchState>(
          builder: (context, searchState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 드래그 핸들
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 지도 내용
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '경로 안내',
                          style: TextStyle(
                            fontSize: AppSizes.scaledFont(24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(height: 16),
                        _buildSearchInput(
                          context: context,
                          label: '출발지를 입력하세요',
                          value: searchState.searchStartLocation ?? '',
                          onTap: () async {
                            final newStart = await _mapPanelController
                                .openStartLocationSearch(context);
                            await _mapPanelController.handleStartLocationSelection(
                                context, newStart);
                          },
                        ),
                        const Gap(height: 12),
                        _buildSearchInput(
                          context: context,
                          label: '목적지를 입력하세요',
                          value: searchState.searchDestinationLocation ?? '',
                          onTap: () async {
                            final newDest =
                                await _mapPanelController.openDestinationSearch(context);
                            await _mapPanelController.handleDestinationLocationSelection(
                                context, newDest);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchInput({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  fontSize: 16,
                  color: value.isEmpty ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
            Icon(Icons.search, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.route, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
