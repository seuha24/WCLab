import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 화면 크기에 맞게 Width, Height, Font Size, Radius를 스케일링하는 유틸리티 클래스.
/// 반응형 디자인을 지원하기 위해 화면 크기에 따라 스케일링.
///
/// 이 클래스는 스케일링 시 크기가 특정 최대 및 최소값을 넘지 않도록 제한.
///
/// [ScreenUtil] 패키지를 사용하여 다양한 화면 크기에 따른 스케일링 비율을 계산.
class AppSizes {
  /// 현재 디바이스가 폰인지 여부를 확인하는 플래그 (화면 너비 기준).
  static final bool _isPhone = ScreenUtil().screenWidth < 600;

  /// 스케일링이 최대화되는 화면 너비.
  static const double _maxWidth = 430;

  /// 스케일링이 최대화되는 화면 높이.
  static const double _maxHeight = 1030;

  /// 스케일링이 최소화되는 화면 너비.
  static const double _minWidth = 320;

  /// 스케일링이 최소화되는 화면 높이.
  static const double _minHeight = 568;

  /// 글꼴 크기가 지나치게 커지지 않도록 최대 글꼴 크기를 설정.
  static const double _maxFontSize = 24;

  /// 둥근 모서리를 위한 반경의 최대값.
  static const double _maxRadius = 20;

  /// 주어진 Width를 화면 너비에 맞춰 스케일링. 스케일링이 최소 및 최대 범위 내에서 유지.
  ///
  /// * [size]: 스케일링할 원래 너비 값.
  static double scaledWidth(double size) {
    if (ScreenUtil().screenWidth > _maxWidth) {
      return size;
    }
    if (ScreenUtil().screenWidth < _minWidth) {
      return size * (_minWidth / ScreenUtil().screenWidth * 0.8);
    }
    double scaledSize =
        _isPhone ? SizeExtension(size).w : SizeExtension(size).w * 0.7;
    return scaledSize > _maxWidth ? _maxWidth : scaledSize;
  }

  /// 주어진 Height를 화면 높이에 맞춰 스케일링. 스케일링이 최소 및 최대 범위 내에서 유지.
  ///
  /// * [size]: 스케일링할 원래 높이 값.
  static double scaledHeight(double size) {
    if (ScreenUtil().screenHeight > _maxHeight) {
      return size;
    }
    if (ScreenUtil().screenHeight < _minHeight) {
      return size * (_minHeight / ScreenUtil().screenHeight);
    }
    double scaledSize =
        _isPhone ? SizeExtension(size).h : SizeExtension(size).h * 0.7;
    return scaledSize > _maxHeight ? _maxHeight : scaledSize;
  }

  /// 주어진 Font Size를 화면 너비에 맞춰 스케일링. 스케일링이 최소 및 최대 범위 내에서 유지.
  ///
  /// * [size]: 스케일링할 원래 글꼴 크기 값.
  static double scaledFont(double size) {
    if (ScreenUtil().screenWidth > _maxWidth) {
      return size;
    }
    if (ScreenUtil().screenWidth < _minWidth) {
      return size * (_minWidth / ScreenUtil().screenWidth * 0.81);
    }
    double scaledSize =
        _isPhone ? SizeExtension(size).sp : SizeExtension(size / 2).sp;
    return scaledSize > _maxFontSize ? _maxFontSize : scaledSize;
  }

  /// 주어진 Radius를 화면 너비에 맞춰 스케일링. 스케일링이 최소 및 최대 범위 내에서 유지.
  ///
  /// * [radius]: 스케일링할 원래 반경 값.
  static double scaledRadius(double radius) {
    if (ScreenUtil().screenWidth > _maxWidth) {
      return radius;
    }
    if (ScreenUtil().screenWidth < _minWidth) {
      return radius * (_minWidth / ScreenUtil().screenWidth);
    }
    double scaledSize = _isPhone ? radius : radius * 1.2;
    return scaledSize > _maxRadius ? _maxRadius : scaledSize;
  }
}
