import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/main.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/dashboard/views/dashboard_view.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/modules/transactions/views/quick_add_bottom_sheet.dart';
import 'package:money_tracker/app/routes/app_routes.dart';

void main() {
  testWidgets('Full navigation and interaction test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoneyTrackerApp());
    await tester.pumpAndSettle();

    // Verify Dashboard
    expect(find.text('Personal Finance'), findsOneWidget);
    expect(find.text('รายเดือน'), findsOneWidget);
    expect(find.text('รายปี'), findsOneWidget);
    expect(find.text('ทั้งหมด'), findsOneWidget);

    // Test period switching in DashboardHeader
    await tester.tap(find.text('รายปี'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ทั้งหมด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายเดือน'));
    await tester.pumpAndSettle();

    // Try navigating to Budget Settings
    Get.toNamed(Routes.BUDGET_SETTINGS);
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่างบประมาณ'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to Transactions List
    Get.toNamed(Routes.TRANSACTIONS_LIST);
    await tester.pumpAndSettle();
    expect(find.text('รายการธุรกรรมทั้งหมด'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to Data Management
    Get.toNamed(Routes.DATA_MANAGEMENT);
    await tester.pumpAndSettle();
    expect(find.text('จัดการข้อมูล (Data Management)'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to PIN Settings
    Get.toNamed(Routes.PIN_SETTINGS);
    await tester.pumpAndSettle();
    expect(find.text('ความปลอดภัยและรหัส PIN'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Test QuickAddBottomSheet (Thai)
    QuickAddBottomSheet.show(tester.element(find.byType(DashboardView)));
    await tester.pumpAndSettle();
    expect(find.text('บันทึกรายการ'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();

    // Test QuickAddBottomSheet (English)
    final dashController = Get.find<DashboardController>();
    dashController.setLanguage('en');
    await tester.pumpAndSettle();

    QuickAddBottomSheet.show(tester.element(find.byType(DashboardView)));
    await tester.pumpAndSettle();
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Record Income & Expense'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Food & Dining'), findsWidgets);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();

    // Reset back to Thai
    dashController.setLanguage('th');
    await tester.pumpAndSettle();

    // Test Locking and PIN Success Animation
    final secController = Get.find<SecurityController>();
    await secController.setPin('1234');
    secController.lock();
    await tester.pumpAndSettle();

    expect(find.text('Money Tracker Security'), findsOneWidget);

    // Enter PIN: 1, 2, 3, 4
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();

    // Verify Success Animation state is rendered
    expect(find.text('ปลดล็อกสำเร็จ'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับกลับสู่ Money Tracker'), findsOneWidget);

    // Settle through success and exit animation transitions
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify successfully returned to Dashboard
    expect(find.text('Personal Finance'), findsOneWidget);
  });
}
