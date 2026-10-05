import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/scheduled_payment_model.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';

void main() {
  group('ScheduledPaymentItem Model Tests', () {
    test('calculateNextDueDate for daily frequency', () {
      final item = ScheduledPaymentItem(
        id: '1',
        title: 'Daily Coffee',
        amount: 60.0,
        categoryName: 'กาแฟ/เครื่องดื่ม',
        frequency: ScheduleFrequency.daily,
        startDate: DateTime(2026, 10, 1, 8, 30),
        nextDueDate: DateTime(2026, 10, 1, 8, 30),
      );

      final next = item.calculateNextDueDate();
      expect(next, DateTime(2026, 10, 2, 8, 30));
    });

    test('calculateNextDueDate for weekly frequency', () {
      final item = ScheduledPaymentItem(
        id: '2',
        title: 'Weekly Allowance',
        amount: 1500.0,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.weekly,
        startDate: DateTime(2026, 10, 5, 9, 0),
        nextDueDate: DateTime(2026, 10, 5, 9, 0),
      );

      final next = item.calculateNextDueDate();
      expect(next, DateTime(2026, 10, 12, 9, 0));
    });

    test('calculateNextDueDate for monthly frequency', () {
      final item = ScheduledPaymentItem(
        id: '3',
        title: 'Rent',
        amount: 8500.0,
        categoryName: 'ที่อยู่อาศัย',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 10, 25, 10, 0),
        nextDueDate: DateTime(2026, 10, 25, 10, 0),
      );

      final next = item.calculateNextDueDate();
      expect(next, DateTime(2026, 11, 25, 10, 0));
    });

    test('calculateNextDueDate for monthly frequency on month-end edge case (31st to Feb)', () {
      final item = ScheduledPaymentItem(
        id: '4',
        title: 'Utility Bill',
        amount: 1200.0,
        categoryName: 'สาธารณูปโภค',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 1, 31, 12, 0),
        nextDueDate: DateTime(2026, 1, 31, 12, 0),
      );

      final next = item.calculateNextDueDate();
      // Year 2026 February has 28 days
      expect(next, DateTime(2026, 2, 28, 12, 0));
    });

    test('calculateNextDueDate for yearly frequency', () {
      final item = ScheduledPaymentItem(
        id: '5',
        title: 'Car Insurance',
        amount: 18000.0,
        categoryName: 'ประกัน',
        frequency: ScheduleFrequency.yearly,
        startDate: DateTime(2026, 10, 5, 10, 0),
        nextDueDate: DateTime(2026, 10, 5, 10, 0),
      );

      final next = item.calculateNextDueDate();
      expect(next, DateTime(2027, 10, 5, 10, 0));
    });

    test('toJson and fromJson symmetry', () {
      final original = ScheduledPaymentItem(
        id: '123',
        title: 'AIS Fibre',
        amount: 599.0,
        type: TransactionType.expense,
        costNature: CostNature.fixed,
        categoryName: 'สาธารณูปโภค',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 10, 1, 9, 0),
        nextDueDate: DateTime(2026, 11, 1, 9, 0),
        autoRecord: true,
        status: ScheduledPaymentStatus.active,
        note: 'High speed internet',
        reminderDaysBefore: 3,
      );

      final json = original.toJson();
      final restored = ScheduledPaymentItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.costNature, original.costNature);
      expect(restored.categoryName, original.categoryName);
      expect(restored.frequency, original.frequency);
      expect(restored.startDate, original.startDate);
      expect(restored.nextDueDate, original.nextDueDate);
      expect(restored.autoRecord, original.autoRecord);
      expect(restored.status, original.status);
      expect(restored.note, original.note);
      expect(restored.reminderDaysBefore, original.reminderDaysBefore);
    });

    test('due date status helpers', () {
      final now = DateTime.now();

      // Today
      final todayItem = ScheduledPaymentItem(
        id: 'today',
        title: 'Today Bill',
        amount: 100,
        categoryName: 'ทั่วไป',
        startDate: now,
        nextDueDate: DateTime(now.year, now.month, now.day, 12, 0),
      );
      expect(todayItem.isDue, isTrue);
      expect(todayItem.daysUntilDue, 0);

      // Future (7 days later)
      final futureDate = now.add(const Duration(days: 7));
      final futureItem = ScheduledPaymentItem(
        id: 'future',
        title: 'Future Bill',
        amount: 200,
        categoryName: 'ทั่วไป',
        startDate: now,
        nextDueDate: DateTime(futureDate.year, futureDate.month, futureDate.day, 12, 0),
      );
      expect(futureItem.isDue, isFalse);
      expect(futureItem.daysUntilDue, 7);
      expect(futureItem.isDueSoon(7), isTrue);
      expect(futureItem.isDueSoon(3), isFalse);

      // Overdue (3 days ago)
      final pastDate = now.subtract(const Duration(days: 3));
      final overdueItem = ScheduledPaymentItem(
        id: 'overdue',
        title: 'Overdue Bill',
        amount: 300,
        categoryName: 'ทั่วไป',
        startDate: pastDate,
        nextDueDate: DateTime(pastDate.year, pastDate.month, pastDate.day, 12, 0),
      );
      expect(overdueItem.isDue, isTrue);
      expect(overdueItem.daysUntilDue, -3);
    });

    test('calculatePreviousDueDate for daily, weekly, monthly, and yearly', () {
      // Daily
      final daily = ScheduledPaymentItem(
        id: 'd1',
        title: 'Daily test',
        amount: 50,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.daily,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 5, 8, 0),
      );
      expect(daily.calculatePreviousDueDate(), DateTime(2026, 10, 4, 8, 0));

      // Weekly
      final weekly = ScheduledPaymentItem(
        id: 'w1',
        title: 'Weekly test',
        amount: 500,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.weekly,
        startDate: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2026, 10, 15, 9, 30),
      );
      expect(weekly.calculatePreviousDueDate(), DateTime(2026, 10, 8, 9, 30));

      // Monthly
      final monthly = ScheduledPaymentItem(
        id: 'm1',
        title: 'Monthly test',
        amount: 1000,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2026, 3, 25, 10, 0),
        nextDueDate: DateTime(2026, 4, 25, 10, 0),
      );
      expect(monthly.calculatePreviousDueDate(), DateTime(2026, 3, 25, 10, 0));

      // Monthly rolling back over New Year (Jan to Dec of previous year)
      final janItem = ScheduledPaymentItem(
        id: 'jan',
        title: 'Jan bill',
        amount: 2000,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.monthly,
        startDate: DateTime(2025, 5, 15, 10, 0),
        nextDueDate: DateTime(2026, 1, 15, 10, 0),
      );
      expect(janItem.calculatePreviousDueDate(), DateTime(2025, 12, 15, 10, 0));

      // Yearly
      final yearly = ScheduledPaymentItem(
        id: 'y1',
        title: 'Yearly bill',
        amount: 15000,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.yearly,
        startDate: DateTime(2025, 8, 10, 12, 0),
        nextDueDate: DateTime(2026, 8, 10, 12, 0),
      );
      expect(yearly.calculatePreviousDueDate(), DateTime(2025, 8, 10, 12, 0));

      // One-time returns startDate
      final oneTime = ScheduledPaymentItem(
        id: 'ot1',
        title: 'One-time bill',
        amount: 5000,
        categoryName: 'ทั่วไป',
        frequency: ScheduleFrequency.oneTime,
        startDate: DateTime(2026, 10, 1, 9, 0),
        nextDueDate: DateTime(2026, 10, 20, 9, 0),
      );
      expect(oneTime.calculatePreviousDueDate(), DateTime(2026, 10, 1, 9, 0));
    });

    test('previousDueDate preservation in copyWith and serialization', () {
      final prevDate = DateTime(2026, 9, 25, 10, 0);
      final item = ScheduledPaymentItem(
        id: 'test-prev',
        title: 'Bill with previousDueDate',
        amount: 1200,
        categoryName: 'ที่อยู่อาศัย',
        startDate: DateTime(2026, 9, 25, 10, 0),
        nextDueDate: DateTime(2026, 10, 25, 10, 0),
        previousDueDate: prevDate,
      );

      final json = item.toJson();
      final restored = ScheduledPaymentItem.fromJson(json);

      expect(restored.previousDueDate, prevDate);
    });

    test('TransactionItem scheduled payment linkage serialization', () {
      final origDue = DateTime(2026, 10, 25, 10, 0);
      final tx = TransactionItem(
        id: 'tx-1',
        title: 'Paid Rent',
        amount: 8500,
        type: TransactionType.expense,
        categoryName: 'ที่อยู่อาศัย',
        date: DateTime(2026, 10, 25),
        scheduledPaymentId: 'sched-123',
        originalScheduledDueDate: origDue,
      );

      final json = tx.toJson();
      final restored = TransactionItem.fromJson(json);

      expect(restored.scheduledPaymentId, 'sched-123');
      expect(restored.originalScheduledDueDate, origDue);
    });
  });
}
