import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_health_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';
import 'wallet_health_diagnostic_sheet.dart';

/// บัตรแสดงยอดกระเป๋าเงินและสถานะทางการเงิน สไตล์ Nothing OS Design System
/// ผสมผสานเรขาคณิต Squircle 28px, เส้นขอบ Hairline คมกริบ 0.8px,
/// ตัวเลขสไตล์ Dot-Matrix และไฟสถานะ LED สีแดง Nothing Red
class BalanceCard extends GetView<DashboardController> {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 2,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isMonthly =
          controller.currentPeriod.value == TimeFilterPeriod.monthly;
      final totalBalance = controller.totalCurrentBalance;
      final heroAmount = controller.periodHeroBalance;
      final isSurplus = controller.isSurplus;
      final isHidden = controller.isBalanceHidden.value;
      final health = controller.walletHealth;
      final Color statusColor = health.tierColor;

      return NothingCard(
        isGlass: false,
        borderRadius: 28,
        backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // 1. HEADER ROW: Glyph Icon, Title, Privacy Toggle & Micro Health Pill
            // ========================================================
            Row(
              children: [
                // Glyph Wallet Icon Container (Interactive)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => WalletHealthDiagnosticSheet.show(context),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
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
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        isSurplus
                            ? Icons.account_balance_wallet_outlined
                            : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'wallet_status'.tr.toUpperCase(),
                                style: NothingTypography.grotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: NothingTypography.safeSpacing(
                                    'wallet_status'.tr,
                                    0.8,
                                  ),
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: controller.toggleBalanceHidden,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 15,
                                color: isDark
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF555555),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        controller.formattedPeriodTitle.toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: NothingTypography.safeSpacing(
                            controller.formattedPeriodTitle,
                            1.0,
                          ),
                          color: isDark
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Nothing OS Micro Health Pill (LED + Score + Tier + Arrow)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => WalletHealthDiagnosticSheet.show(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: health.tierColor.withValues(
                            alpha: isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: health.tierColor.withValues(
                              alpha: isDark ? 0.45 : 0.25,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NothingLedIndicator(
                              size: 5,
                              color: health.tierColor,
                              isPulsing:
                                  health.tier == WalletHealthTier.critical,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${health.totalScore} ${health.tierKey.tr.toUpperCase()}',
                              style: NothingTypography.grotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: health.tierColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 13,
                              color: health.tierColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ========================================================
            // 2. HERO BALANCE SECTION (Dot Matrix / Share Tech Mono)
            // ========================================================
            Row(
              children: [
                NothingLedIndicator(
                  size: 5,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMonthly
                        ? 'current_money_in_wallet'.tr.toUpperCase()
                        : '${'period_net_cashflow'.tr.toUpperCase()} (${controller.formattedPeriodTitle})',
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: NothingTypography.safeSpacing(
                        isMonthly
                            ? 'current_money_in_wallet'.tr
                            : 'period_net_cashflow'.tr,
                        1.2,
                      ),
                      color: isDark
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF666666),
                    ),
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
                            color: isDark ? Colors.white : Colors.black,
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
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: heroAmount),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) {
                            return _buildNothingFormattedAmount(val, isDark);
                          },
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Safety / Pace Status Tag (Monochrome Pill with Hairline Border)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181818)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus
                          ? Icons.verified_user_rounded
                          : Icons.warning_amber_rounded,
                      size: 13,
                      color: isSurplus
                          ? AppColors.incomeColor(isDark)
                          : (isDark
                              ? AppColors.nothingRedLight
                              : AppColors.nothingRed),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMonthly
                          ? (isSurplus
                              ? 'safe_zone_covered'.tr
                              : 'tight_zone_warning'.tr)
                          : '${controller.surplusOrDeficit >= 0 ? '+' : ''}${currencyFmt.format(controller.surplusOrDeficit)} (${'vs_budget_plan'.tr})',
                      style: NothingTypography.grotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ========================================================
            // 3. THREE CASH FLOW PILLARS (Inflow / Outflow / Net Balance - NO TARGET!)
            // ========================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161616)
                    : const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // 1. Inflow (Income)
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: Icons.south_west_rounded,
                      iconColor: AppColors.incomeColor(isDark),
                      label: 'total_inflow'.tr,
                      value: '+${currencyFmt.format(controller.actualIncome)}',
                      valueColor: AppColors.incomeColor(isDark),
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 0.8,
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // 2. Outflow (Expenses + Savings)
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: Icons.north_east_rounded,
                      iconColor: AppColors.expenseColor(isDark),
                      label: 'total_outflow'.tr,
                      value:
                          '-${currencyFmt.format(controller.actualExpenses + controller.actualSavings)}',
                      valueColor: AppColors.expenseColor(isDark),
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 0.8,
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // 3. Net Balance (คงเหลือสุทธิ - Replaced former Target)
                  Expanded(
                    child: _buildCashflowPillar(
                      icon: controller.actualBalance >= 0
                          ? Icons.account_balance_wallet_outlined
                          : Icons.trending_down_rounded,
                      iconColor: controller.actualBalance >= 0
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? AppColors.nothingRedLight
                              : AppColors.nothingRed),
                      label: 'net_balance'.tr,
                      value:
                          '${controller.actualBalance >= 0 ? '+' : ''}${currencyFmt.format(controller.actualBalance)}',
                      valueColor: controller.actualBalance >= 0
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? AppColors.nothingRedLight
                              : AppColors.nothingRed),
                      isDark: isDark,
                      isHidden: isHidden,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========================================================
            // 4. MONTHLY PLAN CAPSULE (CORRELATED WITH CURRENT DAY)
            // ========================================================
            if (isMonthly)
              _buildNothingDayCorrelatedMonthlyCapsule(
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
          ],
        ),
      );
    });
  }

  // =========================================================================
  // MONTHLY PLAN CAPSULE CORRELATED WITH CURRENT DAY (วันปัจจุบัน)
  // =========================================================================
  Widget _buildNothingDayCorrelatedMonthlyCapsule({
    required bool isDark,
    required NumberFormat currencyFmt,
  }) {
    final currentDay = controller.currentDayInPeriod;
    final totalDays = controller.daysInCurrentMonth;
    final remainingDays = controller.remainingDaysInMonth;
    final plannedToDate = controller.plannedVariableBudgetToDate;
    final actualSpentToDate = controller.totalVariableExpenses;
    final variance = controller.variableSpendingVarianceToDate;
    final isOnTrack = controller.isVariableSpendingOnTrack;
    final remainingDailyQuota = controller.remainingDailyAllowance;

    final totalSegments = 16;
    final filledSegments =
        (controller.monthElapsedRatio * totalSegments).round().clamp(0, totalSegments);

    final statusBgColor = isOnTrack
        ? (isDark
            ? const Color(0xFF0F291E)
            : const Color(0xFFE8F5E9))
        : (isDark
            ? const Color(0xFF2E0C0E)
            : const Color(0xFFFDE8E8));

    final statusTextColor = isOnTrack
        ? const Color(0xFF10B981)
        : (isDark ? AppColors.nothingRedLight : AppColors.nothingRed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
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
          // Row 1: Header + Day Progress Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'monthly_plan_cycle'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: NothingTypography.safeSpacing(
                        'monthly_plan_cycle'.tr,
                        0.6,
                      ),
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222222)
                      : const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'day_progress_label'.trParams({
                    'current': '$currentDay',
                    'total': '$totalDays',
                  }),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Month Progress Segmented Bar
          NothingSegmentedBar(
            totalSegments: totalSegments,
            filledSegments: filledSegments,
            activeColor: isDark ? Colors.white : Colors.black,
            height: 4.0,
            spacing: 3.0,
          ),
          const SizedBox(height: 12),

          // Row 3: Spending Comparison to Current Day
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Planned to date & Spent to date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planned_to_date'.tr,
                      style: NothingTypography.grotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currencyFmt.format(plannedToDate),
                      style: NothingTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'actual_spent_to_date'.tr}: ${currencyFmt.format(actualSpentToDate)}',
                      style: NothingTypography.grotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Variance Status Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusTextColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${variance >= 0 ? '+' : ''}${currencyFmt.format(variance)}',
                      style: NothingTypography.mono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: statusTextColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isOnTrack
                          ? 'saved_below_plan'.tr
                          : 'spent_over_plan'.tr,
                      style: NothingTypography.grotesk(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 4: Remaining Cycle Guidance (No overflow)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.05 : 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_flat_rounded,
                  size: 13,
                  color: isDark
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF666666),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'remaining_cycle_pace'.trParams({
                      'days': '$remainingDays',
                      'rate': currencyFmt.format(remainingDailyQuota),
                    }),
                    style: NothingTypography.grotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFD4D4D8)
                          : const Color(0xFF444444),
                    ),
                  ),
                ),
              ],
            ),
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
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.nothingBorder
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
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
                'total_current_balance'.tr.toUpperCase(),
                style: NothingTypography.grotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: NothingTypography.safeSpacing(
                    'total_current_balance'.tr,
                    0.8,
                  ),
                  color: isDark
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF555555),
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                isHidden ? '••••••••' : currencyFmt.format(balance),
                style: NothingTypography.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
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
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label.toUpperCase(),
                  style: NothingTypography.grotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: NothingTypography.safeSpacing(label, 0.2),
                    color: isDark
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF666666),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isHidden ? '••••' : value,
            style: NothingTypography.mono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
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

    final textColor = isDark ? Colors.white : Colors.black;
    final negativeColor = isDark
        ? AppColors.nothingRedLight
        : AppColors.nothingRed;
    final amountColor = isNegative ? negativeColor : textColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${isNegative ? '-' : ''}฿',
          style: NothingTypography.grotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          wholeFormatted,
          style: NothingTypography.mono(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: amountColor,
          ),
        ),
        Text(
          '.$decimalFormatted',
          style: NothingTypography.mono(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
