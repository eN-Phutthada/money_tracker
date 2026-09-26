import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงโควตาค่ากินรายวัน สไตล์ Nothing OS Design System
/// ผสมผสานหน้าปัดดิจิทัลสไตล์ Nothing Dial, ตัวเลข Monospace คมชัด,
/// และตัวชี้วัดความเร็วการใช้จ่าย (Run-rate) สไตล์วิศวกรรม
class DailyAllowanceCard extends GetView<DashboardController> {
  const DailyAllowanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );

    return Obx(() {
      final targetDaily = controller.budgetPlan.value.targetDailyAllowance;
      final todaySpent = controller.todayVariableExpenses;
      final todayRemaining = controller.todayRemainingAllowance;
      final isOverToday = todayRemaining < 0;

      // Progress calculation for today's quota
      final usedProgress = targetDaily > 0
          ? (todaySpent / targetDaily).clamp(0.0, 1.0)
          : 0.0;
      final usedPct = targetDaily > 0
          ? (todaySpent / targetDaily * 100).toInt()
          : 0;

      final bool isWarning = usedProgress >= 0.7 && !isOverToday;
      final Color statusAccent = isOverToday
          ? (isDark ? AppColors.nothingRedLight : AppColors.nothingRed)
          : (isWarning
                ? AppColors.warning
                : (isDark ? Colors.white : Colors.black));

      final String statusLabel = isOverToday
          ? 'over_short'.tr.toUpperCase()
          : (isWarning
                ? 'moderate_short'.tr.toUpperCase()
                : 'on_track_short'.tr.toUpperCase());

      // Monthly Run-rate metrics
      final remainingDailyRunRate = controller.remainingDailyAllowance;
      final remainingDays = controller.remainingDaysInMonth;

      final double todaySavings = targetDaily - todaySpent;
      final double dailyBonus = (todaySavings > 0 && remainingDays > 0)
          ? (todaySavings / remainingDays)
          : 0.0;

      return NothingCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW: Glyph Icon, Title, Status Pill & Tune Button ---
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF181818)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.fastfood_outlined,
                    color: isDark ? Colors.white : Colors.black,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'daily_allowance_today'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: NothingTypography.safeSpacing(
                              'daily_allowance_today'.tr,
                              0.8,
                            ),
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.formattedPeriodTitle.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: NothingTypography.safeSpacing(
                              controller.formattedPeriodTitle,
                              0.8,
                            ),
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Nothing OS Micro Status Pill
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isOverToday
                          ? (isDark
                                ? const Color(0xFF2E0C0E)
                                : const Color(0xFFFDE8E8))
                          : (isDark
                                ? const Color(0xFF181818)
                                : const Color(0xFFF0F0F0)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverToday
                            ? (isDark
                                  ? AppColors.nothingRed.withValues(alpha: 0.6)
                                  : AppColors.nothingRed.withValues(alpha: 0.3))
                            : (isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.08)),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NothingLedIndicator(
                          size: 5,
                          color: statusAccent,
                          isPulsing: isOverToday,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: NothingTypography.grotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: statusAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Tune Button (Clean Squircle)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      try {
                        HapticFeedback.lightImpact();
                      } catch (_) {}
                      Get.toNamed(Routes.BUDGET_SETTINGS);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF181818)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.nothingBorder
                              : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // --- HERO VIEW: Nothing Dial & Big Number ---
            Row(
              children: [
                // Nothing OS Dial (Tick Marks + Segmented Ring)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(76, 76),
                        painter: _NothingDialPainter(
                          progress: usedProgress,
                          isDark: isDark,
                          activeColor: statusAccent,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isOverToday ? 'over_short'.tr.toUpperCase() : '$usedPct%',
                            style: NothingTypography.mono(
                              fontSize: isOverToday ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: statusAccent,
                            ),
                          ),
                          Text(
                            'used_label'.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Hero Remaining Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isOverToday
                              ? 'over_for_today'.tr.toUpperCase()
                              : 'remaining_for_today'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF555555),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Big Number (Dot Matrix / Monospace)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              isOverToday ? '-฿' : '฿',
                              style: NothingTypography.grotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: statusAccent,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              currencyFmt
                                  .format(todayRemaining.abs())
                                  .replaceAll('฿', ''),
                              style: NothingTypography.mono(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: statusAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${'today_spent'.tr} ',
                              style: NothingTypography.grotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF555555),
                              ),
                            ),
                            Text(
                              currencyFmt.format(todaySpent),
                              style: NothingTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFD4D4D8)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            Text(
                              ' • ${'daily_quota'.tr} ',
                              style: NothingTypography.grotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF555555),
                              ),
                            ),
                            Text(
                              '${currencyFmt.format(targetDaily)}/${'day'.tr}',
                              style: NothingTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFD4D4D8)
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- MACRO VIEW: Dynamic Monthly Run-rate Ribbon ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161616)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NothingLedIndicator(
                        size: 5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'monthly_runrate_label'.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: NothingTypography.safeSpacing(
                                'monthly_runrate_label'.tr,
                                0.6,
                              ),
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          remainingDays > 0
                              ? 'days_left'.trParams({
                                  'days': '$remainingDays',
                                })
                              : 'month_ended'.tr,
                          style: NothingTypography.grotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${'remaining_rate'.tr}: ',
                                style: NothingTypography.grotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: isDark
                                      ? const Color(0xFFD4D4D8)
                                      : const Color(0xFF444444),
                                ),
                              ),
                              Text(
                                '${currencyFmt.format(remainingDailyRunRate)}/${'day'.tr}',
                                style: NothingTypography.mono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (dailyBonus > 0) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF222222)
                                    : const Color(0xFFEAEAEA),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.nothingBorder
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '+${currencyFmt.format(dailyBonus)}/${'day'.tr} ${'bonus'.tr}',
                                style: NothingTypography.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Nothing OS Radial Dial Custom Painter with segmented tick marks
class _NothingDialPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color activeColor;

  _NothingDialPainter({
    required this.progress,
    required this.isDark,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    const totalTicks = 24;
    final filledTicks = (progress.clamp(0.0, 1.0) * totalTicks).round();

    for (int i = 0; i < totalTicks; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / totalTicks) * i;
      final isFilled = i < filledTicks;

      final tickLength = isFilled ? 6.0 : 4.0;
      final outerPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );

      final paint = Paint()
        ..color = isFilled
            ? activeColor
            : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10))
        ..strokeWidth = isFilled ? 2.2 : 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NothingDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.activeColor != activeColor;
  }
}
