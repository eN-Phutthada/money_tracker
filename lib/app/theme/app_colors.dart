import 'package:flutter/material.dart';

/// ชุดสี Modern FinTech 2026 Palette สำหรับ Money Tracker
class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFF10B981);       // Sage Green (กระแสเงินสดเชิงบวก)
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color accent = Color(0xFF8B5CF6);        // Cyber Lavender (เงินออม & ลงทุน)
  static const Color accentLight = Color(0xFFEDE9FE);

  // Radiant Gradient Tokens (FinTech 2026 Signature)
  static const List<Color> primaryGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> accentGradient = [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
  static const List<Color> deficitGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
  static const List<Color> fixedCostGradient = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const List<Color> variableCostGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> cosmicNavyGradient = [Color(0xFF111726), Color(0xFF090D16)];

  // Light Mode Palette
  static const Color background = Color(0xFFF8FAFC);    // Warm Off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);
  static const Color textPrimary = Color(0xFF0F172A);   // Muted Charcoal
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF090D16); // Deep Cosmic Navy
  static const Color darkSurface = Color(0xFF111726);    // Slate Glass
  static const Color darkSurfaceSecondary = Color(0xFF1B2236);
  static const Color darkBorder = Color(0xFF242E47);
  static const Color darkDivider = Color(0xFF1E283D);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Cost Nature Colors
  static const Color fixedCostAccent = Color(0xFF3B82F6);     // Sapphire Blue
  static const Color fixedCostPastel = Color(0xFFEFF6FF);
  static const Color variableCostAccent = Color(0xFFF59E0B);  // Amber Gold
  static const Color variableCostPastel = Color(0xFFFFFBEB);

  // Status & Financial Health (Surplus / Deficit / Warning)
  static const Color warning = Color(0xFFF59E0B);           // Amber Warning
  static const Color surplusBg = Color(0xFFECFDF5);
  static const Color surplusBorder = Color(0xFFA7F3D0);
  static const Color surplusText = Color(0xFF065F46);

  static const Color deficitBg = Color(0xFFFFF1F2);
  static const Color deficitBorder = Color(0xFFFECDD3);
  static const Color deficitText = Color(0xFFE11D48);       // Rose Quartz
}
