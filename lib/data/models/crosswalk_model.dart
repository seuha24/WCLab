part of object;

class CrosswalkModel extends Crosswalk {
  const CrosswalkModel({
    required super.name,
    required super.post,
    required super.type,
    required super.dir,
    required super.pos,
  });

  factory CrosswalkModel.fromMap(Map<String, dynamic> map) {
    return CrosswalkModel(
      name: map['name'],
      post: map['post'],
      type: map['type'],
      dir: map['dir'],
      pos: map['pos'],
    );
  }
}
