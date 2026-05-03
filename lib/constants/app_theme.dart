import 'package:flutter/material.dart';

const kBgColor = Color(0xFFF2F2F7);
const kCardColor = Colors.white;
const kAccentBlue = Color(0xFF007AFF);
const kTextPrimary = Colors.black;
const kTextSecondary = Color(0xFF8E8E93);
const kCardRadius = BorderRadius.all(Radius.circular(16));
const kSheetRadius = BorderRadius.vertical(top: Radius.circular(20));
const kDividerColor = Color(0xFFE5E5EA);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgColor,
    cardColor: kCardColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccentBlue,
      primary: kAccentBlue,
      surface: kCardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgColor,
      elevation: 0,
      foregroundColor: kTextPrimary,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: kCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: kCardRadius),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCardColor,
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondary,
      elevation: 0,
    ),
  );
}
