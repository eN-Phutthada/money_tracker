import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงยอดเงินคงเหลือสุทธิและสถานะทางการเงิน สไตล์ Modern FinTech 2026
class BalanceCard extends GetView<DashboardController> {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final actual = controller.actualBalance;
      final expected = controller.expectedBalance;
      final surplus = controller.surplusOrDeficit;
      final isSurplus = controller.isSurplus;

      final Color statusBg = isSurplus
          ? (isDark ? const Color(0xFF063528) : AppColors.surplusBg)
          : (isDark ? const Color(0xFF381219) : AppColors.deficitBg);

      final Color statusBorder = isSurplus
          ? (isDark ? const Color(0xFF0D5E46) : AppColors.surplusBorder)
          : (isDark ? const Color(0xFF6B1D2C) : AppColors.deficitBorder);

      final Color statusText = isSurplus
          ? (isDark ? const Color(0xFF6EE7B7) : AppColors.surplusText)
          : (isDark ? const Color(0xFFFDA4AF) : AppColors.deficitText);

      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Health Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'กระแสเงินสดสุทธิ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Dynamic Health Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSurplus ? AppColors.primary : AppColors.deficitText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSurplus ? 'Safe Zone • เกินเป้า' : 'Caution • เกินงบ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusText,
                        ),
                      ),
                    ],
                  ),
                ).animate().shimmer(duration: const Duration(seconds: 2), delay: const Duration(seconds: 1)),
              ],
            ),
            const SizedBox(height: 14),

            // Actual Balance
            Text(
              'เงินคงเหลือจริง (Actual Balance)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFmt.format(actual),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 14),

            // Expected vs Difference Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ควรเหลือเงินตามแผน',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyFmt.format(expected),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isSurplus ? 'เงินคงเหลือเกินเป้า' : 'ขาดเงินไปจากแผน',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${isSurplus ? '+' : ''}${currencyFmt.format(surplus)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSurplus ? AppColors.primary : AppColors.deficitText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }
}
