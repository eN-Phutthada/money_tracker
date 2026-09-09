import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../models/finance_models.dart';

/// Modal Quick Input สำหรับบันทึกรายการด่วนในหน้าเดียว
class QuickAddModal extends StatefulWidget {
  final Function(TransactionItem) onSave;

  const QuickAddModal({super.key, required this.onSave});

  static Future<void> show(BuildContext context, Function(TransactionItem) onSave) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: QuickAddModal(onSave: onSave),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: QuickAddModal(onSave: onSave),
        ),
      );
    }
  }

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  CostNature _selectedCostNature = CostNature.variable;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อรายการและจำนวนเงิน'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(amountText.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('จำนวนเงินต้องมากกว่า 0'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final item = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: _selectedType,
      costNature: _selectedType == TransactionType.expense
          ? _selectedCostNature
          : CostNature.notApplicable,
      categoryName: _categoryController.text.trim().isEmpty
          ? (_selectedType == TransactionType.income
              ? 'รายได้ทั่วไป'
              : _selectedType == TransactionType.savingsInvestment
                  ? 'เงินออม'
                  : 'ทั่วไป')
          : _categoryController.text.trim(),
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag Handle & Title
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'บันทึกรายการใหม่',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Transaction Type Segment
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTypeTab(
                  type: TransactionType.income,
                  label: 'รายรับ',
                  icon: Icons.arrow_downward_rounded,
                  activeColor: AppColors.incomeText,
                ),
                _buildTypeTab(
                  type: TransactionType.expense,
                  label: 'รายจ่าย',
                  icon: Icons.arrow_upward_rounded,
                  activeColor: AppColors.deficitText,
                ),
                _buildTypeTab(
                  type: TransactionType.savingsInvestment,
                  label: 'เงินออม/ลงทุน',
                  icon: Icons.savings_outlined,
                  activeColor: AppColors.savingsText,
                ),
              ],
            ),
          ),

          // 2. Cost Nature Selector (แสดงเฉพาะเมื่อเลือกเป็นรายจ่าย)
          if (_selectedType == TransactionType.expense) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'ประเภทต้นทุน:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      _buildCostNatureChip(
                        nature: CostNature.variable,
                        label: 'จิปาถะ / ค่ากิน',
                        icon: Icons.fastfood_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildCostNatureChip(
                        nature: CostNature.fixed,
                        label: 'คงที่ (Fixed)',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // 3. Amount Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Title Input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'ชื่อรายการ (เช่น ข้าวกลางวัน, ค่ากาแฟ, ค่าเน็ต)',
              prefixIcon: const Icon(Icons.edit_note_outlined, size: 20, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 5. Category & Date Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'หมวดหมู่ (เว้นว่างได้)',
                    prefixIcon: const Icon(Icons.category_outlined, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Submit Button
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'บันทึกรายการ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab({
    required TransactionType type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostNatureChip({
    required CostNature nature,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedCostNature == nature;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCostNature = nature;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? nature.tagBgColor : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? nature.tagTextColor.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? nature.tagTextColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? nature.tagTextColor : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
