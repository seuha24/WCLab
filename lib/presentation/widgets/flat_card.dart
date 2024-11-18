part of ui;

/// [FlatCard]는 title을 가지는 위젯이다.
///
/// 정적 위젯인 [StatelessWidget]을 상속받으며, default contructor로만 객체 생성이 가능하다.
/// [String]으로 이루어진 제목들과, 내부에 두개의 위젯 또는 ui를 가지고 화면상에 출력해야 하는 경우 주로 사용한다.
/// [title], [Icon] 등으로 주로 활용하여 사용하였으며, 생성시 title, bottomTitle 은 반드시 지정해야한다.
///
/// 사용 예시는 아래와 같다.
/// ```dart
/// FlatCard(
///   title: '다크모드',
///   bottomTitle: false,
///   onTap: () async { Navigator.pop(context); ...})
/// ```
///
/// 가질 수 있는 파라미터는 아래와 같다.
///
/// ## Parameter
/// * [backgroundColor] : [FlatCard] 위젯의 배경색을 나타낸다.
/// * [subTitle] : [FlatCard]의 부제목을 나타낸다.
/// * [subLabel] : [FlatCard]의 Label로 [subTitle]의 우측에 작성된다.
/// * [subTail] : [FlatCard]의 Tail로 [subLabel]의 우측에 작성된다.
/// * [title] : [FlatCard]의 제목을 나타낸다.
/// * [bottomTitle] : 기본값은 true이며, [FlatCard]에서 원하는 [titleBuilder] 위젯을 실행하기 위해 만든 변수이다.
/// * [leading] : [FlatCard]의 좌측에 들어갈 요소이다.
/// * [onTap] : [FlatCard] 클릭시에 발생하는 이벤트를 나타낸다.
/// * [subTitleColor] : [FlatCard]에서 사용되는 [subTitle], [subLabel]의 글자색을 나타낸다.
/// * [titleOnly] : 기본값은 false이며, [FlatCard]에서 원하는 [titleBuilder] 위젯을 실행하기 위해 만든 변수이다.
/// * [trailing] : [FlatCard]의 우측에 들어갈 요소이다.
///
/// [ListTile]의 [contentPadding] 파라미터를 통해 수직, 수평을 기준으로 여백을 지정한다.
/// 여백은 [double]의 값으로 나타내며 각각 [SizeTheme.w_sm], [SizeTheme.h_lg]으로 지정한다.
///
/// ### Notice
/// 사용하는 값에 제한은 없으나, 수정시 되도록 [SizeTheme]을 활용하여 값을 할당하는 것을 권고한다.
///
/// #### see also
/// [FlatCard]에 대한 이해를 도울 이미지를 아래에 첨부한다.
/// <img src="https://github.com/WclLab/SafeLight-document/blob/master/documents/docs-image/exFlatCard.jpg?raw=true">
class FlatCard extends StatelessWidget {
  /// [backgroundColor]는 [FlatCard] 위젯의 배경색을 나타낸다.
  ///
  /// [ListTile]의 [tileColor] 파라미터를 통해 값을 할당한다.s
  final Color? backgroundColor;

  /// [subTitle]는 [FlatCard]의 부제목을 나타낸다.
  ///
  ///  [bottomTitle]의 값에 따라 [title] 요소의 상/하단에 작은 글씨로 부제목을 나타낸다.
  ///  [subTitleColor]에 따라 글자색이 결정되며, [subLabel]과 동일하게 적용된다.
  ///
  /// [subTitle]의 style은 [TextSpan]의 [style] 파라미터를 통해 값을 할당하며, [textTheme.bodyMedium]으로 지정한다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 수정 시 되도록 [textTheme.bodyMedium]를 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// TextSpan(
  ///   text: subTitle,
  ///   style: Theme.of(context).textTheme.bodyMedium!.apply(...),)
  /// ```
  final String? subTitle;

  /// [subLabel]은 [FlatCard]의 Label로 [subTitle]의 우측에 작성된다.
  ///
  /// [bottomTitle]의 값에 따라 [title] 요소의 상/하단에 작은 글씨로 부제목을 나타낸다.
  /// [subTitleColor]에 따라 글자색이 결정되며, [subTitle]과 동일하게 적용된다.
  final String? subLabel;

  /// [subTail]은 [FlatCard]의 Tail로 [subLabel]의 우측에 작성된다.
  ///
  /// [bottomTitle]의 값에 따라 [title] 요소의 상/하단에 작은 글씨로 부제목을 나타낸다.
  ///
  /// [subTail]의 style은 [TextSpan]의 [style] 파라미터를 통해 값을 할당하며, [textTheme.bodySmall]으로 지정한다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 수정시 되도록 [textTheme.bodySmall]를 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// TextSpan(
  ///   text: subTail,
  ///   style: Theme.of(context).textTheme.bodySmall, ...),)
  /// ```
  final String? subTail;

  /// [title]은 [FlatCard]의 제목을 나타낸다.
  ///
  /// [bottomTitle]의 값에 따라 [subTitle], [subLabel], [subTail] 요소의 상/하단에 위치한다.
  /// [FlatCard] 생성 시 반드시 지정해야한다.
  ///
  /// [title]의 style은 [AutoSizeText]의 [style] 파라미터를 통해 값을 할당하며, [textTheme.headlineLarge]으로 지정한다.
  ///
  /// ### Notice
  /// 사용하는 값에 제한은 없으나, 수정시 되도록 [textTheme.headlineLarge]를 활용하여 값을 할당하는 것을 권고한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// AutoSizeText( title, style: Theme.of(context).textTheme.headlineLarge,)
  /// ```
  final String title;

