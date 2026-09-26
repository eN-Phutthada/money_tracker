import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';

/// แถบ Header แดชบอร์ดสไตล์ Nothing OS Design System
/// 1. ตัวเลือกช่วงเวลาทรงแคปซูลความคมชัดสูง (Nothing Segmented Pills: MONTH / YEAR / ALL)
/// 2. แถบนำทางช่วงเวลามินิมอล (Nothing Date Navigator Hub) พร้อมปุ่ม Squircle และไฟ LED แสดงรอบปัจจุบัน
/// 3. ปฏิทินเลือกเดือนสไตล์ Nothing Grid พร้อมการแบ่งไตรมาสแบบเรขาคณิต
class DashboardHeader extends GetView<DashboardController> {
  const DashboardHeader({super.key});

  // ==========================================
  // NOTHING OS MONTH PICKER MODAL SHEET
  // ==========================================
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Modal Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.nothingRed,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'select_period'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: NothingTypography.safeSpacing('select_period'.tr, 1.2),
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'select_period_desc'.tr,
                          style: NothingTypography.grotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Year Selector
              Obx(() {
                final year = rxYear.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          rxYear.value--;
                        },
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Text(
                        '${year + 543} ($year)',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          rxYear.value++;
                        },
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 4. 12-Month Nothing Grid
              Obx(() {
                final year = rxYear.value;
                final selected = controller.selectedDate.value;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthIndex = index + 1;
                    final isSelected = selected.year == year && selected.month == monthIndex;
                    final isCurrentMonth = now.year == year && now.month == monthIndex;

                    final monthName = 'month_short_$monthIndex'.tr;

                    return Material(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.setSelectedDate(DateTime(year, monthIndex, 1));
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isCurrentMonth
                                      ? AppColors.nothingRed
                                      : (isDark ? AppColors.darkBorder : AppColors.border)),
                              width: isCurrentMonth || isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCurrentMonth) ...[
                                const NothingLedIndicator(size: 4.5, color: AppColors.nothingRed),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                monthName,
                                style: NothingTypography.grotesk(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
              const SizedBox(height: 18),

              // 5. Jump to Current Month Button
              Material(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    controller.resetToCurrentPeriod();
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const NothingLedIndicator(size: 6, color: AppColors.nothingRed),
                        const SizedBox(width: 8),
                        Text(
                          'jump_to_current_month'.tr.toUpperCase(),
                          style: NothingTypography.grotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: NothingTypography.safeSpacing('jump_to_current_month'.tr, 1.0),
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
        // 1. NOTHING OS PERIOD SEGMENTED PILLS
        _buildPeriodSwitcher(isDark),
        const SizedBox(height: 10),

        // 2. NOTHING DATE NAVIGATOR HUB
        _buildDateNavigatorHub(context, isDark),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 220));
  }

  // ==========================================
  // NOTHING OS PERIOD SEGMENTED PILLS
  // ==========================================
  Widget _buildPeriodSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Obx(() {
        final period = controller.currentPeriod.value;

        return Row(
          children: [
            Expanded(
              child: _buildSegmentPill(
                title: 'monthly'.tr.toUpperCase(),
                isSelected: period == TimeFilterPeriod.monthly,
                onTap: () => controller.setTimeFilter(TimeFilterPeriod.monthly),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentPill(
                title: 'yearly'.tr.toUpperCase(),
                isSelected: period == TimeFilterPeriod.yearly,
                onTap: () => controller.setTimeFilter(TimeFilterPeriod.yearly),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentPill(
                title: 'all_time'.tr.toUpperCase(),
                isSelected: period == TimeFilterPeriod.allTime,
                onTap: () => controller.setTimeFilter(TimeFilterPeriod.allTime),
                isDark: isDark,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSegmentPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final Color bg = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : Colors.transparent;

    final Color fg = isSelected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            title,
            style: NothingTypography.grotesk(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: NothingTypography.safeSpacing(title, 1.2),
              color: fg,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // NOTHING DATE NAVIGATOR HUB
  // ==========================================
  Widget _buildDateNavigatorHub(BuildContext context, bool isDark) {
    return Obx(() {
      final period = controller.currentPeriod.value;
      final isCurrent = controller.isCurrentPeriod;
      final isMonthly = period == TimeFilterPeriod.monthly;
      final isAllTime = period == TimeFilterPeriod.allTime;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Left Navigator Button
            if (!isAllTime) ...[
              Material(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.previousPeriod();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              const SizedBox(width: 4),
            ],

            // Center Interactive Period Capsule
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isMonthly ? () => _showMonthPickerSheet(context) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            isMonthly
                                ? Icons.calendar_month_outlined
                                : (period == TimeFilterPeriod.yearly
                                    ? Icons.event_note_outlined
                                    : Icons.all_inclusive_rounded),
                            color: isDark ? Colors.white : Colors.black,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.formattedPeriodTitle.toUpperCase(),
                                  style: NothingTypography.grotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: NothingTypography.safeSpacing(controller.formattedPeriodTitle, 1.0),
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                if (isMonthly) ...[
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Dynamic Right Status Action / Badge
            if (!isAllTime) ...[
              if (!isCurrent) ...[
                // Jump to Current Month/Year Pill
                Material(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.resetToCurrentPeriod();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.nothingRed.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NothingLedIndicator(size: 4.5, color: AppColors.nothingRed),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isMonthly ? 'current_month'.tr : 'current_year'.tr,
                              style: NothingTypography.grotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                // Active Period LED Dot Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NothingLedIndicator(size: 4.5, color: AppColors.nothingRed),
                      const SizedBox(width: 5),
                      Text(
                        'active_period'.tr.toUpperCase(),
                        style: NothingTypography.grotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: NothingTypography.safeSpacing('active_period'.tr, 0.8),
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Right Navigator Button
              Material(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.nextPeriod();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // All-Time Items Count Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NothingLedIndicator(size: 4.5, color: AppColors.nothingRed),
                    const SizedBox(width: 4),
                    Text(
                      'items_count_badge'.trParams({'count': '${controller.transactions.length}'}),
                      style: NothingTypography.grotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      );
    });
  }
}
