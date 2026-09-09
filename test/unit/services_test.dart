import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/csv_service.dart';
import 'package:money_tracker/app/data/services/security_service.dart';

void main() {
  group('CsvService Tests', () {
    test('Generate CSV with UTF-8 BOM and parse back', () {
      final now = DateTime(2026, 9, 9, 14, 30);
      final items = [
        TransactionItem(
          id: 'tx_001',
          title: 'เงินเดือน',
          amount: 50000,
          type: TransactionType.income,
          costNature: CostNature.variable,
          categoryName: 'เงินเดือน',
          date: now,
          note: 'เงินเดือนประจำเดือน',
        ),
        TransactionItem(
          id: 'tx_002',
          title: 'ค่ากาแฟ Specialty',
          amount: 140,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'กาแฟ/เครื่องดื่ม',
          date: now,
          note: 'Dirty Coffee',
        ),
      ];

      final csvContent = CsvService.exportToCsv(items);

      // Verify UTF-8 BOM is present
      expect(csvContent.startsWith('\uFEFF'), isTrue);

      // Parse back
      final parsedItems = CsvService.importFromCsv(csvContent);
      expect(parsedItems.length, 2);
      expect(parsedItems[0].title, 'เงินเดือน');
      expect(parsedItems[0].amount, 50000.0);
      expect(parsedItems[0].type, TransactionType.income);

      expect(parsedItems[1].title, 'ค่ากาแฟ Specialty');
      expect(parsedItems[1].amount, 140.0);
      expect(parsedItems[1].type, TransactionType.expense);
    });
  });

  group('SecurityService Tests', () {
    test('PIN verification flow', () {
      final service = SecurityService();
      // Default: pin not enabled, verify returns true
      expect(service.isPinEnabled, isFalse);
      expect(service.verifyPin('1234'), isTrue);
    });
  });
}
