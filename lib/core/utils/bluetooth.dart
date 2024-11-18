// ignore_for_file: constant_identifier_names
part of core;

class Bluetooth {
  static const String SERVICE_UUID = '0003cdd0-0000-1000-8000-00805f9b0131';
  static const String CHAR_UUID = '0003cdd2-0000-1000-8000-00805f9b0131';
  static const List<int> CMD_VOICE = [0x31, 0x00, 0x01];
  static const List<int> CMD_ACOUSTIC = [0x31, 0x00, 0x02];
}
