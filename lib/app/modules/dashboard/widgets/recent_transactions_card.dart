import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงประวัติรายการธุรกรรมล่าสุด สไตล์ Modern FinTech Feed 2026
/// นำเสนอในรูปแบบการ์ดแคปซูล (Tile Feed) พร้อมชิปประเภทธุรกรรม, เวลา, ยอดเงินเด่นชัด และ Swipe-to-Delete
class RecentTransactionsCard extends GetView<DashboardController> {
  const RecentTransactionsCard({super.key});

  IconData _getCategoryIcon(String category) {
    if (category.contains('อาหาร') || category.contains('ของกิน') || category.contains('Food')) return Icons.fastfood_rounded;
    if (category.contains('กาแฟ') || category.contains('เครื่องดื่ม') || category.contains('Coffee')) return Icons.local_cafe_rounded;
    if (category.contains('เดินทาง') || category.contains('รถ') || category.contains('Transport')) return Icons.directions_subway_rounded;
    if (category.contains('ช้อปปิ้ง') || category.contains('Shopping')) return Icons.shopping_bag_rounded;
    if (category.contains('ของใช้') || category.contains('Personal')) return Icons.inventory_2_rounded;
    if (category.contains('ที่อยู่อาศัย') || category.contains('Housing')) return Icons.home_rounded;
    if (category.contains('สาธารณูปโภค') || category.contains('Utilities')) return Icons.flash_on_rounded;
    if (category.contains('สื่อสาร') || category.contains('เน็ต')) return Icons.wifi_rounded;
    if (category.contains('เงินเดือน') || category.contains('Salary')) return Icons.account_balance_wallet_rounded;
    if (category.contains('ออม') || category.contains('DCA') || category.contains('กองทุน') || category.contains('Savings')) return Icons.savings_rounded;
    if (category.contains('ประกัน') || category.contains('สุขภาพ') || category.contains('Health')) return Icons.health_and_safety_rounded;
    if (category.contains('การศึกษา') || category.contains('Education')) return Icons.school_rounded;
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final items = controller.filteredTransactions;
      final displayItems = items.take(8).toList();

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.8),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ROW: Receipt Icon, Title, Count Badge & See All ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Receipt Icon Squircle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title & Counter Badge
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'recent_transactions'.tr,
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${items.length}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // See All Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Get.toNamed(Routes.TRANSACTIONS_LIST);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'see_all'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- EMPTY STATE OR TRANSACTION TILES ---
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.4) : AppColors.surfaceSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_rounded,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_transactions'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            QuickAddBottomSheet.show(context);
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(
                            'add_first_transaction'.tr,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final icon = _getCategoryIcon(item.categoryName);

                      // Type Styling & Indicators
                      Color amountColor;
                      Color iconBgColor;
                      String prefix = '';
                      String natureLabel = '';
                      Color natureColor = AppColors.textSecondary;

                      if (item.isIncome) {
                        amountColor = AppColors.primary;
                        iconBgColor = AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12);
                        prefix = '+';
                        natureLabel = 'income'.tr;
                        natureColor = AppColors.primary;
                      } else if (item.isSavings) {
                        amountColor = AppColors.accent;
                        iconBgColor = AppColors.accent.withValues(alpha: isDark ? 0.18 : 0.12);
                        prefix = '';
                        natureLabel = 'filter_savings'.tr;
                        natureColor = AppColors.accent;
                      } else {
                        amountColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
                        iconBgColor = item.isFixedCost
                            ? AppColors.fixedCostAccent.withValues(alpha: isDark ? 0.18 : 0.12)
                            : AppColors.variableCostAccent.withValues(alpha: isDark ? 0.18 : 0.12);
                        prefix = '-';
                        natureLabel = item.isFixedCost ? 'fixed_cost'.tr : 'variable_cost'.tr;
                        natureColor = item.isFixedCost ? AppColors.fixedCostAccent : AppColors.variableCostAccent;
                      }

                      final isEn = controller.isEnglish;
                      final yearNum = isEn ? item.date.year % 100 : (item.date.year + 543) % 100;
                      final timeStr = DateFormat('HH:mm').format(item.date);

                      return Dismissible(
                        key: Key('recent_${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.deficitText.withValues(alpha: isDark ? 0.22 : 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.deficitText.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.delete_forever_rounded,
                                color: AppColors.deficitText,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'delete_transaction'.tr,
                                style: const TextStyle(
                                  color: AppColors.deficitText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          controller.deleteTransaction(item.id);
                          AppFeedback.showSuccess(
                            title: 'transaction_deleted_title'.tr,
                            message: item.title,
                            amount: item.amount,
                            transactionType: item.type,
                            actionLabel: 'undo'.tr,
                            duration: const Duration(milliseconds: 4500),
                            onAction: () {
                              HapticFeedback.mediumImpact();
                              controller.addTransaction(item, notify: true);
                            },
                          );
                        },
                        child: Material(
                          color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6) : AppColors.surfaceSecondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              QuickAddBottomSheet.show(context, existingItem: item);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Category Squircle Icon
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: iconBgColor,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(icon, color: item.isIncome ? AppColors.primary : (item.isSavings ? AppColors.accent : natureColor), size: 18),
                                  ),
                                  const SizedBox(width: 12),

                                  // Item Title, Nature Pill & Date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title.tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            // Nature Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: natureColor.withValues(alpha: isDark ? 0.16 : 0.1),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                natureLabel,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: natureColor,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            // Category Name
                                            Flexible(
                                              child: Text(
                                                item.categoryName.tr,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),

                                            // Date & Time
                                            Flexible(
                                              flex: 2,
                                              child: Text(
                                                '• ${item.date.day}/${item.date.month}/$yearNum $timeStr',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Amount
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '$prefix${currencyFmt.format(item.amount)}',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: amountColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }
}
