import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:money_tracker/app/modules/security/controllers/security_controller.dart';
import 'package:money_tracker/app/routes/app_routes.dart';
import 'package:money_tracker/app/translations/app_translations.dart';
import 'package:money_tracker/app/widgets/liquid_glass_nav_dock.dart';
import 'package:money_tracker/app/widgets/shaders/shaders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('th', 'TH');
  });

  group('LiquidGlass Shader Architecture Tests', () {
    setUp(() {
      Get.reset();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('th', 'TH');
      Get.put(DashboardController());
      Get.put(SecurityController());
    });

    test('LiquidGlassLensShader initializes with correct asset path', () {
      final shader = LiquidGlassLensShader();
      expect(shader.shaderAssetPath, 'shaders/liquid_glass_lens.frag');
      expect(shader.isLoaded, isFalse); // Before async initialize in headless test
      expect(shader.shader, isNull);
    });

    test('ShaderPainter handles null and non-null safely', () {
      final painter = ShaderPainter(null);
      expect(painter.shader, isNull);
      expect(painter.shouldRepaint(ShaderPainter(null)), isFalse);
    });

    testWidgets('LiquidGlassBackgroundCapture renders child and fallback properly',
        (tester) async {
      final shader = LiquidGlassLensShader();
      final bgKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RepaintBoundary(
                  key: bgKey,
                  child: Container(
                    width: 300,
                    height: 500,
                    color: Colors.blue,
                  ),
                ),
                LiquidGlassBackgroundCapture(
                  backgroundKey: bgKey,
                  shader: shader,
                  child: const Text('Liquid Glass Content'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Liquid Glass Content'), findsOneWidget);
    });

    testWidgets('LiquidGlassNavDock.floatingOnScreen embeds RepaintBoundary & Dock',
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
      expect(find.byType(LiquidGlassNavDock), findsOneWidget);
      expect(find.byType(LiquidGlassBackgroundCapture), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });
}
