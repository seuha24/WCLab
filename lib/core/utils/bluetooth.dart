// ignore_for_file: constant_identifier_names
part of '../../framework/core.dart';

class Bluetooth {
  static const String SERVICE_UUID = '0003cdd0-0000-1000-8000-00805f9b0131';
  static const String CHAR_UUID = '0003cdd2-0000-1000-8000-00805f9b0131';  // RX (송신용)
  static const String CHAR_TX_UUID = '0003cdd1-0000-1000-8000-00805f9b0131'; // TX (수신용)
  
  // 경찰청 규격서에 따른 명령 코드 (2022.4.27 개정)
  static const List<int> CMD_LOCATION = [0x31, 0x00, 0x01];  // 위치안내
  static const List<int> CMD_SIGNAL = [0x31, 0x00, 0x02];    // 신호안내
  static const List<int> CMD_VOICE = [0x31, 0x00, 0x03];     // 음성안내 (신규 추가)
  
  /// BLE DEVICE NAME 형식 검증
  /// 경찰청 규격서에 따라 "AHG001+MAC주소+" 형식인지 확인
  /// 예시: "AHG001+BBA050E123D4+"
  static bool validateDeviceName(String? name) {
    if (name == null || name.isEmpty) return false;
    
    // 정규식 패턴: AHG001+12자리 16진수+
    final pattern = RegExp(r'^AHG001\+[A-F0-9]{12}\+$');
    return pattern.hasMatch(name.toUpperCase());
  }
  
  /// DEVICE NAME에서 MAC 주소 추출
  /// 예시: "AHG001+BBA050E123D4+" → "BBA050E123D4"
  static String? extractMacAddress(String? name) {
    if (!validateDeviceName(name)) return null;
    
    // "AHG001+" 이후 12자리 추출
    return name!.substring(7, 19);
  }
}
