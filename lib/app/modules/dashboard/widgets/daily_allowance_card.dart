import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงโควตาค่ากินรายวัน (Daily Allowance & Run-rate)
/// สไตล์ Luxury Modern FinTech 2026 พร้อมวงแหวนนีออนและแถบสถิติความเร็วการใช้จ่าย
class DailyAllowanceCard extends GetView<DashboardController> {
  const DailyAllowanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Obx(() {
      final targetDaily = controller.budgetPlan.value.targetDailyAllowance;
      final todaySpent = controller.todayVariableExpenses;
      final todayRemaining = controller.todayRemainingAllowance;
      final isOverToday = todayRemaining < 0;

      // Progress calculation for today's quota
      final usedProgress = targetDaily > 0 ? (todaySpent / targetDaily).clamp(0.0, 1.0) : 0.0;
      final usedPct = targetDaily > 0 ? (todaySpent / targetDaily * 100).toInt() : 0;

      // Status classification
      final bool isWarning = usedProgress >= 0.7 && !isOverToday;
      final Color statusAccent;
      final Color statusBg;
      final Color statusBorder;
      final String statusLabel;

      if (isOverToday) {
        statusAccent = AppColors.deficitText;
        statusBg = isDark ? const Color(0xFF3B1219) : const Color(0xFFFEE2E2);
        statusBorder = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);
        statusLabel = 'over_quota_caution'.tr;
      } else if (isWarning) {
        statusAccent = const Color(0xFFF59E0B);
        statusBg = isDark ? const Color(0xFF36200B) : const Color(0xFFFEF3C7);
        statusBorder = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
        statusLabel = 'moderate_pacing'.tr;
      } else {
        statusAccent = AppColors.primary;
        statusBg = isDark ? const Color(0xFF0D281E) : const Color(0xFFDCFCE7);
        statusBorder = isDark ? const Color(0xFF065F46) : const Color(0xFF86EFAC);
        statusLabel = 'on_track_safe'.tr;
      }

      // Monthly Run-rate metrics
      final remainingDailyRunRate = controller.remainingDailyAllowance;
      final remainingDays = controller.remainingDaysInMonth;
      final isMonthlySafe = remainingDailyRunRate >= targetDaily * 0.7;

      // Smart incentive: calculate daily bonus if saved today
      final double todaySavings = targetDaily - todaySpent;
      final double dailyBonus = (todaySavings > 0 && remainingDays > 0)
          ? (todaySavings / remainingDays)
          : 0.0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: statusAccent.withValues(alpha: isDark ? 0.12 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Surface Background with Subtle Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkSurface,
                              AppColors.darkSurfaceSecondary.withValues(alpha: 0.8),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFFAFCFF),
                            ],
                    ),
                  ),
                ),
              ),

              // 2. Ambient Aura Glow in top right corner
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        statusAccent.withValues(alpha: isDark ? 0.18 : 0.12),
                        statusAccent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Card Content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.border.withValues(alpha: 0.8),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ROW: Food Icon, Title, Pulsing Status Badge & Settings ---
                    Row(
                      children: [
                        // Food Icon Squircle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.variableCostAccent.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.variableCostAccent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.variableCostAccent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'daily_allowance_today'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                controller.formattedPeriodTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pulsing Status Pill
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusBorder, width: 0.9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusAccent.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: statusAccent,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Quick Settings Button
                        Material(
                          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Get.toNamed(Routes.BUDGET_SETTINGS);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // --- MICRO VIEW: Neon Progress Ring & Hero Numbers ---
                    Row(
                      children: [
                        // Neon Progress Ring
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(74, 74),
                                painter: _NeumorphicProgressRingPainter(
                                  progress: usedProgress,
                                  isDark: isDark,
                                  activeColor: statusAccent,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isOverToday ? 'over_for_today'.tr : '$usedPct%',
                                      style: TextStyle(
                                        fontSize: isOverToday ? 12 : 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: statusAccent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'today_used'.tr,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Hero Remaining or Over Balance
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "เหลือใช้วันนี้" / "เกินงบวันนี้"
                              Text(
                                isOverToday ? '${'over_for_today'.tr} ${'today_over'.tr}' : '${'remaining_for_today'.tr} ${'today_used'.tr}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Big Hero Number with styled ฿
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '฿',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: statusAccent.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      currencyFmt.format(todayRemaining.abs()).replaceAll('฿', ''),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        color: statusAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Spent vs Target Subtitle
                              Text(
                                '${'today_spent'.tr} ${currencyFmt.format(todaySpent)} • ${'target'.tr} ${currencyFmt.format(targetDaily)}/${'day'.tr}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- MACRO VIEW: Dynamic Monthly Run-rate Ribbon ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.22)
                            : AppColors.surfaceSecondary.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                remainingDays == 0 ? Icons.event_available_rounded : Icons.auto_graph_rounded,
                                size: 15,
                                color: AppColors.variableCostAccent,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  remainingDays == 0
                                      ? 'last_day_of_month'.tr
                                      : 'monthly_runrate_label'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (remainingDays > 0)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${currencyFmt.format(remainingDailyRunRate)}/${'day'.tr}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isMonthlySafe
                                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                                : AppColors.deficitText,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${'days_left'.trParams({'days': '$remainingDays'})})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'ends_today'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          // Smart savings tag if user has saved money today
                          if (dailyBonus >= 1 && remainingDays > 0) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const SizedBox(width: 22),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'savings_bonus_runrate'.trParams({'amount': dailyBonus.toStringAsFixed(0)}),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }
}

/// Custom Painter สำหรับวงแหวนความเร็วการใช้โควตา (Neon Dynamic Progress Ring)
class _NeumorphicProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color activeColor;

  _NeumorphicProgressRingPainter({
    required this.progress,
    required this.isDark,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 6.5;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Glowing aura behind the active arc
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );

    // Active arc with sharp round cap
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeumorphicProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activeColor != activeColor;
}
