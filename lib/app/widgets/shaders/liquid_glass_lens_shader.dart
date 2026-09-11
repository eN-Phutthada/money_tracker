import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'base_shader.dart';

/// Shader สำหรับสร้างเอฟเฟกต์เลนส์แก้วเหลว (Optical Liquid Glass Lens)
/// พร้อมคุณสมบัติการหักเหแสง (Refraction), การแยกสีรุ้ง (Chromatic Dispersion),
/// ขอบสะท้อนแสง (Superellipse Specular Rim), และการเบลอตามแนวทางของ shaders/liquid_glass_lens.frag
class LiquidGlassLensShader extends BaseShader {
  LiquidGlassLensShader({
    super.shaderAssetPath = 'shaders/liquid_glass_lens.frag',
  });

  @override
  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
    Offset? focalPoint,
    double? effectSize,
    double? blurIntensity,
    double? dispersionStrength,
    double? refractionStrength,
    Rect? sourceRect,
  }) {
    final s = shader;
    if (!isLoaded || s == null) return;

    final actualWidth = width > 0 ? width : 1.0;
    final actualHeight = height > 0 ? height : 1.0;
    final center = focalPoint ?? Offset(actualWidth / 2, actualHeight / 2);

    // Uniform 0, 1: uResolution
    s.setFloat(0, actualWidth);
    s.setFloat(1, actualHeight);

    // Uniform 2, 3: uMouse (Focal center of the liquid lens)
    s.setFloat(2, center.dx);
    s.setFloat(3, center.dy);

    // Uniform 4: uEffectSize
    s.setFloat(4, effectSize ?? 5.0);

    // Uniform 5: uBlurIntensity
    s.setFloat(5, blurIntensity ?? 0.0);

    // Uniform 6: uDispersionStrength (Chromatic dispersion)
    s.setFloat(6, dispersionStrength ?? 0.50);

    // Uniform 7: uRefractionStrength (Optical refraction / lens curvature)
    s.setFloat(7, refractionStrength ?? 2.2);
  }
}
