import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรแสดงประวัติรายการธุรกรรมล่าสุด สไตล์ Nothing OS Feed
/// สไตล์มินิมอลโมโนโครม พร้อมตัวอักษร Monospace, แคปซูล Nature Pill, เส้นขอบ Hairline และไอคอนสไตล์ Glyph
class RecentTransactionsCard extends GetView<DashboardController> {
  const RecentTransactionsCard({super.key});

  IconData _getCategoryIcon(String category) {
    if (category.contains('ถอน') || category.contains('Withdraw')) {
      return Icons.outbox_rounded;
    }
    if (category.contains('อาหาร') ||
        category.contains('ของกิน') ||
        category.contains('Food')) {
      return Icons.fastfood_outlined;
    }
    if (category.contains('กาแฟ') ||
        category.contains('เครื่องดื่ม') ||
        category.contains('Coffee')) {
      return Icons.local_cafe_outlined;
    }
    if (category.contains('เดินทาง') ||
        category.contains('รถ') ||
        category.contains('Transport')) {
      return Icons.directions_subway_outlined;
    }
    if (category.contains('ช้อปปิ้ง') || category.contains('Shopping')) {
      return Icons.shopping_bag_outlined;
    }
    if (category.contains('ของใช้') || category.contains('Personal')) {
      return Icons.inventory_2_outlined;
    }
    if (category.contains('ที่อยู่อาศัย') || category.contains('Housing')) {
      return Icons.home_outlined;
    }
    if (category.contains('สาธารณูปโภค') || category.contains('Utilities')) {
      return Icons.bolt_outlined;
    }
    if (category.contains('สื่อสาร') || category.contains('เน็ต')) {
      return Icons.wifi_outlined;
    }
    if (category.contains('เงินเดือน') || category.contains('Salary')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (category.contains('ออม') ||
        category.contains('DCA') ||
        category.contains('กองทุน') ||
        category.contains('Savings')) {
      return Icons.savings_outlined;
    }
    if (category.contains('ประกัน') ||
        category.contains('สุขภาพ') ||
        category.contains('Health')) {
      return Icons.health_and_safety_outlined;
    }
    if (category.contains('การศึกษา') || category.contains('Education')) {
      return Icons.school_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 2,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final items = controller.filteredTransactions;
      final displayItems = items.take(8).toList();

      return NothingCard(
          showDotGrid: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ROW: GLYPH ICON, TITLE, COUNT & SEE ALL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Glyph Icon Box
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161616)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingBorder
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Pill Counter
                  Expanded(
                    child: Row(
                      children: [
                        const NothingLedIndicator(
                          color: AppColors.nothingRed,
                          size: 6,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: NothingDotText(
                            'recent_activity'.tr.toUpperCase(),
                            fontSize: 12.5,
                            letterSpacing: NothingTypography.safeSpacing(
                              'recent_activity'.tr,
                              1.2,
                            ),
                            isMono: false,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        NothingPill(
                          label: '${items.length}',
                          color: isDark
                              ? const Color(0xFF222222)
                              : const Color(0xFFEEEEEE),
                          textColor: isDark ? Colors.white : Colors.black,
                          isDotMatrix: true,
                          fontSize: 10,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
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
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'all'.tr.toUpperCase(),
                              style: NothingTypography.grotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: NothingTypography.safeSpacing('all'.tr, 0.8),
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isDark ? Colors.white : Colors.black,
                            ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D0D0D)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161616)
                              : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.nothingBorder
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.receipt_outlined,
                            size: 22,
                            color: isDark
                                ? AppColors.nothingSubtext
                                : const Color(0xFF777777),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_transactions'.tr,
                        style: NothingTypography.grotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.nothingSubtext
                              : const Color(0xFF777777),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          QuickAddBottomSheet.show(context);
                        },
                        icon: const Icon(Icons.add, size: 15),
                        label: Text(
                          'add_first_transaction'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nothingRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                    String prefix = '';
                    String natureLabel = '';
                    Color natureColor;

                    final statusRed = AppColors.expenseColor(isDark);
                    final statusIncome = AppColors.incomeColor(isDark);
                    final statusSavings = AppColors.savingsColor(isDark);
                    final statusWithdrawal = AppColors.withdrawalColor(isDark);

                    if (item.isSavingsWithdrawal) {
                      amountColor = statusWithdrawal;
                      prefix = '+';
                      natureLabel = 'badge_withdraw'.tr.toUpperCase();
                      natureColor = statusWithdrawal;
                    } else if (item.isIncome) {
                      amountColor = statusIncome;
                      prefix = '+';
                      natureLabel = 'badge_income'.tr.toUpperCase();
                      natureColor = statusIncome;
                    } else if (item.isSavings) {
                      amountColor = statusSavings;
                      prefix = '';
                      natureLabel = 'badge_savings'.tr.toUpperCase();
                      natureColor = statusSavings;
                    } else {
                      amountColor = statusRed;
                      prefix = '-';
                      natureLabel = item.isFixedCost
                          ? 'badge_fixed'.tr.toUpperCase()
                          : 'badge_var'.tr.toUpperCase();
                      natureColor = item.isFixedCost
                          ? (isDark
                                ? const Color(0xFFD4D4D8)
                                : const Color(0xFF4B5563))
                          : statusRed;
                    }

                    final isEn = controller.isEnglish;
                    final yearNum = isEn
                        ? item.date.year % 100
                        : (item.date.year + 543) % 100;
                    final timeStr = DateFormat('HH:mm').format(item.date);

                    return Dismissible(
                          key: Key('recent_${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: statusRed.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: statusRed.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  color: statusRed,
                                  size: 19,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DELETE',
                                  style: GoogleFonts.shareTechMono(
                                    color: statusRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
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
                            color: isDark
                                ? const Color(0xFF0D0D0D)
                                : const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                QuickAddBottomSheet.show(
                                  context,
                                  existingItem: item,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.nothingBorder
                                        : Colors.black.withValues(alpha: 0.07),
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
                                        color: isDark
                                            ? const Color(0xFF161616)
                                            : const Color(0xFFEEEEEE),
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.nothingBorder
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: item.isSavingsWithdrawal
                                            ? statusWithdrawal
                                            : (item.isExpense
                                                  ? statusRed
                                                  : (item.isSavings
                                                        ? statusSavings
                                                        : statusIncome)),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Item Title, Nature Pill & Date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title.tr,
                                            style: NothingTypography.grotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              // Nature Pill
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: natureColor.withValues(
                                                    alpha: isDark ? 0.16 : 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  natureLabel,
                                                  style:
                                                      NothingTypography.grotesk(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.5,
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
                                                  style:
                                                      NothingTypography.grotesk(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isDark
                                                            ? AppColors
                                                                  .nothingSubtext
                                                            : const Color(
                                                                0xFF777777,
                                                              ),
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
                                                  '// ${item.date.day}.${item.date.month}.$yearNum $timeStr',
                                                  style: NothingTypography.mono(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? AppColors.nothingSubtext
                                                        : const Color(0xFF888888),
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
                                        style: NothingTypography.mono(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: amountColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 35 * index),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        )
                        .slideX(
                          begin: 0.04,
                          end: 0,
                          delay: Duration(milliseconds: 35 * index),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
                ],
          ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }
}
