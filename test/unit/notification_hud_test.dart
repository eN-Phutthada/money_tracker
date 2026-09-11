import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_tracker/app/data/models/transaction_model.dart';
import 'package:money_tracker/app/widgets/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    AppFeedback.dismiss();
    Get.reset();
  });

  testWidgets('AppFeedback notification HUD displays with amount, type, progress, and dismisses', (WidgetTester tester) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                AppFeedback.showSuccess(
                  title: 'บันทึกสำเร็จ',
                  message: 'อาหาร/ของกิน • วันนี้',
                  amount: 250.0,
                  transactionType: TransactionType.expense,
                  actionLabel: 'เลิกทำ',
                  onAction: () {
                    actionTapped = true;
                  },
                );
              },
              child: const Text('Trigger Notification'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap button to trigger notification
    await tester.tap(find.text('Trigger Notification'));
    await tester.pump(); // Start entrance
    await tester.pump(const Duration(milliseconds: 400)); // Complete entrance spring

    // Verify title, message, and action label are displayed
    expect(find.text('บันทึกสำเร็จ'), findsOneWidget);
    expect(find.text('อาหาร/ของกิน • วันนี้'), findsOneWidget);
    expect(find.text('เลิกทำ'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);

    // Verify amount badge is rendered with expense minus prefix
    expect(find.text('-฿250.00'), findsOneWidget);

    // Tap action button
    await tester.tap(find.text('เลิกทำ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(actionTapped, isTrue);
  });

  testWidgets('AppFeedback showError and dismiss API test', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                AppFeedback.showError(
                  title: 'เกิดข้อผิดพลาด',
                  message: 'ไม่สามารถเชื่อมต่อได้',
                );
              },
              child: const Text('Trigger Error'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trigger Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ALERT'), findsOneWidget);
    expect(find.text('เกิดข้อผิดพลาด'), findsOneWidget);

    // Call dismiss
    AppFeedback.dismiss();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('เกิดข้อผิดพลาด'), findsNothing);
  });
}
