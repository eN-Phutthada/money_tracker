import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/scheduled_payment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../../transactions/views/scheduled_payments_sheet.dart';
import '../controllers/dashboard_controller.dart';

/// การ์ด Bento แสดงรายการรอจ่ายเงินล่วงหน้า / จ่ายประจำ สไตล์ Nothing OS Design System
class UpcomingPaymentsCard extends GetView<DashboardController> {
  const UpcomingPaymentsCard({super.key});

  IconData _getCategoryIcon(String category) {
    if (category.contains('เน็ต') ||
        category.contains('สื่อสาร') ||
        category.contains('Wifi')) {
      return Icons.wifi_outlined;
    }
    if (category.contains('ที่อยู่อาศัย') ||
        category.contains('เช่า') ||
        category.contains('ห้อง') ||
        category.contains('Housing')) {
      return Icons.home_outlined;
    }
    if (category.contains('สาธารณูปโภค') ||
        category.contains('ไฟ') ||
        category.contains('น้ำ') ||
        category.contains('Utilities')) {
      return Icons.bolt_outlined;
    }
    if (category.contains('บันเทิง') ||
        category.contains('Netflix') ||
        category.contains('Spotify') ||
        category.contains('Entertainment')) {
      return Icons.movie_outlined;
    }
    if (category.contains('ประกัน') || category.contains('Insurance')) {
      return Icons.health_and_safety_outlined;
    }
    if (category.contains('เดินทาง') ||
        category.contains('รถ') ||
        category.contains('Transit')) {
      return Icons.directions_car_outlined;
    }
    if (category.contains('อาหาร') || category.contains('Food')) {
      return Icons.fastfood_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  String _getFrequencyLabel(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.oneTime:
        return 'frequency_one_time'.tr;
      case ScheduleFrequency.daily:
        return 'frequency_daily'.tr;
      case ScheduleFrequency.weekly:
        return 'frequency_weekly'.tr;
      case ScheduleFrequency.monthly:
        return 'frequency_monthly'.tr;
      case ScheduleFrequency.yearly:
        return 'frequency_yearly'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 2,
    );

    return Obx(() {
      final items = controller.upcomingScheduledPayments;
      final displayItems = items.take(4).toList();
      final hasOverdue = items.any((i) => i.isDue && i.daysUntilDue < 0);
      final hasDueSoon = items.any((i) => i.isDueSoon(3));

      final Color ledColor = hasOverdue
          ? AppColors.nothingRed
          : (hasDueSoon ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

      return NothingCard(
        showDotGrid: false,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ROW: GLYPH ICON, TITLE, COUNT, & MANAGE BUTTON ---
            Row(
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
                      Icons.event_repeat_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & LED Status
                Expanded(
                  child: Row(
                    children: [
                      NothingLedIndicator(
                        color: ledColor,
                        size: 6,
                        isPulsing: hasOverdue,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'upcoming_payments'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 6),

                // Add Scheduled Payment Quick Button (+)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    QuickAddBottomSheet.show(context, initialIsScheduled: true);
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  tooltip: 'create_new_schedule'.tr,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF1C1C1C)
                        : const Color(0xFFEEEEEE),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 4),

                // Manage All Sheet Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ScheduledPaymentsSheet.show(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'manage_schedules'.tr.toUpperCase(),
                            style: NothingTypography.grotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.nothingRedLight
                                  : AppColors.nothingRed,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.nothingRedLight
                                : AppColors.nothingRed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- CONTENT: EMPTY STATE OR ITEMS LIST ---
            if (displayItems.isEmpty) ...[
              _buildEmptyState(context, isDark),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _buildScheduledItemTile(
                    context,
                    item,
                    currencyFmt,
                    isDark,
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.nothingBorder
              : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 28,
            color: isDark ? AppColors.nothingMuted : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'no_upcoming_payments'.tr,
            style: NothingTypography.grotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'schedule_payment_desc'.tr,
            style: NothingTypography.grotesk(
              fontSize: 11,
              color: isDark ? AppColors.nothingSubtext : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              QuickAddBottomSheet.show(context, initialIsScheduled: true);
            },
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'create_new_schedule'.tr,
              style: NothingTypography.grotesk(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              side: BorderSide(
                color: isDark
                    ? AppColors.nothingBorder
                    : Colors.black.withValues(alpha: 0.15),
                width: 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledItemTile(
    BuildContext context,
    ScheduledPaymentItem item,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    final days = item.daysUntilDue;
    final isOverdue = item.isDue && days < 0;
    final isToday = item.isDue && days == 0;
    final isTomorrow = days == 1;

    String dueBadgeText;
    Color dueBadgeColor;
    Color dueTextColor;

    if (isOverdue) {
      dueBadgeText = 'overdue_days'.trParams({'days': '${-days}'});
      dueBadgeColor = AppColors.nothingRed.withValues(alpha: 0.16);
      dueTextColor = AppColors.nothingRed;
    } else if (isToday) {
      dueBadgeText = 'due_today'.tr;
      dueBadgeColor = const Color(0xFFF59E0B).withValues(alpha: 0.16);
      dueTextColor = const Color(0xFFF59E0B);
    } else if (isTomorrow) {
      dueBadgeText = 'due_tomorrow'.tr;
      dueBadgeColor = const Color(0xFF3B82F6).withValues(alpha: 0.16);
      dueTextColor = const Color(0xFF3B82F6);
    } else {
      dueBadgeText = 'due_in_days'.trParams({'days': '$days'});
      dueBadgeColor = isDark
          ? const Color(0xFF222222)
          : Colors.black.withValues(alpha: 0.05);
      dueTextColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.nothingRed.withValues(alpha: 0.5)
              : (isDark
                    ? AppColors.nothingBorder
                    : Colors.black.withValues(alpha: 0.08)),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            QuickAddBottomSheet.show(context, existingScheduledItem: item);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Category Icon + Title + Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202020)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isDark
                              ? AppColors.nothingBorder
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.categoryName),
                        size: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        item.title,
                        style: NothingTypography.grotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Amount
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFmt.format(item.amount),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom Row: Badges (Wrap) on left + Action buttons on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badges (Frequency, Mode, Due status) wrapped dynamically so text is never truncated
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Frequency pill
                          NothingPill(
                            label: _getFrequencyLabel(item.frequency),
                            color: isDark
                                ? const Color(0xFF1C1C1C)
                                : const Color(0xFFEEEEEE),
                            textColor: isDark
                                ? AppColors.nothingSubtext
                                : AppColors.textSecondary,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),

                          // Mode badge (auto / confirm)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1C)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.autoRecord
                                      ? Icons.bolt_rounded
                                      : Icons.notifications_none_rounded,
                                  size: 11,
                                  color: item.autoRecord
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                            ? AppColors.nothingSubtext
                                            : AppColors.textSecondary),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.autoRecord
                                      ? 'auto_record'.tr
                                      : 'manual_confirm'.tr,
                                  style: NothingTypography.grotesk(
                                    fontSize: 9.5,
                                    color: isDark
                                        ? AppColors.nothingSubtext
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Due date status badge
                          NothingPill(
                            label: dueBadgeText,
                            color: dueBadgeColor,
                            textColor: dueTextColor,
                            isDotMatrix: true,
                            fontSize: 9,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Quick Action Buttons (Mark as Paid & Skip)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pay Now Action
                        Tooltip(
                          message: 'pay_now'.tr,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              controller.executeScheduledPayment(item);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Skip Cycle Action
                        Tooltip(
                          message: 'skip_round'.tr,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showSkipDialog(context, item);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF222222)
                                    : const Color(0xFFECECEC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.nothingBorder
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                Icons.skip_next_rounded,
                                size: 15,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSkipDialog(BuildContext context, ScheduledPaymentItem item) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF181818)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.nothingBorder
                  : Colors.black.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'skip_round'.tr,
                style: NothingTypography.grotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'skip_round_confirm'.tr,
                style: NothingTypography.grotesk(
                  fontSize: 12.5,
                  color: AppColors.nothingSubtext,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.skipScheduledPayment(item.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nothingRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('confirm'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
