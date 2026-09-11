import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/budget_controller.dart';

/// หน้าจอตั้งค่าเป้าหมายงบประมาณ (Budget Settings View) สไตล์ Modern FinTech 2026
/// นำเสนอในรูปแบบ Budgeting Studio ระดับพรีเมียม:
/// 1. Hero Financial Projection Matrix พร้อมแถบแสดงสัดส่วน 4 มิติ และข้อความแนะนำสุขภาพการเงิน
/// 2. Smart Financial Strategy Bento Deck สำหรับสลับสูตร 50/30/20, 60/20/20, 40/30/30 อัตโนมัติ
/// 3. Interactive Daily Allowance Studio พร้อมปุ่ม Quick Stepper และ Slider ปรับระดับ
/// 4. 3 เสาหลักโครงสร้างงบประมาณ (Income, Savings, Fixed Costs) แบบการ์ด Bento แยกอิสระ
class BudgetSettingsView extends GetView<BudgetController> {
  const BudgetSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'budget_settings'.tr,
        badgeText: 'Smart Plan',
        subtitle: 'budget_subtitle'.tr,
        actions: [
          ModernAppBar.themeToggleButton(context: context, isDark: isDark),
          ModernAppBar.primaryActionButton(
            onTap: controller.save,
            label: 'save'.tr,
            icon: Icons.check_rounded,
          ),
        ],
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
                // 1. HERO FINANCIAL PROJECTION MATRIX
                _buildHeroProjectionMatrix(context, currencyFmt, isDark),
                const SizedBox(height: 20),

                // 2. SMART FINANCIAL STRATEGY BENTO DECK
                _buildStrategyBentoDeck(context, isDark),
                const SizedBox(height: 20),

                // 3. INTERACTIVE DAILY ALLOWANCE STUDIO
                _buildDailyAllowanceStudio(context, currencyFmt, isDark),
                const SizedBox(height: 20),

                // 4. THREE PILLARS OF FINANCIAL ARCHITECTURE
                _buildThreePillarsSection(context, currencyFmt, isDark),
                const SizedBox(height: 26),

