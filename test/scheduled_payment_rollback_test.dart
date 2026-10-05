import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/scheduled_payment_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/storage_service.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  tearDown(() {
    Get.reset();
  });

  test('executeScheduledPayment records linkage and deleteTransaction reverts due date', () async {
    final storageService = StorageService();
    Get.put<StorageService>(storageService);

    final controller = DashboardController();
    Get.put<DashboardController>(controller);

    final initialDueDate = DateTime(2026, 10, 25, 9, 0);
    final sched = ScheduledPaymentItem(
      id: 'sched-101',
      title: 'ค่าเช่าห้อง',
      amount: 6500.0,
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      categoryName: 'ที่อยู่อาศัย',
      frequency: ScheduleFrequency.monthly,
      startDate: initialDueDate,
      nextDueDate: initialDueDate,
      status: ScheduledPaymentStatus.active,
    );

    controller.addScheduledPayment(sched, notify: false);
    expect(controller.scheduledPayments.length, 1);
    expect(controller.scheduledPayments.first.nextDueDate, initialDueDate);

    // 1. Execute scheduled payment
    controller.executeScheduledPayment(sched, executionDate: initialDueDate, notify: false);

    // Verify transaction created with linkage
    expect(controller.transactions.length, 1);
    final tx = controller.transactions.first;
    expect(tx.title, 'ค่าเช่าห้อง');
    expect(tx.amount, 6500.0);
    expect(tx.scheduledPaymentId, 'sched-101');
    expect(tx.originalScheduledDueDate, initialDueDate);

    // Verify scheduled payment advanced to next month (Nov 25)
    final advancedSched = controller.scheduledPayments.first;
    expect(advancedSched.nextDueDate, DateTime(2026, 11, 25, 9, 0));
    expect(advancedSched.previousDueDate, initialDueDate);

    // 2. User deletes the transaction because it was recorded by mistake
    controller.deleteTransaction(tx.id);

    // Verify transaction removed
    expect(controller.transactions.isEmpty, isTrue);

    // Verify scheduled payment rolled back to initial due date (Oct 25)
    final revertedSched = controller.scheduledPayments.first;
    expect(revertedSched.nextDueDate, initialDueDate);
    expect(revertedSched.status, ScheduledPaymentStatus.active);

    // 3. User taps "Undo" in snackbar / re-adds the transaction
    controller.addTransaction(tx, notify: false);
    expect(controller.transactions.length, 1);

    // Verify scheduled payment advances forward again (Nov 25)
    final reAdvancedSched = controller.scheduledPayments.first;
    expect(reAdvancedSched.nextDueDate, DateTime(2026, 11, 25, 9, 0));
  });

  test('One-time scheduled payment execution and rollback on transaction deletion', () async {
    final storageService = StorageService();
    Get.put<StorageService>(storageService);

    final controller = DashboardController();
    Get.put<DashboardController>(controller);

    final oneTimeDate = DateTime(2026, 10, 15, 14, 0);
    final oneTimeSched = ScheduledPaymentItem(
      id: 'ot-102',
      title: 'จ่ายค่ามัดจำ',
      amount: 3000.0,
      type: TransactionType.expense,
      costNature: CostNature.fixed,
      categoryName: 'ทั่วไป',
      frequency: ScheduleFrequency.oneTime,
      startDate: oneTimeDate,
      nextDueDate: oneTimeDate,
      status: ScheduledPaymentStatus.active,
    );

    controller.addScheduledPayment(oneTimeSched, notify: false);

    // 1. Execute one-time schedule
    controller.executeScheduledPayment(oneTimeSched, executionDate: oneTimeDate, notify: false);

    expect(controller.transactions.length, 1);
    final tx = controller.transactions.first;
    expect(tx.scheduledPaymentId, 'ot-102');

    // Should be completed
    final completedSched = controller.scheduledPayments.first;
    expect(completedSched.status, ScheduledPaymentStatus.completed);

    // 2. Delete transaction -> should revert to active and keep due date
    controller.deleteTransaction(tx.id);
    expect(controller.transactions.isEmpty, isTrue);

    final restoredSched = controller.scheduledPayments.first;
    expect(restoredSched.status, ScheduledPaymentStatus.active);
    expect(restoredSched.nextDueDate, oneTimeDate);
  });
}
