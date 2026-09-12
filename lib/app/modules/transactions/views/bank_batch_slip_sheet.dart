import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/bank_slip_model.dart';
import '../../../data/services/bank_slip_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// หน้าต่างพรีวิวและตรวจสอบสลิปแบบกลุ่ม (Krungthai Batch Slip Confirmation Sheet)
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
          maxWidth: 560,
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
  String category;

  _BatchItemState({
    required this.slip,
    this.isDuplicate = false,
    required this.isSelected,
    required this.category,
  });
}

class _BankBatchSlipSheetState extends State<BankBatchSlipSheet> {
  final DashboardController controller = Get.find<DashboardController>();
  final BankSlipService slipService = BankSlipService();
  final currencyFormat = NumberFormat('#,##0.00', 'en_US');

  late List<_BatchItemState> _items;
  bool _isSaving = false;

  final List<String> _availableCategories = const [
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
          category: slip.suggestedCategory,
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
          category: slip.suggestedCategory,
        ),
      );
    }
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  double get _selectedTotalAmount => _items
      .where((i) => i.isSelected)
      .fold(0.0, (sum, i) => sum + i.slip.amount);

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
          customCategory: item.category,
          notify: false,
        );
        savedCount++;
        totalAmount += item.slip.amount;
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

              // Title & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.slip.receiverName ?? item.slip.suggestedCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.slip.bankName} • ${DateFormat('d MMM yyyy, HH:mm น.').format(item.slip.transactionDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '฿${currencyFormat.format(item.slip.amount)}',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deficitText,
                ),
              ),
            ],
          ),

          // Duplicate warning or category selection
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 4),
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
                  const SizedBox(width: 8),
                ],

                // Category selector chip
                InkWell(
                  onTap: () => _showCategoryPicker(context, item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ],
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


/// Typedef สำหรับความเข้ากันได้ย้อนหลัง 100%
typedef KrungthaiBatchSlipSheet = BankBatchSlipSheet;
