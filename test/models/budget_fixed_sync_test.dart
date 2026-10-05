import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/budget_plan_model.dart';
import 'package:money_tracker/app/data/models/scheduled_payment_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';

void main() {
  group('Fixed Costs & Scheduled Payments Sync Unit Tests', () {
    test('monthlyEquivalentAmount normalization across frequencies', () {
      final monthlyItem = ScheduledPaymentItem(
        id: '1',
        title: 'Condo Rent',
        amount: 12000.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ที่อยู่อาศัย',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 25),
      );
      expect(monthlyItem.monthlyEquivalentAmount, 12000.0);
      expect(monthlyItem.isFixedExpense, isTrue);

      final yearlyItem = ScheduledPaymentItem(
        id: '2',
        title: 'Car Insurance',
        amount: 24000.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ประกัน',
        frequency: ScheduleFrequency.yearly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 25),
      );
      expect(yearlyItem.monthlyEquivalentAmount, 2000.0); // 24000 / 12
      expect(yearlyItem.isFixedExpense, isTrue);

      final weeklyItem = ScheduledPaymentItem(
        id: '3',
        title: 'Weekly Cleaning Service',
        amount: 600.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'ที่อยู่อาศัย',
        frequency: ScheduleFrequency.weekly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 8),
      );
      expect(weeklyItem.monthlyEquivalentAmount, closeTo(2600.0, 0.01)); // (600 * 52) / 12 = 2600

      final dailyItem = ScheduledPaymentItem(
        id: '4',
        title: 'Daily Cloud Subscription',
        amount: 10.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'บริการ',
        frequency: ScheduleFrequency.daily,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 2),
      );
      expect(dailyItem.monthlyEquivalentAmount, 300.0); // 10 * 30
      expect(dailyItem.isFixedExpense, isTrue);
    });

    test('isFixedExpense returns false for non-fixed or income items', () {
      final variableItem = ScheduledPaymentItem(
        id: '5',
        title: 'Variable Grocery',
        amount: 5000.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 15),
      );
      expect(variableItem.isFixedExpense, isFalse);

      final incomeItem = ScheduledPaymentItem(
        id: '6',
        title: 'Salary Deposit',
        amount: 50000.0,
        type: TransactionType.income,
        costNature: CostNature.notApplicable,
        categoryName: 'เงินเดือน',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 25),
      );
      expect(incomeItem.isFixedExpense, isFalse);
    });

    test('BudgetPlan model serialization with autoSyncFixedWithSchedules', () {
      final plan = BudgetPlan(
        plannedIncome: 45000.0,
        targetDailyAllowance: 500.0,
        targetMonthlySavings: 10000.0,
        plannedFixedCosts: 15000.0,
        pendingSalary: 0.0,
        autoSyncFixedWithSchedules: true,
      );

      final json = plan.toJson();
      expect(json['autoSyncFixedWithSchedules'], isTrue);

      final restored = BudgetPlan.fromJson(json);
      expect(restored.autoSyncFixedWithSchedules, isTrue);
      expect(restored.plannedFixedCosts, 15000.0);

      final modified = restored.copyWith(
        plannedFixedCosts: 18000.0,
        autoSyncFixedWithSchedules: false,
      );
      expect(modified.autoSyncFixedWithSchedules, isFalse);
      expect(modified.plannedFixedCosts, 18000.0);
    });

    test('Sync variance and unallocated/over-budget calculations', () {
      final plannedFixed = 20000.0;
      final schedules = [
        ScheduledPaymentItem(
          id: '1',
          title: 'Rent',
          amount: 10000.0,
          costNature: CostNature.fixed,
          categoryName: 'ที่อยู่อาศัย',
          frequency: ScheduleFrequency.monthly,
          startDate: DateTime(2026, 10, 1),
          nextDueDate: DateTime(2026, 10, 25),
        ),
        ScheduledPaymentItem(
          id: '2',
          title: 'Internet',
          amount: 800.0,
          costNature: CostNature.fixed,
          categoryName: 'สาธารณูปโภค',
          frequency: ScheduleFrequency.monthly,
          startDate: DateTime(2026, 10, 1),
          nextDueDate: DateTime(2026, 10, 10),
        ),
        ScheduledPaymentItem(
          id: '3',
          title: 'Annual Car Tax',
          amount: 2400.0,
          costNature: CostNature.fixed,
          categoryName: 'ยานพาหนะ',
          frequency: ScheduleFrequency.yearly,
          startDate: DateTime(2026, 10, 1),
          nextDueDate: DateTime(2026, 10, 15),
        ),
      ];

      final totalFixedCommitments = schedules
          .where((s) => s.isFixedExpense && s.isActive)
          .fold<double>(0.0, (sum, s) => sum + s.monthlyEquivalentAmount);

      // 10000 + 800 + (2400 / 12 = 200) = 11000
      expect(totalFixedCommitments, 11000.0);

      final variance = plannedFixed - totalFixedCommitments;
      expect(variance, 9000.0);

      final unallocated = (plannedFixed - totalFixedCommitments).clamp(0.0, double.infinity);
      expect(unallocated, 9000.0);

      final overAllocated = (totalFixedCommitments - plannedFixed).clamp(0.0, double.infinity);
      expect(overAllocated, 0.0);
      expect(variance.abs() <= 0.01, isFalse); // not in exact sync
    });
  });
}
