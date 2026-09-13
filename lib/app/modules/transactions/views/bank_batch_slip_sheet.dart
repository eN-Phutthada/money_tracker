import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bank_slip_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/bank_slip_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';

/// หน้าต่างพรีวิวและตรวจสอบสลิปแบบกลุ่ม (Krungthai Batch Slip Confirmation Sheet)
/// รองรับการแก้ไขข้อมูลทุกรายการ (ชื่อ, ยอดเงิน, หมวดหมู่, วันเวลา, บันทึกช่วยจำ) ก่อนบันทึก
class BankBatchSlipSheet extends StatefulWidget {
  final List<BankSlipData> initialSlips;
  final List<Map<String, dynamic>> duplicateSlips;

  const BankBatchSlipSheet({
    super.key,
    required this.initialSlips,
    this.duplicateSlips = const [],
  });

  static void show({
    BuildContext? context,
    required List<BankSlipData> slips,
    List<Map<String, dynamic>> duplicates = const [],
  }) {
    final activeContext = (context != null && context.mounted ? context : Get.context);
    if (activeContext == null) return;
    final isDesktop = MediaQuery.sizeOf(activeContext).width >= 800;

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 580,
          padding: const EdgeInsets.all(22),
          child: BankBatchSlipSheet(
            initialSlips: slips,
            duplicateSlips: duplicates,
          ),
        ),
      );
    } else {
      Get.bottomSheet(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: BankBatchSlipSheet(
            initialSlips: slips,
            duplicateSlips: duplicates,
          ),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<BankBatchSlipSheet> createState() => _BankBatchSlipSheetState();
}

class _BatchItemState {
  final BankSlipData slip;
  final bool isDuplicate;
  bool isSelected;
  String title;
  double amount;
  String category;
  TransactionType type;
  CostNature costNature;
  DateTime date;
  String? memo;

  _BatchItemState({
    required this.slip,
    this.isDuplicate = false,
    required this.isSelected,
    String? title,
    double? amount,
    required this.category,
    TransactionType? type,
    CostNature? costNature,
    DateTime? date,
    String? memo,
  })  : title = title ?? slip.defaultTitle,
        amount = amount ?? slip.amount,
        type = type ?? slip.suggestedType,
        costNature = costNature ?? slip.suggestedCostNature,
        date = date ?? slip.transactionDate,
        memo = memo ?? slip.memo;
}

class _BankBatchSlipSheetState extends State<BankBatchSlipSheet> {
  final BankSlipService slipService = BankSlipService();
  final currencyFormat = NumberFormat('#,##0.00', 'en_US');

  late List<_BatchItemState> _items;
  bool _isSaving = false;

  static const List<String> _availableCategories = [
    'อาหาร/ของกิน',
    'เดินทาง/ขนส่ง',
    'ช้อปปิ้ง',
    'บันเทิง/พักผ่อน',
    'สาธารณูปโภค',
    'ค่าที่พัก/หอพัก',
    'การศึกษา',
    'สุขภาพ/ยา',
    'โอนเงิน/ธุรกรรม',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _items = [];

    // เพิ่มสลิปปกติ (ติ๊กเลือกไว้)
    for (final slip in widget.initialSlips) {
      _items.add(
        _BatchItemState(
          slip: slip,
          isDuplicate: false,
          isSelected: true,
          title: slip.defaultTitle,
          amount: slip.amount,
          category: slip.suggestedCategory,
          type: slip.suggestedType,
          costNature: slip.suggestedCostNature,
          date: slip.transactionDate,
          memo: slip.memo,
        ),
      );
    }

    // เพิ่มสลิปที่ตรวจพบซ้ำ (ไม่ติ๊กเลือกไว้ เพื่อป้องกันการบันทึกซ้ำโดยไม่ตั้งใจ)
    for (final entry in widget.duplicateSlips) {
      final slip = entry['slip'] as BankSlipData?;
      if (slip == null) continue;
      _items.add(
        _BatchItemState(
          slip: slip,
          isDuplicate: true,
          isSelected: false,
          title: slip.defaultTitle,
          amount: slip.amount,
          category: slip.suggestedCategory,
          type: slip.suggestedType,
          costNature: slip.suggestedCostNature,
          date: slip.transactionDate,
          memo: slip.memo,
        ),
      );
    }
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  double get _selectedTotalAmount => _items
      .where((i) => i.isSelected)
      .fold(0.0, (sum, i) => sum + i.amount);

  Future<void> _pickDateTimeForItem(_BatchItemState item) async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: item.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: item.date.hour, minute: item.date.minute),
    );
    if (!mounted) return;

    setState(() {
      item.date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? item.date.hour,
        pickedTime?.minute ?? item.date.minute,
      );
    });
  }

  void _openItemEditor(_BatchItemState item) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    final editorWidget = _BatchItemEditDialog(
      item: item,
      isDark: isDark,
      categories: _availableCategories,
      onSave: (newTitle, newAmount, newCategory, newType, newDate, newMemo) {
        setState(() {
          item.title = newTitle;
          item.amount = newAmount;
          item.category = newCategory;
          item.type = newType;
          item.date = newDate;
          item.memo = newMemo;
        });
      },
    );

    if (isDesktop) {
      Get.dialog(
        AppGlassDialog(
          maxWidth: 500,
          padding: const EdgeInsets.all(20),
          child: editorWidget,
        ),
      );
    } else {
      Get.bottomSheet(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: editorWidget,
          ),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  Future<void> _saveSelectedSlips() async {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      int savedCount = 0;
      double totalAmount = 0.0;

      for (final item in selected) {
        slipService.saveSlipTransaction(
          item.slip,
          customTitle: item.title,
          customAmount: item.amount,
          customCategory: item.category,
          customType: item.type,
          customCostNature: item.costNature,
          customDate: item.date,
          customNote: item.memo,
          notify: false,
        );
        savedCount++;
        totalAmount += item.amount;
      }

      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}

      Get.back(); // ปิด BottomSheet

      AppFeedback.showSuccess(
        title: 'batch_save_success_title'.tr,
        message: 'batch_save_success_msg'.trParams({
          'count': '$savedCount',
          'amount': '฿${currencyFormat.format(totalAmount)}',
        }),
        amount: totalAmount,
      );
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag indicator
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A3E0), Color(0xFF0072CE)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'batch_review_title'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A3E0).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'item_count_label'.trParams({'count': '${_items.length}'}),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00A3E0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'batch_review_desc'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.6),

          // Slip List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildSlipCard(context, item, isDark);
              },
            ),
          ),

          // Bottom Action Section
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5) : AppColors.surfaceSecondary.withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'batch_selected_summary'.trParams({
                          'selected': '$_selectedCount',
                          'total': '${_items.length}',
                        }),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '฿${currencyFormat.format(_selectedTotalAmount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deficitText,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  onPressed: _selectedCount > 0 && !_isSaving ? _saveSelectedSlips : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'save_selected_count'.trParams({'count': '$_selectedCount'}),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipCard(BuildContext context, _BatchItemState item, bool isDark) {
    final isIncome = item.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isDuplicate
              ? AppColors.deficitText.withValues(alpha: 0.45)
              : item.isSelected
                  ? const Color(0xFF00A3E0).withValues(alpha: 0.5)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.border,
          width: item.isSelected || item.isDuplicate ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: item.isSelected,
                activeColor: const Color(0xFF00A3E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (val) {
                  setState(() {
                    item.isSelected = val ?? false;
                  });
                },
              ),
              const SizedBox(width: 4),

              // Title & Date (Tappable to edit)
              Expanded(
                child: InkWell(
                  onTap: () => _openItemEditor(item),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => _pickDateTimeForItem(item),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${item.slip.bankName} • ${DateFormat('d MMM yyyy, HH:mm น.').format(item.date)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: Color(0xFF00A3E0),
                              ),
                            ],
                          ),
                        ),
                        if (item.memo != null && item.memo!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 11,
                                color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.75) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.memo!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Amount
              InkWell(
                onTap: () => _openItemEditor(item),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '${isIncome ? '+' : '-'}฿${currencyFormat.format(item.amount)}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isIncome ? AppColors.surplusText : AppColors.deficitText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Action row: Category, Type, Edit button, Delete button
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 6),
            child: Row(
              children: [
                if (item.isDuplicate) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.deficitText.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'duplicate_badge'.tr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deficitText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Category selector chip
                InkWell(
                  onTap: () => _showCategoryPicker(context, item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.category.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 15,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Edit Button (ปุ่มแก้ไขรายการโดยตรง)
                InkWell(
                  onTap: () => _openItemEditor(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00A3E0).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF00A3E0)),
                        const SizedBox(width: 4),
                        Text(
                          'edit'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00A3E0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Delete Button (ลบสลิปนี้ออกจากชุด)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _items.remove(item);
                    });
                    if (_items.isEmpty) {
                      Get.back();
                    }
                  },
                  tooltip: 'delete'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, _BatchItemState item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AppGlassDialog(
        maxWidth: 340,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_category'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final isSelected = item.category == cat;
                return ChoiceChip(
                  label: Text(cat.tr),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00A3E0).withValues(alpha: 0.22),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        item.category = cat;
                      });
                      Get.back();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal สำหรับแก้ไขข้อมูลสลิปแต่ละรายการในชุด (Title, Amount, Category, Type, Date, Memo)
