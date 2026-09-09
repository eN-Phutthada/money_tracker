import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/daily_allowance_card.dart';
import '../widgets/fl_finance_chart_card.dart';
import '../widgets/recent_transactions_card.dart';

/// Bento Grid Desktop Layout พร้อม Collapsible Sidebar สไตล์ FinTech 2026
class DesktopDashboardView extends GetView<DashboardController> {
  const DesktopDashboardView({super.key});

  String _getPeriodTitle(DashboardController controller) {
    final date = controller.selectedDate.value;
    switch (controller.currentPeriod.value) {
      case TimeFilterPeriod.monthly:
        const months = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
        return '${months[date.month]} ${date.year + 543}';
      case TimeFilterPeriod.yearly:
        return 'ปี พ.ศ. ${date.year + 543}';
      case TimeFilterPeriod.allTime:
        return 'ภาพรวมสะสมทั้งหมด';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 1. Collapsible Sidebar
        _buildSidebar(context, isDark),

        // 2. Main Bento Content
        Expanded(
          child: Column(
            children: [
              // Top Header
              _buildTopHeader(isDark),

              // Scrollable Bento Grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 680;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isCompact) ...[
                            const BalanceCard(),
                            const SizedBox(height: 18),
                            const DailyAllowanceCard(),
                            const SizedBox(height: 18),
                            _buildCashflowSummaryRow(isDark, isCompact: true),
                            const SizedBox(height: 18),
                            const FlFinanceChartCard(),
                            const SizedBox(height: 18),
                            const RecentTransactionsCard(),
                          ] else ...[
                            // Bento Row 1: Hero Cards
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(flex: 5, child: BalanceCard()),
                                SizedBox(width: 18),
                                Expanded(flex: 4, child: DailyAllowanceCard()),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Bento Row 2: 3 Cashflow Pills
                            _buildCashflowSummaryRow(isDark, isCompact: false),
                            const SizedBox(height: 18),

                            // Bento Row 3: fl_chart & Recent Transactions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(flex: 5, child: FlFinanceChartCard()),
                                SizedBox(width: 18),
                                Expanded(flex: 5, child: RecentTransactionsCard()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(bool isDark) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Period Title & Controls
          Obx(() {
            return Row(
              children: [
                Text(
                  _getPeriodTitle(controller),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (controller.currentPeriod.value != TimeFilterPeriod.allTime) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: controller.previousPeriod,
                    tooltip: 'รอบก่อนหน้า',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: controller.nextPeriod,
                    tooltip: 'รอบถัดไป',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            );
          }),

          // Action Controls
          Row(
            children: [
              // Period Filter Tabs
              Obx(() {
                return Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab(TimeFilterPeriod.monthly, 'รายเดือน (1)', isDark),
                      _buildFilterTab(TimeFilterPeriod.yearly, 'รายปี (2)', isDark),
                      _buildFilterTab(TimeFilterPeriod.allTime, 'ทั้งหมด (3)', isDark),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 12),

              // Add Transaction Button
              ElevatedButton.icon(
                onPressed: () => QuickAddBottomSheet.show(Get.context!),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('บันทึก (N)', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(TimeFilterPeriod period, String label, bool isDark) {
    final isSelected = controller.currentPeriod.value == period;

    return GestureDetector(
      onTap: () => controller.setTimeFilter(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCashflowSummaryRow(bool isDark, {bool isCompact = false}) {
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Obx(() {
      final incomePill = _buildCashflowPill(
        title: 'รายรับทั้งหมด',
        amount: currencyFmt.format(controller.actualIncome),
        icon: Icons.arrow_downward_rounded,
        color: AppColors.primary,
        isDark: isDark,
      );
      final expensePill = _buildCashflowPill(
        title: 'รายจ่ายทั้งหมด',
        amount: currencyFmt.format(controller.actualExpenses),
        icon: Icons.arrow_upward_rounded,
        color: AppColors.deficitText,
        isDark: isDark,
      );
      final savingsPill = _buildCashflowPill(
        title: 'เงินออม & ลงทุน',
        amount: currencyFmt.format(controller.actualSavings),
        icon: Icons.savings_rounded,
        color: AppColors.accent,
        isDark: isDark,
      );

      if (isCompact) {
        return Column(
          children: [
            incomePill,
            const SizedBox(height: 10),
            expensePill,
            const SizedBox(height: 10),
            savingsPill,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: incomePill),
          const SizedBox(width: 14),
          Expanded(child: expensePill),
          const SizedBox(width: 14),
          Expanded(child: savingsPill),
        ],
      );
    });
  }

  Widget _buildCashflowPill({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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

  Widget _buildSidebar(BuildContext context, bool isDark) {
    return Obx(() {
      final collapsed = controller.isSidebarCollapsed.value;
      final width = collapsed ? 78.0 : 230.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        ),
        child: Column(
          children: [
            // App Brand
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('MoneyTracker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          Text('GetX 4.7.3', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Navigation Items
            _buildSidebarItem(
              icon: Icons.dashboard_rounded,
              label: 'ภาพรวมแดชบอร์ด',
              isActive: true,
              collapsed: collapsed,
              onTap: () {},
            ),
            _buildSidebarItem(
              icon: Icons.tune_rounded,
              label: 'ตั้งค่างบประมาณ',
              badgeShortcut: 'S',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.BUDGET_SETTINGS),
            ),
            _buildSidebarItem(
              icon: Icons.storage_rounded,
              label: 'จัดการข้อมูล (CSV)',
              badgeShortcut: 'M',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.DATA_MANAGEMENT),
            ),
            _buildSidebarItem(
              icon: Icons.security_rounded,
              label: 'ความปลอดภัย (PIN)',
              badgeShortcut: 'P',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.PIN_SETTINGS),
            ),
            if (Get.isRegistered<SecurityController>() && Get.find<SecurityController>().isPinEnabled.value)
              _buildSidebarItem(
                icon: Icons.lock_outline_rounded,
                label: 'ล็อกหน้าจอ',
                badgeShortcut: 'L',
                isActive: false,
                collapsed: collapsed,
                onTap: () => Get.find<SecurityController>().lock(),
              ),

            const Spacer(),

            // Theme Toggle & Collapse Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    label: isDark ? 'โหมดสว่าง' : 'โหมดมืด',
                    badgeShortcut: 'D',
                    isActive: false,
                    collapsed: collapsed,
                    onTap: controller.toggleTheme,
                  ),
                  const SizedBox(height: 6),
                  IconButton(
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: controller.toggleSidebar,
                    tooltip: collapsed ? 'ขยาย Sidebar' : 'ย่อ Sidebar',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool collapsed,
    required VoidCallback onTap,
    String? badgeShortcut,
  }) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeShortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeShortcut,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
