import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

// Border radius tokens — use these everywhere; never hardcode BorderRadius.circular()
const kCardRadius = BorderRadius.all(Radius.circular(16));
const kSheetRadius = BorderRadius.vertical(top: Radius.circular(20));
const kButtonRadius = BorderRadius.all(Radius.circular(12));
const kInnerRadius = BorderRadius.all(Radius.circular(8));
const kDialogRadius = BorderRadius.all(Radius.circular(28));
const kIconRadius = BorderRadius.all(Radius.circular(8));
const kPillRadius = BorderRadius.all(Radius.circular(100));

// Named nav-bar color for dark theme (replaces inline Color(0xFF121212))
const kNavBarColorDark = Color(0xFF0A0A0A);

// ---------------------------------------------------------------------------
// Light Theme
// ---------------------------------------------------------------------------

ThemeData buildAppTheme() => buildLightTheme();

ThemeData buildLightTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
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
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      // Large number on counter cards — DM Serif for drama
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: -2.0,
        height: 1.0,
      ),
      // Screen titles
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
        letterSpacing: -0.8,
      ),
      // Card section headers
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
        letterSpacing: -0.5,
      ),
      // AppBar title
      titleMedium: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
        letterSpacing: -0.4,
      ),
      // Body text
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: kTextPrimary,
        letterSpacing: -0.3,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: kTextPrimary,
        letterSpacing: -0.2,
      ),
      // Captions / secondary labels
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        color: kTextSecondary,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: kTextPrimary),
      titleTextStyle: GoogleFonts.dmSans(
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
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// ---------------------------------------------------------------------------
// Dark Theme
// ---------------------------------------------------------------------------

ThemeData buildDarkTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  return base.copyWith(
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
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: -2.0,
        height: 1.0,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: kTextPrimaryDark,
        letterSpacing: -0.8,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTextPrimaryDark,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kTextPrimaryDark,
        letterSpacing: -0.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: kTextPrimaryDark,
        letterSpacing: -0.3,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: kTextPrimaryDark,
        letterSpacing: -0.2,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        color: kTextSecondaryDark,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: kTextPrimaryDark),
      titleTextStyle: GoogleFonts.dmSans(
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
      backgroundColor: kNavBarColorDark,
      selectedItemColor: kAccentBlue,
      unselectedItemColor: kTextSecondaryDark,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// ---------------------------------------------------------------------------
// Context Extensions
// ---------------------------------------------------------------------------

extension AppColors on BuildContext {
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get dividerColor => Theme.of(this).dividerColor;
}
