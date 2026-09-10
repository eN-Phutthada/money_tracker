import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../widgets/modern_app_bar.dart';
import 'quick_add_bottom_sheet.dart';

/// หน้าจอประวัติรายการธุรกรรมทั้งหมด (Full Transaction History with Search & Filter)
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
    if (category.contains('อาหาร') || category.contains('ของกิน')) return Icons.fastfood_rounded;
    if (category.contains('กาแฟ') || category.contains('เครื่องดื่ม')) return Icons.local_cafe_rounded;
    if (category.contains('เดินทาง') || category.contains('รถ')) return Icons.directions_subway_rounded;
    if (category.contains('ช้อปปิ้ง')) return Icons.shopping_bag_rounded;
    if (category.contains('ของใช้')) return Icons.inventory_2_rounded;
    if (category.contains('ที่อยู่อาศัย') || category.contains('คอนโด')) return Icons.home_rounded;
    if (category.contains('สาธารณูปโภค') || category.contains('น้ำ') || category.contains('ไฟ')) return Icons.flash_on_rounded;
    if (category.contains('สื่อสาร') || category.contains('เน็ต')) return Icons.wifi_rounded;
    if (category.contains('เงินเดือน')) return Icons.account_balance_wallet_rounded;
    if (category.contains('ออม') || category.contains('DCA') || category.contains('กองทุน')) return Icons.savings_rounded;
    if (category.contains('ประกัน') || category.contains('สุขภาพ')) return Icons.health_and_safety_rounded;
    return Icons.receipt_long_rounded;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'today'.tr;
    if (target == today.subtract(const Duration(days: 1))) return 'yesterday'.tr;

    if (controller.isEnglish) {
      const monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthsEn[date.month]} ${date.day}, ${date.year}';
    }

    const months = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${date.day} ${months[date.month]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 2);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'all_transactions'.tr,
        subtitle: 'transactions_subtitle'.tr,
        badgeWidget: Obx(() {
          final count = controller.transactions.length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddBottomSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('add_transaction'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Obx(() {
              // Get all transactions sorted by date descending
              var list = controller.transactions.toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              // Filter by Search
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                list = list.where((t) {
                  return t.title.toLowerCase().contains(q) ||
                      t.categoryName.toLowerCase().contains(q) ||
                      (t.note != null && t.note!.toLowerCase().contains(q));
                }).toList();
              }

              // Filter by Type
              if (_selectedTypeFilter != null) {
                list = list.where((t) => t.type == _selectedTypeFilter).toList();
              }

              // Filter by Category
              if (_selectedCategoryFilter != 'ทั้งหมด') {
                list = list.where((t) => t.categoryName == _selectedCategoryFilter).toList();
              }

              // Calculate summary of filtered list
              final totalExpense = list.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
              final totalIncome = list.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
              final totalSavings = list.where((t) => t.isSavings).fold(0.0, (sum, t) => sum + t.amount);

              // Extract all categories for category filter dropdown
              final allCategories = {'ทั้งหมด', ...controller.transactions.map((t) => t.categoryName)};

              // Group items by date string
              final Map<String, List<TransactionItem>> grouped = {};
              for (final item in list) {
                final dateKey = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
                grouped.putIfAbsent(dateKey, () => []).add(item);
              }

              return Column(
                children: [
                  // 1. Search Bar & Filter Chips (Modern Header Controls)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Box
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'search_transactions_hint'.tr,
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _searchQuery.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: isDark ? AppColors.darkBackground : AppColors.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filter Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildTypeFilterChip('filter_all'.tr, null, isDark),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('filter_expense'.tr, TransactionType.expense, isDark),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('filter_income'.tr, TransactionType.income, isDark),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('filter_savings_dca'.tr, TransactionType.savingsInvestment, isDark),
                              const SizedBox(width: 10),
                              // Category Dropdown Filter
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedCategoryFilter != 'ทั้งหมด'
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 13,
                                      color: _selectedCategoryFilter != 'ทั้งหมด' ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: allCategories.contains(_selectedCategoryFilter) ? _selectedCategoryFilter : 'ทั้งหมด',
                                        isDense: true,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedCategoryFilter != 'ทั้งหมด'
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                        ),
                                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                                        items: allCategories.map((cat) {
                                          final catLabel = cat == 'ทั้งหมด' ? 'filter_all'.tr : cat.tr;
                                          return DropdownMenuItem<String>(
                                            value: cat,
                                            child: Text(catLabel),
                                          );
                                        }).toList(),
                                        onChanged: (cat) {
                                          if (cat != null) setState(() => _selectedCategoryFilter = cat);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_searchQuery.isNotEmpty || _selectedTypeFilter != null || _selectedCategoryFilter != 'ทั้งหมด') ...[
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.deficitText.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.deficitText.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.refresh_rounded, size: 13, color: AppColors.deficitText),
                                        const SizedBox(width: 4),
                                        Text(
                                          'clear_filters'.tr,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.deficitText),
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
                  ),

                  // 2. Summary Mini-Card (Modern Status Bar)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6) : AppColors.surfaceSecondary.withValues(alpha: 0.7),
                      border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'results_count'.trParams({'count': '${list.length}'}),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (totalIncome > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${currencyFmt.format(totalIncome)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (totalExpense > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.deficitText.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${currencyFmt.format(totalExpense)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deficitText),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (totalSavings > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currencyFmt.format(totalSavings),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Transactions List
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'no_search_results'.tr,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'no_search_results_desc'.tr,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: grouped.length,
                            itemBuilder: (context, groupIndex) {
                              final dateKey = grouped.keys.elementAt(groupIndex);
                              final groupItems = grouped[dateKey]!;
                              final firstDate = groupItems.first.date;

                              final dayExpense = groupItems.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
                              final dayIncome = groupItems.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Date Group Header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatGroupDate(firstDate),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                                        ),
                                        Row(
                                          children: [
                                            if (dayIncome > 0)
                                              Text(
                                                '+${currencyFmt.format(dayIncome)}  ',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                              ),
                                            if (dayExpense > 0)
                                              Text(
                                                '-${currencyFmt.format(dayExpense)}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deficitText),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Transaction Cards in this group
                                  ...groupItems.map((item) {
                                    final icon = _getCategoryIcon(item.categoryName);
                                    Color amountColor;
                                    String prefix = '';
                                    if (item.isIncome) {
                                      amountColor = AppColors.primary;
                                      prefix = '+';
                                    } else if (item.isSavings) {
                                      amountColor = AppColors.accent;
                                      prefix = '';
                                    } else {
                                      amountColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
                                      prefix = '-';
                                    }

                                    return Dismissible(
                                      key: Key('all_${item.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        color: AppColors.deficitText.withValues(alpha: 0.15),
                                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.deficitText),
                                      ),
                                      onDismissed: (_) {
                                        controller.deleteTransaction(item.id);
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          QuickAddBottomSheet.show(context, existingItem: item);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: amountColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(icon, color: amountColor, size: 20),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title.tr,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${item.categoryName.tr}${item.isFixedCost ? " (Fixed)" : ""}${item.note != null && item.note != item.title ? " • ${item.note}" : ""}',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '$prefix${currencyFmt.format(item.amount)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: amountColor,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, TransactionType? type, bool isDark) {
    final isSelected = _selectedTypeFilter == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTypeFilter = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
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
                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
