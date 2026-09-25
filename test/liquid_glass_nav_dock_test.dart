import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/routes/app_routes.dart';
import 'package:money_tracker/app/widgets/liquid_glass_nav_dock.dart';

void main() {
  testWidgets('LiquidGlassNavDock renders transparent liquid glass with widgets behind', (tester) async {
    Get.put(DashboardController());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => LiquidGlassNavDock.floatingOnScreen(
              context: context,
              currentRoute: Routes.DASHBOARD,
              body: ListView.builder(
                itemCount: 20,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text('Transaction Behind Dock $i'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Transaction Behind Dock 0'), findsOneWidget);
    expect(find.byType(LiquidGlassNavDock), findsOneWidget);
  });
}
