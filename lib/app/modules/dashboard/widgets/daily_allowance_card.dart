import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงโควตาค่ากินรายวัน (Daily Allowance):
/// 1. ยอดใช้จ่ายและโควตาคงเหลือของ "วันนี้"
/// 2. โควตาเฉลี่ยต่อวันสำหรับวันที่เหลือของเดือน (Dynamic Monthly Run-rate)
class DailyAllowanceCard extends GetView<DashboardController> {
  const DailyAllowanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final targetDaily = controller.budgetPlan.value.targetDailyAllowance;
      final todaySpent = controller.todayVariableExpenses;
      final todayRemaining = controller.todayRemainingAllowance;
      final isOverToday = todayRemaining < 0;

      // Progress calculation for today's quota
      final usedProgress = targetDaily > 0 ? (todaySpent / targetDaily).clamp(0.0, 1.0) : 0.0;
      final usedPct = targetDaily > 0 ? (todaySpent / targetDaily * 100).toInt() : 0;

      // Color coding for today's ring & text
      final Color ringColor;
      if (isOverToday) {
        ringColor = AppColors.deficitText;
      } else if (usedProgress >= 0.85) {
        ringColor = const Color(0xFFF59E0B); // Amber warning
      } else {
        ringColor = AppColors.primary;
      }

      // Monthly Run-rate metrics
      final remainingDailyRunRate = controller.remainingDailyAllowance;
      final remainingDays = controller.remainingDaysInMonth;
      final isMonthlySafe = remainingDailyRunRate >= targetDaily * 0.7;

      return Container(
        padding: const EdgeInsets.all(18),
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
            // 1. Header: Title & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'daily_allowance_today'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Get.toNamed(Routes.BUDGET_SETTINGS),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2210) : AppColors.variableCostPastel,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'budget_settings'.tr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.variableCostAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.tune_rounded, size: 11, color: AppColors.variableCostAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Micro View: Today's spending & remaining
            Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(68, 68),
                        painter: _ProgressRingPainter(
                          progress: usedProgress,
                          isDark: isDark,
                          activeColor: ringColor,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isOverToday ? 'เกิน' : '$usedPct%',
                            style: TextStyle(
                              fontSize: isOverToday ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              color: isOverToday
                                  ? AppColors.deficitText
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            'วันนี้',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              isOverToday
                                  ? '${'over_for_today'.tr} ฿${(-todayRemaining).toStringAsFixed(0)}'
                                  : '${'remaining_for_today'.tr} ฿${todayRemaining.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isOverToday
                                    ? AppColors.deficitText
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              isOverToday ? ' ${'today_over'.tr}' : ' ${'today_used'.tr}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOverToday ? AppColors.deficitText : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${'today_spent'.tr} ฿${todaySpent.toStringAsFixed(0)} • ${'target'.tr} ฿${targetDaily.toStringAsFixed(0)}/${'day'.tr}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Macro View: Monthly Run-rate Bar for the rest of the month
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    remainingDays == 0 ? Icons.event_available_rounded : Icons.auto_graph_rounded,
                    size: 14,
                    color: AppColors.variableCostAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      remainingDays == 0
                          ? 'last_day_of_month'.tr
                          : 'monthly_runrate_label'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (remainingDays > 0) ...[
                    Text(
                      '฿${remainingDailyRunRate.toStringAsFixed(0)}/${'day'.tr}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isMonthlySafe
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                            : AppColors.deficitText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${'days_left'.trParams({'days': '$remainingDays'})})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'ends_today'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 50)).slideY(begin: 0.04);
    });
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color activeColor;

  _ProgressRingPainter({
    required this.progress,
    required this.isDark,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 6.0;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activeColor != activeColor;
}
