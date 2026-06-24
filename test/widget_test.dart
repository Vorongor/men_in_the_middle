import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/app.dart';

void main() {
  testWidgets('Home screen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('The MiddleMen'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });
}
