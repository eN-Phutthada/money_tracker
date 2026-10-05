import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/scheduled_payment_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'quick_add_bottom_sheet.dart';

/// หน้าต่างจัดการรายการตั้งเวลาการจ่ายเงินล่วงหน้า (Scheduled Payments Manager)
/// รองรับทั้ง Mobile BottomSheet และ Desktop Glass Dialog สไตล์ Nothing OS Design System
class ScheduledPaymentsSheet extends StatefulWidget {
  const ScheduledPaymentsSheet({super.key});

  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    if (isDesktop) {
      Get.dialog(
        const AppGlassDialog(
          maxWidth: 620,
          padding: EdgeInsets.all(22),
          child: ScheduledPaymentsSheet(),
        ),
      );
    } else {
      Get.bottomSheet(
        const ScheduledPaymentsSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  @override
  State<ScheduledPaymentsSheet> createState() => _ScheduledPaymentsSheetState();
}

class _ScheduledPaymentsSheetState extends State<ScheduledPaymentsSheet> {
  final DashboardController controller = Get.find<DashboardController>();
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Paused, 3: Completed

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

  String _formatDueDate(DateTime date) {
    final isEn = controller.isEnglish;
    final yearSuffix = isEn ? '${date.year % 100}' : '${(date.year + 543) % 100}';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/$yearSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 2,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtle Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Row
            AppPopupHeader(
              title: 'scheduled_payments'.tr,
              subtitle: 'scheduled_payments_subtitle'.tr,
              icon: Icons.schedule_rounded,
              iconColor: AppColors.nothingRed,
              trailing: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Get.back();
                  QuickAddBottomSheet.show(context, initialIsScheduled: true);
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'new_schedule_btn'.tr,
                  style: NothingTypography.grotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nothingRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Telemetry Banner (Total Scheduled Commitments in Month + Fixed vs Budget Plan)
            Obx(() {
              final totalMonth =
                  controller.upcomingMonthlyScheduledCommitments;
              final activeCount = controller.activeScheduledPayments.length;
              final fixedCommitments =
                  controller.totalMonthlyFixedScheduledCommitments;
              final plannedFixed =
                  controller.budgetPlan.value.plannedFixedCosts;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161616)
                      : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                            color: AppColors.nothingRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'monthly_scheduled_commitments'.tr,
                                style: NothingTypography.grotesk(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.nothingSubtext
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyFmt.format(totalMonth),
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        NothingPill(
                          label: '$activeCount',
                          showDot: true,
                          dotColor: const Color(0xFF10B981),
                          isDotMatrix: true,
                          fontSize: 11,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F0F0F)
                            : const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            size: 13,
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'fixed_vs_budget_plan'.trParams({
                                'scheduled': currencyFmt.format(fixedCommitments),
                                'planned': currencyFmt.format(plannedFixed),
                              }),
                              style: NothingTypography.grotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Get.back();
                              Get.toNamed(Routes.BUDGET_SETTINGS);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'budget_settings'.tr,
                                    style: NothingTypography.grotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.nothingRed,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: AppColors.nothingRed,
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
            }),
            const SizedBox(height: 12),

            // Filter Tabs (Segmented Deck)
            Obx(() {
              final allCount = controller.scheduledPayments.length;
              final activeCount = controller.activeScheduledPayments.length;
              final pausedCount = controller.scheduledPayments
                  .where((p) => p.isPaused)
                  .length;
              final completedCount = controller.scheduledPayments
                  .where((p) => p.isCompleted)
                  .length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'all'.tr, allCount, isDark),
                    const SizedBox(width: 6),
                    _buildFilterTab(
                      1,
                      'active_schedules'.tr,
                      activeCount,
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterTab(
                      2,
                      'paused_schedules'.tr,
                      pausedCount,
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterTab(
                      3,
                      'completed_schedules'.tr,
                      completedCount,
                      isDark,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),

            // Smart History Suggestions Banner (if any detected recurring bills exist)
            _buildSmartHistorySuggestionsBanner(context, isDark, currencyFmt),

            // List of Items
            Expanded(
              child: Obx(() {
                final all = controller.scheduledPayments;
                List<ScheduledPaymentItem> filtered;

                switch (_selectedFilterIndex) {
                  case 1:
                    filtered = all.where((p) => p.isActive).toList();
                    break;
                  case 2:
                    filtered = all.where((p) => p.isPaused).toList();
                    break;
                  case 3:
                    filtered = all.where((p) => p.isCompleted).toList();
                    break;
                  default:
                    filtered = all.toList();
                    break;
                }

                filtered.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

                if (filtered.isEmpty) {
                  return _buildEmptyQuickStartDeck(context, isDark, currencyFmt);
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildScheduleItemCard(
                      context,
                      item,
                      currencyFmt,
                      isDark,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label, int count, bool isDark) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.nothingRed
                : (isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08)),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: NothingTypography.grotesk(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '($count)',
              style: GoogleFonts.shareTechMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppColors.nothingSubtext : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItemCard(
    BuildContext context,
    ScheduledPaymentItem item,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    final days = item.daysUntilDue;
    final isOverdue = item.isActive && item.isDue && days < 0;
    final isToday = item.isActive && item.isDue && days == 0;
    final isTomorrow = item.isActive && days == 1;

    String dueBadgeText;
    Color dueBadgeColor;
    Color dueTextColor;

    if (item.isCompleted) {
      dueBadgeText = 'completed_schedules'.tr;
      dueBadgeColor = const Color(0xFF10B981).withValues(alpha: 0.16);
      dueTextColor = const Color(0xFF10B981);
    } else if (item.isPaused) {
      dueBadgeText = 'paused_schedules'.tr;
      dueBadgeColor = isDark
          ? const Color(0xFF222222)
          : Colors.black.withValues(alpha: 0.05);
      dueTextColor = isDark ? Colors.white60 : Colors.black54;
    } else if (isOverdue) {
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
          ? const Color(0xFF202020)
          : Colors.black.withValues(alpha: 0.05);
      dueTextColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            Get.back();
            QuickAddBottomSheet.show(context, existingScheduledItem: item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Top Row: Category Icon + Title + Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.nothingBorder
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.categoryName),
                        size: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        item.title,
                        style: NothingTypography.grotesk(
                          fontSize: 14,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle Row: Badges (Frequency, Mode, Due status) wrapped dynamically
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Frequency pill
                      NothingPill(
                        label: _getFrequencyLabel(item.frequency),
                        color: isDark
                            ? const Color(0xFF1E1E1E)
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
                              ? const Color(0xFF1E1E1E)
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

                      // Due status pill
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
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isDark
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 8),

                // Date Row & Actions
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isDark
                          ? AppColors.nothingMuted
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${'next_due_date'.tr}: ${_formatDueDate(item.nextDueDate)}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.nothingMuted
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Quick Action: Pay Now (if active)
                    if (item.isActive) ...[
                      _buildCompactActionButton(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          controller.executeScheduledPayment(item);
                        },
                        tooltip: 'pay_now'.tr,
                        icon: Icons.check_rounded,
                        iconColor: const Color(0xFF10B981),
                        backgroundColor:
                            const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderColor:
                            const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),

                      // Quick Action: Skip Cycle
                      _buildCompactActionButton(
                        onTap: () => _confirmSkip(context, item),
                        tooltip: 'skip_round'.tr,
                        icon: Icons.skip_next_rounded,
                        iconColor: isDark ? Colors.white70 : Colors.black87,
                        backgroundColor: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFECECEC),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Quick Action: Resume (if paused)
                    if (item.isPaused) ...[
                      _buildCompactActionButton(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.toggleScheduledPaymentStatus(item.id);
                        },
                        tooltip: 'resume_schedule'.tr,
                        icon: Icons.play_arrow_rounded,
                        iconColor: const Color(0xFF10B981),
                        backgroundColor:
                            const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderColor:
                            const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Contextual More Menu (Edit, Pause/Resume, Delete)
                    _buildMoreMenu(context, item, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required VoidCallback onTap,
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Color? borderColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor ?? Colors.transparent,
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(
    BuildContext context,
    ScheduledPaymentItem item,
    bool isDark,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark
                  ? AppColors.nothingBorder
                  : Colors.black.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'more_options'.tr,
        onSelected: (value) {
          if (value == 'edit') {
            HapticFeedback.selectionClick();
            Get.back();
            QuickAddBottomSheet.show(context, existingScheduledItem: item);
          } else if (value == 'toggle') {
            HapticFeedback.selectionClick();
            controller.toggleScheduledPaymentStatus(item.id);
          } else if (value == 'delete') {
            _confirmDelete(context, item);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            height: 38,
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  'edit'.tr,
                  style: NothingTypography.grotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (!item.isCompleted)
            PopupMenuItem<String>(
              value: 'toggle',
              height: 38,
              child: Row(
                children: [
                  Icon(
                    item.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 16,
                    color: item.isActive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isActive
                        ? 'pause_schedule'.tr
                        : 'resume_schedule'.tr,
                    style: NothingTypography.grotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuItem<String>(
            value: 'delete',
            height: 38,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.nothingRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'delete'.tr,
                  style: NothingTypography.grotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.nothingRed,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222222) : const Color(0xFFECECEC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? AppColors.nothingBorder
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  void _confirmSkip(BuildContext context, ScheduledPaymentItem item) {
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

  void _confirmDelete(BuildContext context, ScheduledPaymentItem item) {
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
                'delete'.tr,
                style: NothingTypography.grotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_schedule_confirm'.tr,
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
                      controller.deleteScheduledPayment(item.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nothingRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('delete'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartHistorySuggestionsBanner(
    BuildContext context,
    bool isDark,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      final suggestions = controller.detectedRecurringTransactionSuggestions;
      if (suggestions.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.10 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'detected_recurring_title'.tr,
                    style: NothingTypography.grotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: suggestions.map((tx) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF171717) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingBorder
                            : Colors.black12,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: NothingTypography.grotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              '${currencyFmt.format(tx.amount)} / ${'period_monthly'.tr}',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColors.nothingSubtext
                                    : const Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            controller
                                .createScheduledPaymentFromHistoricalTransaction(
                              tx,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.nothingRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'add_detected_bill'.tr,
                                  style: NothingTypography.grotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyQuickStartDeck(
    BuildContext context,
    bool isDark,
    NumberFormat currencyFmt,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 28,
                color: isDark
                    ? AppColors.nothingSubtext
                    : const Color(0xFF777777),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'no_scheduled_payments'.tr,
              style: NothingTypography.grotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Center(
            child: Text(
              'quick_start_bills_subtitle'.tr,
              style: NothingTypography.grotesk(
                fontSize: 11,
                color: isDark
                    ? AppColors.nothingSubtext
                    : const Color(0xFF777777),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header for Quick-Start Popular Presets
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: AppColors.nothingRed,
              ),
              const SizedBox(width: 5),
              Text(
                'quick_start_bills_title'.tr.toUpperCase(),
                style: NothingTypography.grotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2-Column Bento Grid of popular presets
          LayoutBuilder(
            builder: (context, constraints) {
              final presets =
                  controller.popularScheduledPresets.take(6).toList();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((preset) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return SizedBox(
                    width: itemWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Get.back();
                          QuickAddBottomSheet.show(
                            context,
                            initialIsScheduled: true,
                            initialAmount: preset.suggestedAmount,
                            initialCategory: preset.categoryName,
                            initialCostNature: preset.costNature,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141414)
                                : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.nothingBorder
                                  : Colors.black.withValues(alpha: 0.06),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      preset.icon,
                                      size: 15,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: AppColors.nothingRed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.titleKey.tr,
                                style: NothingTypography.grotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currencyFmt.format(preset.suggestedAmount ?? 500)} / ${'period_monthly'.tr}',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.nothingSubtext
                                      : const Color(0xFF777777),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
