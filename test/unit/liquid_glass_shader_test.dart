import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/routes/app_routes.dart';
import 'package:money_tracker/app/theme/app_popup_decorations.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/liquid_glass_nav_dock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  group('LiquidGlass Easy Integration & Dock Architecture Tests', () {
    setUp(() {
      Get.reset();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
      Get.put(DashboardController());
      Get.put(SecurityController());
    });

    testWidgets('LiquidGlassNavDock.floatingOnScreen embeds RepaintBoundary & LiquidGlassLens',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return LiquidGlassNavDock.floatingOnScreen(
                  context: context,
                  body: const Center(child: Text('Main Screen Body')),
                  currentRoute: Routes.DASHBOARD,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Main Screen Body'), findsOneWidget);
      expect(find.byType(LiquidGlassView), findsOneWidget);
      expect(find.byType(LiquidGlassNavDock), findsOneWidget);
      expect(find.byType(LiquidGlassLens), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('LiquidGlassNavDock renders all 5 core navigation items and actions',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const Scaffold(
            body: LiquidGlassNavDock(currentRoute: Routes.DASHBOARD),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Dashboard icon
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      // 2. Transactions icon
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      // 3. Center Add icon
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      // 4. Budget settings icon
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // 5. Hub & Vault icon
      expect(find.byIcon(Icons.widgets_rounded), findsOneWidget);
    });

    testWidgets('LiquidGlassNavDock hides automatically on desktop layouts (>= 900px)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return LiquidGlassNavDock.floatingOnScreen(
                  context: context,
                  body: const Center(child: Text('Desktop Body Content')),
                  currentRoute: Routes.DASHBOARD,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Desktop Body Content'), findsOneWidget);
      expect(find.byType(LiquidGlassNavDock), findsNothing);
      expect(find.byType(LiquidGlassLens), findsNothing);
    });

    testWidgets('AppGlassDialog renders with transparent LiquidGlassLens', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const AppGlassDialog(
                          child: Text('LiquidGlass Dialog Content'),
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('LiquidGlass Dialog Content'), findsOneWidget);
      expect(find.byType(LiquidGlassLens), findsOneWidget);
    });

    testWidgets('AppConfirmDialog renders with LiquidGlassLens and handles confirm/cancel',
        (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AppConfirmDialog(
                          title: 'ยืนยันการทำรายการ',
                          message: 'ต้องการลบข้อมูลนี้หรือไม่?',
                          onConfirm: () => confirmed = true,
                          onCancel: () => cancelled = true,
                        ),
                      );
                    },
                    child: const Text('Open Confirm'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการทำรายการ'), findsOneWidget);
      expect(find.text('ต้องการลบข้อมูลนี้หรือไม่?'), findsOneWidget);
      expect(find.byType(LiquidGlassLens), findsOneWidget);

      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(cancelled, isFalse);
    });
  });
}
