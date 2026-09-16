import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../widgets/nothing_ui_components.dart';
import 'app_colors.dart';
export '../widgets/app_feedback.dart';

/// คลาสรวมการตกแต่ง Dialog และ Modal Popup สไตล์ Nothing OS Design
/// - สไตล์ Minimal Monochrome คมชัดแบบ High-Contrast
/// - ขอบบางแบบ Hairline Border 0.8px
/// - ความโค้งมนทรง Squircle 26px
/// - Typography Space Grotesk และจุดแสดงสถานะ Nothing Red LED
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
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101010) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                  blurRadius: 36,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.94, 0.94),
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 240),
        ).fadeIn(
          duration: const Duration(milliseconds: 200),
        );
  }
}

/// Header ส่วนหัวของ Popup สไตล์ Nothing OS
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
                  color: isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor ?? (isDark ? Colors.white : Colors.black),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (onClose != null) ...[
              const SizedBox(width: 8),
              Material(
                color: isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onClose!();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 0.8,
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

/// การ์ดแสดงข้อมูลสไตล์ Nothing OS
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF141414) : const Color(0xFFF8F8F8)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
          width: 0.8,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// ไดอะล็อกยืนยันการดำเนินการ สไตล์ Nothing OS
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String? confirmText;
  final String? cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.icon,
    this.iconColor,
    this.confirmButtonColor,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = confirmButtonColor ?? AppColors.nothingRed;

    return AppGlassDialog(
      maxWidth: 420,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPopupHeader(
            title: title,
            icon: icon ?? Icons.help_outline_rounded,
            iconColor: iconColor ?? primaryColor,
            onClose: onCancel ?? () => Get.back(),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              fontWeight: FontWeight.w500,
              height: 1.5,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  cancelText ?? 'cancel'.tr.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: isDark ? AppColors.nothingSubtext : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  confirmText ?? 'confirm'.tr.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ไดอะล็อก/ชีตเลือกธีมการแสดงผล สไตล์ Nothing OS
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
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
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
                    const NothingLedIndicator(color: AppColors.nothingRed, size: 6),
                    const SizedBox(width: 8),
                    NothingDotText(
                      'THEME SETTINGS',
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : Colors.black,
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
                      size: 18,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF888888),
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
                  _buildNothingOptionTile(
                    title: 'theme_system'.tr,
                    subtitle: 'theme_system_desc'.tr,
                    icon: Icons.brightness_auto_outlined,
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () {
                      dashboardController.setThemeMode(ThemeMode.system);
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildNothingOptionTile(
                    title: 'theme_light'.tr,
                    subtitle: 'theme_light_desc'.tr,
                    icon: Icons.light_mode_outlined,
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () {
                      dashboardController.setThemeMode(ThemeMode.light);
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildNothingOptionTile(
                    title: 'theme_dark'.tr,
                    subtitle: 'theme_dark_desc'.tr,
                    icon: Icons.dark_mode_outlined,
                    isSelected: currentMode == ThemeMode.dark,
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

/// ไดอะล็อก/ชีตเลือกภาษา สไตล์ Nothing OS
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
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
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
                    const NothingLedIndicator(color: AppColors.nothingRed, size: 6),
                    const SizedBox(width: 8),
                    NothingDotText(
                      'LANGUAGE SETTINGS',
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : Colors.black,
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
                      size: 18,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF888888),
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
                  _buildNothingOptionTile(
                    title: 'lang_thai'.tr,
                    subtitle: 'lang_thai_desc'.tr,
                    badge: currentLang == 'th' ? 'ACTIVE' : null,
                    icon: Icons.translate_rounded,
                    isSelected: currentLang == 'th',
                    onTap: () {
                      dashboardController.setLanguage('th');
                      Navigator.of(ctx).pop();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildNothingOptionTile(
                    title: 'lang_english'.tr,
                    subtitle: 'lang_english_desc'.tr,
                    badge: currentLang == 'en' ? 'ACTIVE' : null,
                    icon: Icons.language_rounded,
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

Widget _buildNothingOptionTile({
  required String title,
  required String subtitle,
  String? badge,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return Material(
    color: isSelected
        ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE))
        : (isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9)),
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
                ? AppColors.nothingRed
                : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.nothingRed
                    : (isDark ? Colors.white : Colors.black),
              ),
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
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        NothingPill(
                          label: badge,
                          color: AppColors.nothingRed.withValues(alpha: 0.15),
                          textColor: AppColors.nothingRed,
                          isDotMatrix: true,
                          fontSize: 9,
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const NothingLedIndicator(color: AppColors.nothingRed, size: 8),
          ],
        ),
      ),
    ),
  );
}
