import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Domain Layer
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/domain/entities/favorite_route.dart';
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

class FavoriteRouteAddPanelView extends StatefulWidget {
  final ScrollController scrollController;
  final Function? onNavigateBack;
  final Function? onSaveSuccess;

  const FavoriteRouteAddPanelView({
    super.key,
    required this.scrollController,
    this.onNavigateBack,
    this.onSaveSuccess,
  });

  @override
  State<FavoriteRouteAddPanelView> createState() =>
      _FavoriteRouteAddPanelViewState();
}

class _FavoriteRouteAddPanelViewState extends State<FavoriteRouteAddPanelView> {
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
    final repository =
        FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);

    _addFavoriteRoute = AddFavoriteRoute(repository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(String type, [int? index]) async {
    String hintText = '';
    String dialogTitle = '';
    String dialogContentSuffix = '';

    if (type == 'start') {
      hintText = '출발지를 입력하세요.';
      dialogTitle = '출발지 확인';
      dialogContentSuffix = '에서 출발하시나요?';
    } else if (type == 'finish') {
      hintText = '목적지를 입력하세요.';
      dialogTitle = '목적지 확인';
      dialogContentSuffix = '(으)로 도착하시나요?';
    } else if (type == 'stopover' && index != null) {
      hintText = '경유지 ${index + 1}을 입력하세요.';
      dialogTitle = '경유지 확인';
      dialogContentSuffix = '을(를) 경유하시나요?';
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartSearch(
          searchValue: '',
          isFavoriteMode: true,
          hintText: hintText,
          dialogTitle: dialogTitle,
          dialogContentSuffix: dialogContentSuffix,
        ),
      ),
    );

    if (result != null && result is GeoLocation) {
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
                  _stopoverNames[index] =
                      '${result.name} - ${entranceResult['name']}';
                }
              });
            }
          } else {
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
      return;
    }

    if (_startPoint == null || _finishPoint == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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
          return;
        }
      }

      final userId = serverUserId; // 서버 UUID 사용

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
          // 등록 실패
        },
        (success) {
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
                '즐겨찾기 경로 추가',
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
              _buildLocationCard(
                type: 'start',
                icon: Icons.trip_origin,
                color: Colors.green,
                title: '출발지',
                subtitle: _startPoint != null ? _startName : '위치를 선택하세요',
                hasPoint: _startPoint != null,
              ),

              // 목적지
              _buildLocationCard(
                type: 'finish',
                icon: Icons.flag,
                color: Colors.red,
                title: '목적지',
                subtitle: _finishPoint != null ? _finishName : '위치를 선택하세요',
                hasPoint: _finishPoint != null,
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
                return _buildLocationCard(
                  type: 'stopover',
                  index: index,
                  icon: Icons.location_on,
                  color: Colors.blue,
                  title: '경유지 ${index + 1}',
                  subtitle: hasPoint ? _stopoverNames[index] : '위치를 선택하세요',
                  hasPoint: hasPoint,
                );
              }),
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
      ],
    );
  }

  Widget _buildLocationCard({
    required String type,
    int? index,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool hasPoint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPoint ? color.withValues(alpha: 0.5) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasPoint
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: hasPoint ? color : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: hasPoint ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasPoint
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeLocation(type, index),
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _selectLocation(type, index),
              ),
        onTap: hasPoint ? null : () => _selectLocation(type, index),
      ),
    );
  }
}
