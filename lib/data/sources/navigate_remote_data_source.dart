part of data_source;

abstract class NavigateRemoteDataSource {
  Future<LatLng> getCurrentLatLng();
}

class NavigateRemoteDataSourceImpl implements NavigateRemoteDataSource {
  GeolocatorPlatform geolocator;

  NavigateRemoteDataSourceImpl({required this.geolocator});

  @override
  Future<LatLng> getCurrentLatLng() async {
    try {
      final position = await geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ));
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw ServerException();
    }
  }
}
