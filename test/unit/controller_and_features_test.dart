import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/data/services/storage_service.dart';
import 'package:money_tracker/app/modules/budget/controllers/budget_controller.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/app_feedback.dart';
import 'package:money_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  group('DashboardController & Real-world Usability Tests', () {
    late DashboardController controller;

    setUp(() {
      Get.reset();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
      controller = Get.put(DashboardController());
    });

    test('Add, update, and delete transaction lifecycle', () {
      final item = TransactionItem(
        id: 'tx_test_1',
        title: 'ค่าก๋วยเตี๋ยว',
        amount: 60.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime(2026, 9, 10),
      );

      // Add
      controller.addTransaction(item);
      expect(controller.transactions.any((t) => t.id == 'tx_test_1'), isTrue);

      // Update
      final updated = item.copyWith(amount: 75.0, title: 'ก๋วยเตี๋ยวพิเศษ');
      controller.updateTransaction(updated);

      final found = controller.transactions.firstWhere((t) => t.id == 'tx_test_1');
      expect(found.amount, 75.0);
      expect(found.title, 'ก๋วยเตี๋ยวพิเศษ');

      // Delete
      controller.deleteTransaction('tx_test_1');
      expect(controller.transactions.any((t) => t.id == 'tx_test_1'), isFalse);
    });

    test('Clear all to empty (Clean Slate)', () async {
      controller.addTransaction(TransactionItem(
        id: 'tx_dummy',
        title: 'Dummy Item',
        amount: 500.0,
        type: TransactionType.expense,
        costNature: CostNature.variable,
        categoryName: 'อาหาร/ของกิน',
        date: DateTime.now(),
      ));
      expect(controller.transactions.isNotEmpty, isTrue);

      await controller.clearAllToEmpty();
      expect(controller.transactions.isEmpty, isTrue);
    });

    test('Financial calculations update correctly on new transactions', () {
      controller.transactions.assignAll([
        TransactionItem(
          id: '1',
          title: 'เงินเดือน',
          amount: 50000.0,
          type: TransactionType.income,
          categoryName: 'เงินเดือน',
          date: DateTime.now(),
        ),
        TransactionItem(
          id: '2',
          title: 'ค่าห้อง',
          amount: 10000.0,
          type: TransactionType.expense,
          costNature: CostNature.fixed,
          categoryName: 'ที่อยู่อาศัย',
          date: DateTime.now(),
        ),
        TransactionItem(
          id: '3',
          title: 'DCA S&P500',
          amount: 5000.0,
          type: TransactionType.savingsInvestment,
          categoryName: 'เงินออม/DCA',
          date: DateTime.now(),
        ),
        TransactionItem(
          id: '4',
          title: 'ค่าข้าว',
          amount: 300.0,
          type: TransactionType.expense,
          costNature: CostNature.variable,
          categoryName: 'อาหาร/ของกิน',
          date: DateTime.now(),
        ),
      ]);

      expect(controller.actualIncome, 50000.0);
      expect(controller.actualExpenses, 10300.0);
      expect(controller.actualSavings, 5000.0);
      expect(controller.totalFixedExpenses, 10000.0);
      expect(controller.totalVariableExpenses, 300.0);
      expect(controller.todayVariableExpenses, 300.0);
      expect(controller.todayRemainingAllowance, 50.0); // 350 default target - 300 = 50
      expect(controller.actualBalance, 34700.0);
    });

    test('remainingDaysInMonth and remainingDailyAllowance exclude today', () {
      final now = DateTime.now();
      final totalDays = controller.daysInCurrentMonth;
      final expectedDays = (totalDays - now.day).clamp(0, totalDays);
      expect(controller.remainingDaysInMonth, expectedDays);

      if (expectedDays > 0) {
        expect(controller.remainingDailyAllowance, greaterThanOrEqualTo(0.0));
      } else {
        expect(controller.remainingDailyAllowance, 0.0);
      }
    });
  });

  group('BudgetController Tests', () {
    late DashboardController dashboardController;
    late BudgetController budgetController;

    setUp(() {
      Get.reset();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
      dashboardController = Get.put(DashboardController());
      budgetController = Get.put(BudgetController());
    });

    test('Edit budget parameters and save back to dashboard', () {
      budgetController.setPlannedIncome(60000.0);
      budgetController.setTargetMonthlySavings(15000.0);
      budgetController.setPlannedFixedCosts(18000.0);
      budgetController.targetDailyAllowance.value = 400.0;

      expect(budgetController.plannedIncome.value, 60000.0);
      expect(budgetController.targetMonthlySavings.value, 15000.0);
      expect(budgetController.plannedFixedCosts.value, 18000.0);
      expect(budgetController.targetDailyAllowance.value, 400.0);

      // Expected Ending Balance = 60000 - 18000 - (400 * days) - 15000
      final days = budgetController.daysInMonth;
      final expectedEnding = 60000.0 - 18000.0 - (400.0 * days) - 15000.0;
      expect(budgetController.expectedEndingBalance, expectedEnding);

      budgetController.save();
      final updatedPlan = dashboardController.budgetPlan.value;
      expect(updatedPlan.plannedIncome, 60000.0);
      expect(updatedPlan.targetMonthlySavings, 15000.0);
      expect(updatedPlan.plannedFixedCosts, 18000.0);
      expect(updatedPlan.targetDailyAllowance, 400.0);
    });

    test('Budget Templates 50/30/20, 60/20/20, and 40/30/30 calculations', () {
      budgetController.plannedIncome.value = 50000.0;

      // 50/30/20: Fixed 50% = 25,000, Var 30% = 15,000, Savings 20% = 10,000
      budgetController.applyTemplate(BudgetPresetType.rule50_30_20);
      expect(budgetController.plannedFixedCosts.value, 25000.0);
      expect(budgetController.targetMonthlySavings.value, 10000.0);
      expect(budgetController.savingsRatio, closeTo(0.20, 0.01));
      expect(budgetController.fixedCostsRatio, closeTo(0.50, 0.01));
      expect(budgetController.healthStatusMessage, contains('สมดุล'));

      // 60/20/20: Fixed 60% = 30,000, Var 20% = 10,000, Savings 20% = 10,000
      budgetController.applyTemplate(BudgetPresetType.rule60_20_20);
      expect(budgetController.plannedFixedCosts.value, 30000.0);
      expect(budgetController.targetMonthlySavings.value, 10000.0);
      expect(budgetController.fixedCostsRatio, closeTo(0.60, 0.01));

      // 40/30/30: Fixed 40% = 20,000, Var 30% = 15,000, Savings 30% = 15,000
      budgetController.applyTemplate(BudgetPresetType.rule40_30_30);
      expect(budgetController.plannedFixedCosts.value, 20000.0);
      expect(budgetController.targetMonthlySavings.value, 15000.0);
      expect(budgetController.savingsRatio, closeTo(0.30, 0.01));
      expect(budgetController.healthStatusMessage, contains('ยอดเยี่ยม'));
    });

    test('Quick Steppers adjust budget fields accurately', () {
      budgetController.plannedIncome.value = 30000.0;
      budgetController.adjustPlannedIncome(5000.0);
      expect(budgetController.plannedIncome.value, 35000.0);

      budgetController.targetMonthlySavings.value = 5000.0;
      budgetController.adjustTargetMonthlySavings(1000.0);
      expect(budgetController.targetMonthlySavings.value, 6000.0);
      budgetController.adjustTargetMonthlySavings(-500.0);
      expect(budgetController.targetMonthlySavings.value, 5500.0);

      budgetController.plannedFixedCosts.value = 10000.0;
      budgetController.adjustPlannedFixedCosts(500.0);
      expect(budgetController.plannedFixedCosts.value, 10500.0);

      budgetController.targetDailyAllowance.value = 300.0;
      budgetController.adjustDailyAllowance(50.0);
      expect(budgetController.targetDailyAllowance.value, 350.0);
    });
  });

  group('StorageService File Export Tests', () {
    setUp(() {
      Get.reset();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
    });

    test('saveExportFile generates a real file', () async {
      final storage = StorageService();
      const testContent = 'test,csv,content\n1,2,3';
      const testFilename = 'test_export_file.csv';

      final filePath = await storage.saveExportFile(testFilename, testContent);
      expect(filePath.isNotEmpty, isTrue);
      expect(filePath.endsWith(testFilename), isTrue);
    });

    test('Initialization flag lifecycle', () async {
      final storage = StorageService();
      await storage.setInitialized();
      final isInit = await storage.isInitialized();
      expect(isInit, isTrue);
    });

    test('ThemeMode storage lifecycle', () async {
      final storage = StorageService();
      await storage.saveThemeMode('dark');
      final loaded = await storage.loadThemeMode();
      expect(loaded, 'dark');

      await storage.saveThemeMode('system');
      final loadedSystem = await storage.loadThemeMode();
      expect(loadedSystem, 'system');
    });

    test('DashboardController themeMode initial system default and light/dark switching', () {
      Get.locale = const Locale('th', 'TH');
      final controller = Get.put(DashboardController());
      controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode.value, ThemeMode.system);
      expect(controller.themeModeName, 'ตามระบบ');

      // Toggle from initial state toggles to dark
      controller.toggleTheme();
      expect(controller.themeMode.value, ThemeMode.dark);
      expect(controller.themeModeName, 'โหมดมืด');

      // Toggle from dark toggles to light
      controller.toggleTheme();
      expect(controller.themeMode.value, ThemeMode.light);
      expect(controller.themeModeName, 'โหมดสว่าง');

      // Toggle again toggles to dark (does not cycle back to system)
      controller.toggleTheme();
      expect(controller.themeMode.value, ThemeMode.dark);
      expect(controller.themeModeName, 'โหมดมืด');
    });

    test('Language storage lifecycle', () async {
      final storage = StorageService();
      await storage.saveLanguage('en');
      final loadedEn = await storage.loadLanguage();
      expect(loadedEn, 'en');

      await storage.saveLanguage('th');
      final loadedTh = await storage.loadLanguage();
      expect(loadedTh, 'th');

      await storage.saveLanguage('system');
      final loadedSys = await storage.loadLanguage();
      expect(loadedSys, 'system');
    });

    test('resolveInitialLocale defaults to system locale when null or system', () {
      expect(resolveInitialLocale('en'), const Locale('en', 'US'));
      expect(resolveInitialLocale('th'), const Locale('th', 'TH'));

      final sysLocale = resolveInitialLocale(null);
      expect(sysLocale, isA<Locale>());
      expect(['th', 'en'].contains(sysLocale.languageCode), isTrue);

      final sysFromSaved = resolveInitialLocale('system');
      expect(sysFromSaved, sysLocale);
    });

    test('DashboardController language switching and localized period titles', () {
      final controller = Get.put(DashboardController());
      controller.selectedDate.value = DateTime(2026, 9, 10);
      controller.currentPeriod.value = TimeFilterPeriod.monthly;

      // Switch to English
      controller.setLanguage('en');
      expect(controller.currentLanguage.value, 'en');
      expect(controller.isEnglish, isTrue);
      expect(controller.formattedPeriodTitle, 'September 2026');

      // Switch to Yearly in English
      controller.currentPeriod.value = TimeFilterPeriod.yearly;
      expect(controller.formattedPeriodTitle, 'Year 2026');

      // Switch back to Thai
      controller.setLanguage('th');
      expect(controller.currentLanguage.value, 'th');
      expect(controller.isEnglish, isFalse);
      expect(controller.formattedPeriodTitle, 'ปี พ.ศ. 2569');

      // Switch to Monthly in Thai
      controller.currentPeriod.value = TimeFilterPeriod.monthly;
      expect(controller.formattedPeriodTitle, 'กันยายน 2569');

      // Toggle language
      controller.toggleLanguage();
      expect(controller.isEnglish, isTrue);
      expect('budget_settings'.tr, 'Budget Settings');
      expect('all_transactions'.tr, 'All Transactions');
      expect('data_management'.tr, 'Data Management');
      expect('pin_security'.tr, 'Security & PIN');

      controller.toggleLanguage();
      expect(controller.isEnglish, isFalse);
      expect('budget_settings'.tr, 'ตั้งค่างบประมาณ');
      expect('all_transactions'.tr, 'รายการธุรกรรมทั้งหมด');

      // Verify setLanguage ignores unknown codes (system is backend-only)
      controller.setLanguage('system'); // should be ignored
      expect(controller.currentLanguage.value, 'th'); // should still be 'th'
      controller.setLanguage('unknown');              // should be ignored
      expect(controller.currentLanguage.value, 'th');
    });

    test('AppFeedback API executes safely and dismisses without throwing', () {
      AppFeedback.showSuccess(message: 'ทดสอบบันทึกสำเร็จ');
      AppFeedback.showInfo(message: 'ทดสอบข้อมูล');
      AppFeedback.showWarning(message: 'ทดสอบเตือน');
      AppFeedback.dismiss();
      expect(true, isTrue);
    });

    test('QuickAdd BottomSheet translation dictionary keys match both in th_TH and en_US', () {
      final th = AppTranslations().keys['th_TH']!;
      final en = AppTranslations().keys['en_US']!;

      expect(th['record_income_expense'], 'บันทึกรายรับ-รายจ่าย');
      expect(th['record_transaction_desc'], 'เลือกประเภท ระบุจำนวนเงิน และวันที่');
      expect(th['edit_transaction_title'], 'แก้ไขรายการธุรกรรม');
      expect(th['edit_transaction_desc'], 'แก้ไขยอดเงิน วันที่ หรือหมวดหมู่');
      expect(th['variable_cost_desc'], 'ตัดจากโควตารายวัน');
      expect(th['fixed_cost_desc'], 'ค่าใช้จ่ายประจำ/งวด');
      expect(th['note_hint'], 'พิมพ์ชื่อหรือบันทึกเพิ่มเติม');
      expect(th['save_changes'], 'บันทึกการแก้ไข');
      expect(th['add_transaction'], 'บันทึกรายการ');
      expect(th['reset'], 'ล้าง');
      expect(th['อาหาร/ของกิน'], 'อาหาร/ของกิน');
      expect(th['การเดินทาง'], 'การเดินทาง');
      expect(th['เงินเดือน'], 'เงินเดือน');

      expect(en['record_income_expense'], 'Record Income & Expense');
      expect(en['record_transaction_desc'], 'Select type, enter amount and date');
      expect(en['edit_transaction_title'], 'Edit Transaction');
      expect(en['edit_transaction_desc'], 'Edit amount, date, or category');
      expect(en['variable_cost_desc'], 'Deducted from daily quota');
      expect(en['fixed_cost_desc'], 'Recurring / monthly bill');
      expect(en['note_hint'], 'Custom title or note (optional)');
      expect(en['save_changes'], 'Save Changes');
      expect(en['add_transaction'], 'Add Transaction');
      expect(en['reset'], 'Reset');
      expect(en['อาหาร/ของกิน'], 'Food & Dining');
      expect(en['การเดินทาง'], 'Transportation');
      expect(en['เงินเดือน'], 'Salary');
      expect(en['เงินออม/DCA'], 'Savings / DCA');
      expect(en['กองทุนรวม'], 'Mutual Funds');
      expect(en['หุ้น/ตราสาร'], 'Stocks & Bonds');
      expect(en['เงินสำรองฉุกเฉิน'], 'Emergency Fund');
    });

    test('DashboardController balance privacy toggle (isBalanceHidden)', () {
      final controller = Get.put(DashboardController());
      expect(controller.isBalanceHidden.value, isFalse);

      controller.toggleBalanceHidden();
      expect(controller.isBalanceHidden.value, isTrue);

      controller.toggleBalanceHidden();
      expect(controller.isBalanceHidden.value, isFalse);
    });

    test('BalanceCard redesigned translation keys match in th_TH and en_US', () {
      final th = AppTranslations().keys['th_TH']!;
      final en = AppTranslations().keys['en_US']!;

      expect(th['vs_budget_plan'], 'เทียบแผนงบประมาณ');
      expect(th['plan_achievement'], 'บรรลุเป้าหมาย @percent%');
      expect(th['total_outflow'], 'รายจ่ายรวม');
      expect(th['total_inflow'], 'รายรับรวม');
      expect(th['net_buffer'], 'ส่วนต่างสุทธิ');
      expect(th['hide_balance'], 'ซ่อนยอดเงิน');
      expect(th['show_balance'], 'แสดงยอดเงิน');

      expect(en['vs_budget_plan'], 'vs. Planned Budget');
      expect(en['plan_achievement'], '@percent% of Target');
      expect(en['total_outflow'], 'Total Outflow');
      expect(en['total_inflow'], 'Total Inflow');
      expect(en['net_buffer'], 'Net Variance');
      expect(en['hide_balance'], 'Hide balance');
      expect(en['show_balance'], 'Show balance');
    });

    test('DashboardHeader redesigned translation keys match in th_TH and en_US', () {
      final th = AppTranslations().keys['th_TH']!;
      final en = AppTranslations().keys['en_US']!;

      expect(th['select_period'], 'เลือกเดือนและรอบเวลา');
      expect(th['jump_to_current_month'], 'กลับสู่เดือนปัจจุบัน');
      expect(th['quarter_1'], 'ไตรมาส 1');
      expect(th['quarter_2'], 'ไตรมาส 2');
      expect(th['quarter_3'], 'ไตรมาส 3');
      expect(th['quarter_4'], 'ไตรมาส 4');
      expect(th['active_period'], 'รอบปัจจุบัน');
      expect(th['all_time_desc'], 'ข้อมูลสะสมทั้งหมด');

      expect(en['select_period'], 'Select Month & Period');
      expect(en['jump_to_current_month'], 'Back to Current Month (Today)');
      expect(en['quarter_1'], 'Quarter 1 (Q1)');
      expect(en['quarter_2'], 'Quarter 2 (Q2)');
      expect(en['quarter_3'], 'Quarter 3 (Q3)');
      expect(en['quarter_4'], 'Quarter 4 (Q4)');
      expect(en['active_period'], 'Current Period');
      expect(en['all_time_desc'], 'All accumulated records');
    });

    test('BudgetSettingsView redesigned translation keys match in th_TH and en_US', () {
      final th = AppTranslations().keys['th_TH']!;
      final en = AppTranslations().keys['en_US']!;

      expect(th['rule_50_30_20_badge'], 'ยอดนิยม');
      expect(th['rule_60_20_20_badge'], 'ภาระคงที่');
      expect(th['rule_40_30_30_badge'], 'สายออมดุ');
      expect(th['core_pillars_header'], '3 เสาหลักโครงสร้างงบประมาณ');
      expect(th['allocation_breakdown'], 'สัดส่วนการจัดสรรรายรับ');
      expect(th['daily_studio_title'], 'สตูดิโอโควตากินอยู่รายวัน');
      expect(th['apply_template'], 'ปรับใช้สูตรนี้');
      expect(th['planned_fixed_costs_title'], 'ค่าใช้จ่ายคงที่');
      expect(th['planned_savings_title'], 'เป้าหมายเงินออมและลงทุน');

      expect(en['rule_50_30_20_badge'], 'Popular');
      expect(en['rule_60_20_20_badge'], 'Fixed Heavy');
      expect(en['rule_40_30_30_badge'], 'High Savings');
      expect(en['core_pillars_header'], '3 Core Budget Pillars');
      expect(en['allocation_breakdown'], 'Income Allocation Breakdown');
      expect(en['daily_studio_title'], 'Daily Allowance Studio');
      expect(en['apply_template'], 'Apply Strategy');
      expect(en['planned_fixed_costs_title'], 'Fixed Costs');
      expect(en['planned_savings_title'], 'Savings & Investment');
    });
  });
}

