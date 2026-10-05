import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/budget_plan_model.dart';

void main() {
  group('BudgetPlan Model - Pending Salary Tests', () {
    test('Default pendingSalary is 0.0', () {
      const plan = BudgetPlan(
        plannedIncome: 45000.0,
        targetDailyAllowance: 300.0,
        targetMonthlySavings: 10000.0,
        plannedFixedCosts: 12500.0,
      );
      expect(plan.pendingSalary, 0.0);
    });

    test('Custom pendingSalary works properly', () {
      const plan = BudgetPlan(
        plannedIncome: 45000.0,
        targetDailyAllowance: 300.0,
        targetMonthlySavings: 10000.0,
        plannedFixedCosts: 12500.0,
        pendingSalary: 35000.0,
      );
      expect(plan.pendingSalary, 35000.0);
    });

    test('copyWith preserves and updates pendingSalary', () {
      const plan = BudgetPlan(
        plannedIncome: 45000.0,
        targetDailyAllowance: 300.0,
        targetMonthlySavings: 10000.0,
        plannedFixedCosts: 12500.0,
        pendingSalary: 20000.0,
      );

      final copy1 = plan.copyWith(targetDailyAllowance: 400.0);
      expect(copy1.pendingSalary, 20000.0);
      expect(copy1.targetDailyAllowance, 400.0);

      final copy2 = plan.copyWith(pendingSalary: 0.0);
      expect(copy2.pendingSalary, 0.0);
    });

    test('toJson and fromJson serialize pendingSalary correctly', () {
      const plan = BudgetPlan(
        plannedIncome: 50000.0,
        targetDailyAllowance: 350.0,
        targetMonthlySavings: 12000.0,
        plannedFixedCosts: 15000.0,
        pendingSalary: 40000.0,
      );

      final json = plan.toJson();
      expect(json['pendingSalary'], 40000.0);

      final restored = BudgetPlan.fromJson(json);
      expect(restored.pendingSalary, 40000.0);
      expect(restored.plannedIncome, 50000.0);
    });

    test(
      'fromJson falls back to 0.0 when pendingSalary is omitted (backward compatibility)',
      () {
        final json = {
          'plannedIncome': 45000.0,
          'targetDailyAllowance': 300.0,
          'targetMonthlySavings': 10000.0,
          'plannedFixedCosts': 12500.0,
        };

        final plan = BudgetPlan.fromJson(json);
        expect(plan.pendingSalary, 0.0);
      },
    );
  });

  group('Dynamic Balance-to-Quota Formula Logic Tests', () {
    test('Calculates available budget with pending salary correctly', () {
      // Scenario: Current balance is 2,000 THB (salary not in yet),
      // savings target is 5,000 THB, fixed remaining is 2,000 THB.
      // Without pending salary: 2,000 - 5,000 - 2,000 = -5,000 THB (deficit!)
      const currentBalance = 2000.0;
      const targetSavings = 5000.0;
      const remainingFixed = 2000.0;

      double availableWithoutSalary =
          currentBalance - targetSavings - remainingFixed;
      expect(availableWithoutSalary, -5000.0);

      // With pending salary of 30,000 THB:
      // (2,000 + 30,000) - 5,000 - 2,000 = 25,000 THB
      const pendingSalary = 30000.0;
      double availableWithSalary =
          (currentBalance + pendingSalary) - targetSavings - remainingFixed;
      expect(availableWithSalary, 25000.0);

      // Quota for 25 remaining days: 25,000 / 25 = 1,000 THB / day
      const remainingDays = 25;
      final quota = ((availableWithSalary / remainingDays) / 10).round() * 10.0;
      expect(quota, 1000.0);
    });
  });
}
