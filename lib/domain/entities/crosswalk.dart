part of object;

/// [Crosswalk]는 횡단보도 객체이다.
///
/// `lib/domain/usecases/crosswalk_usecase.dart`의 횡단보도 찾기를 통해 검색된 횡단보도 정보를 나타낼 때 사용한다.
///
/// [Crosswalk] 객체가 포함하는 정보는 아래와 같다.
///
/// |field||설명|
/// |:-------|-|:--------|
/// |[name]||횡단보도의 이름(ex. 가톨릭대 앞)|
/// |[post]||해당 횡단보도의 스마트 압버튼(비콘 포스트) 정보|
/// |[type]||횡단보도의 종류(ex. 교차로)|
/// |[dir]||사용자의 위치에 따른 횡단보도의 방향(ex. 역곡역 방면)|
/// |[pos]||사용자의 위치에 따른 반대편 좌표(위도, 경도)|
class Crosswalk extends Equatable {
  /// 횡단보도의 이름을 나타내는 값이다.
  ///
  /// 횡단보도의 이름은 DB(Firestore)에 요청하여 받아올 수 있다. 만약 해당 횡단보도 정보를 DB에서 찾을 수 없다면 `'횡단보도'`로 값이 할당되게 된다.
  ///
  /// 횡단보도의 이름([name])은 `~~ 횡단보도` 의 형태를 띈다. 즉, 아래와 같이 데이터가 할당되어야 한다.
  ///
  /// * 올바른 값 : `가톨릭대 횡단보도`
  final String name;

  /// 현재 검색된 스마트 압버튼(비콘 포스트)의 정보를 나타내는 값이다.
  ///
  /// [post]는 실제 비콘 포스트와의 연결(데이터 송신)에 사용한다.
  ///
  /// * 연결
  /// ```dart
  /// Crosswalk crosswalk = Crosswalk(...);
  /// await crosswalk.post.connect(autoConnect: false);
  /// await crosswalk.post.disconnect(autoConnect: false);
  /// ```
  ///
  /// * 데이터 송신
  /// ```dart
  /// Crosswalk crosswalk = Crosswalk(...);
  /// final services = await crosswalk.post.discoverServices(); // get service list
  /// final characteristics = services[index].characteristics; // get charateristic list
  /// characteristics[index].write(command, withoutResponse: true); // send command
  /// ```
  ///
  /// 또한, DB(Firestore)에서 해당 횡단보도의 정보를 찾을 때, [post]의 [DiscoveredDevice.name]을 활용한다.
  final DiscoveredDevice post;

  /// 현재 횡단보도의 종류를 나타내는 값이다.
  ///
  /// [type]은 DB(Firestore)에 요청하여 받아올 수 있다.
  /// 요청된 값은 [int]형 인덱스로 받을 수 있는데, 이는 [ECrosswalk]의 인덱스와 매칭된다.
  ///
  /// * 인덱스 매칭
  /// ```dart
  /// ECrosswalk.values[index]
  /// ```
  final ECrosswalk type;

  /// 사용자의 위치에 따른 횡단보도의 방향을 나타내는 값이다.
  ///
  /// [dir]은 DB(Firestore)에 요청하여 받아올 수 있다.
  ///
  /// 횡단보도의 방향이란, 사용자의 위치를 기반으로 나아가는 방향을 의미한다.
  ///
  /// (이미지 추가 예정)
  ///
  /// 만약 해당 횡단보도의 정보를 DB(Firestore)에서 찾을 수 없다면, `null`값을 할당한다.
  final String? dir;

  /// 사용자의 위치에 따른 반대편 좌표를 나타내는 값이다.
  ///
  /// [pos]는 DB(Firestore)에 요청하여 받아올 수 있다.
  /// 반대편 좌표란, 사용자의 위치를 기반으로 현재 횡단보도의 맡은 편 시작 지점을 의미한다.
  ///
  /// (이미지 추가 예정)
  ///
  /// 만약 해당 횡단보도의 정보를 DB(Firestore)에서 찾을 수 없다면, `null`값을 할당한다.
  final LatLng? pos;

  /// Default constructor로서 [post] 값을 반드시 받아야 한다.
  ///
  /// 아래와 같이 사용할 수 있다.
  ///
  /// ```dart
  /// // DB(Firestore)에 해당 횡단보도 데이터가 있는 경우
  /// Crosswalk crosswalk = Crosswalk(
  ///   name : DB의 name 값,
  ///   post : BluetoothDevice(...),
  ///   type : DB의 type 값,
  ///   dir : DB의 dir 값,
  ///   pos : DB의 pos 값
  /// );
  ///
  /// // DB(Firestore)에 해당 횡단보도 데이터가 없는 경우
  /// Crosswalk crosswalk = Crosswalk(post : BluetoothDevice(...));
  /// ```
  const Crosswalk({
    this.name = '횡단보도',
    required this.post,
    this.type = ECrosswalk.UNKNOWN,
    this.dir,
    this.pos,
  });

  @override
  List<Object?> get props => [name];

  @override
  String toString() {
    return '{name : $name, post : $post, type : $type, dir : $dir, pos : $pos}';
  }
}
