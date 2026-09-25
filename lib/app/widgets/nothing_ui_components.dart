import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../theme/app_colors.dart';

/// วิดเจ็ตพื้นฐานสไตล์ Nothing OS Design System
/// ผสมผสานความเรียบหรูแบบอินดัสเทรียล, เรขาคณิต Squircle, และไฟ LED Glyph

/// ตัวช่วยกำหนดรูปแบบตัวอักษรสไตล์ Nothing OS Design System
/// พร้อม fallback ฟอนต์ไทย (Prompt) และระบบป้องกันตัวอักษรไทยสระลอย/ห่างเกินไป
class NothingTypography {
  static const List<String> fallbackFonts = ['Prompt', 'sans-serif'];

  /// ตรวจสอบว่าข้อความมีอักขระภาษาไทยหรือไม่
  static bool hasThai(String text) => RegExp(r'[\u0E00-\u0E7F]').hasMatch(text);

  /// คืนค่า letterSpacing ที่ปลอดภัย (สำหรับภาษาไทยห้ามเกิน 0.3 ป้องกันสระลอย/วรรณยุกต์หลุด)
  static double safeSpacing(String? text, double desiredSpacing) {
    if (text == null || text.isEmpty) return desiredSpacing;
    return hasThai(text) ? 0.2 : desiredSpacing;
  }

  /// ฟอนต์ Space Grotesk สำหรับหัวข้อ, ปุ่ม, แท็บ, ฉลาก, ป้ายสถานะ
  static TextStyle grotesk({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0.2,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    ).copyWith(
      fontFamilyFallback: fallbackFonts,
    );
  }

  /// ฟอนต์ Share Tech Mono สำหรับตัวเลข, จำนวนเงิน, สถิติ, วันที่เวลา, มาตรวัด
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 0.0,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.shareTechMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    ).copyWith(
      fontFamilyFallback: fallbackFonts,
    );
  }
}

/// 1. ข้อความสไตล์ Nothing Dot Matrix / Monospace สำหรับตัวเลขและหัวข้อ
class NothingDotText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final double letterSpacing;
  final bool isMono;
  final TextAlign? textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const NothingDotText(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.letterSpacing = 0.5,
    this.isMono = true,
    this.textAlign,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final effectiveSpacing = NothingTypography.safeSpacing(text, letterSpacing);

    final baseStyle = style ?? (isMono
        ? NothingTypography.mono(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? defaultColor,
            letterSpacing: effectiveSpacing,
          )
        : NothingTypography.grotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? defaultColor,
            letterSpacing: effectiveSpacing,
          ));

    return Text(
      text,
      textAlign: textAlign,
      style: baseStyle,
      maxLines: maxLines,
      overflow: overflow,
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
  final bool isGlass;

  const NothingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 26,
    this.backgroundColor,
    this.borderColor,
    this.showDotGrid = true,
    this.onTap,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.border;

    Widget cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: isGlass
            ? null
            : Border.all(
                color: borderColor ?? defaultBorder,
                width: 1.0,
              ),
      ),
      child: child,
    );

    if (showDotGrid) {
      cardBody = Stack(
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
          cardBody,
        ],
      );
    }

    if (isGlass) {
      final glassStyle = LiquidGlassStyle(
        shape: LiquidGlassShape.squircle(
          cornerRadius: borderRadius,
          borderWidth: 1.0,
          lightIntensity: 1.25,
          lightDirection: 65,
          borderType: const OpticalBorder(
            borderSaturation: 1.2,
            ambientIntensity: 1.1,
            borderSolidity: 0.18,
          ),
        ),
        appearance: LiquidGlassAppearance(
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.50),
          blur: const LiquidGlassBlur(sigmaX: 1, sigmaY: 1),
        ),
        refraction: const LiquidGlassRefraction(
          distortion: 0.06,
          distortionWidth: 18,
          chromaticAberration: 0.002,
        ),
      );

      final adaptiveTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: LiquidGlassLens(
          style: glassStyle,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.15),
                      ],
              ),
              border: Border.all(
                color: borderColor ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.10)),
                width: 0.8,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              clipBehavior: Clip.antiAlias,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: adaptiveTextColor),
                child: IconTheme.merge(
                  data: IconThemeData(color: adaptiveTextColor),
                  child: onTap != null
                      ? InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: cardBody,
                        )
                      : cardBody,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: backgroundColor ?? defaultBg,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: cardBody,
            )
          : cardBody,
    );
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
  final bool animate;

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
    this.animate = true,
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
        Widget segment = Container(
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
        );

        if (animate && isFilled) {
          segment = segment
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 18 * index),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
              )
              .scaleX(
                begin: 0.0,
                end: 1.0,
                alignment: Alignment.centerLeft,
                delay: Duration(milliseconds: 18 * index),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
              );
        }

        return Expanded(child: segment);
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
            ? (effectiveAccent != null
                ? (effectiveAccent.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                : (isDark ? Colors.black : Colors.white))
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
                Builder(
                  builder: (context) {
                    final activeDot = dotColor ??
                        (isSelected
                            ? Colors.white
                            : (isDark ? AppColors.nothingRedLight : AppColors.nothingRed));
                    return Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: activeDot,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeDot.withValues(alpha: 0.4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: isDotMatrix
                      ? NothingTypography.mono(
                          fontSize: fontSize ?? 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: NothingTypography.safeSpacing(label, 0.6),
                        )
                      : NothingTypography.grotesk(
                          fontSize: fontSize ?? 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: NothingTypography.safeSpacing(label, 0.3),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
            style: NothingTypography.grotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: NothingTypography.safeSpacing(title, 1.8),
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
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

/// วิดเจ็ตแสดงตราสัญลักษณ์/ไอคอนแอพสไตล์ Nothing OS Design
/// โชว์ Minimalist Wallet Glyph พร้อมไฟสถานะ Nothing Red LED
class NothingAppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showBorder;

  const NothingAppLogo({
    super.key,
    this.size = 32,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.30);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.15),
                width: 0.8,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

