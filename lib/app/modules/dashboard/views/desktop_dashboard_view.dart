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
import '../../../widgets/modern_app_bar.dart';
import '../../../theme/app_popup_decorations.dart';

/// Bento Grid Desktop Layout พร้อม Collapsible Sidebar สไตล์ FinTech 2026
class DesktopDashboardView extends GetView<DashboardController> {
  const DesktopDashboardView({super.key});

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
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Period Title & Controls
          Obx(() {
            final isCurrent = controller.isCurrentPeriod;
            final period = controller.currentPeriod.value;

            return Row(
              children: [
                Text(
                  controller.formattedPeriodTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (period != TimeFilterPeriod.allTime) ...[
                  ModernAppBar.squircleIconButton(
                    onTap: controller.previousPeriod,
                    icon: Icons.chevron_left_rounded,
                    isDark: isDark,
                    tooltip: 'prev_period'.tr,
                  ),
                  ModernAppBar.squircleIconButton(
                    onTap: controller.nextPeriod,
                    icon: Icons.chevron_right_rounded,
                    isDark: isDark,
                    tooltip: 'next_period'.tr,
                  ),
                  if (!isCurrent) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: controller.resetToCurrentPeriod,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.restart_alt_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                period == TimeFilterPeriod.monthly ? 'current_month'.tr : 'current_year'.tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          }),

          // Action Controls
          Row(
            children: [
              // Period Filter Tabs (Floating Segmented Pill)
              Obx(() {
                return Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab(TimeFilterPeriod.monthly, '${'monthly'.tr} (1)', isDark),
                      _buildFilterTab(TimeFilterPeriod.yearly, '${'yearly'.tr} (2)', isDark),
                      _buildFilterTab(TimeFilterPeriod.allTime, '${'all_time'.tr} (3)', isDark),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 14),

              // Add Transaction Button with Radiant Gradient
              ElevatedButton.icon(
                onPressed: () => QuickAddBottomSheet.show(Get.context!),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('add_transaction'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
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
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
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
        title: 'total_income'.tr,
        amount: currencyFmt.format(controller.actualIncome),
        icon: Icons.arrow_downward_rounded,
        color: AppColors.primary,
        isDark: isDark,
      );
      final expensePill = _buildCashflowPill(
        title: 'total_expenses'.tr,
        amount: currencyFmt.format(controller.actualExpenses),
        icon: Icons.arrow_upward_rounded,
        color: AppColors.deficitText,
        isDark: isDark,
      );
      final savingsPill = _buildCashflowPill(
        title: 'savings_and_investing'.tr,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
      final width = collapsed ? 80.0 : 236.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // App Brand
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MoneyTracker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                              ),
                              const SizedBox(width: 4),
                              const Text('FinTech 2026', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
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
              label: 'dashboard_overview'.tr,
              isActive: true,
              collapsed: collapsed,
              onTap: () {},
            ),
            _buildSidebarItem(
              icon: Icons.receipt_long_rounded,
              label: 'all_transactions'.tr,
              badgeShortcut: 'T',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.TRANSACTIONS_LIST),
            ),
            _buildSidebarItem(
              icon: Icons.tune_rounded,
              label: 'budget_settings'.tr,
              badgeShortcut: 'S',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.BUDGET_SETTINGS),
            ),
            _buildSidebarItem(
              icon: Icons.storage_rounded,
              label: 'data_management_short'.tr,
              badgeShortcut: 'M',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.DATA_MANAGEMENT),
            ),
            _buildSidebarItem(
              icon: Icons.security_rounded,
              label: 'security_pin_short'.tr,
              badgeShortcut: 'P',
              isActive: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed(Routes.PIN_SETTINGS),
            ),
            if (Get.isRegistered<SecurityController>() && Get.find<SecurityController>().isPinEnabled.value)
              _buildSidebarItem(
                icon: Icons.lock_outline_rounded,
                label: 'lock_screen'.tr,
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
                  Obx(() {
                    return _buildSidebarItem(
                      icon: Icons.language_rounded,
                      label: 'language_label'.trParams({'lang': controller.currentLanguageName}),
                      isActive: false,
                      collapsed: collapsed,
                      onTap: () => showLanguagePickerDialog(context),
                    );
                  }),
                  const SizedBox(height: 6),
                  Obx(() {
                    final mode = controller.themeMode.value;
                    return _buildSidebarItem(
                      icon: mode == ThemeMode.system
                          ? Icons.brightness_auto_rounded
                          : (isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                      label: 'theme_label'.trParams({'theme': controller.themeModeName}),
                      badgeShortcut: 'D',
                      isActive: false,
                      collapsed: collapsed,
                      onTap: () => showThemePickerDialog(context),
                    );
                  }),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: controller.toggleSidebar,
                    tooltip: collapsed ? 'expand_sidebar'.tr : 'collapse_sidebar'.tr,
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
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  )
                : null,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
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
