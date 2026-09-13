import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/budget_plan_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../widgets/app_feedback.dart';

/// GetX Reactive Controller สำหรับจัดการ State การเงินทั้งระบบ
class DashboardController extends GetxController with WidgetsBindingObserver {
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
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxBool isDarkMode = false.obs;
  final RxString languageMode = 'system'.obs; // 'system', 'th', 'en'
  final RxString currentLanguage = 'th'.obs;
  final RxString userName = ''.obs;
  final RxInt selectedChartIndex = 0.obs; // 0: Spline Area Chart, 1: Donut Chart
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isBalanceHidden = false.obs;
  final FocusNode keyboardFocusNode = FocusNode();

  bool get isEnglish => currentLanguage.value == 'en';

  void toggleBalanceHidden() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    isBalanceHidden.toggle();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    keyboardFocusNode.dispose();
    super.onClose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    if (languageMode.value == 'system') {
      _applySystemLocale();
    }
  }

  Future<void> _loadData() async {
    try {
      final isInit = await _storageService.isInitialized();
      final savedPlan = await _storageService.loadBudgetPlan();
      if (savedPlan != null) {
        budgetPlan.value = savedPlan;
      }

      final savedTransactions = await _storageService.loadTransactions();
      if (savedTransactions != null) {
        transactions.assignAll(savedTransactions);
      } else {
        transactions.clear();
      }

      final savedTheme = await _storageService.loadThemeMode();
      if (savedTheme == 'dark') {
        themeMode.value = ThemeMode.dark;
        isDarkMode.value = true;
        Get.changeThemeMode(ThemeMode.dark);
      } else if (savedTheme == 'light') {
        themeMode.value = ThemeMode.light;
        isDarkMode.value = false;
        Get.changeThemeMode(ThemeMode.light);
      } else {
        themeMode.value = ThemeMode.system;
        isDarkMode.value = false;
        Get.changeThemeMode(ThemeMode.system);
      }

      final savedLang = await _storageService.loadLanguage();
      if (savedLang == 'en' || savedLang == 'th') {
        final lang = savedLang!;
        languageMode.value = lang;
        currentLanguage.value = lang;
        _safeUpdateLocale(lang == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'));
      } else {
        languageMode.value = 'system';
        _applySystemLocale();
      }

      final savedUserName = await _storageService.loadUserName();
      if (savedUserName != null && savedUserName.isNotEmpty) {
        userName.value = savedUserName;
      }

      if (!isInit) {
        await _storageService.saveTransactions(transactions);
        await _storageService.saveBudgetPlan(budgetPlan.value);
        await _storageService.setInitialized();
      }
    } catch (_) {}
  }

  void setUserName(String name) {
    userName.value = name.trim();
    _storageService.saveUserName(name.trim());
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
    final plan = budgetPlan.value;

    if (currentPeriod.value == TimeFilterPeriod.yearly) {
      final isCurrentYear = date.year == now.year;
      final monthsCount = isCurrentYear ? now.month : (date.isBefore(now) ? 12 : 1);
      final daysCount = isCurrentYear
          ? now.difference(DateTime(now.year, 1, 1)).inDays + 1
          : (date.isBefore(now) ? (DateTime(date.year, 12, 31).difference(DateTime(date.year, 1, 1)).inDays + 1) : 1);

      return (plan.plannedIncome * monthsCount) -
          (plan.plannedFixedCosts * monthsCount) -
          (daysCount * plan.targetDailyAllowance) -
          (plan.targetMonthlySavings * monthsCount);
    } else if (currentPeriod.value == TimeFilterPeriod.allTime) {
      if (transactions.isEmpty) return 0.0;
      final sorted = transactions.map((t) => t.date).toList()..sort();
      final earliest = sorted.first;
      final monthsDiff = ((now.year - earliest.year) * 12 + now.month - earliest.month + 1).clamp(1, 120);
      return (plan.plannedIncome * monthsDiff) -
          (plan.plannedFixedCosts * monthsDiff) -
          (plan.targetDailyAllowance * 30 * monthsDiff) -
          (plan.targetMonthlySavings * monthsDiff);
    }

    int currentDay = (date.year == now.year && date.month == now.month)
        ? now.day
        : (date.isBefore(now) ? daysInCurrentMonth : 1);

    return plan.plannedIncome -
        plan.plannedFixedCosts -
        (currentDay * plan.targetDailyAllowance) -
        plan.targetMonthlySavings;
  }

  double get surplusOrDeficit => actualBalance - expectedBalance;

  bool get isSurplus => surplusOrDeficit >= 0;

  /// จำนวนวันที่เหลืออยู่ในเดือนปัจจุบันหลังจาก "วันนี้" (ไม่รวมวันนี้แล้ว)
  int get remainingDaysInMonth {
    final date = selectedDate.value;
    final now = DateTime.now();
    final totalDays = daysInCurrentMonth;
    final isCurrentMonth = (date.year == now.year && date.month == now.month);
    if (!isCurrentMonth) {
      if (date.isBefore(DateTime(now.year, now.month, 1))) {
        return 0; // เดือนในอดีต สิ้นสุดรอบแล้ว
      } else {
        return totalDays; // เดือนในอนาคต
      }
    }
    // ไม่รวมวันนี้ (ลบวันนี้ไปแล้ว): เช่น เดือนมี 30 วัน วันนี้วันที่ 10 -> เหลืออีก 30 - 10 = 20 วัน
    return (totalDays - now.day).clamp(0, totalDays);
  }

  /// ยอดค่าใช้จ่ายผันแปร (กินอยู่/ช้อปปิ้ง/รายวัน) เฉพาะของ "วันนี้"
  double get todayVariableExpenses {
    final now = DateTime.now();
    return transactions.where((t) {
      return t.isVariableCost &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// โควตาคงเหลือเฉพาะของ "วันนี้" (เป้าหมายต่อวัน - ยอดกินใช้วันนี้)
  double get todayRemainingAllowance {
    final target = budgetPlan.value.targetDailyAllowance;
    return target - todayVariableExpenses;
  }

  /// สัดส่วนการใช้โควตาของวันนี้ (0.0 ถึง 1.0+)
  double get todayUsageProgress {
    final target = budgetPlan.value.targetDailyAllowance;
    if (target <= 0) return 0.0;
    return (todayVariableExpenses / target).clamp(0.0, 2.0);
  }

  /// โควตาเฉลี่ยต่อวันสำหรับวันที่เหลือของเดือน (หลังจากหักวันนี้ออกไปแล้ว)
  double get remainingDailyAllowance {
    final remainingDays = remainingDaysInMonth;
    if (remainingDays <= 0) return 0.0;

    final totalDays = daysInCurrentMonth;
    final plan = budgetPlan.value;
    final totalPlannedVariable = plan.plannedVariableBudget(totalDays);

    // หักค่าใช้จ่ายที่เกิดขึ้นแล้วทั้งหมด และกันโควตาคงเหลือของวันนี้ไว้ให้วันนี้ (ถ้าวันนี้ยังใช้ไม่หมด)
    final reservedForToday = todayRemainingAllowance > 0 ? todayRemainingAllowance : 0.0;
    final futureBudget = totalPlannedVariable - totalVariableExpenses - reservedForToday;

    if (futureBudget <= 0) return 0.0;
    return (futureBudget / remainingDays).clamp(0.0, 999999.0);
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

  void addTransaction(TransactionItem item, {bool notify = false}) {
    transactions.add(item);
    _storageService.saveTransactions(transactions);

    if (notify && Get.context != null) {
      AppFeedback.showSuccess(
        title: 'save_success_title'.tr,
        message: 'save_success_msg'.trParams({'title': item.title}),
        amount: item.amount,
        transactionType: item.type,
      );
    }
  }

  void updateTransaction(TransactionItem item, {bool notify = false}) {
    final index = transactions.indexWhere((t) => t.id == item.id);
    if (index != -1) {
      transactions[index] = item;
      _storageService.saveTransactions(transactions);

      if (notify && Get.context != null) {
        AppFeedback.showSuccess(
          title: 'update_success_title'.tr,
          message: 'update_success_msg'.trParams({'title': item.title}),
          amount: item.amount,
          transactionType: item.type,
        );
      }
    }
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((item) => item.id == id);
    _storageService.saveTransactions(transactions);
  }

  Future<void> clearAllToEmpty() async {
    transactions.clear();
    await _storageService.clearAllData(keepInitialized: true);
    if (Get.context != null) {
      AppFeedback.showSuccess(
        title: 'clear_all_data_title'.tr,
        message: 'clear_all_data_desc'.tr,
      );
    }
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

  void resetToCurrentPeriod() {
    selectedDate.value = DateTime.now();
  }

  bool get isCurrentPeriod {
    final now = DateTime.now();
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      return selectedDate.value.year == now.year && selectedDate.value.month == now.month;
    } else if (currentPeriod.value == TimeFilterPeriod.yearly) {
      return selectedDate.value.year == now.year;
    }
    return true;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    isDarkMode.value = (mode == ThemeMode.dark);
    Get.changeThemeMode(mode);
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    _storageService.saveThemeMode(modeStr);
  }

  void toggleTheme() {
    final currentlyDark = (themeMode.value == ThemeMode.dark) ||
        (themeMode.value == ThemeMode.system && (Get.isDarkMode || isDarkMode.value));
    if (currentlyDark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  String get themeModeName {
    switch (themeMode.value) {
      case ThemeMode.system:
        return 'theme_system'.tr;
      case ThemeMode.light:
        return 'theme_light'.tr;
      case ThemeMode.dark:
        return 'theme_dark'.tr;
    }
  }

  static const List<String> thaiMonthNames = [
    '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  static const List<String> englishMonthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> thaiMonthShortNames = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  static const List<String> englishMonthShortNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get formattedPeriodTitle {
    final date = selectedDate.value;
    final period = currentPeriod.value;
    final isEn = isEnglish;

    switch (period) {
      case TimeFilterPeriod.monthly:
        if (isEn) {
          return '${englishMonthNames[date.month]} ${date.year}';
        } else {
          return '${thaiMonthNames[date.month]} ${date.year + 543}';
        }
      case TimeFilterPeriod.yearly:
        if (isEn) {
          return 'Year ${date.year}';
        } else {
          return 'ปี พ.ศ. ${date.year + 543}';
        }
      case TimeFilterPeriod.allTime:
        return 'period_all_time'.tr;
    }
  }

  void _safeUpdateLocale(Locale locale) {
    Get.locale = locale;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest && Get.key.currentState != null) {
      try {
        Get.updateLocale(locale);
      } catch (_) {}
    }
  }

  void _applySystemLocale() {
    try {
      final sysLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      final activeLang = sysLang == 'th' ? 'th' : 'en';
      currentLanguage.value = activeLang;
      _safeUpdateLocale(activeLang == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'));
    } catch (_) {
      currentLanguage.value = 'th';
      _safeUpdateLocale(const Locale('th', 'TH'));
    }
  }

  void setLanguage(String langCode) {
    if (langCode != 'en' && langCode != 'th') return;
    languageMode.value = langCode;
    currentLanguage.value = langCode;
    _safeUpdateLocale(langCode == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'));
    _storageService.saveLanguage(langCode);
  }

  void toggleLanguage() {
    setLanguage(currentLanguage.value == 'en' ? 'th' : 'en');
  }

  String get currentLanguageName => currentLanguage.value == 'en' ? 'English' : 'ภาษาไทย';

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
    budgetPlan.value = const BudgetPlan(
      plannedIncome: 45000.0,
      targetDailyAllowance: 350.0,
      targetMonthlySavings: 10000.0,
      plannedFixedCosts: 12500.0,
    );
    await _storageService.saveTransactions(transactions);
    await _storageService.saveBudgetPlan(budgetPlan.value);
  }
}
