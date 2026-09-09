import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/budget_plan_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';

void main() {
  group('TransactionItem Model Tests', () {
    test('Create and JSON serialize/deserialize', () {
      final now = DateTime(2026, 9, 9, 12, 0);
      final item = TransactionItem(
        id: 'tx_123',
        title: 'ข้าวกะเพราไข่ดาว',
        amount: 65,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร',
        date: now,
        note: 'มื้อเที่ยง',
      );

      final json = item.toJson();
      final fromJson = TransactionItem.fromJson(json);

      expect(fromJson.id, 'tx_123');
      expect(fromJson.title, 'ข้าวกะเพราไข่ดาว');
      expect(fromJson.amount, 65.0);
      expect(fromJson.type, TransactionType.expense);
      expect(fromJson.costNature, CostNature.variable);
      expect(fromJson.categoryName, 'อาหาร');
      expect(fromJson.date, now);
      expect(fromJson.note, 'มื้อเที่ยง');
      expect(fromJson.isExpense, isTrue);
      expect(fromJson.isVariableCost, isTrue);
    });

    test('Enum values parsing via fromJson', () {
      final itemIncome = TransactionItem.fromJson({
        'type': 'income',
        'costNature': 'notApplicable',
      });
      expect(itemIncome.type, TransactionType.income);
      expect(itemIncome.costNature, CostNature.notApplicable);

      final itemSavings = TransactionItem.fromJson({
        'type': 'savingsInvestment',
        'costNature': 'notApplicable',
      });
      expect(itemSavings.type, TransactionType.savingsInvestment);
      expect(itemSavings.isSavings, isTrue);

      final itemFixed = TransactionItem.fromJson({
        'type': 'expense',
        'costNature': 'fixed',
      });
      expect(itemFixed.type, TransactionType.expense);
      expect(itemFixed.isFixedCost, isTrue);
    });
  });

  group('BudgetPlan Model Tests', () {
    test('Default budget plan calculations', () {
      const plan = BudgetPlan(
        plannedIncome: 45000,
        targetDailyAllowance: 300,
        targetMonthlySavings: 10000,
        plannedFixedCosts: 12500,
      );

      expect(plan.plannedIncome, 45000.0);
      expect(plan.targetDailyAllowance, 300.0);
      expect(plan.targetMonthlySavings, 10000.0);
      expect(plan.plannedFixedCosts, 12500.0);

      expect(plan.plannedVariableBudget(30), 9000.0);
      expect(plan.expectedEndingBalance(30), 13500.0);
    });

    test('JSON serialization & deserialization', () {
      const plan = BudgetPlan(
        plannedIncome: 50000,
        targetDailyAllowance: 350,
        targetMonthlySavings: 12000,
        plannedFixedCosts: 15000,
      );

      final json = plan.toJson();
      final fromJson = BudgetPlan.fromJson(json);

      expect(fromJson.plannedIncome, 50000.0);
      expect(fromJson.targetDailyAllowance, 350.0);
      expect(fromJson.targetMonthlySavings, 12000.0);
      expect(fromJson.plannedFixedCosts, 15000.0);
    });
  });
}
