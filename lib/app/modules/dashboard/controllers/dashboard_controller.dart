import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/budget_plan_model.dart';
import '../../../data/models/scheduled_payment_model.dart';
import '../../../data/models/scheduled_payment_preset.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_health_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_feedback.dart';

/// GetX Reactive Controller สำหรับจัดการ State การเงินทั้งระบบ
class DashboardController extends GetxController with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();

  // Reactive State
  final RxList<TransactionItem> transactions = <TransactionItem>[].obs;
  final RxList<ScheduledPaymentItem> scheduledPayments =
      <ScheduledPaymentItem>[].obs;
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
  final RxInt selectedChartIndex =
      0.obs; // 0: Spline Area Chart, 1: Donut Chart
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

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (themeMode.value == ThemeMode.system) {
      try {
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        isDarkMode.value = (platformBrightness == Brightness.dark);
      } catch (_) {}
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

      final savedScheduled = await _storageService.loadScheduledPayments();
      if (savedScheduled != null) {
        scheduledPayments.assignAll(savedScheduled);
      } else {
        scheduledPayments.clear();
      }
      processDueAutoPayments();

      // Requirement: การเข้าแอพทุกครั้งระบบธีมจะตามระบบ (Default to System Theme on every launch)
      themeMode.value = ThemeMode.system;
      try {
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        isDarkMode.value = (platformBrightness == Brightness.dark);
      } catch (_) {
        isDarkMode.value = false;
      }
      Get.changeThemeMode(ThemeMode.system);

      final savedLang = await _storageService.loadLanguage();
      if (savedLang == 'en' || savedLang == 'th') {
        final lang = savedLang!;
        languageMode.value = lang;
        currentLanguage.value = lang;
        _safeUpdateLocale(
          lang == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'),
        );
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

  /// ยอดถอนเงินออมในรอบเวลาปัจจุบัน
  double get actualSavingsWithdrawals => filteredTransactions
      .where((t) => t.isSavingsWithdrawal)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// ยอดเงินออมสุทธิในรอบเวลาปัจจุบัน (ออมเข้า - ถอนออก)
  double get netSavings => actualSavings - actualSavingsWithdrawals;

  /// ยอดเงินออมสะสมสุทธิทั้งหมด (ออมเข้าสะสมทั้งหมด - ถอนออกสะสมทั้งหมด)
  double get totalNetSavings {
    double saved = 0;
    double withdrawn = 0;
    for (final t in transactions) {
      if (t.isSavings) {
        saved += t.amount;
      } else if (t.isSavingsWithdrawal) {
        withdrawn += t.amount;
      }
    }
    return saved - withdrawn;
  }

  double get totalFixedExpenses => filteredTransactions
      .where((t) => t.isFixedCost)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalVariableExpenses => filteredTransactions
      .where((t) => t.isVariableCost)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get actualBalance => actualIncome - actualExpenses - actualSavings;

  /// ยอดเงินคงเหลือสะสมสุทธิทั้งหมด (All-time net current balance: รายรับสะสมทั้งหมด - รายจ่ายทั้งหมด - เงินออมทั้งหมด ณ ปัจจุบัน)
  double get totalCurrentBalance {
    double income = 0;
    double expense = 0;
    double savings = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else if (t.isExpense) {
        expense += t.amount;
      } else if (t.isSavings) {
        savings += t.amount;
      }
    }
    return income - expense - savings;
  }

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
      final monthsCount = isCurrentYear
          ? now.month
          : (date.isBefore(now) ? 12 : 1);
      final daysCount = isCurrentYear
          ? now.difference(DateTime(now.year, 1, 1)).inDays + 1
          : (date.isBefore(now)
                ? (DateTime(
                        date.year,
                        12,
                        31,
                      ).difference(DateTime(date.year, 1, 1)).inDays +
                      1)
                : 1);

      return (plan.plannedIncome * monthsCount) -
          (plan.plannedFixedCosts * monthsCount) -
          (daysCount * plan.targetDailyAllowance) -
          (plan.targetMonthlySavings * monthsCount);
    } else if (currentPeriod.value == TimeFilterPeriod.allTime) {
      if (transactions.isEmpty) return 0.0;
      final sorted = transactions.map((t) => t.date).toList()..sort();
      final earliest = sorted.first;
      final monthsDiff =
          ((now.year - earliest.year) * 12 + now.month - earliest.month + 1)
              .clamp(1, 120);
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

  /// วันปัจจุบันในรอบเวลาที่เลือก (ถ้าเป็นเดือนปัจจุบันคือ today.day, ถ้าเป็นเดือนอดีตคือวันสิ้นเดือน, ถ้าเดือนอนาคตคือ 1)
  int get currentDayInPeriod {
    final now = DateTime.now();
    final date = selectedDate.value;
    final isCurrent = (date.year == now.year && date.month == now.month);
    if (isCurrent) return now.day;
    if (date.isBefore(DateTime(now.year, now.month, 1))) {
      return daysInCurrentMonth;
    }
    return 1;
  }

  /// สัดส่วนเวลาที่ผ่านไปในเดือนนี้ (0.0 ถึง 1.0)
  double get monthElapsedRatio {
    final totalDays = daysInCurrentMonth;
    if (totalDays <= 0) return 0.0;
    return (currentDayInPeriod / totalDays).clamp(0.0, 1.0);
  }

  /// งบค่ากิน/ผันแปรตามแผนสะสมถึงวันปัจจุบัน (วันปัจจุบัน * โควตารายวัน)
  double get plannedVariableBudgetToDate =>
      currentDayInPeriod * budgetPlan.value.targetDailyAllowance;

  /// ผลต่างการใช้จ่ายผันแปรเทียบกับแผนสะสมถึงวันนี้ (งบตามแผนถึงวันนี้ - ที่ใช้ไปจริง)
  /// ค่าเป็นบวก = ประหยัดกว่าแผน (Under budget), ค่าติดลบ = ใช้เกินแผน (Over budget)
  double get variableSpendingVarianceToDate =>
      plannedVariableBudgetToDate - totalVariableExpenses;

  /// สถานะการใช้จ่ายผันแปรอยู่ในเกณฑ์แผนสะสมหรือไม่
  bool get isVariableSpendingOnTrack => variableSpendingVarianceToDate >= 0;

  /// รวมค่าใช้จ่ายคงที่ + ค่ากินทั้งเดือนตามโควตารายวัน (+ เป้าหมายเงินออม)
  double get monthlyTotalPlannedExpenses =>
      budgetPlan.value.plannedFixedCosts +
      (daysInCurrentMonth * budgetPlan.value.targetDailyAllowance) +
      budgetPlan.value.targetMonthlySavings;

  /// ภาระค่าใช้จ่ายที่ต้องสำรองจ่ายในเดือนนี้ (ค่าใช้จ่ายคงที่ที่ยังค้างจ่าย + ค่ากินวันที่เหลือตามโควตา)
  double get monthlyRemainingCommitments =>
      remainingMonthlyFixedCosts +
      (remainingDaysInMonth * budgetPlan.value.targetDailyAllowance);

  /// ตัวเลขยอดเงินหลักที่แสดงบนบัตรสถานะกระเป๋าเงินตามช่วงเวลาที่เลือก
  /// - รายเดือน: แสดง "เงินเหลือปัจจุบัน" (totalCurrentBalance)
  /// - รายปี: แสดงยอดกระแสเงินสดสุทธิของปีนี้ (actualBalance)
  /// - ทั้งหมด: แสดงยอดเงินคงเหลือสะสมสุทธิทั้งหมด (totalCurrentBalance)
  double get periodHeroBalance {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      return totalCurrentBalance;
    } else if (currentPeriod.value == TimeFilterPeriod.allTime) {
      return totalCurrentBalance;
    }
    return actualBalance;
  }

  /// ส่วนต่าง (Surplus หรือ Deficit) คำนวณสัมพันธ์กับวันปัจจุบัน
  double get surplusOrDeficit {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      if (actualIncome > 0) {
        return actualBalance - expectedBalance;
      }
      return totalCurrentBalance - monthlyRemainingCommitments;
    }
    return actualBalance - expectedBalance;
  }

  /// สถานะกระเป๋าเงินปลอดภัย (เขียว) หรือเกินงบ/ระวัง (แดง)
  bool get isSurplus {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      // 1. ถ้ากระแสเงินสดเดือนนี้บวกอยู่แล้ว หรือบรรลุตามแผนสัมพันธ์กับวันปัจจุบัน
      if (actualBalance >= expectedBalance && actualBalance >= 0) {
        return true;
      }
      // 2. แม้เงินเดือนยังไม่ออก แต่ถ้าเงินในกระเป๋าปัจจุบัน >= ค่าคงที่ที่ค้าง + ค่ากินวันที่เหลือตามโควตา
      return totalCurrentBalance >= monthlyRemainingCommitments;
    }
    return surplusOrDeficit >= 0;
  }

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
    return transactions
        .where((t) {
          return t.isVariableCost &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
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
    final reservedForToday = todayRemainingAllowance > 0
        ? todayRemainingAllowance
        : 0.0;
    final futureBudget =
        totalPlannedVariable - totalVariableExpenses - reservedForToday;

    if (futureBudget <= 0) return 0.0;
    return (futureBudget / remainingDays).clamp(0.0, 999999.0);
  }

  // =========================================================================
  // ระบบเงินปัจจุบัน - เงินออมต่อเดือน - รายจ่ายคงที่ต่อเดือน -> คำนวณโควตารายวัน
  // =========================================================================

  /// รายจ่ายคงที่ที่ยังค้างจ่ายในรอบเดือนนี้ (ค่าใช้จ่ายคงที่ตามแผน - ที่จ่ายไปแล้วในเดือนนี้)
  /// และคำนึงถึงภาระบิลคงที่ที่รอชำระในเดือนนี้ตามรายการตั้งเวลา
  double get remainingMonthlyFixedCosts {
    final planned = budgetPlan.value.plannedFixedCosts;
    final paid = totalFixedExpenses;
    final remainingFromPlan = (planned - paid) > 0 ? (planned - paid) : 0.0;
    final unpaidSchedules = upcomingUnpaidFixedScheduledCommitmentsThisMonth;
    return remainingFromPlan > unpaidSchedules
        ? remainingFromPlan
        : unpaidSchedules;
  }

  /// งบเงินคงเหลือจริงสำหรับกินอยู่ในรอบเดือนนี้
  /// คำนวณจาก: (เงินปัจจุบัน + เงินเดือนยังไม่ออก) - เงินออมต่อเดือน (targetMonthlySavings) - รายจ่ายคงที่ที่ยังค้างจ่าย (remainingMonthlyFixedCosts)
  double get dynamicAvailableMonthlyBudget {
    final balance = totalCurrentBalance + budgetPlan.value.pendingSalary;
    final savings = budgetPlan.value.targetMonthlySavings;
    final fixedCosts = remainingMonthlyFixedCosts;
    return balance - savings - fixedCosts;
  }

  /// โควตารายวันคำนวณจากเงินจริง (Dynamic Daily Quota):
  /// (เงินปัจจุบัน - เงินออมต่อเดือน - รายจ่ายคงที่ต่อเดือนที่เหลือ) / จำนวนวันที่เหลืออยู่ในเดือน
  double get dynamicCalculatedDailyQuota {
    final available = dynamicAvailableMonthlyBudget;
    if (available <= 0) return 0.0;
    final days = remainingDaysInMonth > 0 ? remainingDaysInMonth : 1;
    final quota = available / days;
    return (quota / 10).round() *
        10.0; // ปัดเศษลงตัวละ 10 บาทเพื่อการใช้งานจริงที่สะดวก
  }

  /// นำโควตาที่คำนวณจากเงินจริงไปบันทึกเป็นเป้าหมายรายวันของแผน
  void applyDynamicCalculatedQuota() {
    final quota = dynamicCalculatedDailyQuota;
    if (quota <= 0) return;
    final updatedPlan = budgetPlan.value.copyWith(targetDailyAllowance: quota);
    updateBudgetPlan(updatedPlan);
  }

  // ==========================================
  // WALLET HEALTH 0-100 ENGINE & DIAGNOSTICS
  // ==========================================

  /// ผลการประเมินสุขภาพกระเป๋าเงิน (Wallet Health Diagnostics 0-100)
  WalletHealthResult get walletHealth {
    final now = DateTime.now();
    final date = selectedDate.value;
    final plan = budgetPlan.value;
    final totalDays = daysInCurrentMonth;
    final isCurrentMonth = (date.year == now.year && date.month == now.month);
    final currentDay = isCurrentMonth
        ? now.day
        : (date.isBefore(DateTime(now.year, now.month, 1)) ? totalDays : 1);
    final remainingDays = remainingDaysInMonth;

    // -------------------------------------------------------------
    // 1. Burn Rate & Pace (30 คะแนน)
    // -------------------------------------------------------------
    final plannedVar = plan.plannedVariableBudget(totalDays);
    final effectivePlannedVar = plannedVar > 0 ? plannedVar : 1.0;
    final daysPassedRatio = (currentDay / (totalDays > 0 ? totalDays : 30))
        .clamp(0.01, 1.0);
    final spendingRatio = (totalVariableExpenses / effectivePlannedVar).clamp(
      0.0,
      3.0,
    );

    double burnMultiplier;
    double paceScore;
    String paceStatus;
    String paceDetail;
    bool isPaceHealthy;

    if (totalVariableExpenses <= 0) {
      burnMultiplier = 0.0;
      paceScore = 30.0;
      paceStatus = 'pace_excellent'.tr;
      paceDetail = 'pace_no_expense_yet'.tr;
      isPaceHealthy = true;
    } else {
      burnMultiplier = spendingRatio / daysPassedRatio;
      if (burnMultiplier <= 1.0) {
        paceScore = 30.0;
        paceStatus = 'pace_on_track'.tr;
        paceDetail = 'pace_on_track_desc'.trParams({
          'spent': '${(spendingRatio * 100).toInt()}%',
          'days': '${(daysPassedRatio * 100).toInt()}%',
        });
        isPaceHealthy = true;
      } else if (burnMultiplier <= 1.25) {
        paceScore = (30.0 - ((burnMultiplier - 1.0) / 0.25) * 8.0).clamp(
          0.0,
          30.0,
        );
        paceStatus = 'pace_slightly_fast'.tr;
        paceDetail = 'pace_slightly_fast_desc'.trParams({
          'speed': burnMultiplier.toStringAsFixed(1),
        });
        isPaceHealthy = false;
      } else if (burnMultiplier <= 1.75) {
        paceScore = (22.0 - ((burnMultiplier - 1.25) / 0.5) * 12.0).clamp(
          0.0,
          30.0,
        );
        paceStatus = 'pace_fast_warning'.tr;
        paceDetail = 'pace_fast_desc'.trParams({
          'speed': burnMultiplier.toStringAsFixed(1),
        });
        isPaceHealthy = false;
      } else {
        paceScore = (10.0 - ((burnMultiplier - 1.75) / 1.0) * 10.0).clamp(
          0.0,
          10.0,
        );
        paceStatus = 'pace_critical_fast'.tr;
        paceDetail = 'pace_critical_desc'.trParams({
          'speed': burnMultiplier.toStringAsFixed(1),
        });
        isPaceHealthy = false;
      }
    }

    final paceDimension = WalletHealthDimension(
      title: 'dim_burn_rate_pace'.tr,
      score: paceScore,
      maxScore: 30.0,
      statusText: paceStatus,
      detail: paceDetail,
      isHealthy: isPaceHealthy,
      icon: Icons.speed_rounded,
    );

    // -------------------------------------------------------------
    // 2. Fixed Commitment Coverage (30 คะแนน)
    // -------------------------------------------------------------
    final remainingFixed = remainingMonthlyFixedCosts;
    double commitmentScore;
    String commitmentStatus;
    String commitmentDetail;
    bool isCommitmentHealthy;

    if (remainingFixed <= 0) {
      commitmentScore = 30.0;
      commitmentStatus = 'commitment_cleared'.tr;
      commitmentDetail = 'commitment_cleared_desc'.tr;
      isCommitmentHealthy = true;
    } else {
      final coverage = totalCurrentBalance > 0
          ? (totalCurrentBalance / remainingFixed).clamp(0.0, 1.0)
          : 0.0;
      commitmentScore = coverage * 30.0;
      if (coverage >= 1.0) {
        commitmentStatus = 'commitment_secured'.tr;
        commitmentDetail = 'commitment_secured_desc'.tr;
        isCommitmentHealthy = true;
      } else {
        commitmentStatus = 'commitment_risk'.tr;
        commitmentDetail = 'commitment_risk_desc'.trParams({
          'pct': '${(coverage * 100).toInt()}%',
        });
        isCommitmentHealthy = false;
      }
    }

    final commitmentDimension = WalletHealthDimension(
      title: 'dim_fixed_coverage'.tr,
      score: commitmentScore,
      maxScore: 30.0,
      statusText: commitmentStatus,
      detail: commitmentDetail,
      isHealthy: isCommitmentHealthy,
      icon: Icons.receipt_long_rounded,
    );

    // -------------------------------------------------------------
    // 3. Savings Discipline & Leakage (25 คะแนน)
    // -------------------------------------------------------------
    final targetSavings = plan.targetMonthlySavings;
    double savingsScore;
    String savingsStatus;
    String savingsDetail;
    bool isSavingsHealthy;

    if (targetSavings <= 0) {
      savingsScore = 20.0;
      savingsStatus = 'savings_no_target'.tr;
      savingsDetail = 'savings_no_target_desc'.tr;
      isSavingsHealthy = true;
    } else {
      final savingsAchieved = (actualSavings / targetSavings).clamp(0.0, 1.0);
      savingsScore = savingsAchieved * 20.0;

      if (actualSavingsWithdrawals > 0) {
        savingsScore = (savingsScore - 8.0).clamp(0.0, 25.0);
        savingsStatus = 'savings_leakage_warning'.tr;
        savingsDetail = 'savings_leakage_desc'.tr;
        isSavingsHealthy = false;
      } else {
        savingsScore = (savingsScore + 5.0).clamp(0.0, 25.0);
        if (actualSavings >= targetSavings) {
          savingsStatus = 'savings_target_hit'.tr;
          savingsDetail = 'savings_target_hit_desc'.tr;
          isSavingsHealthy = true;
        } else {
          savingsStatus = 'savings_accumulating'.tr;
          savingsDetail = 'savings_accumulating_desc'.trParams({
            'pct': '${(savingsAchieved * 100).toInt()}%',
          });
          isSavingsHealthy = savingsAchieved >= 0.5;
        }
      }
    }

    final savingsDimension = WalletHealthDimension(
      title: 'dim_savings_discipline'.tr,
      score: savingsScore,
      maxScore: 25.0,
      statusText: savingsStatus,
      detail: savingsDetail,
      isHealthy: isSavingsHealthy,
      icon: Icons.savings_outlined,
    );

    // -------------------------------------------------------------
    // 4. Cash Runway Buffer (15 คะแนน)
    // -------------------------------------------------------------
    final double averageDailySpend = currentDay > 0
        ? (actualExpenses / currentDay)
        : plan.targetDailyAllowance;
    final double safeDailySpend = averageDailySpend > 1.0
        ? averageDailySpend
        : (plan.targetDailyAllowance > 0 ? plan.targetDailyAllowance : 100.0);
    final double runwayDays = totalCurrentBalance > 0
        ? (totalCurrentBalance / safeDailySpend)
        : 0.0;
    final double requiredDays = remainingDays > 0
        ? remainingDays.toDouble()
        : 1.0;

    double runwayScore;
    String runwayStatus;
    String runwayDetail;
    bool isRunwayHealthy;

    if (runwayDays >= requiredDays) {
      runwayScore = 15.0;
      runwayStatus = 'runway_sufficient'.tr;
      runwayDetail = 'runway_sufficient_desc'.trParams({
        'days': '${runwayDays.toInt()}',
      });
      isRunwayHealthy = true;
    } else {
      runwayScore = ((runwayDays / requiredDays) * 15.0).clamp(0.0, 15.0);
      runwayStatus = 'runway_short'.tr;
      runwayDetail = 'runway_short_desc'.trParams({
        'days': '${runwayDays.toInt()}',
        'short': '${(requiredDays - runwayDays).toInt()}',
      });
      isRunwayHealthy = false;
    }

    final runwayDimension = WalletHealthDimension(
      title: 'dim_runway_buffer'.tr,
      score: runwayScore,
      maxScore: 15.0,
      statusText: runwayStatus,
      detail: runwayDetail,
      isHealthy: isRunwayHealthy,
      icon: Icons.timer_outlined,
    );

    // -------------------------------------------------------------
    // Total Score & Tier
    // -------------------------------------------------------------
    final int totalScore =
        (paceScore + commitmentScore + savingsScore + runwayScore)
            .round()
            .clamp(0, 100);
    final WalletHealthTier tier;
    if (totalScore >= 90) {
      tier = WalletHealthTier.optimal;
    } else if (totalScore >= 75) {
      tier = WalletHealthTier.healthy;
    } else if (totalScore >= 50) {
      tier = WalletHealthTier.fair;
    } else {
      tier = WalletHealthTier.critical;
    }

    // Suggested Daily Pace
    double suggestedPace = dynamicCalculatedDailyQuota;
    if (suggestedPace <= 0) {
      suggestedPace = remainingDailyAllowance > 0
          ? remainingDailyAllowance
          : plan.targetDailyAllowance;
    }

    // Headline Advice
    final String headline;
    switch (tier) {
      case WalletHealthTier.optimal:
        headline = 'health_headline_optimal'.tr;
        break;
      case WalletHealthTier.healthy:
        headline = 'health_headline_healthy'.tr;
        break;
      case WalletHealthTier.fair:
        headline = 'health_headline_fair'.trParams({
          'amount': suggestedPace.toStringAsFixed(0),
        });
        break;
      case WalletHealthTier.critical:
        headline = 'health_headline_critical'.tr;
        break;
    }

    // Actionable Insights list
    final insights = <WalletHealthInsight>[];

    // Insight 1: Fixed Bills
    if (remainingFixed <= 0) {
      insights.add(
        WalletHealthInsight(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'insight_fixed_cleared_title'.tr,
          description: 'insight_fixed_cleared_desc'.tr,
        ),
      );
    } else if (isCommitmentHealthy) {
      insights.add(
        WalletHealthInsight(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF3B82F6),
          title: 'insight_fixed_covered_title'.tr,
          description: 'insight_fixed_covered_desc'.trParams({
            'amount': remainingFixed.toStringAsFixed(0),
          }),
        ),
      );
    } else {
      insights.add(
        WalletHealthInsight(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'insight_fixed_deficit_title'.tr,
          description: 'insight_fixed_deficit_desc'.trParams({
            'amount': remainingFixed.toStringAsFixed(0),
          }),
          actionLabel: 'action_view_budget'.tr,
          onAction: () => Get.toNamed(Routes.BUDGET_SETTINGS),
        ),
      );
    }

    // Insight 2: Daily Allowance / Pace
    if (!isPaceHealthy) {
      insights.add(
        WalletHealthInsight(
          icon: Icons.tune_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'insight_pace_warning_title'.tr,
          description: 'insight_pace_warning_desc'.trParams({
            'pace': suggestedPace.toStringAsFixed(0),
            'days': '$remainingDays',
          }),
          actionLabel: 'action_apply_dynamic_quota'.tr,
          onAction: applyDynamicCalculatedQuota,
        ),
      );
    } else {
      insights.add(
        WalletHealthInsight(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'insight_pace_good_title'.tr,
          description: 'insight_pace_good_desc'.trParams({
            'quota': plan.targetDailyAllowance.toStringAsFixed(0),
          }),
        ),
      );
    }

    // Insight 3: Savings Leakage or Target
    if (actualSavingsWithdrawals > 0) {
      insights.add(
        WalletHealthInsight(
          icon: Icons.outbox_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'insight_savings_withdrawn_title'.tr,
          description: 'insight_savings_withdrawn_desc'.trParams({
            'amount': actualSavingsWithdrawals.toStringAsFixed(0),
          }),
        ),
      );
    } else if (actualSavings >= targetSavings && targetSavings > 0) {
      insights.add(
        WalletHealthInsight(
          icon: Icons.celebration_outlined,
          iconColor: const Color(0xFF10B981),
          title: 'insight_savings_target_hit_title'.tr,
          description: 'insight_savings_target_hit_desc'.tr,
        ),
      );
    }

    return WalletHealthResult(
      totalScore: totalScore,
      tier: tier,
      runwayDays: runwayDays,
      burnRateMultiplier: burnMultiplier,
      suggestedDailyPace: suggestedPace,
      headlineAdvice: headline,
      dimensions: [
        paceDimension,
        commitmentDimension,
        savingsDimension,
        runwayDimension,
      ],
      insights: insights,
    );
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
        return t.date.year == targetDate.year &&
            t.date.month == targetDate.month;
      }).toList();

      final income = monthTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final savingsDeposits = monthTransactions
          .where((t) => t.isSavings)
          .fold(0.0, (sum, t) => sum + t.amount);
      final savingsWithdrawals = monthTransactions
          .where((t) => t.isSavingsWithdrawal)
          .fold(0.0, (sum, t) => sum + t.amount);
      final savings = savingsDeposits - savingsWithdrawals;
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

    // If re-adding a transaction that was linked to a scheduled payment, advance it back
    if (item.scheduledPaymentId != null) {
      final schedIndex =
          scheduledPayments.indexWhere((p) => p.id == item.scheduledPaymentId);
      if (schedIndex != -1) {
        final sched = scheduledPayments[schedIndex];
        if (item.originalScheduledDueDate != null &&
            sched.nextDueDate.year == item.originalScheduledDueDate!.year &&
            sched.nextDueDate.month == item.originalScheduledDueDate!.month &&
            sched.nextDueDate.day == item.originalScheduledDueDate!.day) {
          if (sched.frequency == ScheduleFrequency.oneTime) {
            scheduledPayments[schedIndex] = sched.copyWith(
              status: ScheduledPaymentStatus.completed,
              lastExecutedDate: item.date,
              previousDueDate: item.originalScheduledDueDate,
            );
          } else {
            scheduledPayments[schedIndex] = sched.copyWith(
              nextDueDate: sched.calculateNextDueDate(item.date),
              lastExecutedDate: item.date,
              previousDueDate: item.originalScheduledDueDate,
            );
          }
          _storageService.saveScheduledPayments(scheduledPayments);
          _checkAutoSyncFixedCosts();
        }
      }
    }

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
    final index = transactions.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final tx = transactions[index];
    transactions.removeAt(index);
    _storageService.saveTransactions(transactions);

    // Rollback linked scheduled payment if this transaction originated from one
    int schedIndex = -1;
    if (tx.scheduledPaymentId != null) {
      schedIndex =
          scheduledPayments.indexWhere((p) => p.id == tx.scheduledPaymentId);
    } else {
      // Fallback matching in case of older transactions without scheduledPaymentId:
      schedIndex = scheduledPayments.indexWhere((p) =>
          p.title == tx.title &&
          p.amount == tx.amount &&
          p.type == tx.type &&
          p.lastExecutedDate != null &&
          p.lastExecutedDate!.difference(tx.date).inDays.abs() <= 2);
    }

    if (schedIndex != -1) {
      final sched = scheduledPayments[schedIndex];
      final restoredDueDate = tx.originalScheduledDueDate ??
          sched.previousDueDate ??
          sched.calculatePreviousDueDate();

      final reverted = sched.copyWith(
        nextDueDate: restoredDueDate,
        status: ScheduledPaymentStatus.active,
      );
      scheduledPayments[schedIndex] = reverted;
      _storageService.saveScheduledPayments(scheduledPayments);
      _checkAutoSyncFixedCosts();

      if (Get.context != null) {
        AppFeedback.showInfo(
          title: 'schedule_reverted_title'.tr,
          message: 'schedule_reverted_msg'.trParams({'title': sched.title}),
        );
      }
    }
  }

  Future<void> clearAllToEmpty() async {
    transactions.clear();
    scheduledPayments.clear();
    await _storageService.clearAllData(keepInitialized: true);
    if (Get.context != null) {
      AppFeedback.showSuccess(
        title: 'clear_all_data_title'.tr,
        message: 'clear_all_data_desc'.tr,
      );
    }
  }

  // ==========================================
  // SCHEDULED PAYMENTS ACTIONS & GETTERS
  // ==========================================

  List<ScheduledPaymentItem> get activeScheduledPayments =>
      scheduledPayments.where((item) => item.isActive).toList();

  List<ScheduledPaymentItem> get upcomingScheduledPayments {
    final list = scheduledPayments.where((item) => item.isActive).toList();
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  List<ScheduledPaymentItem> get dueOrOverdueScheduledPayments {
    return scheduledPayments
        .where((item) => item.isActive && item.isDue)
        .toList();
  }

  double get upcomingMonthlyScheduledCommitments {
    final targetMonth = selectedDate.value;
    return scheduledPayments
        .where(
          (item) =>
              item.isActive &&
              item.nextDueDate.year == targetMonth.year &&
              item.nextDueDate.month == targetMonth.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// ยอดบิลคงที่ต่อเดือนที่คำนวณจากรายการตั้งเวลาจ่ายคงที่ทั้งหมดที่กำลังทำงานอยู่
  double get totalMonthlyFixedScheduledCommitments {
    return scheduledPayments
        .where((item) => item.isFixedExpense)
        .fold(0.0, (sum, item) => sum + item.monthlyEquivalentAmount);
  }

  /// รายการตั้งเวลาจ่ายคงที่ที่กำลังทำงานอยู่ทั้งหมด
  List<ScheduledPaymentItem> get activeFixedScheduledPayments {
    final list =
        scheduledPayments.where((item) => item.isFixedExpense).toList();
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  /// ยอดบิลคงที่ที่รอชำระในรอบเดือนปัจจุบันตามรายการตั้งเวลา
  double get upcomingUnpaidFixedScheduledCommitmentsThisMonth {
    final targetMonth = selectedDate.value;
    return scheduledPayments
        .where(
          (item) =>
              item.isFixedExpense &&
              item.nextDueDate.year == targetMonth.year &&
              item.nextDueDate.month == targetMonth.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// ส่วนต่างระหว่างงบประมาณคงที่ตามแผน กับผลรวมของรายการตั้งเวลาคงที่
  /// เป็นบวก = มีงบสำรองคงเหลือ (Unallocated Buffer)
  /// เป็นลบ = รายการตั้งเวลาเกินงบ (Exceeded)
  double get fixedCostsSyncVariance =>
      budgetPlan.value.plannedFixedCosts -
      totalMonthlyFixedScheduledCommitments;

  /// งบคงที่ตรงกับรายการตั้งเวลาหรือไม่ (ต่างกันไม่เกิน 1 บาท)
  bool get isFixedCostsInSync => fixedCostsSyncVariance.abs() < 1.0;

  /// ซิงค์ยอดงบค่าใช้จ่ายคงที่ตามผลรวมของรายการตั้งเวลาจ่ายคงที่
  void syncPlannedFixedCostsWithSchedules({bool notify = true}) {
    final total = totalMonthlyFixedScheduledCommitments;
    final updated = budgetPlan.value.copyWith(plannedFixedCosts: total);
    updateBudgetPlan(updated);

    if (notify && Get.context != null) {
      final currencyFmt = NumberFormat.currency(
        locale: 'th_TH',
        symbol: '฿',
        decimalDigits: 0,
      );
      AppFeedback.showSuccess(
        title: 'sync_success_title'.tr,
        message: 'sync_success_desc'.trParams({
          'amount': currencyFmt.format(total),
        }),
      );
    }
  }

  /// สลับการซิงค์งบค่าใช้จ่ายคงที่แบบอัตโนมัติ
  void toggleAutoSyncFixedCosts(bool enabled, {bool notify = true}) {
    final updated = budgetPlan.value.copyWith(
      autoSyncFixedWithSchedules: enabled,
      plannedFixedCosts:
          enabled ? totalMonthlyFixedScheduledCommitments : null,
    );
    updateBudgetPlan(updated);

    if (notify && Get.context != null) {
      AppFeedback.showInfo(
        title: 'auto_sync_fixed_costs'.tr,
        message: enabled
            ? 'auto_sync_enabled_msg'.tr
            : 'auto_sync_disabled_msg'.tr,
      );
    }
  }

  void _checkAutoSyncFixedCosts() {
    if (budgetPlan.value.autoSyncFixedWithSchedules) {
      final total = totalMonthlyFixedScheduledCommitments;
      if ((budgetPlan.value.plannedFixedCosts - total).abs() >= 1.0) {
        final updated = budgetPlan.value.copyWith(plannedFixedCosts: total);
        updateBudgetPlan(updated);
      }
    }
  }

  void addScheduledPayment(ScheduledPaymentItem item, {bool notify = true}) {
    scheduledPayments.add(item);
    _storageService.saveScheduledPayments(scheduledPayments);
    _checkAutoSyncFixedCosts();

    if (notify && Get.context != null) {
      AppFeedback.showSuccess(
        title: 'scheduled_success_title'.tr,
        message: 'scheduled_success_msg'.trParams({'title': item.title}),
        amount: item.amount,
        transactionType: item.type,
      );
    }
  }

  void updateScheduledPayment(ScheduledPaymentItem item, {bool notify = true}) {
    final index = scheduledPayments.indexWhere((p) => p.id == item.id);
    if (index != -1) {
      scheduledPayments[index] = item;
      _storageService.saveScheduledPayments(scheduledPayments);
      _checkAutoSyncFixedCosts();

      if (notify && Get.context != null) {
        AppFeedback.showSuccess(
          title: 'schedule_updated_title'.tr,
          message: 'schedule_updated_msg'.trParams({'title': item.title}),
          amount: item.amount,
          transactionType: item.type,
        );
      }
    }
  }

  void deleteScheduledPayment(String id) {
    scheduledPayments.removeWhere((item) => item.id == id);
    _storageService.saveScheduledPayments(scheduledPayments);
    _checkAutoSyncFixedCosts();
  }

  void toggleScheduledPaymentStatus(String id) {
    final index = scheduledPayments.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = scheduledPayments[index];
      final newStatus = current.status == ScheduledPaymentStatus.active
          ? ScheduledPaymentStatus.paused
          : ScheduledPaymentStatus.active;
      final updated = current.copyWith(status: newStatus);
      scheduledPayments[index] = updated;
      _storageService.saveScheduledPayments(scheduledPayments);
      _checkAutoSyncFixedCosts();

      if (Get.context != null) {
        if (newStatus == ScheduledPaymentStatus.paused) {
          AppFeedback.showInfo(
            title: 'pause_schedule'.tr,
            message: 'schedule_paused_msg'.trParams({'title': current.title}),
          );
        } else {
          AppFeedback.showSuccess(
            title: 'resume_schedule'.tr,
            message: 'schedule_resumed_msg'.trParams({'title': current.title}),
          );
        }
      }
    }
  }

  void executeScheduledPayment(
    ScheduledPaymentItem item, {
    DateTime? executionDate,
    bool notify = true,
  }) {
    final execDate =
        executionDate ?? (item.isDue ? DateTime.now() : item.nextDueDate);
    final transaction = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: item.title,
      amount: item.amount,
      type: item.type,
      costNature: item.costNature,
      categoryName: item.categoryName,
      date: execDate,
      note: item.note,
      scheduledPaymentId: item.id,
      originalScheduledDueDate: item.nextDueDate,
    );
    addTransaction(transaction, notify: false);

    if (item.frequency == ScheduleFrequency.oneTime) {
      final updated = item.copyWith(
        status: ScheduledPaymentStatus.completed,
        lastExecutedDate: DateTime.now(),
        previousDueDate: item.nextDueDate,
      );
      updateScheduledPayment(updated, notify: false);
    } else {
      final nextDue = item.calculateNextDueDate(execDate);
      final updated = item.copyWith(
        nextDueDate: nextDue,
        lastExecutedDate: DateTime.now(),
        previousDueDate: item.nextDueDate,
      );
      updateScheduledPayment(updated, notify: false);
    }

    if (notify && Get.context != null) {
      AppFeedback.showSuccess(
        title: 'schedule_paid_title'.tr,
        message: 'schedule_paid_msg'.trParams({
          'title': item.title,
          'amount': '${item.amount.toStringAsFixed(2)} ฿',
        }),
        amount: item.amount,
        transactionType: item.type,
      );
    }
  }

  void skipScheduledPayment(String id) {
    final index = scheduledPayments.indexWhere((p) => p.id == id);
    if (index != -1) {
      final item = scheduledPayments[index];
      if (item.frequency == ScheduleFrequency.oneTime) {
        final updated = item.copyWith(
          status: ScheduledPaymentStatus.completed,
          previousDueDate: item.nextDueDate,
        );
        updateScheduledPayment(updated, notify: false);
      } else {
        final nextDue = item.calculateNextDueDate();
        final updated = item.copyWith(
          nextDueDate: nextDue,
          previousDueDate: item.nextDueDate,
        );
        updateScheduledPayment(updated, notify: false);
      }

      if (Get.context != null) {
        AppFeedback.showInfo(
          title: 'schedule_skipped_title'.tr,
          message: 'schedule_skipped_msg'.trParams({'title': item.title}),
        );
      }
    }
  }

  void processDueAutoPayments() {
    final autoDueItems = scheduledPayments
        .where((item) => item.isActive && item.autoRecord && item.isDue)
        .toList();
    if (autoDueItems.isEmpty) return;

    int count = 0;
    for (final item in autoDueItems) {
      executeScheduledPayment(
        item,
        executionDate: item.nextDueDate,
        notify: false,
      );
      count++;
    }

    if (count > 0 && Get.context != null) {
      AppFeedback.showSuccess(
        title: 'auto_paid_notification_title'.tr,
        message: 'auto_paid_notification_desc'.trParams({'count': '$count'}),
      );
    }
  }

  /// เทมเพลตบิลและภาระการเงินยอดนิยม (Curated Presets)
  List<ScheduledPaymentPreset> get popularScheduledPresets =>
      ScheduledPaymentPreset.curatedPresets;

  /// ตรวจจับรายการที่ผู้ใช้เคยจ่ายซ้ำในอดีต (>= 2 ครั้ง) ที่ยังไม่ได้ตั้งเป็นรายการจ่ายล่วงหน้า
  List<TransactionItem> get detectedRecurringTransactionSuggestions {
    final Map<String, List<TransactionItem>> titleGroups = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) continue;
      final cleanTitle = tx.title.trim().toLowerCase();
      if (cleanTitle.isEmpty) continue;

      titleGroups.putIfAbsent(cleanTitle, () => []).add(tx);
    }

    final List<TransactionItem> candidates = [];
    final scheduledTitles = scheduledPayments
        .map((s) => s.title.trim().toLowerCase())
        .toSet();

    titleGroups.forEach((normalizedTitle, txList) {
      // หากตั้งเวลาไว้แล้ว ไม่แนะนำซ้ำ
      if (scheduledTitles.contains(normalizedTitle)) return;

      if (txList.length >= 2) {
        txList.sort((a, b) => b.date.compareTo(a.date));
        final latest = txList.first;
        final older = txList[1];

        final diffDays = latest.date.difference(older.date).inDays.abs();
        if (diffDays >= 14) {
          candidates.add(latest);
        }
      }
    });

    candidates.sort((a, b) => b.date.compareTo(a.date));
    return candidates.take(5).toList();
  }

  /// สร้างรายการตั้งเวลาจาก Preset อัตโนมัติ 1-Tap
  void createScheduledPaymentFromPreset(
    ScheduledPaymentPreset preset, {
    double? customAmount,
    DateTime? firstDueDate,
    bool notify = true,
  }) {
    final now = DateTime.now();
    final dueDate = firstDueDate ?? DateTime(now.year, now.month, 25, 9, 0);
    final newItem = ScheduledPaymentItem(
      id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
      title: preset.titleKey.tr,
      amount: customAmount ?? preset.suggestedAmount ?? 1000.0,
      type: preset.type,
      costNature: preset.costNature,
      categoryName: preset.categoryName,
      frequency: preset.frequency,
      startDate: dueDate,
      nextDueDate: dueDate,
      autoRecord: false,
      status: ScheduledPaymentStatus.active,
    );
    addScheduledPayment(newItem, notify: notify);
  }

  /// สร้างรายการตั้งเวลาจากธุรกรรมประวัติจริง 1-Tap
  void createScheduledPaymentFromHistoricalTransaction(
    TransactionItem tx, {
    ScheduleFrequency frequency = ScheduleFrequency.monthly,
    bool notify = true,
  }) {
    final now = DateTime.now();
    final day = tx.date.day.clamp(1, 28);
    var nextDue = DateTime(now.year, now.month, day, 9, 0);
    if (nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month + 1, day, 9, 0);
    }

    final newItem = ScheduledPaymentItem(
      id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
      title: tx.title,
      amount: tx.amount,
      type: tx.type,
      costNature: CostNature.fixed,
      categoryName: tx.categoryName,
      frequency: frequency,
      startDate: nextDue,
      nextDueDate: nextDue,
      autoRecord: false,
      status: ScheduledPaymentStatus.active,
    );
    addScheduledPayment(newItem, notify: notify);
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
      selectedDate.value = DateTime(
        selectedDate.value.year,
        selectedDate.value.month - 1,
      );
    } else if (currentPeriod.value == TimeFilterPeriod.yearly) {
      selectedDate.value = DateTime(selectedDate.value.year - 1);
    }
  }

  void nextPeriod() {
    if (currentPeriod.value == TimeFilterPeriod.monthly) {
      selectedDate.value = DateTime(
        selectedDate.value.year,
        selectedDate.value.month + 1,
      );
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
      return selectedDate.value.year == now.year &&
          selectedDate.value.month == now.month;
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
    final currentlyDark =
        (themeMode.value == ThemeMode.dark) ||
        (themeMode.value == ThemeMode.system &&
            (Get.isDarkMode || isDarkMode.value));
    if (currentlyDark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  String get themeModeName {
    final currentlyDark =
        (themeMode.value == ThemeMode.dark) ||
        (themeMode.value == ThemeMode.system &&
            (Get.isDarkMode || isDarkMode.value));
    return currentlyDark ? 'theme_dark'.tr : 'theme_light'.tr;
  }

  static const List<String> thaiMonthNames = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  static const List<String> englishMonthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> thaiMonthShortNames = [
    '',
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  static const List<String> englishMonthShortNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
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
        final displayYear = isEn ? '${date.year}' : '${date.year + 543}';
        return 'period_year_format'.trParams({'year': displayYear});
      case TimeFilterPeriod.allTime:
        return 'period_all_time'.tr;
    }
  }

  void _safeUpdateLocale(Locale locale) {
    Get.locale = locale;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest && Get.key.currentState != null) {
      try {
        Get.updateLocale(locale);
      } catch (_) {}
    }
  }

  void _applySystemLocale() {
    try {
      final sysLang = WidgetsBinding
          .instance
          .platformDispatcher
          .locale
          .languageCode
          .toLowerCase();
      final activeLang = sysLang == 'th' ? 'th' : 'en';
      currentLanguage.value = activeLang;
      _safeUpdateLocale(
        activeLang == 'en'
            ? const Locale('en', 'US')
            : const Locale('th', 'TH'),
      );
    } catch (_) {
      currentLanguage.value = 'th';
      _safeUpdateLocale(const Locale('th', 'TH'));
    }
  }

  void setLanguage(String langCode) {
    if (langCode != 'en' && langCode != 'th') return;
    languageMode.value = langCode;
    currentLanguage.value = langCode;
    _safeUpdateLocale(
      langCode == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'),
    );
    _storageService.saveLanguage(langCode);
  }

  void toggleLanguage() {
    setLanguage(currentLanguage.value == 'en' ? 'th' : 'en');
  }

  String get currentLanguageName =>
      currentLanguage.value == 'en' ? 'English' : 'ภาษาไทย';

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
