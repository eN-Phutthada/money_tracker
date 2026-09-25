import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bank_slip_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/bank_slip_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';

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
        BankBatchSlipSheet(
          initialSlips: slips,
          duplicateSlips: duplicates,
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
        Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101010) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: editorWidget,
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
        color: isDark ? const Color(0xFF101010) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag indicator
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
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
                    color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 22,
                    ),
                  ),
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
                              'batch_review_title'.tr.toUpperCase(),
                              style: NothingTypography.grotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: NothingTypography.safeSpacing(
                                  'batch_review_title'.tr,
                                  1.0,
                                ),
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const NothingLedIndicator(
                                  size: 5,
                                  color: AppColors.nothingRed,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'item_count_label'.trParams({'count': '${_items.length}'}),
                                  style: NothingTypography.mono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'batch_review_desc'.tr,
                        style: NothingTypography.grotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
          ),

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
              color: isDark ? const Color(0xFF101010) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
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
                        }).toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '฿${currencyFormat.format(_selectedTotalAmount)}',
                          style: NothingTypography.mono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nothingRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _selectedCount > 0 && !_isSaving ? _saveSelectedSlips : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'save_selected_count'.trParams({'count': '$_selectedCount'}).toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.6,
                            color: Colors.white,
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

  Widget _buildSlipCard(BuildContext context, _BatchItemState item, bool isDark) {
    final isIncome = item.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isDuplicate
              ? AppColors.nothingRed.withValues(alpha: 0.6)
              : item.isSelected
                  ? (isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25))
                  : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
          width: item.isDuplicate ? 1.0 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox (Nothing OS squircle styling)
              Transform.scale(
                scale: 0.95,
                child: Checkbox(
                  value: item.isSelected,
                  activeColor: isDark ? Colors.white : Colors.black,
                  checkColor: isDark ? Colors.black : Colors.white,
                  side: BorderSide(
                    color: isDark ? Colors.white38 : Colors.black38,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (val) {
                    setState(() {
                      item.isSelected = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),

              // Title & Date (Tappable to edit)
              Expanded(
                child: InkWell(
                  onTap: () => _openItemEditor(item),
                  borderRadius: BorderRadius.circular(8),
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
                                style: NothingTypography.grotesk(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
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
                                  style: NothingTypography.mono(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
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
                                color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.memo!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NothingTypography.grotesk(
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
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
                    style: NothingTypography.mono(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isIncome ? AppColors.surplusText : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Action row: Category, Type, Edit button, Delete button
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 6),
            child: Row(
              children: [
                if (item.isDuplicate) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF280E10) : const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingRed.withValues(alpha: 0.6)
                            : AppColors.nothingRed.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NothingLedIndicator(
                          size: 4.5,
                          color: AppColors.nothingRed,
                          isPulsing: true,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'duplicate_badge'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? AppColors.nothingRedLight : AppColors.nothingRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Category selector chip
                Flexible(
                  child: InkWell(
                    onTap: () => _showCategoryPicker(context, item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF202020) : const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.category.tr,
                              style: NothingTypography.grotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Edit Button
                InkWell(
                  onTap: () => _openItemEditor(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202020) : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'edit'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Delete Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'select_category'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final isSelected = item.category == cat;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      item.category = cat;
                    });
                    Get.back();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      cat.tr,
                      style: NothingTypography.grotesk(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF444444)),
                      ),
                    ),
                  ),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${'edit'.tr} (${widget.item.slip.bankName})'.toUpperCase(),
                  style: NothingTypography.grotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => Get.back(),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Type (Expense / Income) - Nothing OS Segmented Pills
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedType = TransactionType.expense);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedType == TransactionType.expense
                          ? (isDark ? const Color(0xFF280E10) : const Color(0xFFFDE8E8))
                          : (isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedType == TransactionType.expense
                            ? AppColors.nothingRed
                            : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedType == TransactionType.expense) ...[
                          const NothingLedIndicator(color: AppColors.nothingRed, size: 5),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'expense'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: _selectedType == TransactionType.expense
                                ? (isDark ? AppColors.nothingRedLight : AppColors.nothingRed)
                                : (isDark ? const Color(0xFF888888) : const Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedType = TransactionType.income);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedType == TransactionType.income
                          ? (isDark ? const Color(0xFF0E2818) : const Color(0xFFE8FDF0))
                          : (isDark ? const Color(0xFF181818) : const Color(0xFFF2F2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedType == TransactionType.income
                            ? AppColors.surplusText
                            : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedType == TransactionType.income) ...[
                          const NothingLedIndicator(color: AppColors.surplusText, size: 5),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'income'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: _selectedType == TransactionType.income
                                ? AppColors.surplusText
                                : (isDark ? const Color(0xFF888888) : const Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title Input
          TextField(
            controller: _titleController,
            style: NothingTypography.grotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'transaction_title'.tr.toUpperCase(),
              labelStyle: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF181818) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white54 : Colors.black54,
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: NothingTypography.mono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'amount'.tr.toUpperCase(),
              labelStyle: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
              ),
              prefixText: '฿ ',
              prefixStyle: NothingTypography.mono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF181818) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white54 : Colors.black54,
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time Picker Tile
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181818) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('d MMMM yyyy, HH:mm น.').format(_selectedDate),
                    style: NothingTypography.mono(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_calendar_outlined,
                    size: 16,
                    color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          Text(
            'select_category'.tr.toUpperCase(),
            style: NothingTypography.grotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFEEEEEE)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08)),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    cat.tr,
                    style: NothingTypography.grotesk(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF444444)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Memo / Note Input
          TextField(
            controller: _memoController,
            maxLines: 2,
            style: NothingTypography.grotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'note'.tr.toUpperCase(),
              labelStyle: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF181818) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white54 : Colors.black54,
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          // Receipt Items Preview (ถ้ามี)
          if (widget.item.slip.receiptItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'รายการสินค้าในใบเสร็จ (${widget.item.slip.receiptItems.length} รายการ)'
                            .toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.item.slip.receiptItems.map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: NothingTypography.mono(
                              color: AppColors.nothingRed,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              it,
                              style: NothingTypography.grotesk(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF555555),
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
          const SizedBox(height: 20),

          // Actions (Cancel / Save)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    'cancel'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nothingRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  child: Text(
                    'save'.tr.toUpperCase(),
                    style: NothingTypography.grotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
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
