import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/main.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/dashboard/views/dashboard_view.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/modules/transactions/views/quick_add_bottom_sheet.dart';
import 'package:money_tracker/app/routes/app_routes.dart';

import 'package:money_tracker/app/widgets/liquid_glass_nav_dock.dart';

void main() {
  testWidgets('Full navigation and interaction test', (WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('th', 'TH');
    addTearDown(() => tester.platformDispatcher.clearLocaleTestValue());

    await tester.pumpWidget(const MoneyTrackerApp(initialLocale: Locale('th', 'TH')));
    await tester.pumpAndSettle();

    // Verify Dashboard
    expect(find.text('Personal Finance'), findsOneWidget);
    expect(find.text('รายเดือน'), findsOneWidget);
    expect(find.text('รายปี'), findsOneWidget);
    expect(find.text('ทั้งหมด'), findsOneWidget);
    expect(find.byType(LiquidGlassNavDock), findsOneWidget);

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
    expect(find.text('เป้าหมายเงินออมและลงทุน'), findsOneWidget);
    expect(find.text('ค่าใช้จ่ายคงที่'), findsOneWidget);
    expect(find.text('เงินเดือน ฟรีแลนซ์ โบนัส ดอกเบี้ย และรายรับอื่นๆ'), findsOneWidget);
    expect(find.text('DCA หุ้น กองทุนรวม สำรองฉุกเฉิน ทองคำ'), findsOneWidget);
    expect(find.text('ค่าห้อง ค่าน้ำ ค่าไฟ ผ่อนรถ ประกัน ค่าสมาชิก'), findsOneWidget);
    expect(find.textContaining('ของรายได้'), findsWidgets);
    expect(find.byType(LiquidGlassNavDock), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to Transactions List
    Get.toNamed(Routes.TRANSACTIONS_LIST);
    await tester.pumpAndSettle();
    expect(find.text('รายการธุรกรรมทั้งหมด'), findsOneWidget);
    expect(find.byType(LiquidGlassNavDock), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to Data Management
    Get.toNamed(Routes.DATA_MANAGEMENT);
    await tester.pumpAndSettle();
    expect(find.text('data_management'.tr), findsOneWidget);
    expect(find.byType(LiquidGlassNavDock), findsNothing);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Try navigating to PIN Settings
    Get.toNamed(Routes.PIN_SETTINGS);
    await tester.pumpAndSettle();
    expect(find.text('ความปลอดภัยและรหัส PIN'), findsOneWidget);
    expect(find.byType(LiquidGlassNavDock), findsNothing);

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

    expect(find.text('pin_security_title'.tr), findsOneWidget);

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

    // Test Language Toggle
    dashController.toggleLanguage();
    await tester.pumpAndSettle();
    expect(dashController.isEnglish, isTrue);

    // Toggle back to TH
    dashController.toggleLanguage();
    await tester.pumpAndSettle();
    expect(dashController.isEnglish, isFalse);

    // Test Navigation Dock Hub & Vault Menu (Central Settings Location)
    expect(find.byIcon(Icons.widgets_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.widgets_rounded));
    await tester.pumpAndSettle();

    // Verify Hub & Vault menu items are displayed
    expect(find.text('HUB & VAULT CENTER'), findsOneWidget);
    expect(find.text('จัดการข้อมูล'), findsOneWidget);
    expect(find.text('ธีมการแสดงผล'), findsOneWidget);

    // Tap theme setting to open theme dialog
    await tester.tap(find.text('ธีมการแสดงผล'));
    await tester.pumpAndSettle();

    // Verify Light Mode and Dark Mode exist, and 'ตามระบบ' is removed
    expect(find.text('โหมดสว่าง'), findsOneWidget);
    expect(find.text('โหมดมืด'), findsOneWidget);
    expect(find.text('ตามระบบ'), findsNothing);

    // Select Dark Mode
    await tester.tap(find.text('โหมดมืด'));
    await tester.pumpAndSettle();
    expect(dashController.themeMode.value, ThemeMode.dark);
  });
}