class _BatchItemEditDialog extends StatefulWidget {
  final _BatchItemState item;
  final bool isDark;
  final List<String> categories;
  final void Function(
    String newTitle,
    double newAmount,
    String newCategory,
    TransactionType newType,
    DateTime newDate,
    String? newMemo,
  ) onSave;

  const _BatchItemEditDialog({
    required this.item,
    required this.isDark,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_BatchItemEditDialog> createState() => _BatchItemEditDialogState();
}

class _BatchItemEditDialogState extends State<_BatchItemEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _memoController;
  late String _selectedCategory;
  late TransactionType _selectedType;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _amountController = TextEditingController(text: widget.item.amount.toStringAsFixed(2));
    _memoController = TextEditingController(text: widget.item.memo ?? '');
    _selectedCategory = widget.item.category;
    _selectedType = widget.item.type;
    _selectedDate = widget.item.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
    );
    if (!mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDate.hour,
        pickedTime?.minute ?? _selectedDate.minute,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim());

    if (title.isEmpty) {
      AppFeedback.showError(message: 'enter_title_error'.tr);
      return;
    }
    if (amount == null || amount <= 0) {
      AppFeedback.showError(message: 'enter_amount_error'.tr);
      return;
    }

    widget.onSave(
      title,
      amount,
      _selectedCategory,
      _selectedType,
      _selectedDate,
      _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
    );

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A3E0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF00A3E0), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${'edit'.tr} (${widget.item.slip.bankName})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Get.back(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Transaction Type (Expense / Income)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('expense'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  selected: _selectedType == TransactionType.expense,
                  selectedColor: AppColors.deficitText.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = TransactionType.expense);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('income'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  selected: _selectedType == TransactionType.income,
                  selectedColor: AppColors.surplusText.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = TransactionType.income);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title Input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'transaction_title'.tr,
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'amount'.tr,
              prefixText: '฿ ',
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time Picker Tile
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF00A3E0)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('d MMMM yyyy, HH:mm น.').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_calendar_rounded, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips
          Text(
            'select_category'.tr,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat.tr, style: const TextStyle(fontSize: 11.5)),
                selected: isSelected,
                selectedColor: const Color(0xFF00A3E0).withValues(alpha: 0.22),
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Memo / Note Input
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'note'.tr,
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          // Receipt Items Preview (ถ้ามี)
          if (widget.item.slip.receiptItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF00A3E0)),
                      const SizedBox(width: 6),
                      Text(
                        'รายการสินค้าในใบเสร็จ (${widget.item.slip.receiptItems.length} รายการ)',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.item.slip.receiptItems.map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF00A3E0), fontSize: 11)),
                          Expanded(
                            child: Text(
                              it,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submit,
                  child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiBatchSlipSheet = BankBatchSlipSheet;
