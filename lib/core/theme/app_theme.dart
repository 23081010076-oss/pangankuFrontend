import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Color Palette - Natural & Modern
  static const Color forest = Color(0xFF1E5631); // Dark forest green
  static const Color leaf = Color(0xFF2D6A4F); // Primary green
  static const Color moss = Color(0xFF40916C); // Secondary green
  static const Color sage = Color(0xFF52B788); // Light accent
  static const Color mint = Color(0xFF74C69D); // Very light accent
  static const Color cream = Color(0xFFFFF8F0); // Background
  static const Color sand = Color(0xFFFFF3E0); // Light background

  // Functional Colors
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFEF5350);
  static const Color danger = Color(0xFFEF5350); // Same as error
  static const Color info = Color(0xFF42A5F5);
  static const Color primaryLight = Color(0xFFE8F5E9); // Light green

  // Neutral Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, leaf, moss],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [moss, sage, mint],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, surface],
  );

  // Typography
  static const String fontFamily = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge =
      BorderRadius.all(Radius.circular(24));

  // Spacing
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: leaf,
          secondary: moss,
          tertiary: sage,
          error: error,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        fontFamily: fontFamily,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: surface,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: radiusLarge),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: leaf,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(
                horizontal: spaceLG, vertical: spaceMD,),
            shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
            textStyle: button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: leaf,
            textStyle: button.copyWith(fontSize: 14),
            padding: const EdgeInsets.symmetric(
                horizontal: spaceMD, vertical: spaceSM,),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: const OutlineInputBorder(
            borderRadius: radiusMedium,
            borderSide: BorderSide(color: divider, width: 1.5),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: radiusMedium,
            borderSide: BorderSide(color: divider, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: radiusMedium,
            borderSide: BorderSide(color: leaf, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: radiusMedium,
            borderSide: BorderSide(color: error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spaceMD, vertical: spaceMD,),
          hintStyle: bodyLarge.copyWith(color: textTertiary),
          labelStyle: bodyMedium,
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          elevation: 8,
          selectedItemColor: leaf,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: bodySmall.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: bodySmall,
        ),
      );
}
