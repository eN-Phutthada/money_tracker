import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../security/controllers/security_controller.dart';
import '../../transactions/views/quick_add_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/daily_allowance_card.dart';
import '../widgets/fl_finance_chart_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/wallet_health_diagnostic_sheet.dart';

/// Bento Grid Desktop Layout พร้อม Collapsible Sidebar สไตล์ Nothing OS Design System
class DesktopDashboardView extends GetView<DashboardController> {
  const DesktopDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 1. Collapsible Sidebar (Nothing OS Industrial Command Rail)
        _buildSidebar(context, isDark),

        // 2. Main Bento Content (Nothing OS Matrix Canvas)
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFF7F7F7),
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
                              const BalanceCard().cascadeAnimate(0),
                              const SizedBox(height: 18),
                              const DailyAllowanceCard().cascadeAnimate(1),
                              const SizedBox(height: 18),
                              _buildCashflowSummaryRow(isDark, isCompact: true).cascadeAnimate(2),
                              const SizedBox(height: 18),
                              const FlFinanceChartCard().cascadeAnimate(3),
                              const SizedBox(height: 18),
                              const RecentTransactionsCard().cascadeAnimate(4),
                            ] else ...[
                              // Bento Row 1: Hero Cards
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: const BalanceCard().cascadeAnimate(0)),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 4, child: const DailyAllowanceCard().cascadeAnimate(1)),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Bento Row 2: 3 Cashflow Pills
                              _buildCashflowSummaryRow(isDark, isCompact: false).cascadeAnimate(2),
                              const SizedBox(height: 18),

                              // Bento Row 3: fl_chart & Recent Transactions
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: const FlFinanceChartCard().cascadeAnimate(3)),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 5, child: const RecentTransactionsCard().cascadeAnimate(4)),
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
        ),
      ],
    );
  }

  Widget _buildTopHeader(bool isDark) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080808) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black,
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
                      color: isDark ? const Color(0xFF161616) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: controller.resetToCurrentPeriod,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const NothingLedIndicator(
                                color: AppColors.nothingRed,
                                size: 5,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                period == TimeFilterPeriod.monthly ? 'current_month'.tr : 'current_year'.tr,
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
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
              // Period Filter Tabs (Segmented Nothing Pill)
              Obx(() {
                return Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
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
              // Wallet Health Diagnostics Button (H)
              OutlinedButton.icon(
                onPressed: () => WalletHealthDiagnosticSheet.show(Get.context!),
                icon: const Icon(Icons.health_and_safety_outlined, size: 16),
                label: Text(
                  '${'inspect_health'.tr} (H)',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Add Transaction Button with Nothing Red Industrial Accent
              ElevatedButton.icon(
                onPressed: () => QuickAddBottomSheet.show(Get.context!),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'add_transaction'.tr,
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nothingRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF242424) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                  width: 0.8,
                )
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? AppColors.nothingMuted : AppColors.textSecondary),
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
        indicatorColor: AppColors.incomeColor(isDark),
        isDark: isDark,
      );
      final expensePill = _buildCashflowPill(
        title: 'total_expenses'.tr,
        amount: currencyFmt.format(controller.actualExpenses),
        icon: Icons.arrow_upward_rounded,
        indicatorColor: AppColors.expenseColor(isDark),
        isDark: isDark,
      );
      final withdrawalAmt = controller.actualSavingsWithdrawals;
      final savingsPill = _buildCashflowPill(
        title: 'savings_and_investing'.tr,
        amount: currencyFmt.format(controller.actualSavings),
        icon: Icons.savings_rounded,
        indicatorColor: AppColors.savingsColor(isDark),
        isDark: isDark,
        subtitle: withdrawalAmt > 0
            ? '${'withdrawal'.tr}: -${currencyFmt.format(withdrawalAmt)}'
            : null,
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
    required Color indicatorColor,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101010) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: indicatorColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NothingLedIndicator(
                      color: indicatorColor,
                      size: 5,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.nothingMuted : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
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
          color: isDark ? const Color(0xFF080808) : const Color(0xFFFAFAFA),
          border: Border(
            right: BorderSide(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
        ),
        child: Column(
          children: [
            // App Brand (Nothing OS Industrial Bento Header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: [
                  const NothingAppLogo(
                    size: 40,
                    borderRadius: 14,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONEY TRACKER',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              const NothingLedIndicator(
                                color: AppColors.nothingRed,
                                size: 5,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'NOTHING OS 3.0',
                                style: GoogleFonts.shareTechMono(
                                    fontSize: 9,
                                    color: AppColors.nothingRed,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 8),

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
            if (Get.isRegistered<SecurityController>() &&
                Get.find<SecurityController>().isPinEnabled.value)
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
                    return _buildSidebarItem(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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
                      color: isDark ? AppColors.nothingMuted : AppColors.textSecondary,
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
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF1C1C1C) : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            children: [
              if (isActive) ...[
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.nothingRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? AppColors.nothingMuted : AppColors.textSecondary),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.nothingMuted : AppColors.textSecondary),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeShortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badgeShortcut,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.nothingMuted : AppColors.textSecondary,
                      ),
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

/// Cascade Stagger Entrance Animation for Desktop Dashboard Bento Cards
extension DesktopDashboardCascadeExt on Widget {
  Widget cascadeAnimate(int index) {
    return animate()
        .fadeIn(
          duration: const Duration(milliseconds: 320),
          delay: Duration(milliseconds: 70 * index),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          duration: const Duration(milliseconds: 320),
          delay: Duration(milliseconds: 70 * index),
          curve: Curves.easeOutCubic,
        );
  }
}

