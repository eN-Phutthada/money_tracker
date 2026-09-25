import 'package:flutter/material.dart';

/// ชุดสี Nothing OS Design System Palette สำหรับ Money Tracker
/// โดดเด่นด้วยโทนสี Monochrome-first (ดำสนิท, ดำกราไฟต์, ขาวบริสุทธิ์)
/// พร้อมเอกลักษณ์ Nothing Red (#D71921) ในจุดดึงดูดสายตาและสถานะสด
class AppColors {
  // Signature Nothing Red Accent
  static const Color nothingRed = Color(0xFFD71921);       // Iconic Nothing Red
  static const Color nothingRedLight = Color(0xFFFF3B30);  // High-visibility Red
  static const Color nothingRedDark = Color(0xFFB3141A);

  // Brand Accents (Monochrome Core with Red Highlight)
  static const Color primary = Color(0xFFFFFFFF);          // Pure White Contrast
  static const Color primaryDark = Color(0xFFE5E5EA);
  static const Color primaryLight = Color(0xFFFFFFFF);
  static const Color accent = nothingRed;                  // Nothing Red Accent
  static const Color accentLight = Color(0xFFFF453A);

  // Nothing OS Minimalist Gradients
  static const List<Color> primaryGradient = [Color(0xFFFFFFFF), Color(0xFFD1D1D6)];
  static const List<Color> accentGradient = [Color(0xFFD71921), Color(0xFFB3141A)];
  static const List<Color> deficitGradient = [Color(0xFFD71921), Color(0xFF990F14)];
  static const List<Color> fixedCostGradient = [Color(0xFFE5E5EA), Color(0xFF8E8E93)];
  static const List<Color> variableCostGradient = [Color(0xFFD71921), Color(0xFFFF3B30)];
  static const List<Color> cosmicNavyGradient = [Color(0xFF141414), Color(0xFF000000)];

  // Light Mode Palette (Nothing OS Ceramic White)
  static const Color background = Color(0xFFF4F4F6);       // Clean Chalk White
  static const Color surface = Color(0xFFFFFFFF);          // Crisp White Card
  static const Color surfaceSecondary = Color(0xFFEBEBF0); // Muted Pill Surface
  static const Color border = Color(0xFFD1D1D6);           // Subtle Hairline
  static const Color divider = Color(0xFFE5E5EA);
  static const Color textPrimary = Color(0xFF000000);      // Pure Pitch Black
  static const Color textSecondary = Color(0xFF636366);    // Neutral Muted Gray
  static const Color textTertiary = Color(0xFF8E8E93);

  // Dark Mode Palette (Nothing OS Pitch Black)
  static const Color darkBackground = Color(0xFF000000);   // Pure Pitch Black
  static const Color darkSurface = Color(0xFF121212);      // Matte Charcoal Card
  static const Color darkSurfaceSecondary = Color(0xFF1C1C1E); // Elevated Pill Surface
  static const Color darkBorder = Color(0x2EFFFFFF);       // 18% White Precision Hairline
  static const Color darkDivider = Color(0x1FFFFFFF);      // 12% White Divider
  static const Color darkTextPrimary = Color(0xFFFFFFFF);  // Pure Crisp White
  static const Color darkTextSecondary = Color(0xFF8E8E93);// Soft Technical Gray
  static const Color darkTextTertiary = Color(0xFF636366); // Dark Gray

  // Cost Nature Colors (Clean Industrial Nothing Aesthetics)
  static const Color fixedCostAccent = Color(0xFFE5E5EA);  // Clean Industrial Silver
  static const Color fixedCostPastel = Color(0xFF2C2C2E);
  static const Color variableCostAccent = nothingRed;      // Red Accent for Spending
  static const Color variableCostPastel = Color(0xFF33080A);

  // Status & Financial Health
  static const Color warning = Color(0xFFFF9500);          // Amber Indicator
  static const Color surplusBg = Color(0xFF1A1A1A);
  static const Color surplusBorder = Color(0x3DFFFFFF);
  static const Color surplusText = Color(0xFFFFFFFF);

  static const Color deficitBg = Color(0xFF2B0A0D);
  static const Color deficitBorder = Color(0x66D71921);
  static const Color deficitText = nothingRed;             // Nothing Red for Deficit / Caution

  // Additional Nothing OS Aliases
  static const Color nothingBorder = Color(0x2EFFFFFF);    // 18% White Precision Hairline
  static const Color nothingSubtext = Color(0xFFA1A1AA);   // High-contrast Technical Gray
  static const Color nothingMuted = Color(0xFF8E8E93);     // Technical Muted Gray
  static const Color nothingGreen = Color(0xFF34C759);     // Vibrant Telemetry Green (Dark Mode)
  static const Color nothingGreenDark = Color(0xFF008736); // Deep Telemetry Green (Light Mode)
  static const Color nothingBlue = Color(0xFF3B82F6);      // Hi-tech Electric Blue (Savings)
  static const Color nothingBlueLight = Color(0xFF60A5FA); // Light Electric Blue (Dark Mode Savings)
  static const Color nothingAmber = Color(0xFFF59E0B);     // Industrial Amber (Withdrawal)
  static const Color nothingAmberLight = Color(0xFFFBBF24);// Light Amber (Dark Mode Withdrawal)
  static const Color nothingBlack = Color(0xFF000000);     // Pitch Black
  static const Color nothingCardDark = Color(0xFF121212);  // Matte Graphite

  // Adaptive Color Helpers for High Contrast in Light/Dark Modes
  static Color statusRed(bool isDark) => isDark ? nothingRedLight : nothingRed;
  static Color fixedCost(bool isDark) => isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C);
  static Color primaryAdaptive(bool isDark) => isDark ? Colors.white : Colors.black;

  // Unified 4-Pillar Financial Colors (Income, Expense, Savings, Withdrawal)
  static Color incomeColor(bool isDark) => isDark ? nothingGreen : nothingGreenDark;
  static Color expenseColor(bool isDark) => isDark ? nothingRedLight : nothingRed;
  static Color savingsColor(bool isDark) => isDark ? nothingBlueLight : nothingBlue;
  static Color withdrawalColor(bool isDark) => isDark ? nothingAmberLight : nothingAmber;
}
