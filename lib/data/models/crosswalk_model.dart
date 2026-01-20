part of '../../framework/object.dart';

class CrosswalkModel extends Crosswalk {
  const CrosswalkModel({
    required super.name,
    required super.post,
    required super.type,
  });

  factory CrosswalkModel.fromMap(Map<String, dynamic> map) {
    return CrosswalkModel(
      name: map['name'],
      post: map['post'],
      type: map['type'],
    );
  }
}
