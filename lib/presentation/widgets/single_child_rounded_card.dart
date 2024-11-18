part of ui;

/// [SingleChildRoundedCard]는 child를 가지는 위젯이다.
///
/// 정적 위젯인 [StatelessWidget]를 상속받으며, default contructor로만 객체 생성이 가능하다.
/// 내부에 하나의 위젯 또는 ui를 가지고 화면상에 출력해야 하는 경우 주로 사용한다.
/// [Image], [Icon], [ListView] 등으로 활용하여 사용하였다.
///
/// 가질 수 있는 파라미터는 아래와 같으며, 생성시 child는 반드시 지정해야한다.
///
/// ## Parameter
/// * [child] : [SingleChildRoundedCard]가 가지는 단일 자식 위젯이다.
/// * [backgroundColor] : [SingleChildRoundedCard]의 배경색을 나타낸다.
/// * [padding] : [SingleChildRoundedCard]의 패딩 영역의 정도를 나타낸다.
/// * [width] : [SingleChildRoundedCard]의 너비를 나타낸다.
/// * [height] : [SingleChildRoundedCard]의 높이를 나타낸다.
/// * [radius] : [SingleChildRoundedCard]의 모서리 둥글기 정도를 나타낸다.
///
/// [StatelessWidget]의 최상단 위젯은 [Container]로서 [width], [height]를 사용하여 크기를 지정한다.
///
/// 사용 예시는 아래와 같다.
///
/// ```dart
/// SingleChildRoundedCard(child: Icon(Icons.person, ...),)
/// ```
///
/// #### see also
/// [SingleChildRoundedCard]에 대한 이해를 돕기 위해 실제 ui에 사용된 예시 이미지를 아래에 첨부한다.
/// <img src="https://github.com/WclLab/SafeLight-document/blob/master/documents/docs-image/exSingleChildRoundedCard.jpg?raw=true">
class SingleChildRoundedCard extends StatelessWidget {
  /// [child]는 [SingleChildRoundedCard]가 가지는 단일 자식 위젯이다.
  ///
  /// 사용 시 지정한 파라미터를 통해 위젯을 만든다.
  /// [Image], [Icon], [ListView] 등으로 활용하여 사용하였다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// SingleChildRoundedCard(..., child: Image(..., ...),)
  /// ```
  final Widget child;

  /// [backgroundColor]는 [SingleChildRoundedCard]의 배경색을 나타낸다.
  ///
  /// [BoxDecoration]의 [color] 파라미터를 통해 값을 할당하며, [backgroundColor] 값을 할당하지 않을 시 [themes.dart]에 작성한 [colorScheme.background]으로 지정된다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 되도록 [colorScheme.background]으로 값을 할당하는 것을 권고한다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// SingleChildRoundedCard(..., color: Theme.of(context).colorScheme.primary,)
  /// ```
  final Color? backgroundColor;

  /// [padding]은 [SingleChildRoundedCard]의 패딩 영역의 정도를 나타낸다.
  ///
  /// [Container]의 [padding] 파라미터를 통해 값을 할당하며, [EdgeInsets.all]를 활용하여 상하좌우에 동일하게 적용된다.
  ///
  /// [double]값으로 패딩 영역의 정도를 나타내며, 값을 할당하지 않을 시 [SizeTheme.w_sm / 2]으로 지정된다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 되도록 [SizeTheme.w_sm]을 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// SingleChildRoundedCard(..., padding: EdgeInsets.all(SizeTheme.h_lg * 2),)
  /// ```
  ///
  /// 또한 값을 할당하지 않은 경우 특정 영역의 패딩값은 지정할 수 없으므로 [EdgeInsets.only] 등을 활용하여 사용해야한다.
  final EdgeInsets? padding;

  /// [width]는 [SingleChildRoundedCard]의 너비를 나타낸다.
  ///
  /// [Container]의 [width] 파라미터를 통해 값을 할당하며, [double] 값으로 너비를 나타낸다.
  final double? width;

  /// [height]는 [SingleChildRoundedCard]의 높이를 나타낸다.
  ///
  /// [Container]의 [height] 파라미터를 통해 값을 할당하며, [double] 값으로 높이를 나타낸다.
  final double? height;

  /// [radius]는 [SingleChildRoundedCard]의 모서리 둥글기 정도를 나타낸다.
  ///
  /// [BoxDecoration]의 [borderRadius] 파라미터를 통해 값을 할당하며, [BorderRadius.circular]를 활용하여 모든 모서리에 적용된다.
  /// [double]값으로 모서리의 둥근 정도를 나타내며, 값을 할당하지 않을 시 [SizeTheme.r_sm] 으로 지정된다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 되도록 [SizeTheme.r_sm]으로 값을 할당하는 것을 권고한다.
  /// 이때, 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// SingleChildRoundedCard(..., radius : SizeTheme.r_lg);
  /// ```
  ///
  /// 또한, 특정 모서리의 둥글기는 제어할 수 없으므로 이러한 경우에는 다른 위젯을 사용해야 한다.
  final double? radius;

  /// 각 인스턴스에 값을 할당하는 [SingleChildScrollView]의 생성자이다.
  ///
  /// ### Example
  /// ```dart
  /// // 단일 child 위젯 사용 예시
  /// SingleChildRoundedCard(child : Text("Example"));
  ///
  /// // 단일 child 위젯 + 배경색 추가 예시
  /// SingleChildRoundedCard(
  ///   child : Text("Example2"),
  ///   backgroundColor : Colors.red),);
  /// ```
  const SingleChildRoundedCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.width,
    this.height,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(radius ?? SizeTheme.r_sm),
      ),
      padding: padding ?? EdgeInsets.all(SizeTheme.w_sm / 2),
      child: child,
    );
  }
}
