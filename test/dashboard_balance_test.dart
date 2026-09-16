import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardController - totalCurrentBalance (เงินเหลือปัจจุบันสะสมทั้งหมด)', () {
    late DashboardController controller;

    setUp(() {
      controller = DashboardController();
    });

    test('Returns 0.0 when transactions list is empty', () {
      controller.transactions.clear();
      expect(controller.totalCurrentBalance, equals(0.0));
      expect(controller.actualBalance, equals(0.0));
    });

    test('Calculates all-time net current balance (Income - Expense - Savings) accurately', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      controller.transactions.assignAll([
        // Last month transactions
        TransactionItem(
          id: '1',
          title: 'เงินเดือนเดือนก่อน',
          amount: 50000.0,
          type: TransactionType.income,
          categoryName: 'เงินเดือน',
          date: lastMonth,
        ),
        TransactionItem(
          id: '2',
          title: 'ค่าหอเดือนก่อน',
          amount: 8000.0,
          type: TransactionType.expense,
          costNature: CostNature.fixed,
          categoryName: 'ที่อยู่อาศัย',
          date: lastMonth,
        ),
        TransactionItem(
          id: '3',
          title: 'DCA หุ้นเดือนก่อน',
          amount: 5000.0,
          type: TransactionType.savingsInvestment,
          categoryName: 'เงินออม/DCA',
          date: lastMonth,
        ),

        // This month transactions
        TransactionItem(
          id: '4',
          title: 'เงินเดือนเดือนนี้',
          amount: 50000.0,
          type: TransactionType.income,
          categoryName: 'เงินเดือน',
          date: now,
        ),
        TransactionItem(
          id: '5',
          title: 'ค่ากินวันนี้',
          amount: 1200.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร/ของกิน',
          date: now,
        ),
        TransactionItem(
          id: '6',
          title: 'กองทุนสำรองเลี้ยงชีพ',
          amount: 3000.0,
          type: TransactionType.savingsInvestment,
          categoryName: 'เงินออม/DCA',
          date: now,
        ),
      ]);

      // All-time:
      // Income = 50,000 + 50,000 = 100,000
      // Expense = 8,000 + 1,200 = 9,200
      // Savings = 5,000 + 3,000 = 8,000
      // Total Current Balance = 100,000 - 9,200 - 8,000 = 82,800
      expect(controller.totalCurrentBalance, equals(82800.0));

      // Period balance (monthly filter for this month):
      // Income = 50,000
      // Expense = 1,200
      // Savings = 3,000
      // Actual Period Balance = 50,000 - 1,200 - 3,000 = 45,800
      expect(controller.actualBalance, equals(45800.0));

      // Verify that changing period to yearly or allTime keeps totalCurrentBalance all-time net
      controller.setTimeFilter(TimeFilterPeriod.allTime);
      expect(controller.totalCurrentBalance, equals(82800.0));
      expect(controller.actualBalance, equals(82800.0));

      controller.setTimeFilter(TimeFilterPeriod.monthly);
      expect(controller.totalCurrentBalance, equals(82800.0));
      expect(controller.actualBalance, equals(45800.0));
    });

    test('Correctly reflects deficit when expenses exceed income', () {
      controller.transactions.assignAll([
        TransactionItem(
          id: '1',
          title: 'รายรับเริ่มต้น',
          amount: 1000.0,
          type: TransactionType.income,
          categoryName: 'อื่นๆ',
          date: DateTime.now(),
        ),
        TransactionItem(
          id: '2',
          title: 'ซ่อมรถฉุกเฉิน',
          amount: 4500.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'ยานพาหนะ',
          date: DateTime.now(),
        ),
      ]);

      // 1000 - 4500 = -3500
      expect(controller.totalCurrentBalance, equals(-3500.0));
    });

    test('Dynamic daily quota: calculates (currentBalance - savings - fixedCosts) / remainingDays', () {
      final now = DateTime.now();
      controller.transactions.assignAll([
        TransactionItem(
          id: '1',
          title: 'เงินเดือนสะสม',
          amount: 50000.0,
          type: TransactionType.income,
          categoryName: 'เงินเดือน',
          date: now,
        ),
      ]);

      // Total balance = 50,000
      // Plan: savings = 10,000, fixed = 12,500
      // Available = 50,000 - 10,000 - 12,500 = 27,500
      expect(controller.totalCurrentBalance, equals(50000.0));
      expect(controller.dynamicAvailableMonthlyBudget, equals(27500.0));

      final days = controller.remainingDaysInMonth > 0 ? controller.remainingDaysInMonth : 1;
      final expectedDaily = ((27500.0 / days) / 10).round() * 10.0;
      expect(controller.dynamicCalculatedDailyQuota, equals(expectedDaily));

      // Test apply quota
      controller.applyDynamicCalculatedQuota();
      expect(controller.budgetPlan.value.targetDailyAllowance, equals(expectedDaily));
    });

    test('ThemeMode defaults to system on controller start', () {
      expect(controller.themeMode.value, equals(ThemeMode.system));
    });

    test('Monthly view: periodHeroBalance is totalCurrentBalance (เงินเหลือปัจจุบัน)', () {
      final now = DateTime.now();
      controller.transactions.assignAll([
        TransactionItem(
          id: '1',
          title: 'เงินเก็บตั้งต้น',
          amount: 60000.0,
          type: TransactionType.income,
          categoryName: 'เงินเก็บ',
          date: DateTime(now.year, now.month - 1, 1),
        ),
        TransactionItem(
          id: '2',
          title: 'ค่าใช้จ่ายเดือนนี้',
          amount: 5000.0,
          type: TransactionType.expense,
          categoryName: 'อาหาร',
          date: now,
        ),
      ]);

      // In monthly mode: hero balance is total current balance (60,000 - 5,000 = 55,000)
      controller.setTimeFilter(TimeFilterPeriod.monthly);
      expect(controller.periodHeroBalance, equals(55000.0));
      expect(controller.actualBalance, equals(-5000.0)); // month cashflow is -5,000

      // In yearly mode: hero balance is actual period balance (-5,000 or year cashflow)
      controller.setTimeFilter(TimeFilterPeriod.yearly);
      expect(controller.periodHeroBalance, equals(controller.actualBalance));
    });

    test('End-of-month salary: wallet status is NOT red if totalCurrentBalance covers remaining commitments', () {
      final now = DateTime.now();
      // Suppose today is day 10, salary arrives at end of month (no income yet this month)
      // User has 40,000 in wallet from previous months
      controller.transactions.assignAll([
        TransactionItem(
          id: '1',
          title: 'เงินในบัญชีเดิม',
          amount: 40000.0,
          type: TransactionType.income,
          categoryName: 'เงินเก็บ',
          date: DateTime(now.year, now.month - 1, 28),
        ),
        TransactionItem(
          id: '2',
          title: 'ค่ากินต้นเดือน',
          amount: 3000.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร',
          date: now,
        ),
      ]);

      controller.setTimeFilter(TimeFilterPeriod.monthly);

      // Even though month income is 0 and month cashflow is -3,000:
      // Current balance = 37,000.
      // Remaining commitments = remaining fixed costs + (remaining days * daily quota)
      // 37,000 is more than enough to cover remaining commitments -> isSurplus must be TRUE (Green / Safe)!
      expect(controller.isSurplus, isTrue);

      // Now suppose user spent almost everything, balance drops to 500 baht:
      controller.transactions.add(
        TransactionItem(
          id: '3',
          title: 'ช้อปปิ้งใหญ่',
          amount: 36800.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'ช้อปปิ้ง',
          date: now,
        ),
      );
      // Balance is now 200 baht, which cannot cover remaining commitments
      expect(controller.totalCurrentBalance, equals(200.0));
      expect(controller.isSurplus, isFalse); // Turns red/caution to protect user!
    });
  });
}
