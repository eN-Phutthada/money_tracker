import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงรายการธุรกรรมล่าสุดพร้อมไอคอนแยกตามหมวดหมู่
class RecentTransactionsCard extends GetView<DashboardController> {
  const RecentTransactionsCard({super.key});

  IconData _getCategoryIcon(String category) {
    if (category.contains('อาหาร') || category.contains('ของกิน')) return Icons.fastfood_rounded;
    if (category.contains('กาแฟ') || category.contains('เครื่องดื่ม')) return Icons.local_cafe_rounded;
    if (category.contains('เดินทาง') || category.contains('รถ')) return Icons.directions_subway_rounded;
    if (category.contains('ช้อปปิ้ง')) return Icons.shopping_bag_rounded;
    if (category.contains('ของใช้')) return Icons.inventory_2_rounded;
    if (category.contains('ที่อยู่อาศัย') || category.contains('คอนโด')) return Icons.home_rounded;
    if (category.contains('สาธารณูปโภค') || category.contains('น้ำ') || category.contains('ไฟ')) return Icons.flash_on_rounded;
    if (category.contains('สื่อสาร') || category.contains('เน็ต')) return Icons.wifi_rounded;
    if (category.contains('เงินเดือน')) return Icons.account_balance_wallet_rounded;
    if (category.contains('ออม') || category.contains('DCA') || category.contains('กองทุน')) return Icons.savings_rounded;
    if (category.contains('ประกัน') || category.contains('สุขภาพ')) return Icons.health_and_safety_rounded;
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final items = controller.filteredTransactions;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'recent_transactions'.tr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(Routes.TRANSACTIONS_LIST),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${'see_all'.tr} (${items.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'no_transactions'.tr,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.take(8).length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final icon = _getCategoryIcon(item.categoryName);

                  Color amountColor;
                  String prefix = '';
                  if (item.isIncome) {
                    amountColor = AppColors.primary;
                    prefix = '+';
                  } else if (item.isSavings) {
                    amountColor = AppColors.accent;
                    prefix = '';
                  } else {
                    amountColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
                    prefix = '-';
                  }

                  final isEn = controller.isEnglish;
                  final yearNum = isEn ? item.date.year % 100 : (item.date.year + 543) % 100;

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.deficitText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.deficitText),
                    ),
                    onDismissed: (_) => controller.deleteTransaction(item.id),
                    child: InkWell(
                      onTap: () => QuickAddBottomSheet.show(context, existingItem: item),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: amountColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: amountColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.categoryName.tr} • ${item.date.day}/${item.date.month}/$yearNum',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$prefix${currencyFmt.format(item.amount)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 150)).slideY(begin: 0.04);
    });
  }
}
