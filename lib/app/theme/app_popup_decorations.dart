import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import 'app_colors.dart';
export '../widgets/app_feedback.dart';

/// คลาสรวมการตกแต่ง Dialog และ Modal Popup สไตล์ LiquidGlass FinTech ระดับพรีเมียม
class AppGlassDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;

  const AppGlassDialog({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.maxHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight ?? double.infinity,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 36,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: LiquidGlassLens(
              style: LiquidGlassStyle(
                shape: const LiquidGlassShape.squircle(
                  cornerRadius: 26,
                  borderWidth: 1.2,
                  lightIntensity: 1.3,
                  lightDirection: 65,
                  borderType: OpticalBorder(
                    borderSaturation: 1.35,
                    ambientIntensity: 1.15,
                    borderSolidity: 0.25,
                  ),
                ),
                appearance: LiquidGlassAppearance(
                  color: isDark
                      ? const Color(0xFF111726).withValues(alpha: 0.65)
                      : const Color(0xFFFFFFFF).withValues(alpha: 0.76),
                  blur: const LiquidGlassBlur(sigmaX: 18, sigmaY: 18),
                ),
                refraction: const LiquidGlassRefraction(
                  distortion: 0.08,
                  distortionWidth: 28,
                  chromaticAberration: 0.002,
                ),
              ),
              child: Container(
                padding: padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.darkSurface.withValues(alpha: 0.30),
                            AppColors.darkSurfaceSecondary.withValues(alpha: 0.16),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.38),
                            Colors.white.withValues(alpha: 0.20),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.border.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.92, 0.92),
          curve: Curves.easeOutBack,
          duration: const Duration(milliseconds: 280),
        ).fadeIn(
          duration: const Duration(milliseconds: 220),
        );
  }
}

/// Header ส่วนหัวของ Popup สไตล์ Modern
class AppPopupHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onClose;
  final Widget? trailing;

  const AppPopupHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: effectiveColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: effectiveColor, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      shadows: [
                        Shadow(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.45),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              InkWell(
                onTap: onClose ?? () => Get.back(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.8)
                        : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Dialog ยืนยันการทำรายการแบบ Glassmorphism สวยงามระดับพรีเมียม
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'ยืนยัน',
    this.cancelText = 'ยกเลิก',
    this.icon,
    this.iconColor,
    this.confirmButtonColor,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = confirmButtonColor ?? AppColors.primary;

    return AppGlassDialog(
      maxWidth: 420,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPopupHeader(
            title: title,
            icon: icon,
            iconColor: iconColor ?? primaryColor,
            onClose: onCancel ?? () => Get.back(),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
              height: 1.55,
              shadows: [
                Shadow(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                  blurRadius: 1.5,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel ?? () => Get.back(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  cancelText,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ไดอะล็อก/ชีตเลือกธีมการแสดงผล (ตามระบบ | โหมดสว่าง | โหมดมืด) สไตล์ Glassmorphism
void showThemePickerDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dashboardController = Get.find<DashboardController>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dashboardController.isEnglish ? 'Display Theme' : 'ธีมการแสดงผล',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options List
            Obx(() {
              final currentMode = dashboardController.themeMode.value;

              return Column(
                children: [
                  _buildThemeOptionTile(
                    title: dashboardController.isEnglish ? 'Light Mode' : 'โหมดสว่าง',
                    subtitle: dashboardController.isEnglish
                        ? 'Crisp, bright white background'
                        : 'พื้นหลังโทนขาว คมชัด สดใส สบายตา',
                    icon: Icons.light_mode_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    isSelected: currentMode == ThemeMode.light || (currentMode == ThemeMode.system && !isDark),
                    onTap: () {
                      dashboardController.setThemeMode(ThemeMode.light);
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOptionTile(
                    title: dashboardController.isEnglish ? 'Dark Mode' : 'โหมดมืด',
                    subtitle: dashboardController.isEnglish
                        ? 'Sleek dark background, easy on the eyes'
                        : 'พื้นหลังโทนเข้ม ถนอมสายตา และประหยัดแบตเตอรี่',
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF6366F1),
                    isSelected: currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && isDark),
                    onTap: () {
                      dashboardController.setThemeMode(ThemeMode.dark);
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                ],
              );
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildThemeOptionTile({
  required String title,
  required String subtitle,
  String? badge,
  required IconData icon,
  required Color iconColor,
  required bool isSelected,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return Material(
    color: isSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    ),
  );
}

/// ไดอะล็อก/ชีตเลือกภาษา (ภาษาไทย | English) สไตล์ Glassmorphism
void showLanguagePickerDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dashboardController = Get.find<DashboardController>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'language_settings'.tr,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options List
            Obx(() {
              final currentLang = dashboardController.currentLanguage.value;

              return Column(
                children: [
                  _buildThemeOptionTile(
                    title: 'ภาษาไทย',
                    subtitle: 'แสดงผลเป็นภาษาไทย และปี พ.ศ.',
                    badge: currentLang == 'th' ? 'ปัจจุบัน' : null,
                    icon: Icons.flag_rounded,
                    iconColor: const Color(0xFFEF4444),
                    isSelected: currentLang == 'th',
                    onTap: () {
                      dashboardController.setLanguage('th');
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOptionTile(
                    title: 'English',
                    subtitle: 'Display in English with Gregorian Year (CE)',
                    badge: currentLang == 'en' ? 'Active' : null,
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    isSelected: currentLang == 'en',
                    onTap: () {
                      dashboardController.setLanguage('en');
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                ],
              );
            }),
          ],
        ),
      );
    },
  );
}

