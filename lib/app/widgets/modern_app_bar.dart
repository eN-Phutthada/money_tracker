import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/security/controllers/security_controller.dart';
import '../theme/app_colors.dart';
import 'nothing_ui_components.dart';

/// วิดเจ็ตแถบเมนูด้านบนสไตล์ Nothing OS Design
/// - สไตล์ Minimal Monochrome คมชัดแบบ High-Contrast
/// - พื้นหลังโปร่งแสง Smoked Glass / Pitch Black พร้อม BackdropFilter Blur
/// - ปุ่มย้อนกลับและ Action Button ทรง Squircle มน 13px พร้อมขอบ Hairline 0.8px
/// - Typography: Space Grotesk / Monospace พร้อม Letter Spacing กว้าง
/// - จุด LED Indicator สีแดง Nothing Red บน Badge แสดงสถานะ
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

    // Leading Widget (Nothing Squircle Back Button by default if canPop or showBackButton)
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && canPop) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 2),
        child: Material(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (onBackPressed != null) {
                onBackPressed!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: isDark ? Colors.white : Colors.black,
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title!.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: NothingTypography.safeSpacing(title, 0.8),
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            if (badgeWidget != null) ...[
              const SizedBox(width: 8),
              badgeWidget!,
            ] else if (badgeText != null) ...[
              const SizedBox(width: 8),
              NothingPill(
                label: badgeText!,
                color: (badgeColor ?? AppColors.nothingRed).withValues(alpha: isDark ? 0.18 : 0.12),
                textColor: badgeColor ?? AppColors.nothingRed,
                showDot: true,
                dotColor: badgeColor ?? AppColors.nothingRed,
                isDotMatrix: true,
              ),
            ],
          ],
        ),
        if (subtitleWidget != null) ...[
          const SizedBox(height: 2),
          subtitleWidget!,
        ] else if (subtitle != null) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle!,
              style: NothingTypography.grotesk(
                fontSize: 10.5,
                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ],
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: (leadingWidget != null) ? 54 : 0,
      leading: leadingWidget,
      title: contentTitle,
      titleSpacing: leadingWidget != null ? 6 : 18,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F0F0F).withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.00),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.06),
                      ],
              ),
            ),
          ),
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
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.07),
              ),
          ],
        ),
      ),
    );
  }

  /// สร้างปุ่ม Action สไตล์ Nothing OS Red Accent (Primary Action)
  static Widget primaryActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    String? compactLabel,
    List<Color>? gradientColors,
    Color shadowColor = AppColors.nothingRed,
  }) {
    return Builder(
      builder: (context) {
        final isMobile = MediaQuery.sizeOf(context).width < 500;
        final resolvedLabel = isMobile
            ? (compactLabel ?? (label.contains(' ') ? label.split(' ').first : label))
            : label;

        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.nothingRed,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      resolvedLabel.toUpperCase(),
                      style: NothingTypography.grotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: NothingTypography.safeSpacing(resolvedLabel, 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        color: backgroundColor ??
            (isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: size,
              color: iconColor ?? (isDark ? Colors.white : Colors.black),
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

  /// วิดเจ็ตสถานะความปลอดภัยสไตล์ Nothing OS Squircle พร้อมไฟ LED (Live Security Pulse Badge)
  static Widget securityBadge({
    required BuildContext context,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Obx(() {
      final hasSec = Get.isRegistered<SecurityController>();
      final isPinOn = hasSec && Get.find<SecurityController>().isPinEnabled.value;
      final statusColor = isPinOn
          ? const Color(0xFF10B981)
          : (isDark ? AppColors.nothingRedLight : AppColors.nothingRed);

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: isPinOn ? 'security_pin_short'.tr : 'pin_security'.tr,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ??
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
                      ? const Color(0xFF141414)
                      : const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isPinOn ? Icons.shield_rounded : Icons.shield_outlined,
                      size: 13,
                      color: isDark ? Colors.white70 : Colors.black,
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

  /// วิดเจ็ตสลับธีม 1-Tap ทรง Squircle โมเดิร์นสไตล์ Nothing (Quick Theme Squircle)
  static Widget themeToggleButton({
    required BuildContext context,
    required bool isDark,
  }) {
    return Obx(() {
      final hasController = Get.isRegistered<DashboardController>();
      if (!hasController) return const SizedBox.shrink();
      final controller = Get.find<DashboardController>();
      final mode = controller.themeMode.value;
      final currentlyDark = (mode == ThemeMode.dark) ||
          (mode == ThemeMode.system && isDark);

      final IconData themeIcon = currentlyDark
          ? Icons.light_mode_rounded
          : Icons.dark_mode_rounded;
      final Color iconColor = currentlyDark
          ? const Color(0xFFFBBF24)
          : (isDark ? Colors.white : Colors.black);

      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: 'theme_label'.trParams({'theme': controller.themeModeName}),
          child: Material(
            color: isDark ? const Color(0xFF141414) : const Color(0xFFF4F4F4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? AppColors.nothingBorder
                    : Colors.black.withValues(alpha: 0.08),
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
                child: Icon(themeIcon, size: 17, color: iconColor),
              ),
            ),
          ),
        ),
      );
    });
  }
}
