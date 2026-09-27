import 'package:flutter_test/flutter_test.dart';
import 'package:remind_me/main.dart';

void main() {
  testWidgets('RemindMe app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RemindMeApp());

    expect(find.text('RemindMe'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Add Reminder'), findsOneWidget);
  });
}