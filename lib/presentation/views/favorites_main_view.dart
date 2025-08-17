import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';
import 'package:safelight/presentation/views/favorite_point_add_view.dart';
import 'package:safelight/presentation/views/favorite_route_add_view.dart';
import 'package:safelight/framework/controller.dart';

class FavoritesMainView extends StatefulWidget {
  const FavoritesMainView({super.key});

  @override
  State<FavoritesMainView> createState() => _FavoritesMainViewState();
}

class _FavoritesMainViewState extends State<FavoritesMainView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  // UseCase
  late GetFavoritePoints _getFavoritePoints;
  late GetFavoriteRoutes _getFavoriteRoutes;
  
  // 상태 변수
  List<FavoritePoint> _favoritePoints = [];
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUseCases();
    _loadFavorites();
  }
  
  void _initializeUseCases() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository = FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);
    
    _getFavoritePoints = GetFavoritePoints(repository);
    _getFavoriteRoutes = GetFavoriteRoutes(repository);
  }
  
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 사용자 정보 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }
      
      // authType 가져오기 (누락된 경우 Firebase provider로 판단)
      AuthType authType = await _authService.loadAuthType();
      
      // authType이 anonymous(기본값)이면 Firebase provider로 판단
      if (authType == AuthType.anonymous) {
        final providerData = user.providerData;
        if (providerData.isNotEmpty) {
          final providerId = providerData.first.providerId;
          if (providerId == 'google.com') {
            authType = AuthType.google;
            await _authService.saveAuthType(authType: AuthType.google);
          } else if (providerId == 'apple.com') {
            authType = AuthType.apple;
            await _authService.saveAuthType(authType: AuthType.apple);
          }
        }
      }
      
      final loginMethod = authType == AuthType.google ? 'google' : 'apple';
      
      // 서버 UUID 가져오기
      String? serverUserId = await _authService.loadServerUserId();
      
      // 서버 ID가 없으면 /user/me API 호출하여 가져오기
      if (serverUserId == null) {
        // GetUserInfoEvent를 호출하여 서버 ID 가져오기
        if (!mounted) return;
        context.read<AuthBloc>().add(GetUserInfoEvent());
        
        // 잠시 대기 후 다시 시도
        await Future.delayed(const Duration(seconds: 1));
        serverUserId = await _authService.loadServerUserId();
        
        if (serverUserId == null) {
          setState(() {
            _errorMessage = '사용자 정보를 가져올 수 없습니다.';
            _isLoading = false;
          });
          return;
        }
      }
      
      final userId = serverUserId; // 서버 UUID 사용
      
      // 즐겨찾기 지점 가져오기
      final pointsResult = await _getFavoritePoints.call(
        GetFavoritePointsParams(
          loginMethod: loginMethod,
          userId: userId,
        ),
      );
      
      pointsResult.fold(
        (failure) {
          debugPrint('지점 조회 실패: $failure');
          _favoritePoints = []; // 빈 리스트로 설정
        },
        (points) => _favoritePoints = points,
      );
      
      // 즐겨찾기 경로 가져오기 (실패해도 지점은 표시)
      final routesResult = await _getFavoriteRoutes.call(
        GetFavoriteRoutesParams(
          loginMethod: loginMethod,
          userId: userId,
        ),
      );
      
      routesResult.fold(
        (failure) {
          // 경로 조회 실패는 무시 (백엔드 미구현)
          debugPrint('경로 조회 실패 (백엔드 미구현): $failure');
          _favoriteRoutes = []; // 빈 리스트로 설정
        },
        (routes) => _favoriteRoutes = routes,
      );
      
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '즐겨찾기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '지점'),
            Tab(text: '경로'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFavorites,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // 지점 탭
                    _buildPointsTab(),
                    // 경로 탭
                    _buildRoutesTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentIndex = _tabController.index;
          if (currentIndex == 0) {
            // 지점 추가 화면으로 이동
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritePointAddView(),
              ),
            );
            if (result == true) {
              _loadFavorites(); // 추가 후 목록 새로고침
            }
          } else {
            // 경로 추가 화면으로 이동
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoriteRouteAddView(),
              ),
            );
            if (result == true) {
              _loadFavorites(); // 추가 후 목록 새로고침
            }
          }
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildPointsTab() {
    if (_favoritePoints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '등록된 즐겨찾기 지점이 없습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '우측 하단 + 버튼을 눌러 추가하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritePoints.length,
      itemBuilder: (context, index) {
        final point = _favoritePoints[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.amber,
                size: 28,
              ),
            ),
            title: Text(
              point.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '위도: ${point.latitude.toStringAsFixed(6)}\n경도: ${point.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () {
              // 목적지로 설정하고 화면 닫기
              Navigator.pop(context, {
                'type': 'point',
                'data': point,
              });
            },
          ),
        );
      },
    );
  }
  
  Widget _buildRoutesTab() {
    if (_favoriteRoutes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '등록된 즐겨찾기 경로가 없습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '우측 하단 + 버튼을 눌러 추가하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRoutes.length,
      itemBuilder: (context, index) {
        final route = _favoriteRoutes[index];
        final validPoints = route.points.where((p) => p != null).length;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions,
                color: Colors.blue,
                size: 28,
              ),
            ),
            title: Text(
              route.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '경유지 $validPoints개',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () {
              // 경로로 네비게이션 시작
              Navigator.pop(context, {
                'type': 'route',
                'data': route,
              });
            },
          ),
        );
      },
    );
  }
}