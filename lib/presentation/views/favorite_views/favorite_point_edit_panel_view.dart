import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Domain Layer
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/entities/place_result.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';

// Data Layer
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';

// Framework (for part of classes like AuthBloc, StartSearch, GeoLocation, etc.)
import 'package:safelight/framework/ui.dart';
import 'package:safelight/framework/controller.dart';

class FavoritePointEditPanelView extends StatefulWidget {
  final ScrollController scrollController;
  final FavoritePoint favoritePoint;
  final Function? onNavigateBack;
  final Function? onSaveSuccess;

  const FavoritePointEditPanelView({
    super.key,
    required this.scrollController,
    required this.favoritePoint,
    this.onNavigateBack,
    this.onSaveSuccess,
  });

  @override
  State<FavoritePointEditPanelView> createState() =>
      _FavoritePointEditPanelViewState();
}

class _FavoritePointEditPanelViewState
    extends State<FavoritePointEditPanelView> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  late UpdateFavoritePoint _updateFavoritePoint;

  bool _isLoading = false;
  String _searchLocation = '';
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _initializeUseCase();
    _initializeData();
  }

  void _initializeUseCase() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository =
        FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);

    _updateFavoritePoint = UpdateFavoritePoint(repository);
  }

  void _initializeData() {
    _nameController.text = widget.favoritePoint.name;
    _selectedLatitude =
        widget.favoritePoint.entranceLatitude ?? widget.favoritePoint.latitude;
    _selectedLongitude = widget.favoritePoint.entranceLongitude ??
        widget.favoritePoint.longitude;
    _searchLocation = widget.favoritePoint.name;
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
          hintText: '새로운 위치를 입력하세요.',
          dialogTitle: '위치 변경',
          dialogContentSuffix: '(으)로 변경하시나요?',
        ),
      ),
    );

    if (result != null && result is GeoLocation) {
      setState(() {
        _searchLocation = '선택된 위치';
        _selectedLatitude = result.lat;
        _selectedLongitude = result.lng;
      });
    }
  }

  Future<void> _updateFavoritePointData() async {
    if (_nameController.text.isEmpty) return;
    if (_selectedLatitude == null || _selectedLongitude == null) return;
    if (widget.favoritePoint.favIdx == null) return;

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

      final result = await _updateFavoritePoint.call(
        UpdateFavoritePointParams(
          loginMethod: credentials.loginMethod,
          userId: credentials.userId,
          favIdx: widget.favoritePoint.favIdx!,
          name: _nameController.text,
          longitude: _selectedLongitude!,
          latitude: _selectedLatitude!,
        ),
      );

      result.fold(
        (failure) {
          if (mounted) widget.onNavigateBack?.call();
        },
        (success) {
          if (mounted) widget.onSaveSuccess?.call();
        },
      );
    } catch (e) {
      if (mounted) widget.onNavigateBack?.call();
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
                '즐겨찾기 지점 수정',
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
                '위치 변경',
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
                  '현재 좌표: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
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
                  onPressed: _isLoading ? null : _updateFavoritePointData,
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
                          '수정',
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
