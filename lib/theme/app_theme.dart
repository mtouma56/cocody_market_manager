import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the commercial property management application.
class AppTheme {
  AppTheme._();

  // Structured Business Palette - Functional color indicators for property management
  static const Color primaryGreen =
      Color(0xFF4CAF50); // Confirmation actions and positive status
  static const Color primaryBlue =
      Color(0xFF2196F3); // Navigation and informational content
  static const Color alertRed =
      Color(0xFFF44336); // Critical actions and overdue payments
  static const Color neutralDark =
      Color(0xFF212121); // Primary text and essential UI elements
  static const Color neutralMedium =
      Color(0xFF757575); // Secondary text and subtle components
  static const Color neutralLight =
      Color(0xFFFAFAFA); // Background surfaces and card containers
  static const Color successAccent =
      Color(0xFF66BB6A); // Completed payments and active leases
  static const Color warningAccent =
      Color(0xFFFF9800); // Pending actions and upcoming deadlines
  static const Color infoAccent =
      Color(0xFF42A5F5); // Property details and informational badges
  static const Color surfaceWhite =
      Color(0xFFFFFFFF); // Card surfaces and modal backgrounds

  // Dark theme variants
  static const Color primaryGreenDark = Color(0xFF66BB6A);
  static const Color primaryBlueDark = Color(0xFF42A5F5);
  static const Color alertRedDark = Color(0xFFEF5350);
  static const Color neutralDarkDark = Color(0xFFE0E0E0);
  static const Color neutralMediumDark = Color(0xFFBDBDBD);
  static const Color neutralLightDark = Color(0xFF121212);
  static const Color successAccentDark = Color(0xFF81C784);
  static const Color warningAccentDark = Color(0xFFFFB74D);
  static const Color infoAccentDark = Color(0xFF64B5F6);
  static const Color surfaceWhiteDark = Color(0xFF1E1E1E);

