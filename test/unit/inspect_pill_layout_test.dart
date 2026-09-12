import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/dashboard/widgets/balance_card.dart';
import 'package:money_tracker/app/modules/dashboard/widgets/daily_allowance_card.dart';
import 'package:money_tracker/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Inspect header row and pills layout', (WidgetTester tester) async {
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
    Get.put<DashboardController>(DashboardController());

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('th', 'TH'),
        translations: AppTranslations(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  BalanceCard(),
                  SizedBox(height: 14),
                  DailyAllowanceCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final balanceCardFinder = find.byType(BalanceCard);
    final dailyCardFinder = find.byType(DailyAllowanceCard);

    // Find the pill in BalanceCard
    final balancePill = find.byWidgetPredicate((widget) {
      if (widget is Text) {
        return widget.data == 'Safe Zone • เกินเป้า' || widget.data == 'Caution • เกินงบ';
      }
      return false;
    });
    expect(balancePill, findsOneWidget);
    final balanceCardRect = tester.getRect(balanceCardFinder);
    final balancePillRect = tester.getRect(balancePill);
    final balanceOffset = balanceCardRect.right - balancePillRect.right;

    // Find the pill in DailyAllowanceCard
    final dailyPill = find.byWidgetPredicate((widget) {
      if (widget is Text) {
        return widget.data == 'Safe • สบายใจ' || widget.data == 'Moderate • คุมยอด' || widget.data == 'Over • เกินโควตา';
      }
      return false;
    });
    expect(dailyPill, findsOneWidget);
    final dailyCardRect = tester.getRect(dailyCardFinder);
    final dailyPillRect = tester.getRect(dailyPill);
    final dailyOffset = dailyCardRect.right - dailyPillRect.right;

    // Both status pills should be aligned to the right edge with ~30-34px offset (20px card padding + ~10-12px pill internal padding)
    expect(balanceOffset, closeTo(32.0, 3.0));
    expect(dailyOffset, closeTo(32.0, 3.0));
    // Difference between both pill alignments must be under 2 pixels
    expect((balanceOffset - dailyOffset).abs(), lessThan(2.0));
  });
}
