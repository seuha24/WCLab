part of '../../framework/object.dart';

/// [CitsVersionModel]은 API 응답을 [CitsVersion]으로 변환하는 모델
class CitsVersionModel extends CitsVersion {
  const CitsVersionModel({
    required super.junctionsVersion,
    required super.crosswalkVersion,
  });

  /// API 2-3 JSON 응답에서 생성
  ///
  /// ```json
  /// {
  ///   "cits_junctions_seoul_version": 2512,
  ///   "cits_crosswalk_seoul_version": 2512
  /// }
  /// ```
  factory CitsVersionModel.fromJson(Map<String, dynamic> json) {
    return CitsVersionModel(
      junctionsVersion: json['cits_junctions_seoul_version'] as int,
      crosswalkVersion: json['cits_crosswalk_seoul_version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cits_junctions_seoul_version': junctionsVersion,
      'cits_crosswalk_seoul_version': crosswalkVersion,
    };
  }
}
