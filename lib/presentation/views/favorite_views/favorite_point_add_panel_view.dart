import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Domain Layer
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';

// Data Layer
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';

// Framework (for part of classes like AuthBloc, StartSearch, GeoLocation, BuildingResponse, etc.)
import 'package:safelight/framework/ui.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/controller.dart';

class FavoritePointAddPanelView extends StatefulWidget {
  final ScrollController scrollController;
  final Function? onNavigateBack;
  final Function? onSaveSuccess;

  const FavoritePointAddPanelView({
    super.key,
    required this.scrollController,
    this.onNavigateBack,
    this.onSaveSuccess,
  });

  @override
  State<FavoritePointAddPanelView> createState() =>
      _FavoritePointAddPanelViewState();
}

class _FavoritePointAddPanelViewState extends State<FavoritePointAddPanelView> {
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
    final repository =
        FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);

    _addFavoritePoint = AddFavoritePoint(repository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchForLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartSearch(
          searchValue: '',
          isFavoriteMode: true,
          hintText: '즐겨찾기 지점을 입력하세요.',
          dialogTitle: '지점 확인',
          dialogContentSuffix: '을(를) 즐겨찾기에 추가하시나요?',
        ),
      ),
    );

    if (result != null && result is GeoLocation) {
      setState(() {
        _searchLocation = '선택된 위치';
        _selectedLatitude = result.lat;
        _selectedLongitude = result.lng;
      });
    } else if (result != null && result is PlaceResult) {
      setState(() {
        _searchLocation = '검색 중...';
      });

      if (!mounted) return;
      final entranceBloc = context.read<EntranceBloc>();
      entranceBloc.add(
        FetchBuildingEntrances(
          address: result.name,
          longitude: result.geometry.location.lng,
          latitude: result.geometry.location.lat,
        ),
      );

      await for (final state in entranceBloc.stream) {
        if (state is EntranceLoaded) {
          if (state.buildingResponse.entrances.isNotEmpty) {
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
            setState(() {
              _searchLocation = result.name;
              _selectedLatitude = result.geometry.location.lat;
              _selectedLongitude = result.geometry.location.lng;
            });
          }
          break;
        } else if (state is EntranceError) {
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
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      final result = await _addFavoritePoint.call(
        AddFavoritePointParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
          name: _nameController.text,
          longitude: _selectedLongitude!,
          latitude: _selectedLatitude!,
        ),
      );

      result.fold(
        (failure) {
          // 등록 실패
        },
        (point) {
          if (mounted) {
            widget.onSaveSuccess?.call();
          }
        },
      );
    } catch (e) {
      // 에러 발생
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
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigateBack?.call(),
              ),
              const Text(
                '즐겨찾기 지점 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 콘텐츠
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
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

        // 하단 버튼
        Container(
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
                  onPressed:
                      _isLoading ? null : () => widget.onNavigateBack?.call(),
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
      ],
    );
  }
}
