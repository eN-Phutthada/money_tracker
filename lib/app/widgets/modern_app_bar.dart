import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// วิดเจ็ตแถบเมนูด้านบนสไตล์ Modern FinTech 2026 (Modern AppBar)
/// มีเอกลักษณ์เป็นหนึ่งเดียวทั่วทั้งแอปพลิเคชัน:
/// - ปุ่มย้อนกลับทรงมน Squircle พร้อมสัมผัส Haptic
/// - หัวข้อตัวหนา พร้อมชิป Badge แสดงสถานะ/จำนวน
/// - คำอธิบายย่อย (Subtitle) บอกหน้าที่ของหน้านั้น
/// - ปุ่ม Action สไตล์ Gradient หรือ Squircle Surface
/// - เส้นแบ่งขอบบางด้านล่าง
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
    return Size.fromHeight(toolbarHeight + bottomHeight + (showBottomBorder ? 1.0 : 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    // Leading Widget (Squircle Back Button by default if canPop or showBackButton)
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && canPop) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10, right: 2),
        child: Material(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
              _buildBadgePill(badgeText!, badgeColor ?? AppColors.primary, isDark),
            ],
          ],
        ),
        if (subtitleWidget != null) ...[
          const SizedBox(height: 1.5),
          subtitleWidget!,
        ] else if (subtitle != null) ...[
          const SizedBox(height: 1.5),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: (leadingWidget != null) ? 54 : 0,
      leading: leadingWidget,
      title: contentTitle,
      titleSpacing: leadingWidget != null ? 6 : 18,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight((bottom?.preferredSize.height ?? 0.0) + (showBottomBorder ? 1.0 : 0.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?bottom,
            if (showBottomBorder)
              Container(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                height: 1,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBadgePill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// สร้างปุ่ม Action สไตล์ Gradient เด่น (Primary Action)
  static Widget primaryActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    List<Color> gradientColors = const [AppColors.primary, AppColors.primaryDark],
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
        color: backgroundColor ?? (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
        borderRadius: BorderRadius.circular(12),
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
              color: iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
}
