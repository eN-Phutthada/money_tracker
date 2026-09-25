import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Ultra-Modern Nothing OS Page Transition — In-Place Smooth Cross-Fade
/// - ทางเข้า (Entrance): Fade (0 → 1) + Subtle Micro-Scale (0.99 → 1.0) อยู่กับที่
///   ไม่มีการเลื่อนด้านข้างเพื่อให้ LiquidGlassNavDock นิ่งตลอดเวลา
/// - ทางออกชั้นรอง (Secondary Exit): เฟดลงเล็กน้อย (1.0 → 0.92) ไม่มีการเคลื่อนที่
/// - ใช้ Curve `Curves.easeOutCubic` 220ms สัมผัสพรีเมียม ตอบสนองรวดเร็ว
class ModernNothingTransition extends CustomTransition {
  ModernNothingTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Incoming page: fade in + subtle micro-scale (0.99 → 1.0) — no lateral slide
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.99, end: 1.0).animate(curvedAnimation),
        // Outgoing page (secondary): subtle fade down only — no lateral slide
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.92).animate(secondaryCurved),
          child: child,
        ),
      ),
    );
  }
}
