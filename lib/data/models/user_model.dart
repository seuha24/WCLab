part of object;

class UserModel extends User {
  const UserModel({
    //required super.id,
    //required super.pw,
    required super.credential,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        //id: map['id'], pw: map['pw'],
        credential: map['credential']);
  }
}
