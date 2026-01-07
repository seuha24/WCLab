import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:safelight/data/services/tts_service.dart';

// Domain Layer
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';

// Data Layer
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';

// Framework
import 'package:safelight/framework/ui.dart'; // SignInView, AuthBloc 등
import 'package:safelight/framework/core.dart'; // TTS, Message
import 'package:safelight/framework/controller.dart';
import 'package:safelight/injection.dart'; // DI

// Widgets & Utils
import 'package:safelight/presentation/widgets/gap.dart';
import 'package:safelight/core/utils/app_sizes.dart';

// Presentation
import 'package:safelight/presentation/views/favorite_views/favorite_point_add_panel_view.dart';
import 'package:safelight/presentation/views/favorite_views/favorite_point_edit_panel_view.dart';
import 'package:safelight/presentation/views/favorite_views/favorite_route_add_panel_view.dart';
import 'package:safelight/presentation/views/favorite_views/favorite_route_edit_panel_view.dart';

// 즐겨찾기 패널 상태 enum
enum FavoritePanelState {
  main, // 메인 화면 (지점/경로 목록)
  pointAdd, // 지점 추가
  pointEdit, // 지점 편집
  routeAdd, // 경로 추가
  routeEdit, // 경로 편집
}

class FavoriteMainPanelView extends StatefulWidget {
  const FavoriteMainPanelView({super.key});

  @override
  State<FavoriteMainPanelView> createState() => _FavoriteMainPanelViewState();
}

class _FavoriteMainPanelViewState extends State<FavoriteMainPanelView> {
  final tts = DI.get<TtsService>();
  final message = DI.get<Message>();
  final AuthService _authService = AuthService();

  late DraggableScrollableController _controller;
  late SlidingPanelController _slidingController;
  late MapPanelController _mapPanelController;

  // 현재 패널 상태 관리
  FavoritePanelState _currentState = FavoritePanelState.main;

  // 즐겨찾기 데이터 관리
  List<FavoritePoint> _favoritePoints = [];
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _isLoadingFavorites = false;
  bool _isUserLoggedIn = false;

  // 편집할 아이템 저장
  FavoritePoint? _editingPoint;
  FavoriteRoute? _editingRoute;

  // UseCase 의존성
  late GetFavoritePoints _getFavoritePoints;
  late GetFavoriteRoutes _getFavoriteRoutes;
  late DeleteFavoritePoint _deleteFavoritePoint;
  late DeleteFavoriteRoute _deleteFavoriteRoute;

  @override
  void initState() {
    super.initState();
    _initializeUseCases();
    _controller = DraggableScrollableController();
    _slidingController = Get.find<SlidingPanelController>();
    _mapPanelController = Get.find<MapPanelController>();

    _slidingController.registerPanel(
      'favorite_panel',
      _controller,
      config: PanelConfig(
        minHeight: 0.0,
        maxHeight: 0.8,
        defaultHeight: 0.4,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
      ),
    );

    // 초기 데이터 로드
    _checkAuthState();
    _loadFavorites();
  }

