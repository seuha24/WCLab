part of '../../framework/core.dart';

/// 응답 데이터 모델
class ResponseData {
  final int opcode;
  final bool isAck;
  final bool isNak;
  final int deviceInfo;
  
  const ResponseData({
    required this.opcode,
    required this.isAck,
    required this.isNak,
    required this.deviceInfo,
  });
  
  /// 수신기 사양 정보 파싱
  String get deviceInfoDescription {
    switch (deviceInfo) {
      case 0x00:
        return '음향만 출력';
      case 0x01:
        return '음성 출력';
      case 0x02:
        return '음향+음성 동시 출력';
      default:
        return '알 수 없음';
    }
  }
  
  @override
  String toString() {
    return 'ResponseData(opcode: $opcode, isAck: $isAck, isNak: $isNak, deviceInfo: $deviceInfoDescription)';
  }
}

/// BLE 응답 파서
/// 경찰청 규격서에 따른 응답 패킷 파싱
class ResponseParser {
  /// 응답 패킷 파싱
  /// 
  /// 응답 패킷 구조 (3 bytes):
  /// - HEADER (1 byte): 0x32 (응답 헤더)
  /// - OPCODE (1 byte): 0x00 (응답 메시지)
  /// - DATA (1 byte): 상위 4비트(수신기 사양), 하위 4비트(ACK/NAK)
  static ResponseData? parse(List<int> data) {
    if (data.length != 3) return null;
    
    final header = data[0];
    final opcode = data[1];
    final status = data[2];
    
    // 헤더 검증 (0x32 = 응답 헤더)
    if (header != 0x32) return null;
    
    // 하위 4비트: ACK/NAK 상태
    final ackNakStatus = status & 0x0F;
    
    // 상위 4비트: 수신기 사양 정보
    final deviceInfo = (status & 0xF0) >> 4;
    
    return ResponseData(
      opcode: opcode,
      isAck: ackNakStatus == 0x00,
      isNak: ackNakStatus == 0x01,
      deviceInfo: deviceInfo,
    );
  }
}