import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/budget_plan_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/storage_service.dart';

/// GetX Reactive Controller สำหรับจัดการ State การเงินทั้งระบบ
class DashboardController extends GetxController {
  final StorageService _storageService = StorageService();

  // Reactive State
  final RxList<TransactionItem> transactions = <TransactionItem>[].obs;
  final Rx<BudgetPlan> budgetPlan = const BudgetPlan(
    plannedIncome: 45000.0,
    targetDailyAllowance: 350.0,
    targetMonthlySavings: 10000.0,
    plannedFixedCosts: 12500.0,
  ).obs;

  final Rx<TimeFilterPeriod> currentPeriod = TimeFilterPeriod.monthly.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isDarkMode = false.obs;
  final RxInt selectedChartIndex = 0.obs; // 0: Spline Area Chart, 1: Donut Chart
  final RxBool isSidebarCollapsed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final savedPlan = await _storageService.loadBudgetPlan();
      if (savedPlan != null) {
        budgetPlan.value = savedPlan;
      }

      final savedTransactions = await _storageService.loadTransactions();
      if (savedTransactions != null && savedTransactions.isNotEmpty) {
        transactions.assignAll(savedTransactions);
      } else {
        _seedInitialData();
        await _storageService.saveTransactions(transactions);
        await _storageService.saveBudgetPlan(budgetPlan.value);
      }
    } catch (_) {}
  }

  // ==========================================
  // COMPUTED PROPERTIES (REACTIVE GETTERS)
  // ==========================================

  List<TransactionItem> get filteredTransactions {
    final list = transactions.where((item) {
      switch (currentPeriod.value) {
        case TimeFilterPeriod.monthly:
          return item.date.year == selectedDate.value.year &&
              item.date.month == selectedDate.value.month;
        case TimeFilterPeriod.yearly:
          return item.date.year == selectedDate.value.year;
        case TimeFilterPeriod.allTime:
          return true;
      }
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get actualIncome => filteredTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get actualExpenses => filteredTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get actualSavings => filteredTransactions
      .where((t) => t.isSavings)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalFixedExpenses => filteredTransactions
      .where((t) => t.isFixedCost)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalVariableExpenses => filteredTransactions
      .where((t) => t.isVariableCost)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get actualBalance => actualIncome - actualExpenses - actualSavings;

  int get daysInCurrentMonth {
    final date = selectedDate.value;
    return DateTime(date.year, date.month + 1, 0).day;
  }

  double get expectedBalance {
    final date = selectedDate.value;
    final now = DateTime.now();
    int currentDay = (date.year == now.year && date.month == now.month)
        ? now.day
        : (date.isBefore(now) ? daysInCurrentMonth : 1);

    final plan = budgetPlan.value;
    return plan.plannedIncome -
        plan.plannedFixedCosts -
        (currentDay * plan.targetDailyAllowance) -
        plan.targetMonthlySavings;
  }

  double get surplusOrDeficit => actualBalance - expectedBalance;

  bool get isSurplus => surplusOrDeficit >= 0;

  double get remainingDailyAllowance {
    final date = selectedDate.value;
    final now = DateTime.now();
    final totalDays = daysInCurrentMonth;
    final isCurrentMonth = (date.year == now.year && date.month == now.month);
    final currentDay = isCurrentMonth ? now.day : (date.isBefore(now) ? totalDays : 1);
    final remainingDays = (totalDays - currentDay + 1).clamp(1, totalDays);

    final plan = budgetPlan.value;
    final totalPlannedVariable = plan.plannedVariableBudget(totalDays);
    final remainingBudget = totalPlannedVariable - totalVariableExpenses;

    if (remainingBudget <= 0) return 0.0;
    return (remainingBudget / remainingDays).clamp(0.0, 999999.0);
  }

  // ==========================================
  // DATA FOR FL_CHART
  // ==========================================

  List<Map<String, dynamic>> get trailing6MonthsData {
    final now = selectedDate.value;
    final result = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthTransactions = transactions.where((t) {
        return t.date.year == targetDate.year && t.date.month == targetDate.month;
      }).toList();

      final income = monthTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
      final savings = monthTransactions.where((t) => t.isSavings).fold(0.0, (sum, t) => sum + t.amount);
      final net = income - expense - savings;

      result.add({
        'month': '${targetDate.month}/${(targetDate.year + 543) % 100}',
        'net': net,
        'income': income,
        'expense': expense,
        'savings': savings,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get categoryBreakdown {
    final expenseMap = <String, double>{};
    for (final t in filteredTransactions.where((item) => item.isExpense)) {
      expenseMap[t.categoryName] = (expenseMap[t.categoryName] ?? 0) + t.amount;
    }

    final total = actualExpenses > 0 ? actualExpenses : 1.0;
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];

    int index = 0;
    return expenseMap.entries.map((e) {
      final percentage = (e.value / total) * 100;
      final color = colors[index % colors.length];
      index++;
      return {
        'name': e.key,
        'amount': e.value,
        'percentage': percentage,
        'color': color,
      };
    }).toList();
  }

  // ==========================================
  // ACTIONS
  // ==========================================

  void addTransaction(TransactionItem item) {
    transactions.add(item);
    _storageService.saveTransactions(transactions);

    Get.snackbar(
      'บันทึกสำเร็จ',
      'เพิ่ม "${item.title}" เรียบร้อยแล้ว',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((item) => item.id == id);
    _storageService.saveTransactions(transactions);
  }

  void updateBudgetPlan(BudgetPlan plan) {
    budgetPlan.value = plan;
    _storageService.saveBudgetPlan(plan);
  }

  void setTimeFilter(TimeFilterPeriod period) {
    currentPeriod.value = period;
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  void previousPeriod() {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      selectedDate.value = DateTime(selectedDate.value.year, selectedDate.value.month - 1);
    } else if (currentPeriod.value == TimeFilterPeriod.yearly) {
      selectedDate.value = DateTime(selectedDate.value.year - 1);
    }
  }

  void nextPeriod() {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      selectedDate.value = DateTime(selectedDate.value.year, selectedDate.value.month + 1);
    } else if (currentPeriod.value == TimeFilterPeriod.yearly) {
      selectedDate.value = DateTime(selectedDate.value.year + 1);
    }
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> importTransactions(List<TransactionItem> items) async {
    final existingIds = transactions.map((t) => t.id).toSet();
    for (final item in items) {
      if (!existingIds.contains(item.id)) {
        transactions.add(item);
        existingIds.add(item.id);
      }
    }
    await _storageService.saveTransactions(transactions);
  }

  Future<void> replaceAllTransactions(List<TransactionItem> items) async {
    transactions.assignAll(items);
    await _storageService.saveTransactions(transactions);
  }

  Future<void> resetToDefault() async {
    transactions.clear();
    _seedInitialData();
    budgetPlan.value = const BudgetPlan(
      plannedIncome: 45000.0,
      targetDailyAllowance: 350.0,
      targetMonthlySavings: 10000.0,
      plannedFixedCosts: 12500.0,
    );
    await _storageService.saveTransactions(transactions);
    await _storageService.saveBudgetPlan(budgetPlan.value);
  }

  void _seedInitialData() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    transactions.assignAll([
      TransactionItem(
        id: '1',
        title: 'เงินเดือนประจำ (Software Engineer)',
        amount: 45000.0,
        type: TransactionType.income,
        costNature: CostNature.notApplicable,
        categoryName: 'เงินเดือน',
        date: DateTime(year, month, 1),
      ),
      TransactionItem(
        id: '2',
        title: 'รับงานฟรีแลนซ์ Mobile UI',
        amount: 8500.0,
        type: TransactionType.income,
        costNature: CostNature.notApplicable,
        categoryName: 'ฟรีแลนซ์',
        date: DateTime(year, month, 3),
      ),
      TransactionItem(
        id: '3',
        title: 'ค่าเช่าคอนโดมิเนียม',
        amount: 9500.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ที่อยู่อาศัย',
        date: DateTime(year, month, 2),
      ),
      TransactionItem(
        id: '4',
        title: 'ค่าน้ำประปา & ค่าไฟฟ้าส่วนกลาง',
        amount: 1200.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'สาธารณูปโภค',
        date: DateTime(year, month, 3),
      ),
      TransactionItem(
        id: '5',
        title: 'ค่าแพ็กเกจอินเทอร์เน็ต Fiber & 5G',
        amount: 799.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'การสื่อสาร',
        date: DateTime(year, month, 4),
      ),
      TransactionItem(
        id: '6',
        title: 'เบี้ยประกันชีวิตและสุขภาพ',
        amount: 1800.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ประกันสุขภาพ',
        date: DateTime(year, month, 5),
      ),
      TransactionItem(
        id: '7',
        title: 'ออมกองทุนดัชนี S&P500 (DCA)',
        amount: 7000.0,
        type: TransactionType.savingsInvestment,
        costNature: CostNature.notApplicable,
        categoryName: 'กองทุนรวม',
        date: DateTime(year, month, 2),
      ),
      TransactionItem(
        id: '8',
        title: 'บัญชีเงินฝากดอกเบี้ยสูง e-Savings',
        amount: 3000.0,
        type: TransactionType.savingsInvestment,
        costNature: CostNature.notApplicable,
        categoryName: 'เงินสำรองฉุกเฉิน',
        date: DateTime(year, month, 2),
      ),
      TransactionItem(
        id: '9',
        title: 'วัตถุดิบทำอาหาร & ตลาดสด',
        amount: 680.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime(year, month, 6),
      ),
      TransactionItem(
        id: '10',
        title: 'ทานข้าวนอกบ้าน & กาแฟ Speciality',
        amount: 290.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime(year, month, 7),
      ),
      TransactionItem(
        id: '11',
        title: 'ของใช้ในบ้าน / ซูเปอร์มาร์เก็ต',
        amount: 450.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'ของใช้ส่วนตัว',
        date: DateTime(year, month, 8),
      ),
    ]);
  }
}
