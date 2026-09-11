import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Base class สำหรับการโหลดและจัดการ Flutter Runtime Fragment Shader
abstract class BaseShader {
  final String shaderAssetPath;

  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _isLoaded = false;

  BaseShader({
    required this.shaderAssetPath,
  });

  ui.FragmentShader? get shader => _shader;
  bool get isLoaded => _isLoaded && _shader != null;

  /// โหลด Fragment Program จาก asset bundle
  Future<void> initialize() async {
    await _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(shaderAssetPath);
      _shader = _program!.fragmentShader();
      _isLoaded = true;
    } catch (e) {
      // Gracefully handle test environments or missing GPU SPIR-V compilers
      _isLoaded = false;
      _shader = null;
      debugPrint('BaseShader load notice ($shaderAssetPath): $e');
    }
  }

  /// อัปเดตพารามิเตอร์ (Uniforms) ให้แก่ Shader
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
  });
}
