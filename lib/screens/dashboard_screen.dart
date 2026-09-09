import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import '../widgets/quick_add_modal.dart';

/// หน้าจอหลัก Dashboard สไตล์ Minimalist พร้อม Responsive Layout (Mobile & Desktop)
class DashboardScreen extends StatefulWidget {
  final FinanceService financeService;

  const DashboardScreen({super.key, required this.financeService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.financeService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    widget.financeService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  String _formatCurrency(double amount, {bool showSign = false}) {
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = '$integerPart.${parts[1]} ฿';
    if (!showSign) return formatted;
    if (amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return formatted;
  }

  String _getMonthName(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.financeService;
    final summary = service.summary;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : _buildMobileAppBar(service),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => QuickAddModal.show(context, service.addTransaction),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'บันทึก',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(service, summary)
            : _buildMobileLayout(service, summary),
      ),
    );
  }

  // ==========================================
  // MOBILE APP BAR
  // ==========================================
  PreferredSizeWidget _buildMobileAppBar(FinanceService service) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Finance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getPeriodTitle(service),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (service.currentPeriod == TimeFilterPeriod.monthly) ...[
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            onPressed: service.previousPeriod,
            tooltip: 'เดือนก่อนหน้า',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onPressed: service.nextPeriod,
            tooltip: 'เดือนถัดไป',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  String _getPeriodTitle(FinanceService service) {
    switch (service.currentPeriod) {
      case TimeFilterPeriod.monthly:
        return '${_getMonthName(service.selectedDate.month)} ${service.selectedDate.year + 543}';
      case TimeFilterPeriod.yearly:
        return 'ปี พ.ศ. ${service.selectedDate.year + 543}';
      case TimeFilterPeriod.allTime:
        return 'ภาพรวมสะสมทั้งหมด';
    }
  }

  // ==========================================
  // DESKTOP LAYOUT (Multi-Column Bento Grid)
  // ==========================================
  Widget _buildDesktopLayout(FinanceService service, BudgetSummary summary) {
    return Column(
      children: [
        // Desktop Top Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              // Logo & Title
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPastel,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Money Tracker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _getPeriodTitle(service),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Time Filter Tabs
              _buildTimeFilterBar(service),
              const SizedBox(width: 16),

              // Quick Add Button
              ElevatedButton.icon(
                onPressed: () => QuickAddModal.show(context, service.addTransaction),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'บันทึกรายการ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Desktop Main Content Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Cards Row: Surplus/Deficit Status, Daily Allowance, Cost Breakdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildSurplusDeficitCard(summary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildDailyAllowanceCard(summary, service.budgetPlan),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildCostBreakdownCard(summary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Core 3 Categories Quick Overview
                _buildCashflowSummaryRow(summary),
                const SizedBox(height: 24),

                // 3. Transactions Section
                _buildTransactionsSection(service),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE LAYOUT (Single Column)
  // ==========================================
  Widget _buildMobileLayout(FinanceService service, BudgetSummary summary) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
      children: [
        // Time Filter Selector
        _buildTimeFilterBar(service),
        const SizedBox(height: 16),

        // 1. Expected Balance & Surplus/Deficit Status Card
        _buildSurplusDeficitCard(summary),
        const SizedBox(height: 14),

        // 2. Daily Allowance Card
        _buildDailyAllowanceCard(summary, service.budgetPlan),
        const SizedBox(height: 14),

        // 3. Cost Breakdown (Fixed vs Variable)
        _buildCostBreakdownCard(summary),
        const SizedBox(height: 14),

        // 4. Core Categories Summary Cards
        _buildCashflowSummaryRow(summary),
        const SizedBox(height: 20),

        // 5. Recent Transactions
        _buildTransactionsSection(service),
      ],
    );
  }

  // ==========================================
  // COMPONENT: TIME FILTER BAR
  // ==========================================
  Widget _buildTimeFilterBar(FinanceService service) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterTab(
            label: 'รายเดือน',
            isSelected: service.currentPeriod == TimeFilterPeriod.monthly,
            onTap: () => service.setTimeFilter(TimeFilterPeriod.monthly),
          ),
          _buildFilterTab(
            label: 'รายปี',
            isSelected: service.currentPeriod == TimeFilterPeriod.yearly,
            onTap: () => service.setTimeFilter(TimeFilterPeriod.yearly),
          ),
          _buildFilterTab(
            label: 'ทั้งหมด',
            isSelected: service.currentPeriod == TimeFilterPeriod.allTime,
            onTap: () => service.setTimeFilter(TimeFilterPeriod.allTime),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENT: SURPLUS / DEFICIT & BALANCE CARD
  // ==========================================
  Widget _buildSurplusDeficitCard(BudgetSummary summary) {
    final isSurplus = summary.isSurplus;
    final statusBg = isSurplus ? AppColors.surplusBg : AppColors.deficitBg;
    final statusBorder = isSurplus ? AppColors.surplusBorder : AppColors.deficitBorder;
    final statusText = isSurplus ? AppColors.surplusText : AppColors.deficitText;
    final statusIcon = isSurplus ? AppColors.surplusIcon : AppColors.deficitIcon;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สถานะกระแสเงินสด',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: statusIcon,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      summary.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actual Balance
          const Text(
            'เงินคงเหลือจริงในปัจจุบัน (Actual Balance)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(summary.actualNetBalance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Real-time Comparison: Expected Balance vs Difference
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ควรเหลือเงินตามแผน',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(summary.expectedNetBalance),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                width: 1,
                color: AppColors.divider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSurplus ? 'เหลือเกินเป้าหมาย (Surplus)' : 'ใช้เงินเกินงบ (Deficit)',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(summary.surplusOrDeficit, showSign: true),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: DAILY ALLOWANCE CARD
  // ==========================================
  Widget _buildDailyAllowanceCard(BudgetSummary summary, BudgetPlan plan) {
    final targetDaily = plan.targetDailyAllowance;
    final remainingDaily = summary.remainingDailyAllowance;
    final isWithinBudget = remainingDaily >= targetDaily * 0.7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ค่ากิน/ค่าใช้จ่ายรายวัน',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.variableCostPastel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Daily Allowance',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.variableCostText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                remainingDaily.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isWithinBudget ? AppColors.textPrimary : AppColors.deficitText,
                ),
              ),
              const Text(
                ' ฿ / วัน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'เฉลี่ยใช้ได้อีก ${summary.remainingDaysInMonth} วันที่เหลือในเดือนนี้',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Burn rate info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เป้าหมายต่อวัน:',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  '${targetDaily.toStringAsFixed(0)} ฿/วัน',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: COST BREAKDOWN CARD (Fixed vs Variable)
  // ==========================================
  Widget _buildCostBreakdownCard(BudgetSummary summary) {
    final totalExpense = summary.totalExpenses > 0 ? summary.totalExpenses : 1.0;
    final fixedRatio = (summary.totalFixedExpenses / totalExpense).clamp(0.0, 1.0);
    final variableRatio = (summary.totalVariableExpenses / totalExpense).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สัดส่วนรายจ่าย (Cost Breakdown)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (fixedRatio * 100).round().clamp(1, 99),
                  child: Container(
                    height: 8,
                    color: AppColors.fixedCostText,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (variableRatio * 100).round().clamp(1, 99),
                  child: Container(
                    height: 8,
                    color: AppColors.variableCostText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Fixed Costs Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.fixedCostText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'คงที่ (Fixed):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                _formatCurrency(summary.totalFixedExpenses),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Variable Costs Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.variableCostText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'จิปาถะ (Variable):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                _formatCurrency(summary.totalVariableExpenses),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: CORE 3 CASHFLOW CATEGORIES ROW
  // ==========================================
  Widget _buildCashflowSummaryRow(BudgetSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryStatTile(
            title: 'รายรับ (Income)',
            amount: summary.totalIncome,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.incomeText,
            bgColor: AppColors.incomePastel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryStatTile(
            title: 'รายจ่าย (Expense)',
            amount: summary.totalExpenses,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.deficitText,
            bgColor: AppColors.deficitBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryStatTile(
            title: 'เงินออม/ลงทุน (Savings)',
            amount: summary.totalSavings,
            icon: Icons.savings_outlined,
            color: AppColors.savingsText,
            bgColor: AppColors.savingsPastel,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStatTile({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: RECENT TRANSACTIONS SECTION
  // ==========================================
  Widget _buildTransactionsSection(FinanceService service) {
    final transactions = service.filteredTransactions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'รายการธุรกรรมล่าสุด',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${transactions.length} รายการ',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.inbox_outlined, size: 36, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่มีรายการในหมวดหรือช่วงเวลานี้',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppColors.divider, indent: 64),
              itemBuilder: (ctx, index) {
                final item = transactions[index];
                return _buildTransactionItemTile(service, item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemTile(FinanceService service, TransactionItem item) {
    final isIncome = item.isIncome;
    final isExpense = item.isExpense;

    final Color amountColor = isIncome
        ? AppColors.incomeText
        : isExpense
            ? AppColors.textPrimary
            : AppColors.savingsText;

    final String amountPrefix = isIncome
        ? '+'
        : isExpense
            ? '-'
            : '';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.deficitBg,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.deficitIcon, size: 22),
      ),
      onDismissed: (_) => service.deleteTransaction(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.type.tagBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.type.icon,
                size: 18,
                color: item.type.tagTextColor,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${item.date.day}/${item.date.month}/${item.date.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${item.categoryName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.isExpense) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.costNature.tagBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.costNature == CostNature.fixed ? 'คงที่' : 'จิปาถะ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: item.costNature.tagTextColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount & Delete action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${_formatCurrency(item.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
              onPressed: () => service.deleteTransaction(item.id),
              splashRadius: 16,
              tooltip: 'ลบรายการ',
            ),
          ],
        ),
      ),
    );
  }
}
