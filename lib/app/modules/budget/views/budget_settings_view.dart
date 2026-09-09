import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../controllers/budget_controller.dart';

/// หน้าจอตั้งค่าเป้าหมายงบประมาณ (Budget Settings View)
class BudgetSettingsView extends GetView<BudgetController> {
  const BudgetSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่างบประมาณ'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live Projection Card
                Obx(() {
                  final endingBalance = controller.expectedEndingBalance;
                  final isPositive = endingBalance >= 0;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ประมาณการเงินเหลือสิ้นเดือน',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositive ? AppColors.surplusBg : AppColors.deficitBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPositive ? 'สมดุลดี' : 'ติดลบเกินงบ',
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
                        const SizedBox(height: 8),
                        Text(
                          'คำนวณจาก รายรับ - ค่าใช้จ่ายคงที่ - (โควตารายวัน x ${controller.daysInMonth} วัน) - เงินออม',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // 2. Daily Allowance Adjustment
                _buildSectionHeader('1. โควตาค่ากิน/ใช้จ่ายต่อวัน (Daily Allowance)'),
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
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFmt.format(controller.targetDailyAllowance.value),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => controller.adjustDailyAllowance(-50),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(44, 36),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('-50', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => controller.adjustDailyAllowance(50),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(44, 36),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text('+50', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 10),
                      Obx(() {
                        return Slider(
                          value: controller.targetDailyAllowance.value,
                          min: 100,
                          max: 2000,
                          divisions: 38,
                          activeColor: AppColors.primary,
                          onChanged: (val) => controller.targetDailyAllowance.value = val,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Planned Income, Fixed Costs, Savings
                _buildSectionHeader('2. สรุปแผนรายรับและรายจ่ายประจำเดือน'),
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
                        title: 'เป้าหมายรายรับต่อเดือน',
                        value: controller.plannedIncome,
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _buildNumberField(
                        title: 'เป้าหมายเงินออมและลงทุน (DCA)',
                        value: controller.targetMonthlySavings,
                        icon: Icons.savings_rounded,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                      const Divider(height: 20),
                      _buildNumberField(
                        title: 'ค่าใช้จ่ายคงที่ประมาณการ (Fixed Costs)',
                        value: controller.plannedFixedCosts,
                        icon: Icons.home_work_rounded,
                        color: AppColors.fixedCostAccent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: controller.save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('บันทึกแผนงบประมาณ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
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

  Widget _buildNumberField({
    required String title,
    required RxDouble value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Obx(() {
      return Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            currencyFmt.format(value.value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      );
    });
  }
}