                // 5. LUXURY SAVE ACTION BUTTON
                _buildLuxurySaveButton(isDark),
                const SizedBox(height: 96),
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
      final primaryStatusColor = isPositive ? AppColors.primary : AppColors.deficitText;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryStatusColor.withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryStatusColor.withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Icon + Title + Status Pill)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPositive
                                  ? const [AppColors.primary, Color(0xFF6366F1)]
                                  : const [Color(0xFFEF4444), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryStatusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPositive ? Icons.auto_graph_rounded : Icons.trending_down_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'estimated_ending_balance'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${controller.daysInMonth} ${controller.dashboardController.isEnglish ? "days in cycle" : "วันในรอบเดือน"}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Pulsing Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.deficitText.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryStatusColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryStatusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryStatusColor.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPositive ? 'good_balance'.tr : 'over_budget'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: primaryStatusColor,
                            ),
                          ),
                        ],
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
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: primaryStatusColor,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Calculation Formula Caption
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'budget_calc_desc'.trParams({'days': controller.daysInMonth.toString()}),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Health & Wealth Advisory Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: controller.healthStatusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.healthStatusColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.verified_rounded : Icons.error_outline_rounded,
                        size: 17,
                        color: controller.healthStatusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.healthStatusMessage,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: controller.healthStatusColor,
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
          ),
        ),
      );
    }).animate().fadeIn(duration: const Duration(milliseconds: 300)).slideY(begin: -0.04);
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
    final surplusRatio = (1.0 - (fixedRatio + varRatio + savingsRatio)).clamp(0.0, 1.0);

    final fixedAmount = controller.plannedFixedCosts.value;
    final varAmount = controller.plannedVariableBudget;
    final savingsAmount = controller.targetMonthlySavings.value;
    final surplusAmount = controller.expectedEndingBalance.clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'allocation_breakdown'.tr,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DCA ${(savingsRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
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
            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
            child: CustomPaint(
              painter: BudgetRatioBarPainter(
                fixedRatio: fixedRatio,
                varRatio: varRatio,
                savingsRatio: savingsRatio,
                surplusRatio: surplusRatio,
                fixedColor: AppColors.fixedCostAccent,
                varColor: AppColors.variableCostAccent,
                savingsColor: AppColors.accent,
                surplusColor: AppColors.primary,
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
              label: controller.dashboardController.isEnglish ? 'Fixed' : 'คงที่',
              percent: (fixedRatio * 100).toInt(),
              amount: currencyFmt.format(fixedAmount),
              color: AppColors.fixedCostAccent,
              isDark: isDark,
            ),
            _buildAllocationChip(
              label: controller.dashboardController.isEnglish ? 'Variable' : 'กินอยู่',
              percent: (varRatio * 100).toInt(),
              amount: currencyFmt.format(varAmount),
              color: AppColors.variableCostAccent,
              isDark: isDark,
            ),
            _buildAllocationChip(
              label: controller.dashboardController.isEnglish ? 'Savings' : 'เงินออม',
              percent: (savingsRatio * 100).toInt(),
              amount: currencyFmt.format(savingsAmount),
              color: AppColors.accent,
              isDark: isDark,
            ),
            if (surplusRatio > 0)
              _buildAllocationChip(
                label: controller.dashboardController.isEnglish ? 'Buffer' : 'คงเหลือ',
                percent: (surplusRatio * 100).toInt(),
                amount: currencyFmt.format(surplusAmount),
                color: AppColors.primary,
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
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label $percent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                subtitle: controller.dashboardController.isEnglish ? 'Balanced Life' : 'สมดุลชีวิต',
                badgeText: 'rule_50_30_20_badge'.tr,
                badgeIcon: Icons.star_rounded,
                color: AppColors.primary,
                breakdownText: '50% • 30% • 20%',
                isDark: isDark,
                onTap: () => controller.applyTemplate(BudgetPresetType.rule50_30_20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrategyCard(
                title: '60 / 20 / 20',
                subtitle: controller.dashboardController.isEnglish ? 'Fixed Heavy' : 'ภาระคงที่',
                badgeText: 'rule_60_20_20_badge'.tr,
                badgeIcon: Icons.home_rounded,
                color: AppColors.fixedCostAccent,
                breakdownText: '60% • 20% • 20%',
                isDark: isDark,
                onTap: () => controller.applyTemplate(BudgetPresetType.rule60_20_20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrategyCard(
                title: '40 / 30 / 30',
                subtitle: controller.dashboardController.isEnglish ? 'High Savings' : 'สายออมดุ',
                badgeText: 'rule_40_30_30_badge'.tr,
                badgeIcon: Icons.rocket_launch_rounded,
                color: AppColors.accent,
                breakdownText: '40% • 30% • 30%',
                isDark: isDark,
                onTap: () => controller.applyTemplate(BudgetPresetType.rule40_30_30),
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
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 10, color: color),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),

              // Title Ratio
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Breakdown Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  breakdownText,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: color,
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
          icon: Icons.fastfood_rounded,
          title: 'daily_allowance_section'.tr,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
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
                        Material(
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFmt.format(controller.targetDailyAllowance.value),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.variableCostAccent,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.variableCostAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: AppColors.variableCostAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Monthly Run-Rate Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.variableCostAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currencyFmt.format(monthlyTotal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.variableCostAccent,
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                final val = controller.targetDailyAllowance.value.clamp(0.0, 3000.0);

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        activeTrackColor: AppColors.variableCostAccent,
                        inactiveTrackColor: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.surfaceSecondary,
                        thumbColor: AppColors.variableCostAccent,
                        overlayColor: AppColors.variableCostAccent.withValues(alpha: 0.18),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: val,
                        min: 0,
                        max: 3000,
                        divisions: 60,
                        onChanged: (newVal) => controller.targetDailyAllowance.value = newVal,
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
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'step_50'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '฿3,000',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
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

  // ==========================================
  // 4. THREE PILLARS OF FINANCIAL ARCHITECTURE
  // ==========================================
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

        // Pillar 1: Monthly Income
        _buildPillarBentoCard(
          context,
          title: 'monthly_income_target'.tr,
          subtitle: 'planned_income_desc'.tr,
          value: controller.plannedIncome,
          color: AppColors.primary,
          icon: Icons.account_balance_wallet_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          onQuickAdjust: (delta) => controller.adjustPlannedIncome(delta),
          quickSteps: [1000, 5000],
        ),
        const SizedBox(height: 12),

        // Pillar 2: Savings & Investments (DCA)
        _buildPillarBentoCard(
          context,
          title: 'planned_savings_title'.tr,
          subtitle: 'planned_savings_desc'.tr,
          value: controller.targetMonthlySavings,
          color: AppColors.accent,
          icon: Icons.savings_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          ratioText: '${(controller.savingsRatio * 100).toInt()}% ${controller.dashboardController.isEnglish ? "of income" : "ของรายรับ"}',
          onQuickAdjust: (delta) => controller.adjustTargetMonthlySavings(delta),
          quickSteps: [500, 1000],
        ),
        const SizedBox(height: 12),

        // Pillar 3: Fixed Costs
        _buildPillarBentoCard(
          context,
          title: 'planned_fixed_costs_title'.tr,
          subtitle: 'planned_fixed_costs_desc'.tr,
          value: controller.plannedFixedCosts,
          color: AppColors.fixedCostAccent,
          icon: Icons.home_work_rounded,
          currencyFmt: currencyFmt,
          isDark: isDark,
          ratioText: '${(controller.fixedCostsRatio * 100).toInt()}% ${controller.dashboardController.isEnglish ? "of income" : "ของรายรับ"}',
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
    String? ratioText,
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
        children: [
          Row(
            children: [
              // Squircle Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ratioText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ratioText,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Value Display & Edit Trigger
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditNumberDialog(context, title, value, color),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          const SizedBox(height: 10),

          // Quick Adjustment Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // ==========================================
  // 5. LUXURY GRADIENT SAVE BUTTON
  // ==========================================
  Widget _buildLuxurySaveButton(bool isDark) {
    return Obx(() {
      final isSuccess = controller.isSaveSuccess.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isSuccess
                ? const [Color(0xFF10B981), Color(0xFF059669)]
                : const [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: (isSuccess ? const Color(0xFF10B981) : AppColors.primary)
                  .withValues(alpha: isSuccess ? 0.45 : 0.35),
              blurRadius: isSuccess ? 20 : 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: controller.isSaving.value ? null : controller.save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSuccess
                ? Row(
                    key: const ValueKey('saved_budget_success'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'budget_save_success'.tr,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('save_budget_idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'save_budget'.tr,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // ==========================================
  // SECTION HEADER HELPER
  // ==========================================
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
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
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

  // ==========================================
  // MODERN FINTECH QUICK EDIT DIALOG
  // ==========================================
  void _showEditNumberDialog(
    BuildContext context,
    String title,
    RxDouble rxValue,
    Color color,
  ) {
    final textController = TextEditingController(text: rxValue.value.toInt().toString());
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
              title: '${controller.dashboardController.isEnglish ? "Edit" : "แก้ไข"} $title',
              icon: Icons.edit_note_rounded,
              iconColor: color,
            ),
            const SizedBox(height: 18),

            // Number Input
            TextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              decoration: InputDecoration(
                prefixText: '฿ ',
                prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Add & Subtract Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 5000, 10000].map((addAmount) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final current = double.tryParse(textController.text.replaceAll(',', '')) ?? 0.0;
                      textController.text = (current + addAmount).toInt().toString();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '+$addAmount',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Actions (Cancel / Confirm)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final clean = textController.text.replaceAll(',', '').trim();
                    final parsed = double.tryParse(clean);
                    if (parsed != null && parsed >= 0) {
                      rxValue.value = parsed;
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// CustomPainter สำหรับวาดแท่งสัดส่วนงบประมาณแบบแม่นยำและลื่นไหล
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
