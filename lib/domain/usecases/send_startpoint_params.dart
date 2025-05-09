part of usecase;

class SendStartPointParams {
  final String buildingName;
  final String entranceName;
  final double latitude;
  final double longitude;

  SendStartPointParams({
    required this.buildingName,
    required this.entranceName,
    required this.latitude,
    required this.longitude,
  });
}