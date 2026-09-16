import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงยอดกระเป๋าเงินและสถานะทางการเงิน สไตล์ Nothing OS Design System
/// ผสมผสานเรขาคณิต Squircle 28px, เส้นขอบ Hairline คมกริบ,
/// ตัวเลขสไตล์ Dot-Matrix และไฟสถานะ LED สีแดง Nothing Red
class BalanceCard extends GetView<DashboardController> {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isMonthly = controller.currentPeriod.value == TimeFilterPeriod.monthly;
      final totalBalance = controller.totalCurrentBalance;
      final heroAmount = controller.periodHeroBalance;
      final expected = controller.periodExpectedBalance;
      final surplus = controller.surplusOrDeficit;
      final isSurplus = controller.isSurplus;
      final isHidden = controller.isBalanceHidden.value;

      final Color statusColor = isSurplus ? (isDark ? Colors.white : Colors.black) : AppColors.nothingRed;

      final double achievementRatio = expected > 0
          ? (heroAmount / expected).clamp(0.0, 1.25)
          : (heroAmount >= 0 ? 1.0 : 0.0);
      final int achievementPercent = expected > 0
          ? ((heroAmount / expected) * 100).round()
          : (heroAmount >= 0 ? 100 : 0);

      final int totalSegments = 16;
      final int filledSegments = (achievementRatio.clamp(0.0, 1.0) * totalSegments).round();

