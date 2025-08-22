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

class FavoriteRouteEditView extends StatefulWidget {
  final FavoriteRoute favoriteRoute;
  
  const FavoriteRouteEditView({
    super.key,
    required this.favoriteRoute,
  });

  @override
  State<FavoriteRouteEditView> createState() => _FavoriteRouteEditViewState();
}

class _FavoriteRouteEditViewState extends State<FavoriteRouteEditView> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  late UpdateFavoriteRoute _updateFavoriteRoute;
  
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
    _initializeData();
  }
  
  void _initializeUseCase() {
    final dioClient = DioClient();
    final remoteDataSource = FavoriteRemoteDataSourceImpl(dioClient: dioClient);
    final repository = FavoriteRepositoryImpl(remoteDataSource: remoteDataSource);
    
    _updateFavoriteRoute = UpdateFavoriteRoute(repository);
  }
  
  void _initializeData() {
    // 기존 데이터로 초기화
    _nameController.text = widget.favoriteRoute.name;
    _startPoint = widget.favoriteRoute.startPoint;
    _startName = widget.favoriteRoute.startPoint != null ? '출발지' : '';
    _finishPoint = widget.favoriteRoute.finishPoint;
    _finishName = widget.favoriteRoute.finishPoint != null ? '목적지' : '';
    
    // 경유지 초기화
    for (int i = 0; i < widget.favoriteRoute.stopovers.length && i < 3; i++) {
      _stopovers[i] = widget.favoriteRoute.stopovers[i];
      _stopoverNames[i] = widget.favoriteRoute.stopovers[i] != null ? '경유지 ${i + 1}' : '';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _selectLocation(String type, [int? index]) async {
    // 타입에 따라 다른 텍스트 설정
    String hintText = '';
    String dialogTitle = '';
    String dialogContentSuffix = '';
    
    if (type == 'start') {
      hintText = '출발지를 입력하세요.';
      dialogTitle = '출발지 변경';
      dialogContentSuffix = '에서 출발하시나요?';
    } else if (type == 'finish') {
      hintText = '목적지를 입력하세요.';
      dialogTitle = '목적지 변경';
      dialogContentSuffix = '(으)로 도착하시나요?';
    } else if (type == 'stopover' && index != null) {
      hintText = '경유지 ${index + 1}을 입력하세요.';
      dialogTitle = '경유지 변경';
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
  
  Future<void> _updateFavoriteRouteData() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로 이름을 입력해주세요.')),
      );
      return;
    }
    
    if (_startPoint == null || _finishPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출발지와 목적지를 모두 선택해주세요.')),
      );
      return;
    }
    
    if (widget.favoriteRoute.favIdx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정할 수 없는 항목입니다.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }
      
      final authType = await _authService.loadAuthType();
      final loginMethod = authType == AuthType.google ? 'google' : 'apple';
      
      final serverUserId = await _authService.loadServerUserId();
      if (serverUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
          );
        }
        return;
      }
      
      // 즐겨찾기 경로 수정
      final result = await _updateFavoriteRoute.call(
        UpdateFavoriteRouteParams(
          loginMethod: loginMethod,
          userId: serverUserId,
          favIdx: widget.favoriteRoute.favIdx!,
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
              const SnackBar(content: Text('수정에 실패했습니다.')),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정되었습니다.')),
            );
            Navigator.pop(context, true);
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
          '즐겨찾기 경로 수정',
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
            // 경로 이름 입력
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
                hintText: '예: 출퇴근 경로',
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
            
            // 출발지
            const Text(
              '출발지',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationSelector(
              icon: Icons.trip_origin,
              color: Colors.green,
              label: _startName.isEmpty ? '출발지를 선택하세요' : _startName,
              onTap: () => _selectLocation('start'),
              onRemove: _startName.isNotEmpty ? () => _removeLocation('start') : null,
            ),
            
            const SizedBox(height: 24),
            
            // 목적지
            const Text(
              '목적지',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationSelector(
              icon: Icons.location_on,
              color: Colors.red,
              label: _finishName.isEmpty ? '목적지를 선택하세요' : _finishName,
              onTap: () => _selectLocation('finish'),
              onRemove: _finishName.isNotEmpty ? () => _removeLocation('finish') : null,
            ),
            
            const SizedBox(height: 24),
            
            // 경유지
            const Text(
              '경유지 (선택)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLocationSelector(
                  icon: Icons.add_location,
                  color: Colors.orange,
                  label: _stopoverNames[index].isEmpty 
                    ? '경유지 ${index + 1} (선택)' 
                    : _stopoverNames[index],
                  onTap: () => _selectLocation('stopover', index),
                  onRemove: _stopoverNames[index].isNotEmpty 
                    ? () => _removeLocation('stopover', index) 
                    : null,
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
                onPressed: _isLoading ? null : _updateFavoriteRouteData,
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
  
  Widget _buildLocationSelector({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return InkWell(
      onTap: onTap,
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
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: label.contains('선택하세요') || label.contains('(선택)') 
                    ? Colors.grey[400] 
                    : Colors.black,
                ),
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}