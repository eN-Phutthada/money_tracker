import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../../routes/app_routes.dart';
import '../controllers/budget_controller.dart';

class BudgetSettingsView extends GetView<BudgetController> {
  const BudgetSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'budget_settings'.tr,
        subtitle: 'budget_subtitle'.tr,
      ),
      body: LiquidGlassNavDock.floatingOnScreen(
        context: context,
        currentRoute: Routes.BUDGET_SETTINGS,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroProjectionMatrix(context, currencyFmt, isDark),
                  const SizedBox(height: 20),

                  _buildStrategyBentoDeck(context, isDark),
                  const SizedBox(height: 20),

                  _buildDailyAllowanceStudio(context, currencyFmt, isDark),
                  const SizedBox(height: 20),

                  _buildThreePillarsSection(context, currencyFmt, isDark),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. HERO FINANCIAL PROJECTION MATRIX
  // ==========================================
  Widget _buildHeroProjectionMatrix(
    BuildContext context,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    return Obx(() {
          final endingBalance = controller.expectedEndingBalance;
          final isPositive = endingBalance >= 0;

          return NothingCard(
            showDotGrid: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Icon + Title + Status Pill)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? (isDark
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.12)
                                        : const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.08))
                                  : (isDark
                                        ? AppColors.nothingRed.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.nothingRed.withValues(
                                            alpha: 0.08,
                                          )),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPositive
                                    ? (isDark
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.35)
                                          : const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.25))
                                    : (isDark
                                          ? AppColors.nothingRed.withValues(
                                              alpha: 0.40,
                                            )
                                          : AppColors.nothingRed.withValues(
                                              alpha: 0.25,
                                            )),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.auto_graph_rounded
                                  : Icons.trending_down_rounded,
                              color: isPositive
                                  ? (isDark
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF059669))
                                  : AppColors.nothingRed,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: NothingDotText(
                                    'projected_ending_balance_header'.tr
                                        .toUpperCase(),
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w700,
                                    color: isPositive
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF111111))
                                        : AppColors.nothingRed,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFF0F0F2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.nothingBorder
                                          : Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'days_in_cycle'.trParams({
                                      'days': '${controller.daysInMonth}',
                                    }).toUpperCase(),
                                    style: NothingTypography.mono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark
                                          ? const Color(0xFFB0B0B0)
                                          : const Color(0xFF555555),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: NothingPill(
                        label: isPositive
                            ? 'good_balance'.tr.toUpperCase()
                            : 'over_budget'.tr.toUpperCase(),
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : AppColors.nothingRed,
                        textColor: isPositive
                            ? (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669))
                            : AppColors.nothingRed,
                        showDot: true,
                        dotColor: isPositive
                            ? const Color(0xFF10B981)
                            : AppColors.nothingRed,
                        isDotMatrix: true,
                        fontSize: 9.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hero Ending Balance Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFmt.format(endingBalance),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isPositive
                          ? (isDark ? Colors.white : Colors.black)
                          : AppColors.nothingRed,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Calculation Formula Caption
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F0F0F)
                        : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.06),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'budget_calc_desc'.trParams({
                      'days': controller.daysInMonth.toString(),
                    }),
                    style: NothingTypography.grotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.nothingSubtext
                          : const Color(0xFF777777),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Health & Wealth Advisory Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121212)
                        : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPositive
                          ? (isDark
                                ? AppColors.nothingBorder
                                : Colors.black.withValues(alpha: 0.08))
                          : AppColors.nothingRed.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      NothingLedIndicator(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : AppColors.nothingRed,
                        size: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.healthStatusMessage,
                          style: NothingTypography.grotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Segmented Allocation Progress Track & Legend
                _buildSegmentedAllocationTrack(context, isDark, currencyFmt),
              ],
            ),
          );
        })
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: -0.04);
  }

  // ==========================================
  // SEGMENTED ALLOCATION PROGRESS TRACK
  // ==========================================
  Widget _buildSegmentedAllocationTrack(
    BuildContext context,
    bool isDark,
    NumberFormat currencyFmt,
  ) {
    final fixedRatio = controller.fixedCostsRatio;
    final varRatio = controller.variableCostsRatio;
    final savingsRatio = controller.savingsRatio;
    final surplusRatio = (1.0 - (fixedRatio + varRatio + savingsRatio)).clamp(
      0.0,
      1.0,
    );

    final fixedAmount = controller.plannedFixedCosts.value;
    final varAmount = controller.plannedVariableBudget;
    final savingsAmount = controller.targetMonthlySavings.value;
    final surplusAmount = controller.expectedEndingBalance.clamp(
      0.0,
      double.infinity,
    );

    // High-contrast, distinct 4-pillar colors
    final fixedColor = isDark
        ? const Color(0xFFD4D4D8)
        : const Color(0xFF4B5563);
    final varColor = AppColors.expenseColor(isDark);
    final savingsColor = AppColors.savingsColor(isDark);
    final surplusColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'allocation_breakdown'.tr,
              style: NothingTypography.grotesk(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: savingsColor.withValues(alpha: isDark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: savingsColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                'DCA ${(savingsRatio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: savingsColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Custom Multi-Segmented Progress Track
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            width: double.infinity,
            color: isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.surfaceSecondary,
            child: CustomPaint(
              painter: BudgetRatioBarPainter(
                fixedRatio: fixedRatio,
                varRatio: varRatio,
                savingsRatio: savingsRatio,
                surplusRatio: surplusRatio,
                fixedColor: fixedColor,
                varColor: varColor,
                savingsColor: savingsColor,
                surplusColor: surplusColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 4 Modern Allocation Chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildAllocationChip(
              label: 'fixed_cost_short'.tr,
              percent: (fixedRatio * 100).toInt(),
              amount: currencyFmt.format(fixedAmount),
              color: fixedColor,
              isDark: isDark,
            ),
            _buildAllocationChip(
              label: 'variable_cost_short'.tr,
              percent: (varRatio * 100).toInt(),
              amount: currencyFmt.format(varAmount),
              color: varColor,
              isDark: isDark,
            ),
            _buildAllocationChip(
              label: 'savings_short'.tr,
              percent: (savingsRatio * 100).toInt(),
              amount: currencyFmt.format(savingsAmount),
              color: savingsColor,
              isDark: isDark,
            ),
            if (surplusRatio > 0)
              _buildAllocationChip(
                label: 'buffer_short'.tr,
                percent: (surplusRatio * 100).toInt(),
                amount: currencyFmt.format(surplusAmount),
                color: surplusColor,
                isDark: isDark,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllocationChip({
    required String label,
    required int percent,
    required String amount,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label $percent%',
            style: NothingTypography.grotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            amount,
            style: GoogleFonts.shareTechMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SMART FINANCIAL STRATEGY BENTO DECK
  // ==========================================
  Widget _buildStrategyBentoDeck(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.auto_awesome_rounded,
          title: 'financial_templates_header'.tr,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStrategyCard(
                title: '50 / 30 / 20',
                subtitle: 'balanced_life'.tr,
                badgeText: 'rule_50_30_20_badge'.tr,
                badgeIcon: Icons.star_rounded,
                color: AppColors.primary,
                breakdownText: '50% • 30% • 20%',
                isDark: isDark,
                onTap: () =>
                    controller.applyTemplate(BudgetPresetType.rule50_30_20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrategyCard(
                title: '60 / 20 / 20',
                subtitle: 'fixed_heavy'.tr,
                badgeText: 'rule_60_20_20_badge'.tr,
                badgeIcon: Icons.home_rounded,
                color: AppColors.fixedCostAccent,
                breakdownText: '60% • 20% • 20%',
                isDark: isDark,
                onTap: () =>
                    controller.applyTemplate(BudgetPresetType.rule60_20_20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrategyCard(
                title: '40 / 30 / 30',
                subtitle: 'high_savings'.tr,
                badgeText: 'rule_40_30_30_badge'.tr,
                badgeIcon: Icons.rocket_launch_rounded,
                color: AppColors.accent,
                breakdownText: '40% • 30% • 30%',
                isDark: isDark,
                onTap: () =>
                    controller.applyTemplate(BudgetPresetType.rule40_30_30),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrategyCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData badgeIcon,
    required Color color,
    required String breakdownText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.nothingBorder
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              // Badge Pill
              FittedBox(
                fit: BoxFit.scaleDown,
                child: NothingPill(
                  label: badgeText.toUpperCase(),
                  color: isDark
                      ? const Color(0xFF202020)
                      : const Color(0xFFE8E8E8),
                  textColor: isDark ? Colors.white : Colors.black,
                  isDotMatrix: true,
                  fontSize: 8.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 7),

              // Title Ratio
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(
                subtitle,
                style: NothingTypography.grotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.nothingSubtext
                      : const Color(0xFF777777),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Breakdown Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0C0C0C)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  breakdownText,
                  style: NothingTypography.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. INTERACTIVE DAILY ALLOWANCE STUDIO
  // ==========================================
  Widget _buildDailyAllowanceStudio(
    BuildContext context,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.fastfood_outlined,
          title: 'daily_allowance_section'.tr,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        NothingCard(
          padding: const EdgeInsets.all(18),
          showDotGrid: false,
          child: Column(
            children: [
              // Hero Daily Number Row
              Obx(() {
                final monthlyTotal = controller.plannedVariableBudget;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showEditNumberDialog(
                                context,
                                'daily_allowance_input_title'.tr,
                                controller.targetDailyAllowance,
                                AppColors.variableCostAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          currencyFmt.format(
                                            controller
                                                .targetDailyAllowance
                                                .value,
                                          ),
                                          style: GoogleFonts.shareTechMono(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF222222)
                                            : const Color(0xFFEEEEEE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.nothingBorder
                                              : Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 13,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Monthly Run-Rate Pill
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: NothingPill(
                            label: currencyFmt.format(monthlyTotal),
                            color: isDark
                                ? const Color(0xFF1C1C1C)
                                : const Color(0xFFEDEDED),
                            textColor: isDark ? Colors.white : Colors.black,
                            isDotMatrix: true,
                            fontSize: 10.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'monthly_variable_total'.trParams({
                          'amount': currencyFmt.format(monthlyTotal),
                          'days': controller.daysInMonth.toString(),
                        }),
                        style: NothingTypography.grotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.nothingSubtext
                              : const Color(0xFF777777),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),

              // Quick Stepper Adjustment Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildStepperButton(
                      label: '-฿100',
                      onTap: () => controller.adjustDailyAllowance(-100),
                      color: AppColors.variableCostAccent,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStepperButton(
                      label: '-฿50',
                      onTap: () => controller.adjustDailyAllowance(-50),
                      color: AppColors.variableCostAccent,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStepperButton(
                      label: '+฿50',
                      onTap: () => controller.adjustDailyAllowance(50),
                      color: AppColors.variableCostAccent,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStepperButton(
                      label: '+฿100',
                      onTap: () => controller.adjustDailyAllowance(100),
                      color: AppColors.variableCostAccent,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Slider
              Obx(() {
                final val = controller.targetDailyAllowance.value.clamp(
                  0.0,
                  3000.0,
                );

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: isDark ? Colors.white : Colors.black,
                        inactiveTrackColor: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFE5E5E5),
                        thumbColor: AppColors.nothingRed,
                        overlayColor: AppColors.nothingRed.withValues(
                          alpha: 0.18,
                        ),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: val,
                        min: 0,
                        max: 3000,
                        divisions: 60,
                        onChanged: (newVal) =>
                            controller.targetDailyAllowance.value = newVal,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '฿0',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'step_50'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '฿3,000',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // ==========================================================
              // SMART DYNAMIC ENGINE: เงินปัจจุบัน - เงินออม - รายจ่ายคงที่
              // ==========================================================
              _buildDynamicQuotaEngineCard(context, currencyFmt, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicQuotaEngineCard(
    BuildContext context,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    return Obx(() {
      final currentBalance = controller.currentWalletBalance;
      final savings = controller.targetMonthlySavings.value;
      final fixedCosts = controller.remainingMonthlyFixedCosts;
      final availableBudget = controller.dynamicAvailableBudget;
      final quota = controller.dynamicCalculatedQuota;
      final remainingDays = controller.remainingDaysInMonth;
      final isPositive = availableBudget > 0;

      final Color accentColor = isPositive
          ? (isDark ? Colors.white : Colors.black)
          : (isDark ? AppColors.nothingRedLight : AppColors.nothingRed);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.28)
              : AppColors.surfaceSecondary.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Formula Icon & Title
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dynamic_calculator_title'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'dynamic_calculator_desc'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3-Step Deduction Formula Breakdown (Current - Savings - Fixed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  _buildFormulaDeductionRow(
                    label: 'current_wallet_balance'.tr,
                    amount: currencyFmt.format(currentBalance),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    isDark: isDark,
                    prefix: '',
                  ),
                  const SizedBox(height: 6),
                  _buildFormulaDeductionRow(
                    label: 'deduct_savings_target'.tr,
                    amount: currencyFmt.format(savings),
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    prefix: '- ',
                  ),
                  const SizedBox(height: 6),
                  _buildFormulaDeductionRow(
                    label: 'deduct_remaining_fixed'.tr,
                    amount: currencyFmt.format(fixedCosts),
                    color: isDark
                        ? const Color(0xFFE5E5EA)
                        : const Color(0xFF3A3A3C),
                    isDark: isDark,
                    prefix: '- ',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, thickness: 0.8),
                  ),
                  _buildFormulaDeductionRow(
                    label: 'available_daily_budget_total'.tr,
                    amount: currencyFmt.format(availableBudget),
                    color: accentColor,
                    isDark: isDark,
                    prefix: '= ',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic Daily Quota Result & Action Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'calculated_daily_quota'.tr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencyFmt.format(quota),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ ${'day'.tr}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'remaining_days_in_month_count'.trParams({
                          'days': '$remainingDays',
                        }),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Apply Quota Action Button
                Material(
                  color: isPositive
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: isPositive ? controller.applyDynamicQuota : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: isPositive
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'apply_template'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isPositive
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFormulaDeductionRow({
    required String label,
    required String amount,
    required Color color,
    required bool isDark,
    required String prefix,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 11.5 : 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$prefix$amount',
          style: TextStyle(
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreePillarsSection(
    BuildContext context,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.account_balance_rounded,
          title: 'core_pillars_header'.tr,
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildPillarBentoCard(
          context,
          title: 'monthly_income_target'.tr,
          subtitle: 'planned_income_desc'.tr,
          value: controller.plannedIncome,
          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
          icon: Icons.account_balance_wallet_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          onQuickAdjust: (delta) => controller.adjustPlannedIncome(delta),
          quickSteps: [1000, 5000],
        ),
        const SizedBox(height: 12),

        _buildPillarBentoCard(
          context,
          title: 'planned_savings_title'.tr,
          subtitle: 'planned_savings_desc'.tr,
          value: controller.targetMonthlySavings,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          icon: Icons.savings_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          ratioTextBuilder: () => 'percent_of_income'.trParams({
            'percent': '${(controller.savingsRatio * 100).toInt()}%',
          }),
          onQuickAdjust: (delta) =>
              controller.adjustTargetMonthlySavings(delta),
          quickSteps: [500, 1000],
        ),
        const SizedBox(height: 12),

        _buildPillarBentoCard(
          context,
          title: 'planned_fixed_costs_title'.tr,
          subtitle: 'planned_fixed_costs_desc'.tr,
          value: controller.plannedFixedCosts,
          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          icon: Icons.home_work_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          ratioTextBuilder: () => 'percent_of_income'.trParams({
            'percent': '${(controller.fixedCostsRatio * 100).toInt()}%',
          }),
          onQuickAdjust: (delta) => controller.adjustPlannedFixedCosts(delta),
          quickSteps: [500, 1000],
        ),
      ],
    );
  }

  Widget _buildPillarBentoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required RxDouble value,
    required Color color,
    required IconData icon,
    required NumberFormat currencyFmt,
    required bool isDark,
    String Function()? ratioTextBuilder,
    required Function(double) onQuickAdjust,
    required List<int> quickSteps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showEditNumberDialog(context, title, value, color),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              currencyFmt.format(value.value),
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: -0.4,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 13, color: color),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              if (ratioTextBuilder != null)
                Obx(() {
                  final ratioText = ratioTextBuilder();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      ratioText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                }),
              const Spacer(),
              ...quickSteps.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onQuickAdjust(step.toDouble());
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '+$step',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: isDark ? 0.16 : 0.08,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showEditNumberDialog(
    BuildContext context,
    String title,
    RxDouble rxValue,
    Color color,
  ) {
    final textController = TextEditingController(
      text: rxValue.value.toInt().toString(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AppGlassDialog(
        maxWidth: 420,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPopupHeader(
              title: 'edit_item_title'.trParams({'title': title}),
              icon: Icons.edit_note_rounded,
              iconColor: color,
            ),
            const SizedBox(height: 18),

            TextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '฿ ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F0F12)
                    : AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 5000, 10000].map((addAmount) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final current =
                          double.tryParse(
                            textController.text.replaceAll(',', ''),
                          ) ??
                          0.0;
                      textController.text = (current + addAmount)
                          .toInt()
                          .toString();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.20 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.45 : 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '+$addAmount',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? color : color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final clean = textController.text
                        .replaceAll(',', '')
                        .trim();
                    final parsed = double.tryParse(clean);
                    if (parsed != null && parsed >= 0) {
                      rxValue.value = parsed;
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'confirm'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetRatioBarPainter extends CustomPainter {
  final double fixedRatio;
  final double varRatio;
  final double savingsRatio;
  final double surplusRatio;
  final Color fixedColor;
  final Color varColor;
  final Color savingsColor;
  final Color surplusColor;

  const BudgetRatioBarPainter({
    required this.fixedRatio,
    required this.varRatio,
    required this.savingsRatio,
    required this.surplusRatio,
    required this.fixedColor,
    required this.varColor,
    required this.savingsColor,
    required this.surplusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = fixedRatio + varRatio + savingsRatio + surplusRatio;
    if (total <= 0) return;

    double currentX = 0;

    void drawSegment(double ratio, Color color) {
      if (ratio <= 0) return;
      final w = size.width * (ratio / total);
      final paint = Paint()..color = color;
      canvas.drawRect(Rect.fromLTWH(currentX, 0, w, size.height), paint);
      currentX += w;
    }

    drawSegment(fixedRatio, fixedColor);
    drawSegment(varRatio, varColor);
    drawSegment(savingsRatio, savingsColor);
    drawSegment(surplusRatio, surplusColor);
  }

  @override
  bool shouldRepaint(covariant BudgetRatioBarPainter oldDelegate) {
    return oldDelegate.fixedRatio != fixedRatio ||
        oldDelegate.varRatio != varRatio ||
        oldDelegate.savingsRatio != savingsRatio ||
        oldDelegate.surplusRatio != surplusRatio;
  }
}
