import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/controller.dart';

class FavoriteRouteAddView extends StatefulWidget {
  const FavoriteRouteAddView({super.key});

  @override
  State<FavoriteRouteAddView> createState() => _FavoriteRouteAddViewState();
}

class _FavoriteRouteAddViewState extends State<FavoriteRouteAddView> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  late AddFavoriteRoute _addFavoriteRoute;
  
  bool _isLoading = false;
  
  // 최대 5개 포인트 (경유지1-4 + 도착지)
  final List<RoutePoint?> _routePoints = List.filled(5, null);
  final List<String> _routeNames = List.filled(5, '');
  
  @override
  void initState() {
    super.initState();
    _initializeUseCase();
  }
  
  void _initializeUseCase() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository = FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);
    
    _addFavoriteRoute = AddFavoriteRoute(repository);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _selectLocation(int index) async {
    // startspot_search_view.dart를 참고하여 카카오 검색
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartSearch(
          searchValue: '',
          isFavoriteMode: true,  // 즐겨찾기 모드로 설정 (SearchBloc 업데이트 안 함)
        ),
      ),
    );
    
    if (result != null && result is GeoLocation) {
      // GeoLocation만 반환되면 바로 좌표 사용 (출입구 선택 완료 케이스)
      setState(() {
        _routePoints[index] = RoutePoint(
          longitude: result.lng,
          latitude: result.lat,
        );
        _routeNames[index] = '선택된 위치';
      });
    } else if (result != null && result is PlaceResult) {
      // PlaceResult가 반환되면 출입구 선택 필요
      // BuildingResponse API 호출
      if (!mounted) return;
      final entranceBloc = context.read<EntranceBloc>();
      entranceBloc.add(
        FetchBuildingEntrances(
          address: result.name,
          longitude: result.geometry.location.lng,
          latitude: result.geometry.location.lat,
        ),
      );
      
      // EntranceLoaded 상태 대기
      await for (final state in entranceBloc.stream) {
        if (state is EntranceLoaded) {
          if (state.buildingResponse.entrances.isNotEmpty) {
            // 출입구 선택 화면으로 이동
            if (!mounted) return;
            final entranceResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EntranceSelectionView(
                  buildingResponse: BuildingResponse(
                    buildingId: 0,
                    buildingName: result.name,
                    buildingDetail: result.address,
                    entrances: state.buildingResponse.entrances,
                  ),
                  onEntranceSelected: (entrance) {
                    Navigator.pop(context, {
                      'lat': entrance.location.latitude,
                      'lng': entrance.location.longitude,
                      'name': entrance.entranceName,
                    });
                  },
                ),
              ),
            );
            
            if (entranceResult != null && entranceResult is Map) {
              setState(() {
                _routePoints[index] = RoutePoint(
                  longitude: entranceResult['lng'],
                  latitude: entranceResult['lat'],
                );
                _routeNames[index] = '${result.name} - ${entranceResult['name']}';
              });
            }
          } else {
            // 출입구가 없는 경우 카카오 좌표 사용
            setState(() {
              _routePoints[index] = RoutePoint(
                longitude: result.geometry.location.lng,
                latitude: result.geometry.location.lat,
              );
              _routeNames[index] = result.name;
            });
          }
          break;
        } else if (state is EntranceError) {
          // 에러 발생 시 카카오 좌표 사용
          setState(() {
            _routePoints[index] = RoutePoint(
              longitude: result.geometry.location.lng,
              latitude: result.geometry.location.lat,
            );
            _routeNames[index] = result.name;
          });
          break;
        }
      }
    }
  }
  
  void _removeLocation(int index) {
    setState(() {
      _routePoints[index] = null;
      _routeNames[index] = '';
    });
  }
  
  Future<void> _saveFavoriteRoute() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로 이름을 입력해주세요.')),
      );
      return;
    }
    
    // 최소 1개 이상의 포인트가 있어야 함
    final hasPoints = _routePoints.any((point) => point != null);
    if (!hasPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 하나 이상의 위치를 선택해주세요.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 사용자 정보 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }
      
      final authType = await _authService.loadAuthType();
      final loginMethod = authType == AuthType.google ? 'google' : 'apple';
      final userId = user.uid;
      
      // 즐겨찾기 경로 추가
      final result = await _addFavoriteRoute.call(
        AddFavoriteRouteParams(
          loginMethod: loginMethod,
          userId: userId,
          name: _nameController.text,
          points: _routePoints,
        ),
      );
      
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경로 등록에 실패했습니다.')),
          );
        },
        (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경로가 등록되었습니다.')),
          );
          Navigator.pop(context, true); // 성공 표시와 함께 화면 닫기
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '즐겨찾기 경로 추가',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 경로 이름 입력 섹션
            const Text(
              '경로 이름',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 출퇴근 경로, 등교 경로',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 경로 포인트 섹션
            const Text(
              '경로 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '경유지와 도착지를 순서대로 선택하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // 경로 포인트 리스트
            ...List.generate(5, (index) {
              final pointName = index < 4 ? '경유지 ${index + 1}' : '도착지';
              final hasPoint = _routePoints[index] != null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasPoint ? Colors.blue.withOpacity(0.5) : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasPoint 
                      ? (index < 4 ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                      : Colors.grey.withOpacity(0.1),
                    child: Icon(
                      index < 4 ? Icons.location_on : Icons.flag,
                      color: hasPoint 
                        ? (index < 4 ? Colors.blue : Colors.red)
                        : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    pointName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasPoint ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: hasPoint
                    ? Text(
                        _routeNames[index],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text(
                        '위치를 선택하세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  trailing: hasPoint
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeLocation(index),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () => _selectLocation(index),
                      ),
                  onTap: hasPoint ? null : () => _selectLocation(index),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveFavoriteRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '등록',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}