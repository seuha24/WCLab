part of '../../framework/data_source.dart';

abstract class CrosswalkRemoteDataSource {
  Future<List<CrosswalkModel>> getCrosswalks(
    List<DiscoveredDevice> results,
    LatLng position,
  );
}

class CrosswalkRemoteDataSourceImpl implements CrosswalkRemoteDataSource {
  CrosswalkRemoteDataSourceImpl();

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
            'name': device.name,
            'post': device,
            'type': ECrosswalk.SINGLE_ROAD,
          }),
        );
      }

      return results;
    } catch (e) {
      throw ServerException();
    }
  }
}
