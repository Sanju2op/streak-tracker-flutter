import 'package:flutter/material.dart';

const kBgColor = Color(0xFFF2F2F7);
const kCardColor = Colors.white;
const kTextPrimary = Colors.black;
const kTextSecondary = Color(0xFF8E8E93);
const kDividerColor = Color(0xFFE5E5EA);

// Dark theme base colors
const kBgColorDark = Color(0xFF000000); // Pure black for OLED
const kCardColorDark = Color(0xFF1C1C1E); // Standard iOS dark card
const kTextPrimaryDark = Colors.white;
const kTextSecondaryDark = Color(0xFF8E8E93);
const kDividerColorDark = Color(0xFF38383A);

// Shared
const kAccentBlue = Color(0xFF007AFF);
const kCardRadius = BorderRadius.all(Radius.circular(16));
const kSheetRadius = BorderRadius.vertical(top: Radius.circular(20));

ThemeData buildAppTheme() {
  return buildLightTheme();
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: kBgColor,
    cardColor: kCardColor,
    dividerColor: kDividerColor,
    colorScheme: const ColorScheme.light(
      primary: kAccentBlue,
      secondary: kAccentBlue,
      surface: kBgColor,
      onSurface: kTextPrimary,
      onSurfaceVariant: kTextSecondary,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: kTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(
        color: kTextPrimary,
        fontSize: 17,
        letterSpacing: -0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: kCardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgColorDark,
    cardColor: kCardColorDark,
    dividerColor: kDividerColorDark,
    colorScheme: const ColorScheme.dark(
      primary: kAccentBlue,
      secondary: kAccentBlue,
      surface: kBgColorDark,
      onSurface: kTextPrimaryDark,
      onSurfaceVariant: kTextSecondaryDark,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: kTextPrimaryDark,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: kTextPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(
        color: kTextPrimaryDark,
        fontSize: 17,
        letterSpacing: -0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: kTextPrimaryDark),
      titleTextStyle: TextStyle(
        color: kTextPrimaryDark,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: kCardColorDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondaryDark,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

extension AppColors on BuildContext {
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get dividerColor => Theme.of(this).dividerColor;
}
