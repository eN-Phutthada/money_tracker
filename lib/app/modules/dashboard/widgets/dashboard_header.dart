import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/modern_app_bar.dart';
import '../controllers/dashboard_controller.dart';

/// แถบ Header แดชบอร์ดสไตล์ Modern FinTech 2026:
/// 1. ตัวเลือกช่วงเวลา (Period Segmented Control: รายเดือน | รายปี | ทั้งหมด)
/// 2. แถบนำทางและเลือกเดือน/ปี (Date Navigator Bar) พร้อมตัวเลือกเดือนด่วน (Month Picker) และปุ่มย้อนกลับสู่เดือนปัจจุบัน
class DashboardHeader extends GetView<DashboardController> {
  const DashboardHeader({super.key});

  void _showMonthPickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rxYear = controller.selectedDate.value.year.obs;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'select_period'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Year Stepper Row
              Obx(() {
                final year = rxYear.value;
                final isCurrentYear = year == now.year;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          rxYear.value--;
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'ปีก่อนหน้า',
                      ),
                      Row(
                        children: [
                          Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            controller.isEnglish ? 'Year $year' : 'พ.ศ. ${year + 543}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (isCurrentYear) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.isEnglish ? 'This Year' : 'ปีนี้',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          rxYear.value++;
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'ปีถัดไป',
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 12 Months Grid
              Obx(() {
                final year = rxYear.value;
                final selectedDate = controller.selectedDate.value;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final monthIndex = index + 1;
                    final isSelected = selectedDate.year == year && selectedDate.month == monthIndex;
                    final isNowMonth = now.year == year && now.month == monthIndex;

                    return Material(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.setSelectedDate(DateTime(year, monthIndex));
                          controller.setTimeFilter(TimeFilterPeriod.monthly);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isNowMonth
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : (isDark ? AppColors.darkBorder : AppColors.border)),
                              width: isNowMonth && !isSelected ? 1.4 : 0.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                controller.isEnglish
                                    ? DashboardController.englishMonthShortNames[monthIndex]
                                    : DashboardController.thaiMonthShortNames[monthIndex],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                              ),
                              if (isNowMonth && !isSelected)
                                Text(
                                  controller.isEnglish ? 'Current' : 'เดือนนี้',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),

              // Jump to Today Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.resetToCurrentPeriod();
                    controller.setTimeFilter(TimeFilterPeriod.monthly);
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: Text('jump_to_current_month'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Period Segmented Control (รายเดือน | รายปี | ทั้งหมด)
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
          child: Obx(() {
            final period = controller.currentPeriod.value;
            return Row(
              children: [
                Expanded(
                  child: _buildSegmentItem(
                    title: 'monthly'.tr,
                    icon: Icons.calendar_view_month_rounded,
                    isSelected: period == TimeFilterPeriod.monthly,
                    onTap: () => controller.setTimeFilter(TimeFilterPeriod.monthly),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildSegmentItem(
                    title: 'yearly'.tr,
                    icon: Icons.calendar_today_rounded,
                    isSelected: period == TimeFilterPeriod.yearly,
                    onTap: () => controller.setTimeFilter(TimeFilterPeriod.yearly),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildSegmentItem(
                    title: 'all_time'.tr,
                    icon: Icons.all_inclusive_rounded,
                    isSelected: period == TimeFilterPeriod.allTime,
                    onTap: () => controller.setTimeFilter(TimeFilterPeriod.allTime),
                    isDark: isDark,
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 10),

        // 2. Date Navigator Bar (Steppers + Title + Quick Jump)
        Obx(() {
          final period = controller.currentPeriod.value;
          final isCurrent = controller.isCurrentPeriod;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous Period Button
                if (period != TimeFilterPeriod.allTime) ...[
                  ModernAppBar.squircleIconButton(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.previousPeriod();
                    },
                    icon: Icons.chevron_left_rounded,
                    isDark: isDark,
                    tooltip: period == TimeFilterPeriod.monthly ? 'prev_month'.tr : 'prev_year'.tr,
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                ],

                // Center Title & Interactive Picker Trigger
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: period == TimeFilterPeriod.monthly
                          ? () => _showMonthPickerSheet(context)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              period == TimeFilterPeriod.monthly
                                  ? Icons.calendar_month_rounded
                                  : (period == TimeFilterPeriod.yearly
                                      ? Icons.event_rounded
                                      : Icons.auto_awesome_rounded),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                controller.formattedPeriodTitle,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (period == TimeFilterPeriod.monthly) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Reset to Current Period Badge (If viewing a past or future month/year)
                if (!isCurrent && period != TimeFilterPeriod.allTime) ...[
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.resetToCurrentPeriod();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.restart_alt_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              period == TimeFilterPeriod.monthly ? 'current_month'.tr : 'current_year'.tr,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Next Period Button
                if (period != TimeFilterPeriod.allTime) ...[
                  ModernAppBar.squircleIconButton(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.nextPeriod();
                    },
                    icon: Icons.chevron_right_rounded,
                    isDark: isDark,
                    tooltip: period == TimeFilterPeriod.monthly ? 'next_month'.tr : 'next_year'.tr,
                  ),
                ] else ...[
                  // All Time Transaction Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.transactions.length} ${controller.isEnglish ? "items" : "รายการ"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 300)).slideY(begin: -0.04);
  }

  Widget _buildSegmentItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