  void _initializeUseCases() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository =
        FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);

    _getFavoritePoints = GetFavoritePoints(repository);
    _getFavoriteRoutes = GetFavoriteRoutes(repository);
    _deleteFavoritePoint = DeleteFavoritePoint(repository);
    _deleteFavoriteRoute = DeleteFavoriteRoute(repository);
  }

  /// 사용자 인증 상태를 확인하는 메서드
  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isUserLoggedIn = user != null && !user.isAnonymous;
    });
  }

  /// 로그인 페이지로 이동하는 메서드
  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignInView()),
    );
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        setState(() {
          _isUserLoggedIn = false;
        });
        return;
      }

      setState(() {
        _isUserLoggedIn = true;
      });

      // 인증 정보 가져오기
      var credentials = await _authService.getFavoriteCredentials(user: user);

      // 서버 ID가 없으면 AuthBloc 통해 조회
      if (credentials == null) {
        if (!mounted) return;
        final serverUserId = await _authService.ensureServerUserId(
          authBloc: context.read<AuthBloc>(),
        );
        if (serverUserId == null) return;

        credentials = await _authService.getFavoriteCredentials(user: user);
        if (credentials == null) return;
      }

      // 지점 목록 로드
      final pointsResult = await _getFavoritePoints.call(
        GetFavoritePointsParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
        ),
      );

      pointsResult.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _favoritePoints = [];
            });
            // 캐시 초기화
            DI.get<LocationAnnouncementController>().updateFavoritePointsCache([]);
          }
        },
        (points) {
          if (mounted) {
            setState(() {
              _favoritePoints = points;
            });
            // LocationAnnouncementController 캐시 업데이트
            DI.get<LocationAnnouncementController>().updateFavoritePointsCache(points);
          }
        },
      );

      // 경로 목록 로드
      final routesResult = await _getFavoriteRoutes.call(
        GetFavoriteRoutesParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
        ),
      );

      routesResult.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _favoriteRoutes = [];
            });
          }
        },
        (routes) {
          if (mounted) {
            setState(() {
              _favoriteRoutes = routes;
            });
          }
        },
      );
    } catch (e) {
      // 에러 시 빈 목록
      if (mounted) {
        setState(() {
          _favoritePoints = [];
          _favoriteRoutes = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 패널 컨트롤러 정리: Map에서 제거하여 다음 mount 시 새로 등록되도록 함
    _slidingController.removeController('favorite_panel');
    _controller.dispose();
    super.dispose();
  }

  /// 패널 상태를 변경하는 메서드
  void _changeState(FavoritePanelState newState) {
    setState(() {
      _currentState = newState;
    });
  }

  /// 메인 화면으로 돌아가는 메서드
  void _navigateToMain() {
    _changeState(FavoritePanelState.main);
    _editingPoint = null;
    _editingRoute = null;
  }

  /// 지점 추가 화면으로 이동하는 메서드
  void _navigateToPointAdd() {
    _changeState(FavoritePanelState.pointAdd);
  }

  /// 지점 편집 화면으로 이동하는 메서드
  void _navigateToPointEdit(FavoritePoint point) {
    _editingPoint = point;
    _changeState(FavoritePanelState.pointEdit);
  }

  /// 경로 추가 화면으로 이동하는 메서드
  void _navigateToRouteAdd() {
    _changeState(FavoritePanelState.routeAdd);
  }

  /// 경로 편집 화면으로 이동하는 메서드
  void _navigateToRouteEdit(FavoriteRoute route) {
    _editingRoute = route;
    _changeState(FavoritePanelState.routeEdit);
  }

  /// 저장/수정 성공 후 콜백
  void _onSaveSuccess() {
    _navigateToMain();
    _loadFavorites(); // 목록 새로고침
  }

  /// 지점 삭제
  Future<void> _deletePoint(FavoritePoint point) async {
    if (point.favIdx == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지점 삭제'),
        content: Text('\'${point.name}\' 지점을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 인증 정보 가져오기
      var credentials = await _authService.getFavoriteCredentials(user: user);

      // 서버 ID가 없으면 AuthBloc 통해 조회
      if (credentials == null) {
        if (!mounted) return;
        final serverUserId = await _authService.ensureServerUserId(
          authBloc: context.read<AuthBloc>(),
        );
        if (serverUserId == null) return;

        credentials = await _authService.getFavoriteCredentials(user: user);
        if (credentials == null) return;
      }

      final result = await _deleteFavoritePoint.call(
        DeleteFavoritePointParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
          favIdx: point.favIdx!,
        ),
      );

      result.fold(
        (failure) {
          if (mounted) _loadFavorites();
        },
        (success) {
          if (mounted) _loadFavorites();
        },
      );
    } catch (e) {
      if (mounted) _loadFavorites();
    }
  }

  /// 경로 삭제
  Future<void> _deleteRoute(FavoriteRoute route) async {
    if (route.favIdx == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경로 삭제'),
        content: Text('\'${route.name}\' 경로를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 인증 정보 가져오기
      var credentials = await _authService.getFavoriteCredentials(user: user);

      // 서버 ID가 없으면 AuthBloc 통해 조회
      if (credentials == null) {
        if (!mounted) return;
        final serverUserId = await _authService.ensureServerUserId(
          authBloc: context.read<AuthBloc>(),
        );
        if (serverUserId == null) return;

        credentials = await _authService.getFavoriteCredentials(user: user);
        if (credentials == null) return;
      }

      final result = await _deleteFavoriteRoute.call(
        DeleteFavoriteRouteParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
          favIdx: route.favIdx!,
        ),
      );

      result.fold(
        (failure) {
          if (mounted) _loadFavorites();
        },
        (success) {
          if (mounted) _loadFavorites();
        },
      );
    } catch (e) {
      if (mounted) _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.8,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(height: 16),

              // 즐겨찾기 내용 영역
              Expanded(
                child: _buildCurrentStateWidget(scrollController),
              )
            ],
          ),
        );
      },
    );
  }

  /// 현재 상태에 따라 적절한 위젯을 반환하는 메서드
  Widget _buildCurrentStateWidget(ScrollController scrollController) {
    switch (_currentState) {
      case FavoritePanelState.main:
        return _buildMainView(scrollController);
      case FavoritePanelState.pointAdd:
        return FavoritePointAddPanelView(
          scrollController: scrollController,
          onNavigateBack: _navigateToMain,
          onSaveSuccess: _onSaveSuccess,
        );
      case FavoritePanelState.pointEdit:
        return _editingPoint != null
            ? FavoritePointEditPanelView(
                scrollController: scrollController,
                favoritePoint: _editingPoint!,
                onNavigateBack: _navigateToMain,
                onSaveSuccess: _onSaveSuccess,
              )
            : _buildMainView(scrollController);
      case FavoritePanelState.routeAdd:
        return FavoriteRouteAddPanelView(
          scrollController: scrollController,
          onNavigateBack: _navigateToMain,
          onSaveSuccess: _onSaveSuccess,
        );
      case FavoritePanelState.routeEdit:
        return _editingRoute != null
            ? FavoriteRouteEditPanelView(
                scrollController: scrollController,
                favoriteRoute: _editingRoute!,
                onNavigateBack: _navigateToMain,
                onSaveSuccess: _onSaveSuccess,
              )
            : _buildMainView(scrollController);
    }
  }

  /// 메인 화면 UI 구성 (지점/경로 목록)
  Widget _buildMainView(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // 제목
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  color: Colors.grey[700],
                  size: AppSizes.scaledFont(24),
                ),
                const Gap(width: 8),
                Text(
                  '즐겨찾기',
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (_isLoadingFavorites)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const Gap(height: 16),

        // 비로그인 상태일 때 로그인 버튼 표시
        if (!_isUserLoggedIn) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const Gap(height: 12),
                Text(
                  '장소와 경로를 저장하여 사용하세요.',
                  style: TextStyle(
                    fontSize: AppSizes.scaledFont(16),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD333),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '로그인하기',
                          style: TextStyle(
                            fontSize: AppSizes.scaledFont(18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 로그인된 상태일 때만 지점/경로 추가 버튼 표시
          // 지점 추가 버튼
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _navigateToPointAdd,
              icon: Icon(Icons.add_location, color: Colors.white, size: 20),
              label: Text(
                '지점 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAD96E4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // 경로 추가 버튼
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: _navigateToRouteAdd,
              icon: Icon(Icons.route, color: Colors.white, size: 20),
              label: Text(
                '경로 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD333),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // 즐겨찾기 지점 섹션
          if (_favoritePoints.isNotEmpty) ...[
            Text(
              '즐겨찾기 목록',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(18),
                fontWeight: FontWeight.w800,
                color: Colors.grey[600],
              ),
            ),
            const Gap(height: 12),
            ..._favoritePoints.map((point) => _buildPointItem(point)),
            const Gap(height: 16),
          ],

          // 즐겨찾기 경로 섹션
          if (_favoriteRoutes.isNotEmpty) ...[
            Text(
              '저장된 경로',
              style: TextStyle(
                fontSize: AppSizes.scaledFont(18),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const Gap(height: 12),
            ..._favoriteRoutes.map((route) => _buildRouteItem(route)),
          ],

          // 빈 상태 표시 (로그인된 상태에서만)
          if (_favoritePoints.isEmpty &&
              _favoriteRoutes.isEmpty &&
              !_isLoadingFavorites)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                '저장된 즐겨찾기가 없습니다.',
                style: TextStyle(
                  fontSize: AppSizes.scaledFont(14),
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }

  /// 지점 아이템 UI
  Widget _buildPointItem(FavoritePoint point) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(Icons.location_on, color: Colors.blue[600], size: 20),
        ),
        title: Text(
          point.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '위도: ${point.latitude.toStringAsFixed(6)}, 경도: ${point.longitude.toStringAsFixed(6)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        onTap: () => _mapPanelController.startNavigationWithFavoritePoint(
          context,
          point,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
              tooltip: '${point.name} 수정',
              onPressed: () => _navigateToPointEdit(point),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
              tooltip: '${point.name} 삭제',
              onPressed: () => _deletePoint(point),
            ),
          ],
        ),
      ),
    );
  }

  /// 경로 아이템 UI
  Widget _buildRouteItem(FavoriteRoute route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: Icon(Icons.route, color: Colors.green[600], size: 20),
        ),
        title: Text(
          route.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '출발지 → 목적지${route.stopovers.isNotEmpty ? ' (경유지 ${route.stopovers.length}개)' : ''}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        onTap: () => _mapPanelController.startNavigationWithFavoriteRoute(
          context,
          route,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
              tooltip: '${route.name} 수정',
              onPressed: () => _navigateToRouteEdit(route),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
              tooltip: '${route.name} 삭제',
              onPressed: () => _deleteRoute(route),
            ),
          ],
        ),
      ),
    );
  }
}
