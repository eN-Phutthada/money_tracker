import 'package:get/get.dart';
import '../../../data/models/budget_plan_model.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// GetX Controller สำหรับหน้าจอตั้งค่างบประมาณ
class BudgetController extends GetxController {
  final DashboardController dashboardController = Get.find<DashboardController>();

  late final RxDouble plannedIncome;
  late final RxDouble targetDailyAllowance;
  late final RxDouble targetMonthlySavings;
  late final RxDouble plannedFixedCosts;

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

  void adjustDailyAllowance(double delta) {
    final next = (targetDailyAllowance.value + delta).clamp(100.0, 5000.0);
    targetDailyAllowance.value = next;
  }

  void save() {
    final newPlan = BudgetPlan(
      plannedIncome: plannedIncome.value,
      targetDailyAllowance: targetDailyAllowance.value,
      targetMonthlySavings: targetMonthlySavings.value,
      plannedFixedCosts: plannedFixedCosts.value,
    );

    dashboardController.updateBudgetPlan(newPlan);
    Get.back();

    Get.snackbar(
      'บันทึกสำเร็จ',
      'อัปเดตแผนงบประมาณใหม่เรียบร้อยแล้ว',
      snackPosition: SnackPosition.TOP,
    );
  }
}
