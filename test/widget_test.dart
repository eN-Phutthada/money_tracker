import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/main.dart';

void main() {
  testWidgets('MoneyTrackerApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MoneyTrackerApp());
    await tester.pumpAndSettle();

    // Verify that the dashboard is loaded with the title or key widgets
    expect(find.text('Personal Finance'), findsOneWidget);
  });
}
