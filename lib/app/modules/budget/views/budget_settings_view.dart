import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../controllers/budget_controller.dart';

/// หน้าจอตั้งค่าเป้าหมายงบประมาณ (Budget Settings View) - ปรับแก้ตัวเลขได้จริง พร้อมสูตรคำนวณและสัดส่วนแบบเรียลไทม์
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
          ModernAppBar.primaryActionButton(
            onTap: controller.save,
            label: 'save'.tr,
            icon: Icons.check_rounded,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live Projection Card & Ratio Breakdown
                Obx(() {
                  final endingBalance = controller.expectedEndingBalance;
                  final isPositive = endingBalance >= 0;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: (isPositive ? AppColors.primary : AppColors.deficitText).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'estimated_ending_balance'.tr,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositive ? AppColors.surplusBg : AppColors.deficitBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPositive ? 'good_balance'.tr : 'over_budget'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isPositive ? AppColors.surplusText : AppColors.deficitText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currencyFmt.format(endingBalance),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isPositive ? AppColors.primary : AppColors.deficitText,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'budget_calc_desc'.trParams({'days': controller.daysInMonth.toString()}),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // Health Insight Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: controller.healthStatusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPositive ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                size: 16,
                                color: controller.healthStatusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.healthStatusMessage,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: controller.healthStatusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Segmented Budget Ratio Bar
                        _buildRatioBar(context, isDark),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // 2. Smart Financial Templates Section
                _buildSectionHeader('financial_templates_header'.tr),
                const SizedBox(height: 8),
                _buildTemplatesSelector(context, isDark),
                const SizedBox(height: 18),

                // 3. Daily Allowance Adjustment
                _buildSectionHeader('daily_allowance_section'.tr),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Obx(() {
                        final monthlyTotal = controller.plannedVariableBudget;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => _showEditNumberDialog(
                                    context,
                                    'daily_allowance_input_title'.tr,
                                    controller.targetDailyAllowance,
                                    AppColors.variableCostAccent,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      children: [
                                        Text(
                                          currencyFmt.format(controller.targetDailyAllowance.value),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.edit_rounded, size: 14, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  'tap_to_edit'.tr,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        final val = controller.targetDailyAllowance.value.clamp(0.0, 3000.0);
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 5,
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withValues(alpha: 0.15),
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
                                  const Text(
                                    '฿0',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'step_50'.tr,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                  const Text(
                                    '฿3,000',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                const SizedBox(height: 18),

                // 4. Planned Income, Fixed Costs, Savings
                _buildSectionHeader('monthly_plan_summary_header'.tr),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildNumberField(
                        context,
                        title: 'monthly_income_target'.tr,
                        subtitle: 'planned_income_desc'.tr,
                        value: controller.plannedIncome,
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _buildNumberField(
                        context,
                        title: 'planned_savings_title'.tr,
                        subtitle: 'planned_savings_desc'.tr,
                        value: controller.targetMonthlySavings,
                        icon: Icons.savings_rounded,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _buildNumberField(
                        context,
                        title: 'planned_fixed_costs_title'.tr,
                        subtitle: 'planned_fixed_costs_desc'.tr,
                        value: controller.plannedFixedCosts,
                        icon: Icons.home_work_rounded,
                        color: AppColors.fixedCostAccent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Save Button
                Obx(() {
                  final isSuccess = controller.isSaveSuccess.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isSuccess
                            ? const [Color(0xFF10B981), Color(0xFF059669)]
                            : const [AppColors.primary, AppColors.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? const Color(0xFF10B981) : AppColors.primary)
                              .withValues(alpha: isSuccess ? 0.45 : 0.35),
                          blurRadius: isSuccess ? 18 : 14,
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSuccess
                            ? Row(
                                key: const ValueKey('saved_budget'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'budget_save_success'.tr,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              )
                            : Row(
                                key: const ValueKey('idle_budget'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text('save_budget'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildRatioBar(BuildContext context, bool isDark) {
    final fixedRatio = controller.fixedCostsRatio;
    final varRatio = controller.variableCostsRatio;
    final savingsRatio = controller.savingsRatio;
    final surplusRatio = (1.0 - (fixedRatio + varRatio + savingsRatio)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'สัดส่วนการจัดสรรรายรับ (Ratio Breakdown)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ออม ${(savingsRatio * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildRatioLegendItem('คงที่ ${(fixedRatio * 100).toStringAsFixed(0)}%', AppColors.fixedCostAccent),
            _buildRatioLegendItem('กินอยู่ ${(varRatio * 100).toStringAsFixed(0)}%', AppColors.variableCostAccent),
            _buildRatioLegendItem('เงินออม ${(savingsRatio * 100).toStringAsFixed(0)}%', AppColors.accent),
            if (surplusRatio > 0)
              _buildRatioLegendItem('เงินเหลือ ${(surplusRatio * 100).toStringAsFixed(0)}%', AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTemplatesSelector(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTemplateCard(
            title: '50/30/20',
            subtitle: 'สมดุลชีวิต',
            badge: 'ยอดนิยม',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => controller.applyTemplate(BudgetPresetType.rule50_30_20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTemplateCard(
            title: '60/20/20',
            subtitle: 'เน้นคงที่',
            badge: 'ครอบครัว',
            color: AppColors.fixedCostAccent,
            isDark: isDark,
            onTap: () => controller.applyTemplate(BudgetPresetType.rule60_20_20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTemplateCard(
            title: '40/30/30',
            subtitle: 'สายออมดุ',
            badge: 'เกษียณไว',
            color: AppColors.accent,
            isDark: isDark,
            onTap: () => controller.applyTemplate(BudgetPresetType.rule40_30_30),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    BuildContext context, {
    required String title,
    required String subtitle,
    required RxDouble value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Obx(() {
      return InkWell(
        onTap: () => _showEditNumberDialog(context, title, value, color),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFmt.format(value.value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 13, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    });
  }

  void _showEditNumberDialog(BuildContext context, String title, RxDouble rxValue, Color color) {
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
              title: 'แก้ไข $title',
              icon: Icons.edit_note_rounded,
              iconColor: color,
            ),
            const SizedBox(height: 18),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 5000, 10000].map((addAmount) {
                return InkWell(
                  onTap: () {
                    final current = double.tryParse(textController.text.replaceAll(',', '')) ?? 0.0;
                    textController.text = (current + addAmount).toInt().toString();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
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
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
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
                  child: const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.w700)),
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
