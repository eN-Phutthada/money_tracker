import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_popup_decorations.dart';
import '../../../widgets/liquid_glass_nav_dock.dart';
import '../../../widgets/modern_app_bar.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import 'quick_add_bottom_sheet.dart';
import 'bank_slip_sheet.dart';

/// หน้าจอประวัติรายการธุรกรรมทั้งหมด สไตล์ Nothing OS Design System
/// - สุนทรียภาพ Minimalist Industrial Monochrome คมชัดระดับ Hi-Contrast
/// - การ์ดทรง Squircle ขอบ Hairline 0.8px และพื้นหลัง Pitch Black / Off-White
/// - ตัวเลขการเงิน Monospace ดิจิทัลคมชัด (ShareTechMono)
/// - จุดไฟ LED และปุ่มแคปซูล NothingPill สำหรับการค้นหาและกรองรายการ
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
  bool _filterOnlyWithdrawals = false;
  static const String _allCategoryKey = '__ALL_CATEGORIES__';
  String _selectedCategoryFilter = _allCategoryKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF7F7F7),
      appBar: ModernAppBar(
        title: 'all_transactions'.tr,
        subtitle: 'transactions_subtitle'.tr,
        badgeWidget: Obx(() {
          final count = controller.transactions.length;
          return NothingPill(
            label: '$count',
            isDotMatrix: true,
            showDot: true,
            dotColor: AppColors.nothingRed,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            fontSize: 11,
          );
        }),
        actions: [
          ModernAppBar.primaryActionButton(
            onTap: () => QuickAddBottomSheet.show(context),
            label: 'add_transaction'.tr,
            compactLabel: 'add_short'.tr,
            icon: Icons.add_rounded,
          ),
        ],
      ),
      body: LiquidGlassNavDock.floatingOnScreen(
        context: context,
        currentRoute: Routes.TRANSACTIONS_LIST,
        body: SafeArea(
          bottom: false,
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
                        (t.note != null && t.note!.toLowerCase().contains(q));
                  }).toList();
                }

                // 3. Filter by Type
                if (_filterOnlyWithdrawals) {
                  list = list.where((t) => t.isSavingsWithdrawal).toList();
                } else if (_selectedTypeFilter != null) {
                  list = list
                      .where((t) => t.type == _selectedTypeFilter)
                      .toList();
                }

                // 4. Filter by Category
                if (_selectedCategoryFilter != _allCategoryKey) {
                  list = list
                      .where((t) => t.categoryName == _selectedCategoryFilter)
                      .toList();
                }

                // 5. Calculate telemetry metrics
                final totalExpense = list
                    .where((t) => t.isExpense)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalIncome = list
                    .where((t) => t.isIncome)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalSavingsDeposits = list
                    .where((t) => t.isSavings)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalSavingsWithdrawals = list
                    .where((t) => t.isSavingsWithdrawal)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalSavings = totalSavingsDeposits - totalSavingsWithdrawals;
                final netFlow = totalIncome - totalExpense;

                // Extract all unique categories
                final allCategories = {
                  _allCategoryKey,
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
                    _filterOnlyWithdrawals ||
                    _selectedCategoryFilter != _allCategoryKey;

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
                      totalSavingsDeposits: totalSavingsDeposits,
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
      ),
    );
  }

  /// 1. Search Bar & Filter Controls Header สไตล์ Nothing OS
  Widget _buildSearchAndFilterSection({
    required bool isDark,
    required Set<String> allCategories,
    required bool isFilterActive,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.nothingBorder
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nothing Squircle Search Input with Krungthai Slip Scan Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414)
                        : const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                    decoration: InputDecoration(
                      hintText: 'search_transactions_hint'.tr,
                      hintStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.nothingSubtext
                            : const Color(0xFF888888),
                      ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: _searchQuery.isNotEmpty
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                  ? AppColors.nothingSubtext
                                  : const Color(0xFF888888)),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              color: isDark ? Colors.white70 : Colors.black54,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isDark
                    ? const Color(0xFF141414)
                    : const Color(0xFFF3F3F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    BankSlipScanModal.show(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NothingLedIndicator(
                          size: 5,
                          color: AppColors.nothingRed,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'scan_bank_slip'.tr.toUpperCase(),
                          style:
                              GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 0.5,
                              ).copyWith(
                                fontFamilyFallback: ['Prompt', 'sans-serif'],
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
                NothingPill(
                  label: 'filter_all'.tr,
                  isSelected:
                      _selectedTypeFilter == null && !_filterOnlyWithdrawals,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTypeFilter = null;
                      _filterOnlyWithdrawals = false;
                    });
                  },
                ),
                const SizedBox(width: 6),
                NothingPill(
                  label: 'filter_expense'.tr,
                  isSelected:
                      !_filterOnlyWithdrawals &&
                      _selectedTypeFilter == TransactionType.expense,
                  selectedColor: AppColors.expenseColor(isDark),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _filterOnlyWithdrawals = false;
                      _selectedTypeFilter = TransactionType.expense;
                    });
                  },
                ),
                const SizedBox(width: 6),
                NothingPill(
                  label: 'filter_income'.tr,
                  isSelected:
                      !_filterOnlyWithdrawals &&
                      _selectedTypeFilter == TransactionType.income,
                  selectedColor: AppColors.incomeColor(isDark),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _filterOnlyWithdrawals = false;
                      _selectedTypeFilter = TransactionType.income;
                    });
                  },
                ),
                const SizedBox(width: 6),
                NothingPill(
                  label: 'filter_savings_dca'.tr,
                  isSelected:
                      !_filterOnlyWithdrawals &&
                      _selectedTypeFilter == TransactionType.savingsInvestment,
                  selectedColor: AppColors.savingsColor(isDark),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _filterOnlyWithdrawals = false;
                      _selectedTypeFilter = TransactionType.savingsInvestment;
                    });
                  },
                ),
                const SizedBox(width: 6),
                NothingPill(
                  label: 'filter_savings_withdrawal'.tr,
                  isSelected: _filterOnlyWithdrawals,
                  selectedColor: AppColors.withdrawalColor(isDark),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _filterOnlyWithdrawals = true;
                      _selectedTypeFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Category Dropdown Filter Pill
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter != _allCategoryKey
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark
                              ? const Color(0xFF141414)
                              : const Color(0xFFF3F3F3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.nothingBorder
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 13,
                        color: _selectedCategoryFilter != _allCategoryKey
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark
                                  ? AppColors.nothingSubtext
                                  : const Color(0xFF777777)),
                      ),
                      const SizedBox(width: 5),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allCategories.contains(_selectedCategoryFilter)
                              ? _selectedCategoryFilter
                              : _allCategoryKey,
                          isDense: true,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: _selectedCategoryFilter != _allCategoryKey
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                      ? AppColors.nothingSubtext
                                      : const Color(0xFF777777)),
                          ),
                          style:
                              GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    _selectedCategoryFilter != _allCategoryKey
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                              ).copyWith(
                                fontFamilyFallback: ['Prompt', 'sans-serif'],
                              ),
                          dropdownColor: isDark
                              ? const Color(0xFF161616)
                              : Colors.white,
                          items: allCategories.map((cat) {
                            final catLabel = cat == _allCategoryKey
                                ? 'filter_all'.tr
                                : cat.tr;
                            final isCurrent = _selectedCategoryFilter == cat;
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                catLabel,
                                style:
                                    GoogleFonts.spaceGrotesk(
                                      fontSize: 11.5,
                                      fontWeight: isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? AppColors.nothingRed
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                    ).copyWith(
                                      fontFamilyFallback: [
                                        'Prompt',
                                        'sans-serif',
                                      ],
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
                  const SizedBox(width: 6),
                  NothingPill(
                    label: 'clear_filters'.tr,
                    color: isDark
                        ? AppColors.nothingRedLight
                        : AppColors.nothingRed,
                    textColor: isDark
                        ? AppColors.nothingRedLight
                        : AppColors.nothingRed,
                    showDot: true,
                    dotColor: isDark
                        ? AppColors.nothingRedLight
                        : AppColors.nothingRed,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedTypeFilter = null;
                        _filterOnlyWithdrawals = false;
                        _selectedCategoryFilter = _allCategoryKey;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Hero Telemetry Summary Header สไตล์ Nothing OS Diagnostic Card
  Widget _buildHeroTelemetryBento({
    required bool isDark,
    required NumberFormat currencyFmt,
    required double totalIncome,
    required double totalExpense,
    required double totalSavings,
    double totalSavingsDeposits = 0.0,
    required double netFlow,
    required int resultsCount,
    required bool isFilterActive,
  }) {
    final hasMetrics = totalIncome > 0 || totalExpense > 0 || totalSavings > 0 || totalSavingsDeposits > 0;
    final double totalVolume = totalIncome + totalExpense + (totalSavings > 0 ? totalSavings : 0);
    final double expenseRatio = totalVolume > 0
        ? (totalExpense / totalVolume)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: NothingCard(
        isGlass: true,
        showDotGrid: false,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Results count & Net Flow Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const NothingLedIndicator(
                      size: 6,
                      color: AppColors.nothingRed,
                    ),
                    const SizedBox(width: 8),
                    NothingDotText(
                      'FEED // $resultsCount ${resultsCount == 1 ? "ITEM" : "ITEMS"}',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF666666),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                // Net Flow Pill
                if (hasMetrics)
                  NothingPill(
                    label:
                        '${netFlow >= 0 ? '+' : ''}${currencyFmt.format(netFlow)}',
                    isDotMatrix: true,
                    showDot: true,
                    dotColor: netFlow >= 0
                        ? AppColors.incomeColor(isDark)
                        : AppColors.expenseColor(isDark),
                    color: (netFlow >= 0
                            ? AppColors.incomeColor(isDark)
                            : AppColors.expenseColor(isDark))
                        .withValues(alpha: isDark ? 0.16 : 0.10),
                    textColor: netFlow >= 0
                        ? AppColors.incomeColor(isDark)
                        : AppColors.expenseColor(isDark),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    fontSize: 11.5,
                  ),
              ],
            ),

            if (hasMetrics) ...[
              const SizedBox(height: 12),
              // Financial Pillar Metrics: Inflow, Outflow, Savings
              Row(
                children: [
                  // Inflow Pillar
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFLOW',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.incomeColor(isDark),
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '+${currencyFmt.format(totalIncome)}',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.incomeColor(isDark),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'OUTFLOW',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: AppColors.expenseColor(isDark),
                                ),
                              ),
                              const SizedBox(width: 4),
                              NothingLedIndicator(
                                size: 4,
                                color: AppColors.expenseColor(isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '-${currencyFmt.format(totalExpense)}',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.expenseColor(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Savings Pillar (if any savings transactions exist)
                  if (totalSavingsDeposits > 0 || totalSavings > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAVINGS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.savingsColor(isDark),
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currencyFmt.format(totalSavings),
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.savingsColor(isDark),
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

              // Micro Segmented Health Bar
              NothingSegmentedBar(
                segments: 20,
                progress: expenseRatio,
                activeColor: AppColors.nothingRed,
                height: 3.5,
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.only(top: 4, bottom: 84),
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
            // Date Section Header สไตล์ Nothing OS
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const NothingLedIndicator(
                        size: 5,
                        color: AppColors.nothingRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatGroupDate(firstDate).toUpperCase(),
                        style:
                            GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: isDark
                                  ? AppColors.nothingSubtext
                                  : const Color(0xFF777777),
                            ).copyWith(
                              fontFamilyFallback: ['Prompt', 'sans-serif'],
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text(
                          '+${currencyFmt.format(dayIncome)}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${currencyFmt.format(dayExpense)}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.nothingRed,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Nothing OS Transaction Items in this Group (Animated Stagger)
            ...groupItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return _buildTransactionCard(
                    item: item,
                    isDark: isDark,
                    currencyFmt: currencyFmt,
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 280),
                    delay: Duration(milliseconds: (idx * 30).clamp(0, 300)),
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: const Duration(milliseconds: 280),
                    delay: Duration(milliseconds: (idx * 30).clamp(0, 300)),
                    curve: Curves.easeOutCubic,
                  );
            }),
          ],
        );
      },
    );
  }

  /// 4. Card for each Transaction Item (matching dashboard_view RecentTransactionsCard)
  Widget _buildTransactionCard({
    required TransactionItem item,
    required bool isDark,
    required NumberFormat currencyFmt,
  }) {
    final icon = _getCategoryIcon(item.categoryName);

    Color amountColor;
    String prefix = '';
    String natureLabel = '';
    Color natureColor;

    final itemRed = AppColors.expenseColor(isDark);
    final itemIncome = AppColors.incomeColor(isDark);
    final itemSavings = AppColors.savingsColor(isDark);
    final itemWithdrawal = AppColors.withdrawalColor(isDark);

    if (item.isSavingsWithdrawal) {
      amountColor = itemWithdrawal;
      prefix = '+';
      natureLabel = 'savings_withdrawal'.tr;
      natureColor = itemWithdrawal;
    } else if (item.isIncome) {
      amountColor = itemIncome;
      prefix = '+';
      natureLabel = 'income'.tr;
      natureColor = itemIncome;
    } else if (item.isSavings) {
      amountColor = itemSavings;
      prefix = '';
      natureLabel = 'filter_savings'.tr;
      natureColor = itemSavings;
    } else {
      amountColor = itemRed;
      prefix = '-';
      natureLabel = item.isFixedCost ? 'fixed_cost'.tr : 'variable_cost'.tr;
      natureColor = itemRed;
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
          color: itemRed.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: itemRed.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever_rounded, color: itemRed, size: 20),
            const SizedBox(width: 6),
            Text(
              'delete_transaction'.tr.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: itemRed,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.8,
              ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3.5),
        child: Material(
          color: isDark ? const Color(0xFF121212) : Colors.white,
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
                      ? AppColors.nothingBorder
                      : Colors.black.withValues(alpha: 0.08),
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
                          ? const Color(0xFF181818)
                          : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.nothingBorder
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: item.isSavingsWithdrawal
                          ? itemWithdrawal
                          : (item.isExpense
                                ? itemRed
                                : (item.isSavings
                                      ? itemSavings
                                      : itemIncome)),
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
                          style:
                              GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ).copyWith(
                                fontFamilyFallback: ['Prompt', 'sans-serif'],
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
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: natureColor.withValues(
                                  alpha: isDark ? 0.14 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                natureLabel.toUpperCase(),
                                style:
                                    GoogleFonts.spaceGrotesk(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: natureColor,
                                    ).copyWith(
                                      fontFamilyFallback: [
                                        'Prompt',
                                        'sans-serif',
                                      ],
                                    ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Category Name & Note
                            Flexible(
                              child: Text(
                                '${item.categoryName.tr}${item.note != null && item.note!.trim().isNotEmpty && item.note != item.title ? " • ${item.note}" : ""}',
                                style:
                                    GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.nothingSubtext
                                          : const Color(0xFF777777),
                                    ).copyWith(
                                      fontFamilyFallback: [
                                        'Prompt',
                                        'sans-serif',
                                      ],
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
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10.5,
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

                  // Amount in ShareTechMono
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$prefix${currencyFmt.format(item.amount)}',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
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

  /// 5. Minimalist Nothing OS Empty State
  Widget _buildEmptyState(bool isDark, bool isFilterActive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nothingBorder
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              NothingDotText(
                (isFilterActive ? 'no_search_results'.tr : 'no_transactions'.tr)
                    .toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : Colors.black,
                ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
              ),
              if (isFilterActive) ...[
                const SizedBox(height: 6),
                Text(
                  'no_search_results_desc'.tr,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.nothingSubtext
                        : const Color(0xFF777777),
                  ).copyWith(fontFamilyFallback: ['Prompt', 'sans-serif']),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                NothingPill(
                  label: 'clear_filters'.tr,
                  color: AppColors.nothingRed,
                  showDot: true,
                  dotColor: AppColors.nothingRed,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _selectedTypeFilter = null;
                      _selectedCategoryFilter = _allCategoryKey;
                    });
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                NothingPill(
                  label: 'add_first_transaction'.tr,
                  isSelected: true,
                  selectedColor: AppColors.nothingRed,
                  prefixIcon: const Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    QuickAddBottomSheet.show(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
