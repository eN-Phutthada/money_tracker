import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/security/controllers/security_controller.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// วิดเจ็ตแถบเมนูด้านบนสไตล์ Modern FinTech 2026 (Modern Frosted Glass AppBar)
/// มีเอกลักษณ์หรูหราเป็นหนึ่งเดียวทั่วทั้งแอปพลิเคชัน:
/// - พื้นผิวกระจกฝ้า Frosted Glass พร้อม BackdropFilter Blur
/// - ปุ่มย้อนกลับทรงมน Squircle สไตล์โมเดิร์น พร้อมสัมผัส Haptic
/// - หัวข้อตัวหนา คมชัด พร้อมชิป Badge แสดงสถานะ/จำนวน พร้อมจุด LED Indicator
/// - คำอธิบายย่อย (Subtitle) บอกหน้าที่ของหน้านั้น
/// - ปุ่ม Action สไตล์ Radiant Gradient หรือ Squircle Surface
/// - เส้นแบ่งขอบบางระดับ Ambient Hairline ที่นุ่มนวล
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final String? badgeText;
  final Widget? badgeWidget;
  final Color? badgeColor;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBottomBorder;
  final double toolbarHeight;

  const ModernAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.badgeText,
    this.badgeWidget,
    this.badgeColor,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.bottom,
    this.showBottomBorder = true,
    this.toolbarHeight = 64.0,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(
      toolbarHeight + bottomHeight + (showBottomBorder ? 1.0 : 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    // Leading Widget (Luxury Squircle Back Button by default if canPop or showBackButton)
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && canPop) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(left: 14, top: 11, bottom: 11, right: 2),
        child: Material(
          color: isDark
              ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.85)
              : AppColors.surfaceSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.6)
                  : AppColors.border.withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          elevation: isDark ? 0 : 0.5,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (onBackPressed != null) {
                onBackPressed!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(13),
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    // Title & Subtitle block
    Widget contentTitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titleWidget != null)
              Flexible(child: titleWidget!)
            else if (title != null)
              Flexible(
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (badgeWidget != null) ...[
              const SizedBox(width: 8),
              badgeWidget!,
            ] else if (badgeText != null) ...[
              const SizedBox(width: 8),
              _buildBadgePill(
                badgeText!,
                badgeColor ?? AppColors.primary,
                isDark,
              ),
            ],
          ],
        ),
        if (subtitleWidget != null) ...[
          const SizedBox(height: 2),
          subtitleWidget!,
        ] else if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return AppBar(
      backgroundColor: (isDark ? AppColors.darkSurface : AppColors.surface)
          .withValues(alpha: isDark ? 0.86 : 0.90),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: (leadingWidget != null) ? 54 : 0,
      leading: leadingWidget,
      title: contentTitle,
      titleSpacing: leadingWidget != null ? 6 : 18,
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(
          (bottom?.preferredSize.height ?? 0.0) +
              (showBottomBorder ? 1.0 : 0.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?bottom,
            if (showBottomBorder)
              Container(
                height: 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark ? AppColors.darkBorder : AppColors.border)
                          .withValues(alpha: 0.3),
                      (isDark ? AppColors.darkBorder : AppColors.border)
                          .withValues(alpha: 0.85),
                      (isDark ? AppColors.darkBorder : AppColors.border)
                          .withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBadgePill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4.5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// สร้างปุ่ม Action สไตล์ Radiant Gradient เด่น (Primary Action)
  static Widget primaryActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    List<Color> gradientColors = const [
      AppColors.primary,
      AppColors.primaryDark,
    ],
    Color shadowColor = AppColors.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// สร้างปุ่มไอคอนสไตล์ Squircle Surface (Secondary Action)
  static Widget squircleIconButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isDark,
    String? tooltip,
    double size = 18,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final btn = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color:
            backgroundColor ??
            (isDark
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.85)
                : AppColors.surfaceSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.55)
                : AppColors.border.withValues(alpha: 0.65),
            width: 0.8,
          ),
        ),
        elevation: isDark ? 0 : 0.5,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: size,
              color:
                  iconColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  /// 1. วิดเจ็ตเข็มทิศความปลอดภัยพร้อมไฟ LED กระพริบ (Live Security Pulse Badge)
  static Widget securityBadge({
    required BuildContext context,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Obx(() {
      final hasSec = Get.isRegistered<SecurityController>();
      final isPinOn =
          hasSec && Get.find<SecurityController>().isPinEnabled.value;
      final statusColor = isPinOn ? const Color(0xFF10B981) : AppColors.primary;

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: isPinOn ? 'security_pin_short'.tr : 'pin_security'.tr,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  onTap ??
                  () {
                    HapticFeedback.selectionClick();
                    if (Get.currentRoute != Routes.PIN_SETTINGS) {
                      Get.toNamed(Routes.PIN_SETTINGS);
                    }
                  },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? statusColor.withValues(alpha: 0.12)
                      : statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: isDark ? 0.30 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.65),
                            blurRadius: 5,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isPinOn ? Icons.shield_rounded : Icons.shield_outlined,
                      size: 13,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 2. วิดเจ็ตสลับธีม 1-Tap ทรง Squircle โมเดิร์น (Quick Theme Morphing Squircle)
  static Widget themeToggleButton({
    required BuildContext context,
    required bool isDark,
  }) {
    return Obx(() {
      final hasController = Get.isRegistered<DashboardController>();
      if (!hasController) return const SizedBox.shrink();
      final controller = Get.find<DashboardController>();
      final mode = controller.themeMode.value;

      final IconData themeIcon;
      final Color iconColor;
      if (mode == ThemeMode.dark) {
        themeIcon = Icons.light_mode_rounded;
        iconColor = const Color(0xFFFBBF24);
      } else if (mode == ThemeMode.light) {
        themeIcon = Icons.dark_mode_rounded;
        iconColor = const Color(0xFF6366F1);
      } else {
        themeIcon = Icons.brightness_auto_rounded;
        iconColor = AppColors.primary;
      }

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: 'theme_label'.trParams({'theme': controller.themeModeName}),
          child: Material(
            color: isDark
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.85)
                : AppColors.surfaceSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.border.withValues(alpha: 0.70),
                width: 0.8,
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                controller.toggleTheme();
              },
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(themeIcon, size: 18, color: iconColor),
              ),
            ),
          ),
        ),
      );
    });
  }
}
