import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'base_shader.dart';
import 'shader_painter.dart';

/// วิดเจ็ตจัดการแคปเจอร์ภาพเบื้องหลัง (Background Capture) เพื่อป้อนเข้าสู่ Liquid Glass Shader
/// ตามสถาปัตยกรรมใน shaders/background_capture_widget.dart
class LiquidGlassBackgroundCapture extends StatefulWidget {
  final GlobalKey? backgroundKey;
  final BaseShader shader;
  final Widget child;
  final BorderRadius? borderRadius;
  final double? effectSize;
  final double? blurIntensity;
  final double? dispersionStrength;
  final double? refractionStrength;
  final Offset? focalPoint;
  final Widget Function(BuildContext context, Widget child)? fallbackBuilder;

  const LiquidGlassBackgroundCapture({
    super.key,
    required this.backgroundKey,
    required this.shader,
    required this.child,
    this.borderRadius,
    this.effectSize,
    this.blurIntensity,
    this.dispersionStrength,
    this.refractionStrength,
    this.focalPoint,
    this.fallbackBuilder,
  });

  @override
  State<LiquidGlassBackgroundCapture> createState() =>
      _LiquidGlassBackgroundCaptureState();
}

class _LiquidGlassBackgroundCaptureState
    extends State<LiquidGlassBackgroundCapture> {
  @override
  void initState() {
    super.initState();
    widget.shader.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRad = widget.borderRadius ?? BorderRadius.circular(28);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight > 0
            ? constraints.maxHeight
            : 66.0;

        if (widget.shader.isLoaded && widget.shader.shader != null) {
          widget.shader.updateShaderUniforms(
            width: width,
            height: height,
            backgroundImage: null,
            focalPoint: widget.focalPoint,
            effectSize: widget.effectSize,
            blurIntensity: widget.blurIntensity,
            dispersionStrength: widget.dispersionStrength,
            refractionStrength: widget.refractionStrength,
          );
        }

        return Container(
          // 1. Apple iOS 26 Multi-Depth Floating Elevation Shadows (UNCLIPPED!)
          // Note: NO opaque gradient fill here, so BackdropFilter samples actual screen content underneath!
          decoration: BoxDecoration(
            borderRadius: borderRad,
            boxShadow: [
              // Deep ambient suspension shadow (lifts dock above scrolling content)
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.60)
                    : const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: isDark ? 40 : 32,
                spreadRadius: -2,
                offset: const Offset(0, 14),
              ),
              // Contact occlusion shadow
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              // Liquid primary neon floor radiance
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              // Horizon razor specular caustic glint (top highlight)
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.80),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRad,
            child: BackdropFilter(
              // Sigma 14 provides silky liquid refraction while letting background widgets remain clearly visible!
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  // Layer A: Crystalline Liquid Glass Sheen (Clear, high light-transmission)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRad,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.08),
                                  const Color(0xFF1E293B).withValues(alpha: 0.03),
                                  const Color(0xFF0F172A).withValues(alpha: 0.12),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.white.withValues(alpha: 0.03),
                                  const Color(0xFFF8FAFC).withValues(alpha: 0.06),
                                ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Layer B: Directional Specular Glass Rim & Prismatic Dispersion (STROKE ONLY - 100% TRANSPARENT INTERIOR!)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LiquidGlassRimAndPrismPainter(
                        isDark: isDark,
                        cornerRadius: borderRad.topLeft.x,
                      ),
                    ),
                  ),

                  // Layer C: Hardware Fragment Shader (when loaded)
                  if (widget.shader.isLoaded && widget.shader.shader != null)
                    Positioned.fill(
                      child: CustomPaint(
                        size: Size(width, height),
                        painter: ShaderPainter(widget.shader.shader),
                      ),
                    ),

                  // Layer D: Child content (Nav buttons, icons)
                  widget.child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter สำหรับวาด Directional Specular Glass Rim & Prismatic Chromatic Dispersion
/// สไตล์ Apple iOS 26 / visionOS (STROKE ONLY - ไม่บดบังวิดเจ็ตเบื้องหลัง)
class LiquidGlassRimAndPrismPainter extends CustomPainter {
  final bool isDark;
  final double cornerRadius;

  const LiquidGlassRimAndPrismPainter({
    required this.isDark,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const strokeW = 1.2;
    final rect = (Offset.zero & size).deflate(strokeW / 2);
    final radius = Radius.circular(
      (cornerRadius > strokeW ? cornerRadius - strokeW / 2 : size.height / 2).clamp(0.0, 100.0),
    );
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // 1. Directional Specular Beveled Glass Rim (Apple Meniscus Edge Reflection)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.05),
              ]
            : [
                Colors.white.withValues(alpha: 0.88),
                Colors.white.withValues(alpha: 0.42),
                Colors.white.withValues(alpha: 0.16),
              ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, rimPaint);

    // 2. Prismatic Chromatic Dispersion Fringe along the rim
    // Apple iOS 26 optical rainbow refraction
    final prismPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFFF5252).withValues(alpha: isDark ? 0.16 : 0.12), // Red
          const Color(0xFFFFD700).withValues(alpha: isDark ? 0.20 : 0.15), // Amber
          const Color(0xFF10B981).withValues(alpha: isDark ? 0.24 : 0.18), // Emerald
          const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.24 : 0.20), // Cyan
          const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.20 : 0.16), // Blue
          const Color(0xFFE040FB).withValues(alpha: isDark ? 0.18 : 0.14), // Magenta
          const Color(0xFFFF5252).withValues(alpha: isDark ? 0.16 : 0.12), // Red loop
        ],
        stops: const [0.0, 0.18, 0.36, 0.54, 0.72, 0.88, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, prismPaint);

    // 3. Top Specular Caustic Hairline (Razor-sharp overhead ambient reflection)
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.50 : 0.85),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35],
      ).createShader(rect);

    canvas.drawRRect(rrect, causticPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassRimAndPrismPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.cornerRadius != cornerRadius;
}
