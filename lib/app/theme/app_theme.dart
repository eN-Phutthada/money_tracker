import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// กำหนดค่า ThemeData สไตล์ Nothing OS Design System
/// ผสมผสาน Typography สไตล์โมโนสเปซและอินดัสเทรียล (SpaceGrotesk / Prompt)
/// พร้อมผิวการ์ดทรง Squircle ขอบ Hairline คมกริบ
class AppTheme {
  static TextTheme _buildNothingTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;

    // Use SpaceGrotesk as primary tech font with Prompt for Thai glyphs
    final spaceTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final promptFallback = GoogleFonts.prompt();

    return spaceTheme.copyWith(
      displayLarge: spaceTheme.displayLarge?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: -1.0,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: spaceTheme.displayMedium?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: spaceTheme.headlineLarge?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: 0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: spaceTheme.headlineMedium?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: spaceTheme.titleLarge?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: 0.2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: spaceTheme.titleMedium?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: spaceTheme.labelLarge?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: spaceTheme.bodyLarge?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
      ),
      bodyMedium: spaceTheme.bodyMedium?.copyWith(
        fontFamilyFallback: [promptFallback.fontFamily ?? 'Prompt'],
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildNothingTextTheme(Brightness.light).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.textPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.nothingRed,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.deficitText,
        onError: Colors.white,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.6,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildNothingTextTheme(Brightness.dark).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkTextPrimary,
        onPrimary: Colors.black,
        secondary: AppColors.nothingRed,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.deficitText,
        onError: Colors.white,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 0.6,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
