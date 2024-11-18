// ignore_for_file: non_constant_identifier_names
part of core;

abstract class Themes {}

class SystemTheme implements Themes {
  static const String themeBox = 'themeBox';
  static const String mode = 'mode';

  static ThemeData systemMode(ColorScheme scheme) {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: scheme.primary,
        onPrimary: scheme.onPrimary,
        secondary: scheme.secondary,
        onSecondary: scheme.onSecondary,
        background: scheme.background,
        onBackground: scheme.onBackground,
        surface: scheme.surface,
      ),
      cardColor: scheme.background,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.secondary,
        actionsIconTheme: IconThemeData(
          color: scheme.onSecondary,
          size: 36.sp,
        ),
        foregroundColor: scheme.onSecondary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: scheme.onSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        iconColor: scheme.background,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIconColor: Colors.grey,
        labelStyle: TextStyle(
          color: scheme.onSecondary,
          fontSize: 22.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: SizeTheme.h_sm,
          horizontal: SizeTheme.w_md,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.background,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.background,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.background,
          ),
        ),
        fillColor: scheme.background,
        filled: true,
        focusColor: scheme.background,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.background,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.background,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: Size(double.minPositive, 52.h),
          padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 16.h),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14.r),
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        selectedIconTheme: IconThemeData(size: 32.sp),
        unselectedIconTheme: IconThemeData(size: 32.sp),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.background,
        thickness: 1.5,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: scheme.secondary,
        shape: Border.symmetric(
          horizontal: BorderSide(color: scheme.background, width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: scheme.onSecondary,
        ),
        titleLarge: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: scheme.onSecondary,
        ),
        titleMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.normal,
          color: scheme.onSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: scheme.onSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
          color: scheme.onSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: scheme.onBackground,
        ),
        labelMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: scheme.onSecondary,
        ),
      ),
    );
  }
}

class SizeTheme implements Themes {
  static final w_sm = 12.w;
  static final w_md = 16.w;
  static final w_lg = 24.w;

  static final h_sm = 14.h;
  static final h_md = 16.h;
  static final h_lg = 22.h;

  static final r_sm = 14.r;
  static final r_md = 26.r;
  static final r_lg = 36.r;
}

class ColorTheme implements Themes {
  static const Color highlight1 = Color(0xffFFBC42);
  static const Color highlight2 = Color(0xff619B8A);
  static const Color highlight3 = Color(0xff0496FF);
  static const Color highlight4 = Color(0xffD81159);
  static const Color highlight5 = Color.fromARGB(255, 31, 50, 147);
  static const Color highlight6 = Color(0xff2A2C41);
  static const Color highlight7 = Color.fromRGBO(209, 84, 66, 1);

  static const ColorScheme light = ColorScheme.light(
    primary: Color(0xff758BFD),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFFFFF),
    onSecondary: Color(0xff2A2C41),
    background: Color(0xffF1F2F6),
    onBackground: Color(0xff939AA3),
    surface: Color(0xffEAEAEA),
  );

  static const ColorScheme dark = ColorScheme.dark(
    primary: Color(0xff758BFD),
    onPrimary: Color.fromARGB(255, 255, 255, 255),
    secondary: Color.fromARGB(255, 40, 40, 40),
    onSecondary: Color(0xffF1F2F6),
    background: Colors.black,
    onBackground: Color(0xffEAEAEA),
    surface: Colors.grey,
  );
}
