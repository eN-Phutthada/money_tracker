import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/scheduled_payment_model.dart';
import 'package:money_tracker/app/data/models/scheduled_payment_preset.dart';
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

  group('ScheduledPaymentPreset Tests', () {
    test('Curated presets list is populated with valid presets', () {
      final presets = ScheduledPaymentPreset.curatedPresets;
      expect(presets.isNotEmpty, isTrue);
      expect(presets.length, greaterThanOrEqualTo(10));

      for (final p in presets) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.titleKey.isNotEmpty, isTrue);
        expect(p.suggestedAmount, isNotNull);
        expect(p.suggestedAmount!, greaterThan(0));
        expect(p.categoryName.isNotEmpty, isTrue);
        expect(p.titleKey.tr.isNotEmpty, isTrue);
      }
    });

    test('createScheduledPaymentFromPreset creates scheduled payment correctly', () {
      final storageService = StorageService();
      Get.put<StorageService>(storageService);
      final controller = DashboardController();
      Get.put<DashboardController>(controller);

      expect(controller.scheduledPayments.isEmpty, isTrue);

      final preset = ScheduledPaymentPreset.curatedPresets.firstWhere(
        (p) => p.id == 'preset_electricity',
      );

      controller.createScheduledPaymentFromPreset(preset, notify: false);

      expect(controller.scheduledPayments.length, 1);
      final created = controller.scheduledPayments.first;
      expect(created.title, preset.titleKey.tr);
      expect(created.amount, preset.suggestedAmount);
      expect(created.categoryName, preset.categoryName);
      expect(created.costNature, CostNature.fixed);
      expect(created.frequency, ScheduleFrequency.monthly);
      expect(created.status, ScheduledPaymentStatus.active);
    });
  });

  group('Smart History Recurring Suggestions Tests', () {
    test('detectedRecurringTransactionSuggestions detects repeating payments from history', () {
      final storageService = StorageService();
      Get.put<StorageService>(storageService);
      final controller = DashboardController();
      Get.put<DashboardController>(controller);

      // Add single payment (should NOT be detected yet)
      controller.addTransaction(
        TransactionItem(
          id: 'tx-1',
          title: 'AIS Fibre',
          amount: 599.0,
          type: TransactionType.expense,
          categoryName: 'การสื่อสาร',
          date: DateTime(2026, 8, 10),
        ),
        notify: false,
      );

      expect(controller.detectedRecurringTransactionSuggestions.isEmpty, isTrue);

      // Add 2nd payment 30 days later (SHOULD be detected as recurring!)
      controller.addTransaction(
        TransactionItem(
          id: 'tx-2',
          title: 'AIS Fibre',
          amount: 599.0,
          type: TransactionType.expense,
          categoryName: 'การสื่อสาร',
          date: DateTime(2026, 9, 10),
        ),
        notify: false,
      );

      final suggestions = controller.detectedRecurringTransactionSuggestions;
      expect(suggestions.length, 1);
      expect(suggestions.first.title, 'AIS Fibre');
      expect(suggestions.first.amount, 599.0);

      // 1-Tap convert to scheduled payment
      controller.createScheduledPaymentFromHistoricalTransaction(
        suggestions.first,
        notify: false,
      );

      expect(controller.scheduledPayments.length, 1);
      expect(controller.scheduledPayments.first.title, 'AIS Fibre');
      expect(controller.scheduledPayments.first.amount, 599.0);

      // Now that it is scheduled, it must no longer appear in detected suggestions
      expect(controller.detectedRecurringTransactionSuggestions.isEmpty, isTrue);
    });
  });
}
