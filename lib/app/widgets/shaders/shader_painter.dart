import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// CustomPainter สำหรับเรนเดอร์ Fragment Shader ลงบน Canvas
class ShaderPainter extends CustomPainter {
  final ui.FragmentShader? shader;

  ShaderPainter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    if (shader == null || size.width <= 0 || size.height <= 0) {
      return;
    }

    try {
      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } catch (_) {
      // Fallback silently if shader context is lost
    }
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) =>
      oldDelegate.shader != shader;
}
