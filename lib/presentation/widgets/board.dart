part of ui;

/// [Board] 위젯은 child를 가지는 위젯이다.
///
/// 정적 위젯인 [StatelessWidget]를 상속받으며, defalut contructor로만 객체 생성이 가능하다.
/// [StatelessWidget]의 최상단 위젯은 [Align]로서 [color], [padding], [width], [height] 파라미터를 사용하여 지정한다.
/// 제목과 함께 내부에 하나의 위젯 또는 ui를 가지고 화면 상에 출력해야 하는 경우 주로 사용한다.
///
/// 가질 수 있는 파라미터는 아래와 같으며, 생성시 [title], [body]는 반드시 지정해야한다.
///
/// ## Parameter
/// * [title] : [Board]의 제목을 나타낸다.
/// * [body] : [Board]가 가지는 자식 위젯이다.
/// * [backgroundColor] : [Board]의 배경색을 나타낸다.
/// * [padding] : [Board]의 안쪽 여백을 나타낸다.
/// * [headerPadding] : [Board]의 [title]을 위한 패딩 값을 나타낸다.
/// * [trailing] : [Board]의 우측에 들어갈 요소이다.
/// * [titleStyle] : [Board]의 [title]의 글씨 스타일을 지정한다.
/// * [height] : [Board]의 높이를 나타낸다.
///
/// 사용 예시는 아래와 같다.
///
/// ```dart
/// Board( title: '앱 내 권한',
///   body: Column(..., ...),)
/// ```
class Board extends StatelessWidget {
  /// [title]은 [Board]가 가지는 제목을 나타낸다.
  ///
  /// [String] 타입으로, [Text]의 data로 할당되어 출력된다.
  /// [Board] 생성 시 반드시 지정해야한다.
  ///
  /// [text]의 style은 [Text]의 [style] 파라미터를 통해 값을 할당하며, [textTheme.labelLarge]으로 지정한다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 수정시 되도록 [textTheme.bodyMedium]를 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// Text( title, style: titleStyle ?? Theme.of(context).textTheme.labelLarge,),
  /// ```
  final String title;

  /// [body]는 [Board]가 가지는 자식 위젯이다.
  ///
  /// [Board] 생성 시 반드시 지정해야하며 [ListTile], [ConstrainedBox], [Expanded] 등으로 활용하여 사용하였다.
  /// 사용 시 지정한 파라미터를 통해 위젯을 만든다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// Board(..., body: ConstrainedBox(), ...,)
  /// ```
  final Widget body;

  /// [backgroundColor]는 [Board]의 배경색을 나타낸다.
  ///
  /// [Container]의 [color] 파라미터를 통해 값을 할당한다.
  final Color? backgroundColor;
  final Color? headerColor;

  /// [padding]은 [Board]의 안쪽 여백을 나타낸다.
  ///
  ///: [Container]의 [padding] 파라미터를 통해 값을 할당한다.
  final EdgeInsets? padding;

  /// [headerPadding]은 [Board]의 [title]을 위한 패딩 값을 나타낸다.
  ///
  /// [Container]의 child인 [Padding]의 [padding] 파라미터를 통해 값을 할당한다.
  /// [headerPadding]이 null인 경우 수평값과 수직값은
  /// [EdgeInsets.Symmetric]의 [vertical], [horizontal] 파라미터에 의해
  /// [themes.dart]에 작성한 [SizeTheme.h_sm], [SizeTheme.w_md] 으로 지정된다.
  final EdgeInsets? headerPadding;

  /// [trailing]은 [Board]의 우측에 들어갈 요소이다.
  ///
  /// [ConstrainedBox]의 [child] 파라미터를 통해 값을 할당한다.
  final Widget? trailing;

  /// [titleStyle]은 [Board]의 [title]의 글씨 스타일을 지정한다.
  ///
  /// [Text]의 [style] 파라미터를 통해 값을 할당하며, [textTheme.labelLarge]으로 지정한다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 수정시 되도록 [textTheme.bodyMedium]를 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// Text( title, style: titleStyle ?? Theme.of(context).textTheme.labelLarge,)
  final TextStyle? titleStyle;

  /// [height]는 [Board]의 높이를 나타낸다.
  ///
  /// [Container]의 [height] 파라미터를 통해 값을 할당한다.
  final double? height;

  const Board({
    Key? key,
    required this.title,
    required this.body,
    this.backgroundColor,
    this.padding,
    this.headerPadding,
    this.trailing,
    this.titleStyle,
    this.height,
    this.headerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        color: backgroundColor,
        padding: padding,
        width: double.infinity,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: headerColor ?? Theme.of(context).colorScheme.background,
              child: Padding(
                padding: headerPadding ??
                    EdgeInsets.symmetric(
                      vertical: SizeTheme.h_sm,
                      horizontal: SizeTheme.w_md,
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: trailing == null ? double.infinity : 180.w,
                      ),
                      child: FittedBox(
                        child: Text(
                          title,
                          style: titleStyle ??
                              Theme.of(context).textTheme.labelLarge,
                          textScaleFactor: 1,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: trailing ?? FittedBox(child: trailing),
                    ),
                  ],
                ),
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}
