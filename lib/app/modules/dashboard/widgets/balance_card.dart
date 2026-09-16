import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงยอดกระแสเงินสดสุทธิและสถานะทางการเงิน สไตล์ Modern FinTech Hero Card 2026
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

      // Theme-tailored Luxury Palettes
      final Color cardBorderColor = isSurplus
          ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFF10B981).withValues(alpha: 0.28))
          : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFEF4444).withValues(alpha: 0.28));

      final Color statusPillBg = isSurplus
          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7))
          : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEE2E2));

      final Color statusPillBorder = isSurplus
          ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF86EFAC))
          : (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFFFCA5A5));

      final Color statusPillText = isSurplus
          ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D))
          : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C));

      final Color accentColor = isSurplus ? AppColors.primary : AppColors.deficitText;

      // Variance calculation relative to target
      final double variancePercent = expected != 0 ? ((surplus / expected.abs()) * 100) : 0.0;
      final String percentSign = variancePercent >= 0 ? '+' : '';
      final String percentFormatted = '$percentSign${variancePercent.toStringAsFixed(1)}%';
      final String surplusFormatted = '${surplus >= 0 ? '+' : ''}${currencyFmt.format(surplus)}';

      // Achievement ratio calculation for health meter (clamped 0.0 - 1.0)
      final double achievementRatio = expected > 0
          ? (heroAmount / expected).clamp(0.0, 1.25)
          : (heroAmount >= 0 ? 1.0 : 0.0);
      final int achievementPercent = expected > 0
          ? ((heroAmount / expected) * 100).round()
          : (heroAmount >= 0 ? 100 : 0);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? accentColor.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Dual-Gradient Surface Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSurplus
                          ? (isDark
                              ? [const Color(0xFF0D251C), const Color(0xFF081512), const Color(0xFF0F172A)]
                              : [const Color(0xFFF0FDF8), const Color(0xFFFFFFFF), const Color(0xFFF4FAF7)])
                          : (isDark
                              ? [const Color(0xFF2B0E14), const Color(0xFF14080B), const Color(0xFF0F172A)]
                              : [const Color(0xFFFFF5F5), const Color(0xFFFFFFFF), const Color(0xFFFAF4F4)]),
                    ),
                  ),
                ),
              ),

              // 2. Ambient Aura Glow in top right corner
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                        accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Abstract Cashflow Wave Watermark
              Positioned.fill(
                child: CustomPaint(
                  painter: _CashflowWavePainter(
                    color: accentColor.withValues(alpha: isDark ? 0.07 : 0.05),
                  ),
                ),
              ),

              // 4. Main Card Content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorderColor, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ROW: Wallet Icon, Title, Health Badge & Privacy Toggle ---
                    Row(
                      children: [
                        // Wallet Badge Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                          ),
                          child: Icon(
                            isSurplus ? Icons.account_balance_wallet_rounded : Icons.warning_amber_rounded,
                            color: accentColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title & Current Period
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'wallet_status'.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Privacy Toggle (Eye Icon)
                                  InkWell(
                                    onTap: controller.toggleBalanceHidden,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                        isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        size: 16,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
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

                        // Dynamic Status Pill (Safe Zone / Caution) - Right-Aligned
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusPillBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusPillBorder, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pulsing Status Dot
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isSurplus ? 'safe_zone_surplus'.tr : 'caution_deficit'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusPillText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ).animate().shimmer(duration: const Duration(seconds: 2), delay: const Duration(seconds: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- ALL-TIME CURRENT BALANCE HERO CAPSULE OR MONTHLY BUDGET CAPSULE ---
                    if (isMonthly)
                      _buildMonthlyBudgetSummaryCapsule(
                        context: context,
                        isDark: isDark,
                        isHidden: isHidden,
                        currencyFmt: currencyFmt,
                      )
                    else
                      _buildTotalCurrentBalanceCapsule(
                        balance: totalBalance,
                        isDark: isDark,
                        isHidden: isHidden,
                      ),
                    const SizedBox(height: 16),

                    // --- HERO BALANCE SECTION ---
                    Row(
                      children: [
                        Icon(
                          isMonthly ? Icons.account_balance_wallet_rounded : Icons.timelapse_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isMonthly
                                ? '${'current_money_in_wallet'.tr} (${controller.formattedPeriodTitle})'
                                : '${'period_net_cashflow'.tr} (${controller.formattedPeriodTitle})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Big Number / Hidden Dots
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: isHidden
                          ? Align(
                              key: const ValueKey('hidden_balance'),
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '••••••••',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
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
                                child: _buildFormattedAmount(heroAmount, isDark),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),

                    // Variance Tag (Compared with Budget Plan)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.09),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isMonthly
                                  ? '${'monthly_expected_remaining'.tr}: ${currencyFmt.format(expected)} (${'from_fixed_and_daily'.tr})'
                                  : '$surplusFormatted ($percentFormatted ${'vs_budget_plan'.tr})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // --- CASH FLOW HEALTH METER (PROGRESS GAUGE) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'plan_achievement'.trParams({'percent': '$achievementPercent'}),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${'expected_balance'.tr}: ${currencyFmt.format(expected)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Meter Track & Fill Bar
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: achievementRatio.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSurplus
                                        ? const [Color(0xFF10B981), Color(0xFF06B6D4)]
                                        : const [Color(0xFFEF4444), Color(0xFFF59E0B)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // --- 3 CASH FLOW PILLARS (INCOME, OUTFLOW, TARGET) ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. Inflow (Income)
                          Expanded(
                            child: _buildCashflowPillar(
                              icon: Icons.south_west_rounded,
                              iconColor: AppColors.primary,
                              label: 'total_inflow'.tr,
                              value: '+${currencyFmt.format(controller.actualIncome)}',
                              valueColor: AppColors.primary,
                              isDark: isDark,
                              isHidden: isHidden,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? AppColors.darkDivider : AppColors.divider,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          // 2. Outflow (Expenses + Savings)
                          Expanded(
                            child: _buildCashflowPillar(
                              icon: Icons.north_east_rounded,
                              iconColor: AppColors.deficitText,
                              label: 'total_outflow'.tr,
                              value: '-${currencyFmt.format(controller.actualExpenses + controller.actualSavings)}',
                              valueColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              isDark: isDark,
                              isHidden: isHidden,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? AppColors.darkDivider : AppColors.divider,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          // 3. Expected Target
                          Expanded(
                            child: _buildCashflowPillar(
                              icon: Icons.flag_rounded,
                              iconColor: AppColors.accent,
                              label: 'expected_balance'.tr,
                              value: currencyFmt.format(expected),
                              valueColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              isDark: isDark,
                              isHidden: isHidden,
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
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }

  /// แถบสรุปแผนค่าใช้จ่ายเดือนนี้ (ค่าใช้จ่ายคงที่ + ค่ากินตามโควตา)
  Widget _buildMonthlyBudgetSummaryCapsule({
    required BuildContext context,
    required bool isDark,
    required bool isHidden,
    required NumberFormat currencyFmt,
  }) {
    final fixed = controller.budgetPlan.value.plannedFixedCosts;
    final variable = controller.budgetPlan.value.plannedVariableBudget(controller.daysInCurrentMonth);
    final totalPlanned = controller.monthlyTotalPlannedExpenses;
    final expectedEnding = controller.monthlyPlanEndingBalance;
    final isEndingPositive = expectedEnding >= 0;
    final statusColor = isEndingPositive ? AppColors.primary : AppColors.deficitText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
            : AppColors.surfaceSecondary.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'monthly_budget_summary'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'monthly_commitments_desc'.trParams({
                        'fixed': currencyFmt.format(fixed),
                        'variable': currencyFmt.format(variable),
                      }),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${'expected_balance_planned'.tr} ${currencyFmt.format(expectedEnding)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'total_outflow'.tr}: ${currencyFmt.format(totalPlanned)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                '${'period_net_cashflow'.tr}: ${controller.actualBalance >= 0 ? '+' : ''}${currencyFmt.format(controller.actualBalance)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: controller.actualBalance >= 0 ? AppColors.primary : AppColors.deficitText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// แถบเด่นยอดเงินคงเหลือสะสมสุทธิทั้งหมด (All-Time Net Current Balance Hero Capsule)
  Widget _buildTotalCurrentBalanceCapsule({
    required double balance,
    required bool isDark,
    required bool isHidden,
  }) {
    final isPositive = balance >= 0;
    final statusColor = isPositive ? AppColors.primary : AppColors.deficitText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? statusColor.withValues(alpha: 0.09)
            : statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.32 : 0.22),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 13,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_current_balance'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'total_current_balance_desc'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'all_time'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: isHidden
                ? Align(
                    key: const ValueKey('hidden_total_balance'),
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '••••••••',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                : Align(
                    key: const ValueKey('visible_total_balance'),
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _buildFormattedAmount(
                        balance,
                        isDark,
                        symbolSize: 16,
                        wholeSize: 24,
                        decimalSize: 15,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds beautifully formatted currency with prominent whole digits and subtle decimals
  Widget _buildFormattedAmount(
    double amount,
    bool isDark, {
    double symbolSize = 20,
    double wholeSize = 32,
    double decimalSize = 19,
    Color? customColor,
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final wholeNumber = NumberFormat('#,##0', 'th_TH').format(absAmount.floor());
    final decimalPart = (absAmount % 1).toStringAsFixed(2).substring(1); // e.g. ".50"

    final textColor = customColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final secondaryColor = customColor?.withValues(alpha: 0.8) ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);
    final tertiaryColor = customColor?.withValues(alpha: 0.65) ?? (isDark ? AppColors.darkTextTertiary : AppColors.textSecondary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${isNegative ? '-' : ''}฿',
          style: TextStyle(
            fontSize: symbolSize,
            fontWeight: FontWeight.w700,
            color: secondaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          wholeNumber,
          style: TextStyle(
            fontSize: wholeSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: textColor,
          ),
        ),
        Text(
          decimalPart,
          style: TextStyle(
            fontSize: decimalSize,
            fontWeight: FontWeight.w600,
            color: tertiaryColor,
          ),
        ),
      ],
    );
  }

  /// Builds an individual column inside the 3 Cashflow Pillars
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
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
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
            isHidden ? '•••••' : value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic abstract wave painter for watermark depth behind the card
class _CashflowWavePainter extends CustomPainter {
  final Color color;
  const _CashflowWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Top gentle wave
    final path1 = Path();
    path1.moveTo(0, size.height * 0.65);
    path1.cubicTo(
      size.width * 0.35, size.height * 0.42,
      size.width * 0.65, size.height * 0.88,
      size.width, size.height * 0.45,
    );
    canvas.drawPath(path1, paint);

    // Bottom flowing wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.82);
    path2.cubicTo(
      size.width * 0.3, size.height * 0.62,
      size.width * 0.72, size.height * 0.96,
      size.width, size.height * 0.68,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _CashflowWavePainter oldDelegate) => oldDelegate.color != color;
}
