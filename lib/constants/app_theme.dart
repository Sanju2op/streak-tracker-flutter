import 'package:flutter/material.dart';

const kBgColor = Color(0xFFF2F2F7);
const kCardColor = Colors.white;
const kTextPrimary = Colors.black;
const kTextSecondary = Color(0xFF8E8E93);
const kDividerColor = Color(0xFFE5E5EA);

// Dark theme base colors
const kBgColorDark = Color(0xFF1C1C1E);
const kCardColorDark = Color(0xFF2C2C2E);
const kTextPrimaryDark = Colors.white;
const kTextSecondaryDark = Color(0xFF98989D);
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
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgColor,
      elevation: 0,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: kCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondary,
      elevation: 0,
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
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgColorDark,
      elevation: 0,
      iconTheme: IconThemeData(color: kTextPrimaryDark),
      titleTextStyle: TextStyle(
        color: kTextPrimaryDark,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: kCardColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF151515), // Slightly darker than bg
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondaryDark,
      elevation: 0,
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
