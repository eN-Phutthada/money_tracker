import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../routes/app_routes.dart';
import 'quick_add_bottom_sheet.dart';
import 'bank_slip_sheet.dart';

/// หน้าจอประวัติรายการธุรกรรมทั้งหมด (FinTech 2026 Transaction Command Hub)
class TransactionsListView extends StatefulWidget {
  const TransactionsListView({super.key});

  @override
  State<TransactionsListView> createState() => _TransactionsListViewState();
}

class _TransactionsListViewState extends State<TransactionsListView> {
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  TransactionType? _selectedTypeFilter;
  String _selectedCategoryFilter = 'ทั้งหมด';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('อาหาร') ||
        category.contains('ของกิน') ||
        category.contains('Food')) {
      return Icons.fastfood_rounded;
    }
    if (category.contains('กาแฟ') ||
        category.contains('เครื่องดื่ม') ||
        category.contains('Coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (category.contains('เดินทาง') ||
        category.contains('รถ') ||
        category.contains('Transport')) {
      return Icons.directions_subway_rounded;
    }
    if (category.contains('ช้อปปิ้ง') || category.contains('Shopping')) {
      return Icons.shopping_bag_rounded;
    }
    if (category.contains('ของใช้') || category.contains('Personal')) {
      return Icons.inventory_2_rounded;
    }
    if (category.contains('ที่อยู่อาศัย') || category.contains('Housing')) {
      return Icons.home_rounded;
    }
    if (category.contains('สาธารณูปโภค') || category.contains('Utilities')) {
      return Icons.flash_on_rounded;
    }
    if (category.contains('สื่อสาร') || category.contains('เน็ต')) {
      return Icons.wifi_rounded;
    }
    if (category.contains('เงินเดือน') || category.contains('Salary')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (category.contains('ออม') ||
        category.contains('DCA') ||
        category.contains('กองทุน') ||
        category.contains('Savings')) {
      return Icons.savings_rounded;
    }
    if (category.contains('ประกัน') ||
        category.contains('สุขภาพ') ||
        category.contains('Health')) {
      return Icons.health_and_safety_rounded;
    }
    if (category.contains('การศึกษา') || category.contains('Education')) {
      return Icons.school_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'today'.tr;
    if (target == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr;
    }

    final isEn = controller.isEnglish;
    final monthStr = isEn
        ? DashboardController.englishMonthShortNames[date.month]
        : DashboardController.thaiMonthShortNames[date.month];
    final yearStr = isEn ? '${date.year}' : '${date.year + 543}';
    return 'group_date_format'.trParams({
      'day': '${date.day}',
      'month': monthStr,
      'year': yearStr,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '฿',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: ModernAppBar(
        title: 'all_transactions'.tr,
        subtitle: 'transactions_subtitle'.tr,
        badgeWidget: Obx(() {
          final count = controller.transactions.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
        actions: [
          ModernAppBar.primaryActionButton(
            onTap: () => QuickAddBottomSheet.show(context),
            label: 'add_transaction'.tr,
            icon: Icons.add_rounded,
          ),
        ],
      ),
      body: LiquidGlassNavDock.floatingOnScreen(
        context: context,
        currentRoute: Routes.TRANSACTIONS_LIST,
        body: Stack(
          children: [
            // Ambient FinTech Canvas Lighting Glow
            Positioned(
              top: -50,
              left: MediaQuery.of(context).size.width / 2 - 150,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? AppColors.primary : const Color(0xFF6EE7B7))
                            .withValues(alpha: isDark ? 0.14 : 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Obx(() {
                    // 1. Get transactions sorted by date descending
                    var list = controller.transactions.toList()
                      ..sort((a, b) => b.date.compareTo(a.date));

                    // 2. Filter by Search Query
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      list = list.where((t) {
                        return t.title.toLowerCase().contains(q) ||
                            t.categoryName.toLowerCase().contains(q) ||
                            (t.note != null &&
                                t.note!.toLowerCase().contains(q));
                      }).toList();
                    }

                    // 3. Filter by Type
                    if (_selectedTypeFilter != null) {
                      list = list
                          .where((t) => t.type == _selectedTypeFilter)
                          .toList();
                    }

                    // 4. Filter by Category
                    if (_selectedCategoryFilter != 'ทั้งหมด') {
                      list = list
                          .where(
                            (t) => t.categoryName == _selectedCategoryFilter,
                          )
                          .toList();
                    }

                    // 5. Calculate telemetry metrics
                    final totalExpense = list
                        .where((t) => t.isExpense)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final totalIncome = list
                        .where((t) => t.isIncome)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final totalSavings = list
                        .where((t) => t.isSavings)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final netFlow = totalIncome - totalExpense;

                    // Extract all unique categories
                    final allCategories = {
                      'ทั้งหมด',
                      ...controller.transactions.map((t) => t.categoryName),
                    };

                    // Group items by date string
                    final Map<String, List<TransactionItem>> grouped = {};
                    for (final item in list) {
                      final dateKey =
                          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
                      grouped.putIfAbsent(dateKey, () => []).add(item);
                    }

                    final bool isFilterActive =
                        _searchQuery.isNotEmpty ||
                        _selectedTypeFilter != null ||
                        _selectedCategoryFilter != 'ทั้งหมด';

                    return Column(
                      children: [
                        // Search & Filter Controls Card
                        _buildSearchAndFilterSection(
                          isDark: isDark,
                          allCategories: allCategories,
                          isFilterActive: isFilterActive,
                        ),

                        // Hero Telemetry Bento Summary Header
                        _buildHeroTelemetryBento(
                          isDark: isDark,
                          currencyFmt: currencyFmt,
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          totalSavings: totalSavings,
                          netFlow: netFlow,
                          resultsCount: list.length,
                          isFilterActive: isFilterActive,
                        ),

                        // Transaction Cards Feed or Empty State
                        Expanded(
                          child: list.isEmpty
                              ? _buildEmptyState(isDark, isFilterActive)
                              : _buildTransactionsFeed(
                                  isDark: isDark,
                                  currencyFmt: currencyFmt,
                                  grouped: grouped,
                                ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Search Bar & Filter Controls Header
  Widget _buildSearchAndFilterSection({
    required bool isDark,
    required Set<String> allCategories,
    required bool isFilterActive,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.95,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frosted Glass Search Input with Krungthai Slip Scan Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_transactions_hint'.tr,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _searchQuery.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    BankSlipScanModal.show(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3E0).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF00A3E0)),
                        const SizedBox(width: 6),
                        Text(
                          'scan_bank_slip'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00A3E0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Filter Chips & Category Dropdown
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTypeFilterChip('filter_all'.tr, null, isDark),
                const SizedBox(width: 8),
                _buildTypeFilterChip(
                  'filter_expense'.tr,
                  TransactionType.expense,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildTypeFilterChip(
                  'filter_income'.tr,
                  TransactionType.income,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildTypeFilterChip(
                  'filter_savings_dca'.tr,
                  TransactionType.savingsInvestment,
                  isDark,
                ),
                const SizedBox(width: 10),

                // Category Dropdown Filter Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter != 'ทั้งหมด'
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategoryFilter != 'ทั้งหมด'
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.border.withValues(alpha: 0.7)),
                      width: _selectedCategoryFilter != 'ทั้งหมด' ? 1.2 : 1.0,
                    ),
                    boxShadow: _selectedCategoryFilter != 'ทั้งหมด'
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: _selectedCategoryFilter != 'ทั้งหมด'
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 5),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allCategories.contains(_selectedCategoryFilter)
                              ? _selectedCategoryFilter
                              : 'ทั้งหมด',
                          isDense: true,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: _selectedCategoryFilter != 'ทั้งหมด'
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _selectedCategoryFilter != 'ทั้งหมด'
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedCategoryFilter != 'ทั้งหมด'
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                          ),
                          dropdownColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          items: allCategories.map((cat) {
                            final catLabel = cat == 'ทั้งหมด'
                                ? 'filter_all'.tr
                                : cat.tr;
                            final isCurrent = _selectedCategoryFilter == cat;
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                catLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (cat) {
                            if (cat != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategoryFilter = cat);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Reset Filters Button
                if (isFilterActive) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedTypeFilter = null;
                        _selectedCategoryFilter = 'ทั้งหมด';
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deficitText.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.deficitText.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: AppColors.deficitText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'clear_filters'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deficitText,
                            ),
                          ),
                        ],
                      ),
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

  /// 2. Hero Telemetry Bento Summary Header
  Widget _buildHeroTelemetryBento({
    required bool isDark,
    required NumberFormat currencyFmt,
    required double totalIncome,
    required double totalExpense,
    required double totalSavings,
    required double netFlow,
    required int resultsCount,
    required bool isFilterActive,
  }) {
    final hasMetrics = totalIncome > 0 || totalExpense > 0 || totalSavings > 0;
    final double totalVolume = totalIncome + totalExpense + totalSavings;
    final double incomeRatio = totalVolume > 0
        ? (totalIncome / totalVolume)
        : 0.0;
    final double expenseRatio = totalVolume > 0
        ? (totalExpense / totalVolume)
        : 0.0;
    final double savingsRatio = totalVolume > 0
        ? (totalSavings / totalVolume)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.9)
              : AppColors.border.withValues(alpha: 0.8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Results count & Net Flow Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Count badge
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'results_count'.trParams({'count': '$resultsCount'}),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Net Flow Pill
              if (hasMetrics)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (netFlow >= 0
                                ? AppColors.primary
                                : AppColors.deficitText)
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (netFlow >= 0
                                  ? AppColors.primary
                                  : AppColors.deficitText)
                              .withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        netFlow >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: netFlow >= 0
                            ? AppColors.primary
                            : AppColors.deficitText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${netFlow >= 0 ? '+' : ''}${currencyFmt.format(netFlow)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: netFlow >= 0
                              ? AppColors.primary
                              : AppColors.deficitText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (hasMetrics) ...[
            const SizedBox(height: 10),
            // Financial Pillar Metrics: Inflow, Outflow, Savings
            Row(
              children: [
                // Inflow Pillar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'filter_income'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${currencyFmt.format(totalIncome)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Outflow Pillar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deficitText.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 13,
                              color: AppColors.deficitText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'filter_expense'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '-${currencyFmt.format(totalExpense)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deficitText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Savings Pillar (if any)
                if (totalSavings > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.savings_rounded,
                                size: 13,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'filter_savings'.tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyFmt.format(totalSavings),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Micro Flow Ratio Capsule Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4.5,
                child: Row(
                  children: [
                    if (incomeRatio > 0)
                      Expanded(
                        flex: (incomeRatio * 1000).toInt(),
                        child: Container(color: AppColors.primary),
                      ),
                    if (expenseRatio > 0)
                      Expanded(
                        flex: (expenseRatio * 1000).toInt(),
                        child: Container(color: AppColors.deficitText),
                      ),
                    if (savingsRatio > 0)
                      Expanded(
                        flex: (savingsRatio * 1000).toInt(),
                        child: Container(color: AppColors.accent),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Transactions List Feed
  Widget _buildTransactionsFeed({
    required bool isDark,
    required NumberFormat currencyFmt,
    required Map<String, List<TransactionItem>> grouped,
  }) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 110),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = grouped.keys.elementAt(groupIndex);
        final groupItems = grouped[dateKey]!;
        final firstDate = groupItems.first.date;

        final dayExpense = groupItems
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);
        final dayIncome = groupItems
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatGroupDate(firstDate),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dayIncome > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${currencyFmt.format(dayIncome)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          if (dayIncome > 0 && dayExpense > 0)
                            const SizedBox(width: 6),
                          if (dayExpense > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.deficitText.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${currencyFmt.format(dayExpense)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deficitText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Neo-Card Transaction Items in this Group
            ...groupItems.map((item) {
              return _buildTransactionCard(
                item: item,
                isDark: isDark,
                currencyFmt: currencyFmt,
              );
            }),
          ],
        );
      },
    );
  }

  /// 4. Neo-FinTech Card for each Transaction Item (matching dashboard_view RecentTransactionsCard)
  Widget _buildTransactionCard({
    required TransactionItem item,
    required bool isDark,
    required NumberFormat currencyFmt,
  }) {
    final icon = _getCategoryIcon(item.categoryName);

    // Type Styling & Indicators matching dashboard_view
    Color amountColor;
    Color iconBgColor;
    String prefix = '';
    String natureLabel = '';
    Color natureColor = AppColors.textSecondary;

    if (item.isIncome) {
      amountColor = AppColors.primary;
      iconBgColor = AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12);
      prefix = '+';
      natureLabel = 'income'.tr;
      natureColor = AppColors.primary;
    } else if (item.isSavings) {
      amountColor = AppColors.accent;
      iconBgColor = AppColors.accent.withValues(alpha: isDark ? 0.18 : 0.12);
      prefix = '';
      natureLabel = 'filter_savings'.tr;
      natureColor = AppColors.accent;
    } else {
      amountColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      iconBgColor = item.isFixedCost
          ? AppColors.fixedCostAccent.withValues(alpha: isDark ? 0.18 : 0.12)
          : AppColors.variableCostAccent.withValues(
              alpha: isDark ? 0.18 : 0.12,
            );
      prefix = '-';
      natureLabel = item.isFixedCost ? 'fixed_cost'.tr : 'variable_cost'.tr;
      natureColor = item.isFixedCost
          ? AppColors.fixedCostAccent
          : AppColors.variableCostAccent;
    }

    final isEn = controller.isEnglish;
    final yearNum = isEn ? item.date.year % 100 : (item.date.year + 543) % 100;
    final timeStr = DateFormat('HH:mm').format(item.date);

    return Dismissible(
      key: Key('all_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.deficitText.withValues(alpha: isDark ? 0.22 : 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.deficitText.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.deficitText,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'delete_transaction'.tr,
              style: const TextStyle(
                color: AppColors.deficitText,
                fontWeight: FontWeight.w800,
                fontSize: 13,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: isDark
              ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
              : AppColors.surfaceSecondary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              QuickAddBottomSheet.show(context, existingItem: item);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                      : AppColors.border.withValues(alpha: 0.5),
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
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: item.isIncome
                          ? AppColors.primary
                          : (item.isSavings ? AppColors.accent : natureColor),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Item Title, Nature Pill & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Nature Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: natureColor.withValues(
                                  alpha: isDark ? 0.16 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                natureLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: natureColor,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Category Name & Note
                            Flexible(
                              child: Text(
                                '${item.categoryName.tr}${item.note != null && item.note!.trim().isNotEmpty && item.note != item.title ? " • ${item.note}" : ""}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textSecondary,
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
                                '• ${item.date.day}/${item.date.month}/$yearNum $timeStr',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textSecondary,
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
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 5. Modern Futuristic Empty State (matching dashboard_view)
  Widget _buildEmptyState(bool isDark, bool isFilterActive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.4)
                : AppColors.surfaceSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.6)
                  : AppColors.border.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.15 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFilterActive ? 'no_search_results'.tr : 'no_transactions'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (isFilterActive) ...[
                const SizedBox(height: 4),
                Text(
                  'no_search_results_desc'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _selectedTypeFilter = null;
                      _selectedCategoryFilter = 'ทั้งหมด';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('clear_filters'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
              ] else ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    QuickAddBottomSheet.show(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'add_first_transaction'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
            ],
          ),
        ),
      ),
    );
  }

  /// 6. Interactive Type Filter Chip
  Widget _buildTypeFilterChip(
    String label,
    TransactionType? type,
    bool isDark,
  ) {
    final isSelected = _selectedTypeFilter == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTypeFilter = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.darkBorder
                      : AppColors.border.withValues(alpha: 0.7)),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
