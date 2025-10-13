part of '../../framework/data_source.dart';

abstract class CrosswalkRemoteDataSource {
  Future<List<CrosswalkModel>> getCrosswalks(
    List<DiscoveredDevice> results,
    LatLng position,
  );
}

class CrosswalkRemoteDataSourceImpl implements CrosswalkRemoteDataSource {
  Distance distance;

  CrosswalkRemoteDataSourceImpl({
    required this.distance,
  });

  Map<String, dynamic> _getDirectionAndPosition(
    var geo1,
    var geo2,
    LatLng pos,
  ) {
    LatLng pos1 = LatLng(geo1['geo'].latitude, geo1['geo'].longitude);
    LatLng pos2 = LatLng(geo2['geo'].latitude, geo2['geo'].longitude);

    double meter1 = distance(pos, pos1);
    double meter2 = distance(pos, pos2);

    if (meter1 > meter2) {
      return {'pos': pos1, 'dir': geo1['dir']};
    } else if (meter1 < meter2) {
      return {'pos': pos2, 'dir': geo2['dir']};
    }
    return {'pos': null, 'dir': null};
  }

  @override
  Future<List<CrosswalkModel>> getCrosswalks(
    List<DiscoveredDevice> lists,
    LatLng position,
  ) async {
    try {
      List<CrosswalkModel> results = [];

      // Firebase 조회 없이 모든 BLE 기기를 직접 Crosswalk로 변환
      for (DiscoveredDevice device in lists) {
        results.add(
          CrosswalkModel.fromMap({
            'name': device.name, // BLE 기기 이름을 그대로 사용
            'post': device,
            'type': ECrosswalk.SINGLE_ROAD, // 기본 타입 설정
            'dir': null, // Firebase 없으므로 방향 정보 없음
            'pos': null, // Firebase 없으므로 위치 정보 없음
          }),
        );
      }

      return results;
    } catch (e) {
      throw ServerException();
    }
  }
}
