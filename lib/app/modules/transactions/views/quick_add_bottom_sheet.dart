import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// 3-Second Quick Add BottomSheet พร้อม Ergonomic Numpad ในตัว
class QuickAddBottomSheet extends StatefulWidget {
  const QuickAddBottomSheet({super.key});

  static void show(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const QuickAddBottomSheet(),
          ),
        ),
      );
    } else {
      Get.bottomSheet(
        const QuickAddBottomSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final DashboardController controller = Get.find<DashboardController>();

  String _amountBuffer = '';
  TransactionType _selectedType = TransactionType.expense;
  CostNature _selectedCostNature = CostNature.variable;
  String _selectedCategory = 'อาหาร/ของกิน';
  final String _customTitle = '';
  final DateTime _selectedDate = DateTime.now();

  static const List<Map<String, dynamic>> _quickCategories = [
    {'name': 'อาหาร/ของกิน', 'icon': Icons.fastfood_rounded},
    {'name': 'กาแฟ/เครื่องดื่ม', 'icon': Icons.local_cafe_rounded},
    {'name': 'การเดินทาง', 'icon': Icons.directions_subway_rounded},
    {'name': 'ช้อปปิ้ง', 'icon': Icons.shopping_bag_rounded},
    {'name': 'ของใช้ส่วนตัว', 'icon': Icons.inventory_2_rounded},
    {'name': 'ที่อยู่อาศัย', 'icon': Icons.home_rounded},
    {'name': 'สาธารณูปโภค', 'icon': Icons.flash_on_rounded},
    {'name': 'เงินเดือน', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'เงินออม/DCA', 'icon': Icons.savings_rounded},
  ];

  void _onNumpadPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '⌫') {
        if (_amountBuffer.isNotEmpty) {
          _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1);
        }
      } else if (key == '.') {
        if (!_amountBuffer.contains('.')) {
          _amountBuffer = _amountBuffer.isEmpty ? '0.' : '$_amountBuffer.';
        }
      } else {
        if (_amountBuffer.contains('.')) {
          final parts = _amountBuffer.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        if (_amountBuffer == '0') {
          _amountBuffer = key;
        } else if (_amountBuffer.length < 9) {
          _amountBuffer += key;
        }
      }
    });
  }

  void _addQuickAmount(double value) {
    HapticFeedback.lightImpact();
    final current = double.tryParse(_amountBuffer) ?? 0.0;
    final next = current + value;
    setState(() {
      _amountBuffer = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(2);
    });
  }

  void _submit() {
    final amount = double.tryParse(_amountBuffer);
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
        'แจ้งเตือน',
        'กรุณาระบุจำนวนเงินที่มากกว่า 0',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.deficitBg,
        colorText: AppColors.deficitText,
      );
      return;
    }

    final item = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _customTitle.isNotEmpty ? _customTitle : _selectedCategory,
      amount: amount,
      type: _selectedType,
      costNature: _selectedType == TransactionType.expense ? _selectedCostNature : CostNature.notApplicable,
      categoryName: _selectedCategory,
      date: _selectedDate,
    );

    controller.addTransaction(item);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Type Selector
          Row(
            children: [
              Expanded(
                child: _buildTypeSegment(
                  type: TransactionType.expense,
                  label: 'รายจ่าย',
                  color: AppColors.deficitText,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeSegment(
                  type: TransactionType.income,
                  label: 'รายรับ',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeSegment(
                  type: TransactionType.savingsInvestment,
                  label: 'เงินออม',
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fixed vs Variable (for expense)
          if (_selectedType == TransactionType.expense)
            Row(
              children: [
                _buildCostNaturePill(CostNature.variable, 'จิปาถะ (Variable)', isDark),
                const SizedBox(width: 8),
                _buildCostNaturePill(CostNature.fixed, 'คงที่ (Fixed)', isDark),
              ],
            ),
          if (_selectedType == TransactionType.expense) const SizedBox(height: 12),

          // Amount Display Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Text(
                        _amountBuffer.isEmpty ? '0' : _amountBuffer,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('฿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Amount Add Pills
          Row(
            children: [
              _buildQuickPill('+50', 50, isDark),
              const SizedBox(width: 8),
              _buildQuickPill('+100', 100, isDark),
              const SizedBox(width: 8),
              _buildQuickPill('+500', 500, isDark),
              const Spacer(),
              if (_amountBuffer.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _amountBuffer = ''),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                  child: const Text('ล้าง', style: TextStyle(fontSize: 12, color: AppColors.deficitText)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Category Pills
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _quickCategories[index];
                final isSelected = _selectedCategory == cat['name'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat['name'] as String);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 13,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Built-in 4x3 Ergonomic Numpad
          _buildNumpadGrid(isDark),
          const SizedBox(height: 12),

          // Submit Button
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              'บันทึกรายการ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required TransactionType type,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildCostNaturePill(CostNature nature, String label, bool isDark) {
    final isSelected = _selectedCostNature == nature;
    final color = nature == CostNature.fixed ? AppColors.fixedCostAccent : AppColors.variableCostAccent;

    return GestureDetector(
      onTap: () => setState(() => _selectedCostNature = nature),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill(String label, double value, bool isDark) {
    return InkWell(
      onTap: () => _addQuickAmount(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildNumpadGrid(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _onNumpadPress(key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.7) : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: key == '⌫'
                          ? Icon(Icons.backspace_outlined, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
