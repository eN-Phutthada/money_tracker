import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/wallet_health_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';

/// หน้าต่างตรวจวินิจฉัยสุขภาพกระเป๋าเงินฉบับสมบูรณ์ (Wallet Health Diagnostics)
/// สไตล์ Nothing OS Design System: เรขาคณิต Squircle, เส้นขอบ Hairline คมกริบ,
/// ตัวเลข Monospace และไฟสถานะ LED Matrix
class WalletHealthDiagnosticSheet extends StatelessWidget {
  const WalletHealthDiagnosticSheet({super.key});

  /// เปิดแสดงผลแบบ Responsive (BottomSheet บนมือถือ, Glass Dialog บน Desktop)
  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 580,
          padding: const EdgeInsets.all(24),
          child: const WalletHealthDiagnosticSheet(),
        ),
      );
    } else {
      Get.bottomSheet(
        const WalletHealthDiagnosticSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    final content = Obx(() {
      final health = controller.walletHealth;
      final tierColor = health.tierColor;
      final currencyFmt = NumberFormat.currency(
        locale: 'th_TH',
        symbol: '฿',
        decimalDigits: 0,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row (Nothing Style)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: tierColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'wallet_health_diagnostics'.tr.toUpperCase(),
                      style: NothingTypography.grotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: NothingTypography.safeSpacing('wallet_health_diagnostics'.tr, 0.8),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${'wallet_health_score'.tr} • ${controller.formattedPeriodTitle}',
                      style: NothingTypography.grotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                ),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Hero Health Gauge Card (Nothing Dot Matrix Style)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big Monospace Score
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${health.totalScore}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          '/100',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Health Tier Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tierColor.withValues(alpha: isDark ? 0.45 : 0.30),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NothingLedIndicator(
                            size: 6,
                            color: tierColor,
                            isPulsing: health.tier == WalletHealthTier.critical,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            health.tierKey.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 20-Segment Score Meter
                NothingSegmentedBar(
                  totalSegments: 20,
                  filledSegments: ((health.totalScore / 100.0) * 20).round().clamp(0, 20),
                  activeColor: tierColor,
                  height: 5.5,
                  spacing: 3.0,
                ),
                const SizedBox(height: 14),

                // Headline Advice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    health.headlineAdvice,
                    style: NothingTypography.grotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Runway & Pace Dual Metrics Box
          Row(
            children: [
              // 3.1 Runway Metric
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'runway_days_title'.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${health.runwayDays.toInt()}',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'days_unit'.tr,
                            style: NothingTypography.grotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        health.runwayDays >= controller.remainingDaysInMonth
                            ? 'runway_sufficient'.tr
                            : 'runway_short'.tr,
                        style: NothingTypography.grotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: health.runwayDays >= controller.remainingDaysInMonth
                              ? const Color(0xFF10B981)
                              : AppColors.nothingRed,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 3.2 Spending Pace Metric
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'spending_pace_title'.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            health.burnRateMultiplier <= 0
                                ? '0.0'
                                : health.burnRateMultiplier.toStringAsFixed(1),
                            style: GoogleFonts.shareTechMono(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'x',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        health.burnRateMultiplier <= 1.0
                            ? 'pace_on_track'.tr
                            : 'pace_fast_warning'.tr,
                        style: NothingTypography.grotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: health.burnRateMultiplier <= 1.0
                              ? const Color(0xFF10B981)
                              : (health.burnRateMultiplier <= 1.3 ? const Color(0xFFF59E0B) : AppColors.nothingRed),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (health.suggestedDailyPace > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: tierColor.withValues(alpha: isDark ? 0.35 : 0.20),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      size: 15,
                      color: tierColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'recommended_daily_pace'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'recommended_daily_pace_desc'.trParams({
                            'amount': currencyFmt.format(health.suggestedDailyPace),
                          }),
                          style: NothingTypography.grotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFDDDDDD) : const Color(0xFF333333),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFmt.format(health.suggestedDailyPace),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 4. 4 Dimensions Breakdown
          Text(
            'wallet_health_score'.tr.toUpperCase(),
            style: NothingTypography.grotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),

          ...health.dimensions.map((dim) => _buildDimensionTile(dim, isDark)),
          const SizedBox(height: 16),

          // 5. Actionable Insights Checklist
          if (health.insights.isNotEmpty) ...[
            Text(
              'actionable_insights_title'.tr.toUpperCase(),
              style: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            ...health.insights.map((insight) => _buildInsightTile(insight, isDark)),
            const SizedBox(height: 16),
          ],

          // 6. Bottom Navigation & Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Routes.BUDGET_SETTINGS);
                  },
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(
                    'action_adjust_budget'.tr,
                    style: NothingTypography.grotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'ok'.tr,
                    style: NothingTypography.grotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    });

    if (isDesktop) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionTile(WalletHealthDimension dim, bool isDark) {
    final statusColor = dim.isHealthy
        ? const Color(0xFF10B981)
        : (dim.score >= dim.maxScore * 0.5 ? const Color(0xFFF59E0B) : AppColors.nothingRed);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                dim.icon,
                size: 15,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dim.title,
                  style: NothingTypography.grotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dim.statusText,
                  style: NothingTypography.grotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dim.score.round()}/${dim.maxScore.round()}',
                style: GoogleFonts.shareTechMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          NothingSegmentedBar(
            totalSegments: 12,
            filledSegments: (dim.ratio * 12).round().clamp(0, 12),
            activeColor: statusColor,
            height: 3.5,
            spacing: 2.5,
          ),
          const SizedBox(height: 6),
          Text(
            dim.detail,
            style: NothingTypography.grotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(WalletHealthInsight insight, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.iconColor.withValues(alpha: isDark ? 0.35 : 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              insight.icon,
              size: 16,
              color: insight.iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: NothingTypography.grotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: NothingTypography.grotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          if (insight.actionLabel != null && insight.onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                insight.onAction!();
                Get.back();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: insight.iconColor,
              ),
              child: Text(
                insight.actionLabel!,
                style: NothingTypography.grotesk(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
