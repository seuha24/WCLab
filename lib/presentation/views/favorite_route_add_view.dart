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
  
  // 출발지, 목적지, 경유지(최대 3개) 분리
  RoutePoint? _startPoint;
  String _startName = '';
  RoutePoint? _finishPoint;
  String _finishName = '';
  final List<RoutePoint?> _stopovers = List.filled(3, null);
  final List<String> _stopoverNames = List.filled(3, '');
  
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
  
  Future<void> _selectLocation(String type, [int? index]) async {
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
        if (type == 'start') {
          _startPoint = RoutePoint(
            longitude: result.lng,
            latitude: result.lat,
          );
          _startName = '선택된 위치';
        } else if (type == 'finish') {
          _finishPoint = RoutePoint(
            longitude: result.lng,
            latitude: result.lat,
          );
          _finishName = '선택된 위치';
        } else if (type == 'stopover' && index != null) {
          _stopovers[index] = RoutePoint(
            longitude: result.lng,
            latitude: result.lat,
          );
          _stopoverNames[index] = '선택된 위치';
        }
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
                if (type == 'start') {
                  _startPoint = RoutePoint(
                    longitude: entranceResult['lng'],
                    latitude: entranceResult['lat'],
                  );
                  _startName = '${result.name} - ${entranceResult['name']}';
                } else if (type == 'finish') {
                  _finishPoint = RoutePoint(
                    longitude: entranceResult['lng'],
                    latitude: entranceResult['lat'],
                  );
                  _finishName = '${result.name} - ${entranceResult['name']}';
                } else if (type == 'stopover' && index != null) {
                  _stopovers[index] = RoutePoint(
                    longitude: entranceResult['lng'],
                    latitude: entranceResult['lat'],
                  );
                  _stopoverNames[index] = '${result.name} - ${entranceResult['name']}';
                }
              });
            }
          } else {
            // 출입구가 없는 경우 카카오 좌표 사용
            setState(() {
              if (type == 'start') {
                _startPoint = RoutePoint(
                  longitude: result.geometry.location.lng,
                  latitude: result.geometry.location.lat,
                );
                _startName = result.name;
              } else if (type == 'finish') {
                _finishPoint = RoutePoint(
                  longitude: result.geometry.location.lng,
                  latitude: result.geometry.location.lat,
                );
                _finishName = result.name;
              } else if (type == 'stopover' && index != null) {
                _stopovers[index] = RoutePoint(
                  longitude: result.geometry.location.lng,
                  latitude: result.geometry.location.lat,
                );
                _stopoverNames[index] = result.name;
              }
            });
          }
          break;
        } else if (state is EntranceError) {
          // 에러 발생 시 카카오 좌표 사용
          setState(() {
            if (type == 'start') {
              _startPoint = RoutePoint(
                longitude: result.geometry.location.lng,
                latitude: result.geometry.location.lat,
              );
              _startName = result.name;
            } else if (type == 'finish') {
              _finishPoint = RoutePoint(
                longitude: result.geometry.location.lng,
                latitude: result.geometry.location.lat,
              );
              _finishName = result.name;
            } else if (type == 'stopover' && index != null) {
              _stopovers[index] = RoutePoint(
                longitude: result.geometry.location.lng,
                latitude: result.geometry.location.lat,
              );
              _stopoverNames[index] = result.name;
            }
          });
          break;
        }
      }
    }
  }
  
  void _removeLocation(String type, [int? index]) {
    setState(() {
      if (type == 'start') {
        _startPoint = null;
        _startName = '';
      } else if (type == 'finish') {
        _finishPoint = null;
        _finishName = '';
      } else if (type == 'stopover' && index != null) {
        _stopovers[index] = null;
        _stopoverNames[index] = '';
      }
    });
  }
  
  Future<void> _saveFavoriteRoute() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로 이름을 입력해주세요.')),
      );
      return;
    }
    
    // 출발지와 목적지는 필수
    if (_startPoint == null || _finishPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출발지와 목적지를 모두 선택해주세요.')),
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
      
      // 서버 UUID 사용
      final serverUserId = await _authService.loadServerUserId();
      if (serverUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
          );
        }
        return;
      }
      final userId = serverUserId;
      
      // 즐겨찾기 경로 추가 (경유지는 최대 3개)
      final result = await _addFavoriteRoute.call(
        AddFavoriteRouteParams(
          loginMethod: loginMethod,
          userId: userId,
          name: _nameController.text,
          startPoint: _startPoint,
          finishPoint: _finishPoint,
          stopovers: _stopovers,
        ),
      );
      
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('경로 등록에 실패했습니다.')),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('경로가 등록되었습니다.')),
            );
            Navigator.pop(context, true); // 성공 표시와 함께 화면 닫기
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              '출발지와 목적지를 선택하고, 필요시 경유지를 추가하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // 출발지
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _startPoint != null ? Colors.green.withValues(alpha: 0.5) : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _startPoint != null 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.trip_origin,
                    color: _startPoint != null ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  '출발지',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _startPoint != null ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: _startPoint != null
                  ? Text(
                      _startName,
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
                trailing: _startPoint != null
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeLocation('start'),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () => _selectLocation('start'),
                    ),
                onTap: _startPoint != null ? null : () => _selectLocation('start'),
              ),
            ),
            
            // 목적지
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _finishPoint != null ? Colors.red.withValues(alpha: 0.5) : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _finishPoint != null 
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.flag,
                    color: _finishPoint != null ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  '목적지',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _finishPoint != null ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: _finishPoint != null
                  ? Text(
                      _finishName,
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
                trailing: _finishPoint != null
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeLocation('finish'),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () => _selectLocation('finish'),
                    ),
                onTap: _finishPoint != null ? null : () => _selectLocation('finish'),
              ),
            ),
            
            // 경유지 섹션
            const SizedBox(height: 16),
            const Text(
              '경유지 (선택)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // 경유지 리스트
            ...List.generate(3, (index) {
              final hasPoint = _stopovers[index] != null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasPoint ? Colors.blue.withValues(alpha: 0.5) : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasPoint 
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.location_on,
                      color: hasPoint ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '경유지 ${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasPoint ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: hasPoint
                    ? Text(
                        _stopoverNames[index],
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
                        onPressed: () => _removeLocation('stopover', index),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () => _selectLocation('stopover', index),
                      ),
                  onTap: hasPoint ? null : () => _selectLocation('stopover', index),
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
              color: Colors.grey.withValues(alpha: 0.2),
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