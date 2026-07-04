import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/app.dart';

void main() {
  testWidgets('Home screen renders title with ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('The MiddleMen'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });
}