  /// [bottomTitle]은 [FlatCard]에서 원하는 [titleBuilder] 위젯을 실행하기 위해 만든 변수이다.
  ///
  /// 기본 값은 true이며,
  /// true인 경우 [title]이 [subTitle], [subLabel], [subTail] 요소의 하단에 위치한다.
  /// false인 경우 [title]이 [subTitle], [subLabel], [subTail] 요소의 상단에 위치한다.
  final bool bottomTitle;

  /// [leading]은 [FlatCard]의 좌측에 들어갈 요소이다.
  ///
  /// 사용 시 지정한 파라미터를 통해 위젯을 만든다.
  /// 주로 [Icon] 등으로 활용하여 사용하였다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// FlatCard(..., leading: Icon(...),)
  /// ```
  final Widget? leading;

  /// [onTap]은 [FlatCard]를 클릭할 때 발생하는 이벤트를 나타낸다.
  ///
  /// [Function]으로 입력받고, [ListTile]의 [onTap] 파라미터를 통해 값을 할당한다.
  /// 입력받은 함수를 통해 원하는 동작이(이벤트) 실행된다.
  /// 앱 내에서 다른 화면으로 넘어가기, 값 읽기 등의 동작으로 활용하였다.
  ///
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// // 실제 사용된 코드 예시이다.
  /// FlatCard(
  ///   title: '다크모드',
  ///   titleOnly: true,
  ///   bottomTitle: false,
  ///   onTap: () async { Navigator.pop(context);
  ///   await box.put(SystemTheme.mode, ThemeMode.dark.name);
  ///   setState(() { mode = box.get(SystemTheme.mode);
  ///   });},)
  ///
  /// // print()를 이용하여 onTap을 확인 할 수 있다.
  /// FlatCard( title: '출력',
  ///   titleOnly: true,
  ///   bottomTitle: false,
  ///   onTap: () async { print('출력도 가능합니다');}),
  /// ```
  ///
  /// #### see also
  /// [onTap]에 대한 이해를 돕기 위해 위에서 예로 든 print의 결과 사진을 아래에 첨부한다.
  /// <img src="https://github.com/WclLab/SafeLight-document/blob/master/documents/docs-image/exonTap.jpg?raw=true">
  final Function()? onTap;

  /// [subTitleColor]은 [FlatCard]에서 사용되는 [subTitle], [subLabel]의 글자색을 나타낸다.
  ///
  /// [TextSpan]의 [style]의 [color] 파라미터를 통해 [subTitle]의 글자색을 지정한다.
  /// 사용 예시는 다음과 같다.
  ///
  /// ```dart
  /// TextSpan(..., style: ...color: subTitleColor,)
  /// ```
  final Color? subTitleColor;

  /// [titleOnly]는 [FlatCard]에서 원하는 [titleBuilder] 위젯을 실행하기 위해 만든 변수이다.
  ///
  /// 기본값은 false이며,
  /// true인 경우 오직 [title] 요소만 적용된 위젯이 된다.
  final bool titleOnly;

  /// [trailing]은 [FlatCard]의 우측에 들어갈 요소이다.
  ///
  /// 사용 시 지정한 파라미터를 통해 위젯을 만든다.
  /// 주로 [Icon] 등으로 활용하여 사용하였다.
  /// 사용 예시는 아래와 같다.
  ///
  /// ```dart
  /// FlatCard(..., trailing : Icon(...),)
  /// ```
  final Widget? trailing;

  /// 각 인스턴스에 값을 할당하는 [FlatCard]의 생성자이다.
  ///
  /// ### Example
  /// ```dart
  /// // titleOnly 위젯 사용 예시
  /// FlatCard( title: '다크모드',
  ///   titleOnly: true,
  ///   bottomTitle: false, ...),
  ///   ```
  const FlatCard({
    Key? key,
    this.backgroundColor,
    this.subTitle,
    this.subLabel,
    this.subTail,
    required this.title,
    this.onTap,
    this.leading,
    this.bottomTitle = true,
    this.subTitleColor,
    this.titleOnly = false,
    this.trailing,
  }) : super(key: key);

  Widget _subTitleBuilder(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 90.w),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: RichText(
          text: TextSpan(
            text: subTitle,
            style: Theme.of(context).textTheme.bodyMedium!.apply(
                  color: subTitleColor,
                ),
            children: [
              TextSpan(text: subLabel),
              TextSpan(
                text: subTail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBuilder(BuildContext context) {
    return AutoSizeText(
      title,
      style: Theme.of(context).textTheme.headlineLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: backgroundColor,
      contentPadding: EdgeInsets.symmetric(
        vertical: SizeTheme.w_sm,
        horizontal: SizeTheme.h_lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          SizeTheme.r_sm,
        ),
      ),
      onTap: onTap,
      leading: leading,
      subtitle: titleOnly
          ? null
          : bottomTitle
              ? _titleBuilder(context)
              : _subTitleBuilder(context),
      title: titleOnly
          ? _titleBuilder(context)
          : bottomTitle
              ? _subTitleBuilder(context)
              : _titleBuilder(context),
      trailing: FittedBox(
        child: trailing,
      ),
    );
  }
}
