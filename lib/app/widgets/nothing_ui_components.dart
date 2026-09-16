import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// วิดเจ็ตพื้นฐานสไตล์ Nothing OS Design System
/// ผสมผสานความเรียบหรูแบบอินดัสเทรียล, เรขาคณิต Squircle, และไฟ LED Glyph

/// 1. ข้อความสไตล์ Nothing Dot Matrix / Monospace สำหรับตัวเลขและหัวข้อ
class NothingDotText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final double letterSpacing;
  final bool isMono;
  final TextAlign? textAlign;

  const NothingDotText(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.letterSpacing = 0.5,
    this.isMono = true,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    final baseStyle = isMono
        ? GoogleFonts.shareTechMono(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? defaultColor,
            letterSpacing: letterSpacing,
          )
        : GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? defaultColor,
            letterSpacing: letterSpacing,
          );

    return Text(
      text,
      textAlign: textAlign,
      style: baseStyle.copyWith(
        fontFamilyFallback: ['Prompt', 'sans-serif'],
      ),
    );
  }
}

/// 2. จุดไฟแสดงสถานะ LED สไตล์ Nothing (Nothing Red / Monochrome Pulse)
class NothingLedIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final bool isPulsing;

  const NothingLedIndicator({
    super.key,
    this.color = AppColors.nothingRed,
    this.size = 7.0,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// 3. การ์ดทรง Squircle สไตล์ Nothing OS พร้อมพื้นหลัง Dot-Matrix จางๆ
class NothingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showDotGrid;
  final VoidCallback? onTap;

  const NothingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 26,
    this.backgroundColor,
    this.borderColor,
    this.showDotGrid = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.border;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (showDotGrid) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NothingDotGridPainter(
                  dotColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  spacing: 16.0,
                ),
              ),
            ),
            content,
          ],
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// 4. แถบมาตรวัด LED แบบแบ่งส่วน (Segmented LED Health Bar)
class NothingSegmentedBar extends StatelessWidget {
  final int totalSegments;
  final int? filledSegments;
  final double? progress;
  final Color activeColor;
  final Color? inactiveColor;
  final double height;
  final double spacing;

  const NothingSegmentedBar({
    super.key,
    int? totalSegments,
    int? segments,
    this.filledSegments,
    this.progress,
    this.activeColor = AppColors.nothingRed,
    this.inactiveColor,
    this.height = 5.0,
    this.spacing = 3.0,
  }) : totalSegments = totalSegments ?? segments ?? 16;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultInactive = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final int count = totalSegments > 0 ? totalSegments : 16;
    final int filled = filledSegments ??
        ((progress ?? 0.0).clamp(0.0, 1.0) * count).round();

    return Row(
      children: List.generate(count, (index) {
        final isFilled = index < filled;
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : spacing),
            decoration: BoxDecoration(
              color: isFilled ? activeColor : (inactiveColor ?? defaultInactive),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

/// 5. ปุ่มแคปซูลทรง Nothing OS (Nothing Pill)
class NothingPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Color? color;
  final Color? selectedColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final bool showDot;
  final Color? dotColor;
  final bool isDotMatrix;
  final double? fontSize;

  const NothingPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.prefixIcon,
    this.color,
    this.selectedColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.showDot = false,
    this.dotColor,
    this.isDotMatrix = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveAccent = color ?? selectedColor;

    final Color bg = isSelected
        ? (effectiveAccent ?? (isDark ? Colors.white : Colors.black))
        : (effectiveAccent != null
            ? effectiveAccent.withValues(alpha: isDark ? 0.16 : 0.10)
            : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary));

    final Color fg = textColor ??
        (isSelected
            ? (effectiveAccent != null ? Colors.white : (isDark ? Colors.black : Colors.white))
            : (effectiveAccent ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)));

    final Color border = isSelected
        ? (effectiveAccent ?? (isDark ? Colors.white : Colors.black))
        : (effectiveAccent != null
            ? effectiveAccent.withValues(alpha: isDark ? 0.40 : 0.30)
            : (isDark ? AppColors.darkBorder : AppColors.border));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor ?? (isSelected ? Colors.white : AppColors.nothingRed),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (dotColor ?? AppColors.nothingRed).withValues(alpha: 0.4),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: (isDotMatrix
                    ? GoogleFonts.shareTechMono(
                        fontSize: fontSize ?? 12,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 0.6,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: fontSize ?? 12,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 0.3,
                      )).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6. หัวข้อส่วนสไตล์ Nothing OS (Wide Tracking All-Caps Header)
class NothingSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showRedPip;

  const NothingSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showRedPip = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        if (showRedPip) ...[
          const NothingLedIndicator(size: 6, color: AppColors.nothingRed),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Custom Painter สำหรับวาดจุด Dot Grid สไตล์จอ Nothing
class _NothingDotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  _NothingDotGridPainter({
    required this.dotColor,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NothingDotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor || oldDelegate.spacing != spacing;
  }
}