      return NothingCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW: Glyph Icon, Title, LED Pill & Privacy Toggle ---
            Row(
              children: [
                // Glyph Wallet Icon Container
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
                    isSurplus ? Icons.account_balance_wallet_outlined : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Period Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'wallet_status'.tr.toUpperCase(),
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
                            onTap: controller.toggleBalanceHidden,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

                // Nothing OS Live Status Pill (LED Pip + Label)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSurplus
                        ? (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary)
                        : (isDark ? const Color(0xFF260A0D) : const Color(0xFFFDE8E8)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSurplus
                          ? (isDark ? AppColors.darkBorder : AppColors.border)
                          : AppColors.nothingRed.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NothingLedIndicator(
                        size: 6,
                        color: isSurplus ? (isDark ? Colors.white : Colors.black) : AppColors.nothingRed,
                        isPulsing: !isSurplus,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSurplus ? 'safe_zone_surplus'.tr : 'caution_deficit'.tr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isSurplus
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                              : AppColors.nothingRed,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- MONTHLY BUDGET CAPSULE OR ALL-TIME CAPSULE ---
            if (isMonthly)
              _buildNothingMonthlyCapsule(
                isDark: isDark,
                currencyFmt: currencyFmt,
              )
            else
              _buildNothingAllTimeCapsule(
                balance: totalBalance,
                isDark: isDark,
                isHidden: isHidden,
                currencyFmt: currencyFmt,
              ),
            const SizedBox(height: 18),

            // --- HERO BALANCE SECTION (NOTHING DOT MATRIX STYLE) ---
            Row(
              children: [
                const NothingLedIndicator(size: 5, color: AppColors.nothingRed),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMonthly
                        ? 'current_money_in_wallet'.tr.toUpperCase()
                        : '${'period_net_cashflow'.tr.toUpperCase()} (${controller.formattedPeriodTitle})',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Big Number (Dot Matrix / Monospace)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isHidden
                  ? Align(
                      key: const ValueKey('hidden_balance'),
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '••••••••',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : Align(
                      key: const ValueKey('visible_balance'),
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _buildNothingFormattedAmount(heroAmount, isDark),
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Variance Tag (Monochrome Pill with Hairline Border)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMonthly
                          ? '${'monthly_expected_remaining'.tr}: ${currencyFmt.format(expected)} (${'from_fixed_and_daily'.tr})'
                          : '${surplus >= 0 ? '+' : ''}${currencyFmt.format(surplus)} (${'vs_budget_plan'.tr})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // --- NOTHING SEGMENTED LED HEALTH BAR ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'plan_achievement'.trParams({'percent': '$achievementPercent'}).toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${'expected_balance'.tr.toUpperCase()}: ${currencyFmt.format(expected)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      maxLines: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                NothingSegmentedBar(
                  totalSegments: totalSegments,
                  filledSegments: filledSegments,
                  activeColor: isSurplus ? (isDark ? Colors.white : Colors.black) : AppColors.nothingRed,
                  height: 4.5,
                  spacing: 3.5,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // --- 3 CASH FLOW PILLARS (NOTHING INDUSTRIAL CELLS) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // 1. Inflow (Income)
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: Icons.south_west_rounded,
                      iconColor: isDark ? Colors.white : Colors.black,
                      label: 'total_inflow'.tr,
                      value: '+${currencyFmt.format(controller.actualIncome)}',
                      valueColor: isDark ? Colors.white : Colors.black,
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 0.8,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // 2. Outflow (Expenses + Savings)
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: Icons.north_east_rounded,
                      iconColor: AppColors.nothingRed,
                      label: 'total_outflow'.tr,
                      value: '-${currencyFmt.format(controller.actualExpenses + controller.actualSavings)}',
                      valueColor: AppColors.nothingRed,
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 0.8,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // 3. Expected Target
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: Icons.flag_outlined,
                      iconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      label: 'expected_balance'.tr,
                      value: currencyFmt.format(expected),
                      valueColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 250));
    });
  }

  /// แถบสรุปแผนค่าใช้จ่ายเดือนนี้ สไตล์ Nothing OS
  Widget _buildNothingMonthlyCapsule({
    required bool isDark,
    required NumberFormat currencyFmt,
  }) {
    final fixed = controller.budgetPlan.value.plannedFixedCosts;
    final variable = controller.budgetPlan.value.plannedVariableBudget(controller.daysInCurrentMonth);
    final totalPlanned = controller.monthlyTotalPlannedExpenses;
    final expectedEnding = controller.monthlyPlanEndingBalance;
    final isEndingPositive = expectedEnding >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
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
                  'monthly_budget_summary'.tr.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isEndingPositive
                      ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08))
                      : AppColors.nothingRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEndingPositive
                        ? (isDark ? AppColors.darkBorder : AppColors.border)
                        : AppColors.nothingRed.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${'expected_balance_planned'.tr} ${currencyFmt.format(expectedEnding)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isEndingPositive
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : AppColors.nothingRed,
                  ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'monthly_commitments_desc'.trParams({'fixed': currencyFmt.format(fixed), 'variable': currencyFmt.format(variable)}),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
              Text(
                '${'total_outflow'.tr}: ${currencyFmt.format(totalPlanned)}',
                style: GoogleFonts.shareTechMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// แถบสรุปยอดเงินสะสมทั้งหมด สไตล์ Nothing OS
  Widget _buildNothingAllTimeCapsule({
    required double balance,
    required bool isDark,
    required bool isHidden,
    required NumberFormat currencyFmt,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const NothingLedIndicator(size: 5, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'total_current_balance'.tr.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
            ),
          ),
          Text(
            isHidden ? '••••••••' : currencyFmt.format(balance),
            style: GoogleFonts.shareTechMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowPillar({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
    required bool isHidden,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          isHidden ? '••••' : value,
          style: GoogleFonts.shareTechMono(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNothingFormattedAmount(double amount, bool isDark) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final wholePart = absAmount.truncate();
    final decimalPart = ((absAmount - wholePart) * 100).round();
    final wholeFormatted = NumberFormat('#,##0', 'th_TH').format(wholePart);
    final decimalFormatted = decimalPart.toString().padLeft(2, '0');

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${isNegative ? '-' : ''}฿',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isNegative ? AppColors.nothingRed : textColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          wholeFormatted,
          style: GoogleFonts.shareTechMono(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isNegative ? AppColors.nothingRed : textColor,
          ),
        ),
        Text(
          '.$decimalFormatted',
          style: GoogleFonts.shareTechMono(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
