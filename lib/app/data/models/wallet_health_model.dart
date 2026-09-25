import 'package:flutter/material.dart';

/// ระดับสุขภาพการเงิน (Financial Health Tiers)
enum WalletHealthTier {
  /// 90 - 100: ยอดเยี่ยม ออมเงินตามเป้า ใช้เงินต่ำกว่าเกณฑ์
  optimal,

  /// 75 - 89: มั่นคง ปลอดภัย มีเงินสำรองพร้อมจ่ายบิลคงที่
  healthy,

  /// 50 - 74: เฝ้าระวัง การใช้จ่ายเริ่มตึงตัวหรือเร็วกว่าเวลา
  fair,

  /// < 50: วิกฤต ขาดดุล มีความเสี่ยงเงินหมดก่อนสิ้นเดือน
  critical,
}

/// ข้อมูลการประเมินในแต่ละมิติ (Financial Dimension Breakdown)
class WalletHealthDimension {
  final String title;
  final double score;
  final double maxScore;
  final String statusText;
  final String detail;
  final bool isHealthy;
  final IconData icon;

  const WalletHealthDimension({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.statusText,
    required this.detail,
    required this.isHealthy,
    required this.icon,
  });

  double get ratio => maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
}

/// ข้อเสนอแนะหรือคำแนะนำเชิงปฏิบัติ (Actionable Advice Item)
class WalletHealthInsight {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WalletHealthInsight({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });
}

/// ผลการวินิจฉัยสุขภาพกระเป๋าเงินฉบับสมบูรณ์ (Complete Wallet Health Diagnostics)
class WalletHealthResult {
  final int totalScore; // 0 - 100
  final WalletHealthTier tier;
  final double runwayDays; // จำนวนวันที่เงินอยู่รอดได้
  final double burnRateMultiplier; // ความเร็วการใช้เงินเทียบกับเวลา (1.0 = พอดี)
  final double suggestedDailyPace; // โควตารายวันที่แนะนำเพื่อความปลอดภัย
  final String headlineAdvice; // ข้อความสรุปสั้น 1 บรรทัดบนการ์ด
  final List<WalletHealthDimension> dimensions; // 4 มิติย่อย
  final List<WalletHealthInsight> insights; // รายการคำแนะนำ

  const WalletHealthResult({
    required this.totalScore,
    required this.tier,
    required this.runwayDays,
    required this.burnRateMultiplier,
    required this.suggestedDailyPace,
    required this.headlineAdvice,
    required this.dimensions,
    required this.insights,
  });

  /// สีหลักประจำระดับสุขภาพ
  Color get tierColor {
    switch (tier) {
      case WalletHealthTier.optimal:
        return const Color(0xFF10B981); // Emerald
      case WalletHealthTier.healthy:
        return const Color(0xFF3B82F6); // Blue / Cyan
      case WalletHealthTier.fair:
        return const Color(0xFFF59E0B); // Amber
      case WalletHealthTier.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// ชื่อระดับสุขภาพตามคีย์ภาษา
  String get tierKey {
    switch (tier) {
      case WalletHealthTier.optimal:
        return 'health_tier_optimal';
      case WalletHealthTier.healthy:
        return 'health_tier_healthy';
      case WalletHealthTier.fair:
        return 'health_tier_fair';
      case WalletHealthTier.critical:
        return 'health_tier_critical';
    }
  }
}
