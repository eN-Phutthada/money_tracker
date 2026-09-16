import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Obx(() {
      final targetDaily = controller.budgetPlan.value.targetDailyAllowance;
      final todaySpent = controller.todayVariableExpenses;
      final todayRemaining = controller.todayRemainingAllowance;
      final isOverToday = todayRemaining < 0;

      // Progress calculation for today's quota
      final usedProgress = targetDaily > 0 ? (todaySpent / targetDaily).clamp(0.0, 1.0) : 0.0;
      final usedPct = targetDaily > 0 ? (todaySpent / targetDaily * 100).toInt() : 0;

      final bool isWarning = usedProgress >= 0.7 && !isOverToday;
      final Color statusAccent = isOverToday
          ? AppColors.nothingRed
          : (isWarning ? AppColors.warning : (isDark ? Colors.white : Colors.black));

      final String statusLabel = isOverToday
          ? 'over_quota_caution'.tr
          : (isWarning ? 'moderate_pacing'.tr : 'on_track_safe'.tr);

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
            // --- HEADER ROW: Glyph Icon, Title, Status Pill ---
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'daily_allowance_today'.tr.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              try {
                                HapticFeedback.lightImpact();
                              } catch (_) {}
                              Get.toNamed(Routes.BUDGET_SETTINGS);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 15,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        controller.formattedPeriodTitle.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Nothing OS Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOverToday
                          ? AppColors.nothingRed.withValues(alpha: 0.6)
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NothingLedIndicator(
                        size: 6,
                        color: statusAccent,
                        isPulsing: isOverToday,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusAccent,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      ),
                    ],
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
                            isOverToday ? 'OVER' : '$usedPct%',
                            style: GoogleFonts.shareTechMono(
                              fontSize: isOverToday ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: statusAccent,
                            ),
                          ),
                          Text(
                            'USED',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                      Text(
                        isOverToday
                            ? '${'over_for_today'.tr.toUpperCase()} ${'today_over'.tr}'
                            : '${'remaining_for_today'.tr.toUpperCase()} ${'today_used'.tr}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
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
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: statusAccent,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              currencyFmt.format(todayRemaining.abs()).replaceAll('฿', ''),
                              style: GoogleFonts.shareTechMono(
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

                      Text(
                        '${'today_spent'.tr} ${currencyFmt.format(todaySpent)} • ${'target'.tr} ${currencyFmt.format(targetDaily)}/${'day'.tr}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
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
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const NothingLedIndicator(size: 5, color: AppColors.nothingRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'monthly_runrate_label'.tr.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                        ),
                      ),
                      Text(
                        remainingDays > 0 ? '$remainingDays ${'days_left'.tr}' : 'month_ended'.tr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${'remaining_rate'.tr}: ${currencyFmt.format(remainingDailyRunRate)}/${'day'.tr}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (dailyBonus > 0)
                        Text(
                          '+${currencyFmt.format(dailyBonus)}/${'day'.tr} bonus',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 250));
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
            : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10))
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
