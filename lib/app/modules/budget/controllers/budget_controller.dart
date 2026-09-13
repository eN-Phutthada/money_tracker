import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/budget_plan_model.dart';
import '../../../widgets/app_feedback.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

enum BudgetPresetType {
  rule50_30_20,
  rule60_20_20,
  rule40_30_30,
}

/// GetX Controller สำหรับหน้าจอตั้งค่างบประมาณ
class BudgetController extends GetxController {
  final DashboardController dashboardController = Get.find<DashboardController>();

  late final RxDouble plannedIncome;
  late final RxDouble targetDailyAllowance;
  late final RxDouble targetMonthlySavings;
  late final RxDouble plannedFixedCosts;
  final RxBool isSaving = false.obs;
  final RxBool isSaveSuccess = false.obs;

  @override
  void onInit() {
    super.onInit();
    final plan = dashboardController.budgetPlan.value;
    plannedIncome = plan.plannedIncome.obs;
    targetDailyAllowance = plan.targetDailyAllowance.obs;
    targetMonthlySavings = plan.targetMonthlySavings.obs;
    plannedFixedCosts = plan.plannedFixedCosts.obs;
  }

  int get daysInMonth => dashboardController.daysInCurrentMonth;

  double get plannedVariableBudget => targetDailyAllowance.value * daysInMonth;

  double get expectedEndingBalance =>
      plannedIncome.value -
      plannedFixedCosts.value -
      plannedVariableBudget -
      targetMonthlySavings.value;

  // Percentage Ratios (relative to planned income)
  double get fixedCostsRatio => plannedIncome.value > 0 ? (plannedFixedCosts.value / plannedIncome.value).clamp(0.0, 2.0) : 0.0;
  double get variableCostsRatio => plannedIncome.value > 0 ? (plannedVariableBudget / plannedIncome.value).clamp(0.0, 2.0) : 0.0;
  double get savingsRatio => plannedIncome.value > 0 ? (targetMonthlySavings.value / plannedIncome.value).clamp(0.0, 2.0) : 0.0;
  double get totalCommittedRatio => fixedCostsRatio + variableCostsRatio + savingsRatio;

  String get healthStatusMessage {
    if (expectedEndingBalance < 0) {
      return 'budget_deficit_warning'.tr;
    }
    if (savingsRatio >= 0.25) {
      return 'budget_savings_excellent'.tr;
    }
    if (savingsRatio >= 0.15) {
      return 'budget_savings_good'.tr;
    }
    if (savingsRatio > 0) {
      return 'budget_savings_fair'.tr;
    }
    return 'budget_savings_none'.tr;
  }

  Color get healthStatusColor {
    if (expectedEndingBalance < 0) return const Color(0xFFEF4444);
    if (savingsRatio >= 0.20) return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  void adjustDailyAllowance(double delta) {
    final next = (targetDailyAllowance.value + delta).clamp(0.0, 10000.0);
    targetDailyAllowance.value = next;
  }

  void adjustPlannedIncome(double delta) {
    final next = (plannedIncome.value + delta).clamp(0.0, 10000000.0);
    plannedIncome.value = next;
  }

  void adjustTargetMonthlySavings(double delta) {
    final next = (targetMonthlySavings.value + delta).clamp(0.0, 10000000.0);
    targetMonthlySavings.value = next;
  }

  void adjustPlannedFixedCosts(double delta) {
    final next = (plannedFixedCosts.value + delta).clamp(0.0, 10000000.0);
    plannedFixedCosts.value = next;
  }

  void setPlannedIncome(double value) {
    plannedIncome.value = value.clamp(0.0, 10000000.0);
  }

  void setTargetMonthlySavings(double value) {
    targetMonthlySavings.value = value.clamp(0.0, 10000000.0);
  }

  void setPlannedFixedCosts(double value) {
    plannedFixedCosts.value = value.clamp(0.0, 10000000.0);
  }

  /// ใช้สูตรการจัดสรรงบประมาณยอดนิยมอัตโนมัติ
  void applyTemplate(BudgetPresetType type) {
    final income = plannedIncome.value > 0 ? plannedIncome.value : 30000.0;
    if (plannedIncome.value <= 0) {
      plannedIncome.value = income;
    }

    String templateName = '';
    double fixedPct = 0.50;
    double varPct = 0.30;
    double savingsPct = 0.20;

    switch (type) {
      case BudgetPresetType.rule50_30_20:
        templateName = 'template_50_30_20';
        fixedPct = 0.50;
        varPct = 0.30;
        savingsPct = 0.20;
        break;
      case BudgetPresetType.rule60_20_20:
        templateName = 'template_60_20_20';
        fixedPct = 0.60;
        varPct = 0.20;
        savingsPct = 0.20;
        break;
      case BudgetPresetType.rule40_30_30:
        templateName = 'template_40_30_30';
        fixedPct = 0.40;
        varPct = 0.30;
        savingsPct = 0.30;
        break;
    }

    plannedFixedCosts.value = (income * fixedPct / 100).round() * 100.0;
    targetMonthlySavings.value = (income * savingsPct / 100).round() * 100.0;

    final varTotal = income * varPct;
    final daily = (varTotal / daysInMonth / 10).round() * 10.0;
    targetDailyAllowance.value = daily.clamp(50.0, 10000.0);

    if (Get.context != null) {
      final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
      AppFeedback.showSuccess(
        title: 'applied_template_success'.trParams({'template': templateName.tr}),
        message: 'applied_template_desc'.trParams({
          'income': currencyFmt.format(income),
          'fixed': '${(fixedPct * 100).toInt()}',
          'variable': '${(varPct * 100).toInt()}',
          'savings': '${(savingsPct * 100).toInt()}',
        }),
      );
    }
  }

  void save() {
    final newPlan = BudgetPlan(
      plannedIncome: plannedIncome.value,
      targetDailyAllowance: targetDailyAllowance.value,
      targetMonthlySavings: targetMonthlySavings.value,
      plannedFixedCosts: plannedFixedCosts.value,
    );

    dashboardController.updateBudgetPlan(newPlan);

    if (Get.context != null) {
      isSaving.value = true;
      isSaveSuccess.value = true;
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 320), () {
        isSaving.value = false;
        isSaveSuccess.value = false;
        Get.back();
        AppFeedback.showSuccess(
          title: 'budget_save_success'.tr,
          message: 'budget_save_desc'.tr,
        );
      });
    }
  }
}
