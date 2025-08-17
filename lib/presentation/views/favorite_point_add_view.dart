import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/controller.dart';

class FavoritePointAddView extends StatefulWidget {
  const FavoritePointAddView({super.key});

  @override
  State<FavoritePointAddView> createState() => _FavoritePointAddViewState();
}

class _FavoritePointAddViewState extends State<FavoritePointAddView> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  late AddFavoritePoint _addFavoritePoint;
  
  bool _isLoading = false;
  String _searchLocation = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  
  @override
  void initState() {
    super.initState();
    _initializeUseCase();
  }
  
  void _initializeUseCase() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository = FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);
    
    _addFavoritePoint = AddFavoritePoint(repository);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _searchForLocation() async {
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
        _searchLocation = '선택된 위치';
        _selectedLatitude = result.lat;
        _selectedLongitude = result.lng;
      });
    } else if (result != null && result is PlaceResult) {
      // PlaceResult가 반환되면 출입구 선택 필요
      setState(() {
        _searchLocation = '검색 중...';
      });
      
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
                _searchLocation = '${result.name} - ${entranceResult['name']}';
                _selectedLatitude = entranceResult['lat'];
                _selectedLongitude = entranceResult['lng'];
              });
            }
          } else {
            // 출입구가 없는 경우 카카오 좌표 사용
            setState(() {
              _searchLocation = result.name;
              _selectedLatitude = result.geometry.location.lat;
              _selectedLongitude = result.geometry.location.lng;
            });
          }
          break;
        } else if (state is EntranceError) {
          // 에러 발생 시 카카오 좌표 사용
          setState(() {
            _searchLocation = result.name;
            _selectedLatitude = result.geometry.location.lat;
            _selectedLongitude = result.geometry.location.lng;
          });
          break;
        }
      }
    }
  }
  
  Future<void> _saveFavoritePoint() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기 이름을 입력해주세요.')),
      );
      return;
    }
    
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치를 선택해주세요.')),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다.')),
            );
          }
          return;
        }
      }
      
      final userId = serverUserId; // 서버 UUID 사용
      
      // 즐겨찾기 추가
      final result = await _addFavoritePoint.call(
        AddFavoritePointParams(
          loginMethod: loginMethod,
          userId: userId,
          name: _nameController.text,
          longitude: _selectedLongitude!,
          latitude: _selectedLatitude!,
        ),
      );
      
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('즐겨찾기 등록에 실패했습니다.')),
            );
          }
        },
        (point) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('즐겨찾기가 등록되었습니다.')),
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
          '즐겨찾기 지점 추가',
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
            // 위치 검색 섹션
            const Text(
              '위치 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _searchForLocation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _searchLocation.isEmpty 
                          ? '위치를 검색하세요' 
                          : _searchLocation,
                        style: TextStyle(
                          fontSize: 16,
                          color: _searchLocation.isEmpty 
                            ? Colors.grey[400] 
                            : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_selectedLatitude != null && _selectedLongitude != null) ...[
              const SizedBox(height: 8),
              Text(
                '선택된 좌표: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // 이름 입력 섹션
            const Text(
              '즐겨찾기 이름',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 우리집, 회사',
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
                    color: Colors.amber,
                    width: 2,
                  ),
                ),
              ),
            ),
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
                onPressed: _isLoading ? null : _saveFavoritePoint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
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