  // Shadow and divider colors
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x0AFFFFFF);
  static const Color dividerLight = Color(0x1F757575);
  static const Color dividerDark = Color(0x1FBDBDBD);

  /// Light theme optimized for commercial property management
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryGreen,
      onPrimary: surfaceWhite,
      primaryContainer: successAccent,
      onPrimaryContainer: neutralDark,
      secondary: primaryBlue,
      onSecondary: surfaceWhite,
      secondaryContainer: infoAccent,
      onSecondaryContainer: neutralDark,
      tertiary: warningAccent,
      onTertiary: neutralDark,
      tertiaryContainer: warningAccent.withValues(alpha: 0.2),
      onTertiaryContainer: neutralDark,
      error: alertRed,
      onError: surfaceWhite,
      surface: surfaceWhite,
      onSurface: neutralDark,
      onSurfaceVariant: neutralMedium,
      outline: dividerLight,
      outlineVariant: neutralLight,
      shadow: shadowLight,
      scrim: neutralDark.withValues(alpha: 0.5),
      inverseSurface: neutralDark,
      onInverseSurface: surfaceWhite,
      inversePrimary: primaryGreenDark,
    ),
    scaffoldBackgroundColor: neutralLight,
    cardColor: surfaceWhite,
    dividerColor: dividerLight,

    // AppBar theme for property management headers
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: neutralDark,
      elevation: 1.0,
      shadowColor: shadowLight,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: neutralDark,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: neutralDark,
        size: 24,
      ),
    ),

    // Card theme for property and tenant information
    cardTheme: CardTheme(
      color: surfaceWhite,
      elevation: 2.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // Bottom navigation for main property management sections
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: primaryBlue,
      unselectedItemColor: neutralMedium,
      elevation: 3.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating action button for quick property actions
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: surfaceWhite,
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Button themes for property management actions
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: surfaceWhite,
        backgroundColor: primaryGreen,
        elevation: 2.0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: primaryBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    // Typography for property management content
    textTheme: _buildTextTheme(isLight: true),

    // Input decoration for property data entry
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceWhite,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerLight, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerLight, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: alertRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: alertRed, width: 2.0),
      ),
      labelStyle: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: neutralMedium,
      ),
      hintStyle: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: neutralMedium,
      ),
    ),

    // Switch theme for property status toggles
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return neutralMedium;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen.withValues(alpha: 0.5);
        }
        return neutralMedium.withValues(alpha: 0.3);
      }),
    ),

    // Checkbox theme for property selections
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(surfaceWhite),
      side: const BorderSide(color: neutralMedium, width: 2),
    ),

    // Radio theme for property type selections
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return neutralMedium;
      }),
    ),

    // Progress indicator for data loading
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlue,
      linearTrackColor: neutralLight,
      circularTrackColor: neutralLight,
    ),

    // Slider theme for property value ranges
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryBlue,
      thumbColor: primaryBlue,
      overlayColor: primaryBlue.withValues(alpha: 0.2),
      inactiveTrackColor: neutralLight,
      valueIndicatorColor: primaryBlue,
    ),

    // Tab bar theme for property categories
    tabBarTheme: TabBarTheme(
      labelColor: primaryBlue,
      unselectedLabelColor: neutralMedium,
      indicatorColor: primaryBlue,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Tooltip theme for property information
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: neutralDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.roboto(
        color: surfaceWhite,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // SnackBar theme for property management notifications
    snackBarTheme: SnackBarThemeData(
      backgroundColor: neutralDark,
      contentTextStyle: GoogleFonts.roboto(
        color: surfaceWhite,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 3.0,
    ), dialogTheme: DialogThemeData(backgroundColor: surfaceWhite),
  );

  /// Dark theme optimized for property management in low-light conditions
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryGreenDark,
      onPrimary: neutralDarkDark,
      primaryContainer: successAccentDark,
      onPrimaryContainer: neutralLightDark,
      secondary: primaryBlueDark,
      onSecondary: neutralDarkDark,
      secondaryContainer: infoAccentDark,
      onSecondaryContainer: neutralLightDark,
      tertiary: warningAccentDark,
      onTertiary: neutralLightDark,
      tertiaryContainer: warningAccentDark.withValues(alpha: 0.2),
      onTertiaryContainer: neutralDarkDark,
      error: alertRedDark,
      onError: neutralLightDark,
      surface: surfaceWhiteDark,
      onSurface: neutralDarkDark,
      onSurfaceVariant: neutralMediumDark,
      outline: dividerDark,
      outlineVariant: neutralMediumDark,
      shadow: shadowDark,
      scrim: neutralLightDark.withValues(alpha: 0.5),
      inverseSurface: neutralDarkDark,
      onInverseSurface: neutralLightDark,
      inversePrimary: primaryGreen,
    ),
    scaffoldBackgroundColor: neutralLightDark,
    cardColor: surfaceWhiteDark,
    dividerColor: dividerDark,

    // AppBar theme for dark mode
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhiteDark,
      foregroundColor: neutralDarkDark,
      elevation: 1.0,
      shadowColor: shadowDark,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: neutralDarkDark,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: neutralDarkDark,
        size: 24,
      ),
    ),

    // Card theme for dark mode
    cardTheme: CardTheme(
      color: surfaceWhiteDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // Bottom navigation for dark mode
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceWhiteDark,
      selectedItemColor: primaryBlueDark,
      unselectedItemColor: neutralMediumDark,
      elevation: 3.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating action button for dark mode
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreenDark,
      foregroundColor: neutralLightDark,
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Button themes for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: neutralLightDark,
        backgroundColor: primaryGreenDark,
        elevation: 2.0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlueDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: primaryBlueDark, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlueDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    // Typography for dark mode
    textTheme: _buildTextTheme(isLight: false),

    // Input decoration for dark mode
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceWhiteDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerDark, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerDark, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryBlueDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: alertRedDark, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: alertRedDark, width: 2.0),
      ),
      labelStyle: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: neutralMediumDark,
      ),
      hintStyle: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: neutralMediumDark,
      ),
    ),

    // Switch theme for dark mode
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenDark;
        }
        return neutralMediumDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenDark.withValues(alpha: 0.5);
        }
        return neutralMediumDark.withValues(alpha: 0.3);
      }),
    ),

    // Checkbox theme for dark mode
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(neutralLightDark),
      side: const BorderSide(color: neutralMediumDark, width: 2),
    ),

    // Radio theme for dark mode
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenDark;
        }
        return neutralMediumDark;
      }),
    ),

    // Progress indicator for dark mode
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlueDark,
      linearTrackColor: neutralMediumDark,
      circularTrackColor: neutralMediumDark,
    ),

    // Slider theme for dark mode
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryBlueDark,
      thumbColor: primaryBlueDark,
      overlayColor: primaryBlueDark.withValues(alpha: 0.2),
      inactiveTrackColor: neutralMediumDark,
      valueIndicatorColor: primaryBlueDark,
    ),

    // Tab bar theme for dark mode
    tabBarTheme: TabBarTheme(
      labelColor: primaryBlueDark,
      unselectedLabelColor: neutralMediumDark,
      indicatorColor: primaryBlueDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Tooltip theme for dark mode
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: neutralDarkDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.roboto(
        color: neutralLightDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // SnackBar theme for dark mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: neutralDarkDark,
      contentTextStyle: GoogleFonts.roboto(
        color: neutralLightDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primaryGreenDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 3.0,
    ), dialogTheme: DialogThemeData(backgroundColor: surfaceWhiteDark),
  );

  /// Helper method to build text theme based on brightness for property management
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textPrimary = isLight ? neutralDark : neutralDarkDark;
    final Color textSecondary = isLight ? neutralMedium : neutralMediumDark;

    return TextTheme(
      // Display styles for property headers and titles
      displayLarge: GoogleFonts.roboto(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),

      // Headline styles for property names and section headers
      headlineLarge: GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),

      // Title styles for property cards and tenant information
      titleLarge: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),

      // Body styles for property descriptions and lease details
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: textSecondary,
        letterSpacing: 0.4,
      ),

      // Label styles for property codes, dates, and status indicators
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
