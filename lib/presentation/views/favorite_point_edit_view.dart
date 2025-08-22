import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safelight/data/network/dio_client.dart';
import 'package:safelight/data/repositories/favorite_repository_impl.dart';
import 'package:safelight/data/services/auth_service.dart';
import 'package:safelight/data/sources/favorite_remote_data_source.dart';
import 'package:safelight/domain/entities/auth_type.dart';
import 'package:safelight/domain/entities/favorite_point.dart';
import 'package:safelight/domain/usecases/favorite_usecase.dart';
import 'package:safelight/framework/ui.dart';
import 'package:safelight/framework/object.dart';
import 'package:safelight/framework/controller.dart';

class FavoritePointEditView extends StatefulWidget {
  final FavoritePoint favoritePoint;

  const FavoritePointEditView({
    super.key,
    required this.favoritePoint,
  });

  @override
  State<FavoritePointEditView> createState() => _FavoritePointEditViewState();
}

class _FavoritePointEditViewState extends State<FavoritePointEditView> {
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
    // 기존 데이터로 초기화
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
    // startspot_search_view.dart를 참고하여 카카오 검색
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartSearch(
          searchValue: '',
          isFavoriteMode: true, // 즐겨찾기 모드로 설정 (SearchBloc 업데이트 안 함)
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

    if (widget.favoritePoint.favIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정할 수 없는 항목입니다.')),
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

      // 서버 UUID 가져오기
      String? serverUserId = await _authService.loadServerUserId();

      if (serverUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다.')),
          );
        }
        return;
      }

      // 즐겨찾기 수정
      final result = await _updateFavoritePoint.call(
        UpdateFavoritePointParams(
          loginMethod: loginMethod,
          userId: serverUserId,
          favIdx: widget.favoritePoint.favIdx!,
          name: _nameController.text,
          longitude: _selectedLongitude!,
          latitude: _selectedLatitude!,
        ),
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정에 실패했습니다.')),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정되었습니다.')),
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
          '즐겨찾기 지점 수정',
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
                        _searchLocation.isEmpty ? '위치를 검색하세요' : _searchLocation,
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
    );
  }
}
