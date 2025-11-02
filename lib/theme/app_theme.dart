import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Material 3 theme for commercial property management application.
class AppTheme {
  AppTheme._();

  // MODERN COLOR PALETTE - Professional green theme
  static const Color primary = Color(0xFF2E7D32); // Professional green
  static const Color secondary = Color(0xFF66BB6A); // Green accent
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color warning = Color(0xFFF57C00); // Orange
  static const Color success = Color(0xFF388E3C); // Dark green
  static const Color background = Color(0xFFF5F5F5); // Very light gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color successAccent = Color(0xFF4CAF50);
  static const Color warningAccent = Color(0xFFFFB300);
  static const Color infoAccent = Color(0xFF29B6F6);
  static const Color alertRed = Color(0xFFE53935);
  static const Color primaryGreen = primary;
  static const Color neutralMedium = Color(0xFFB0BEC5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color shadowLight = Color(0x14000000);

  // Gradient colors for AppBar and special cards
  static const Color gradientStart = Color(0xFF1B5E20); // Dark green
  static const Color gradientEnd = Color(0xFF43A047); // Medium green

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLabel = Color(0xFF9E9E9E);

  // Shadow and effect colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color glassmorphismOverlay = Color(0x0DFFFFFF);

  /// Light theme with modern Material 3 design
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: surface,
      primaryContainer: Color(0xFFE8F5E8),
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: surface,
      secondaryContainer: Color(0xFFE8F5E8),
      onSecondaryContainer: textPrimary,
      tertiary: warning,
      onTertiary: surface,
      error: error,
      onError: surface,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: error,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: Color(0xFFF8F9FA),
      onSurfaceVariant: textSecondary,
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFF0F0F0),
      shadow: shadowColor,
      scrim: Color(0x80000000),
    ),

    scaffoldBackgroundColor: background,

    // Modern AppBar with gradient
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: surface,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: surface,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: surface, size: 24),
      actionsIconTheme: IconThemeData(color: surface, size: 24),
    ),

    // Modern card theme with elevated design
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surface,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Modern elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: shadowColor,
        backgroundColor: primary,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Modern outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Modern text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
    ),

    // Modern floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      backgroundColor: primary,
      foregroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Modern input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      focusColor: primary.withValues(alpha: 0.05),
      hoverColor: primary.withValues(alpha: 0.04),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFFDDE3E8), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFFDDE3E8), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: error, width: 1.6),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      helperStyle: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textLabel,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: error,
      ),
    ),

    // Modern text theme with Inter typography
    textTheme: _buildModernTextTheme(),

    // Modern bottom navigation bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),

    // Modern snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.inter(
        color: surface,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      actionTextColor: secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
    ),

    // Modern dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
    ),

    // Modern switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return primary.withAlpha(128);
        return textLabel.withAlpha(77);
      }),
    ),

    // Modern checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Modern progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: primary.withAlpha(51),
      circularTrackColor: primary.withAlpha(51),
    ),

    // Modern divider theme
    dividerTheme: DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
  );

  /// Modern text theme with clear hierarchy
  static TextTheme _buildModernTextTheme() {
    return TextTheme(
      // Main titles - fontSize: 28, fontWeight: FontWeight.bold
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),

      // Important amounts - fontSize: 32, fontWeight: FontWeight.w700
      headlineMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),

      // Card titles - fontSize: 20, fontWeight: FontWeight.w600
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Subtitles - fontSize: 16, fontWeight: FontWeight.w600
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),

      // Section titles
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Small titles
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
        height: 1.4,
      ),

      // Body text - fontSize: 14, fontWeight: FontWeight.normal
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),

      // Secondary body text
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Small body text
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        letterSpacing: 0.2,
        height: 1.4,
      ),

      // Labels - fontSize: 12, fontWeight: FontWeight.w500
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textLabel,
        letterSpacing: 0.3,
        height: 1.3,
      ),

      // Small labels
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textLabel,
        letterSpacing: 0.3,
        height: 1.3,
      ),

      // Tiny labels
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textLabel,
        letterSpacing: 0.4,
        height: 1.2,
      ),
    );
  }

  // Helper method to create gradient for AppBar
  static LinearGradient get appBarGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );

  // Helper method to create glassmorphism effect
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glassmorphismOverlay, glassmorphismOverlay.withAlpha(13)],
        ),
        border: Border.all(color: glassmorphismOverlay, width: 1),
      );

  // Helper method for modern card shadow
  static List<BoxShadow> get modernCardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8,
          offset: Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  // Helper method for elevated card shadow
  static List<BoxShadow> get elevatedCardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 12,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
      ];
}
