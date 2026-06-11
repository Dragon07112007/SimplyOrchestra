import 'package:flutter_test/flutter_test.dart';

import 'package:sideload_dummy/main.dart';

void main() {
  testWidgets('counter increments and resets', (WidgetTester tester) async {
    await tester.pumpWidget(const SideloadDummyApp());

    expect(find.text('Sideload Dummy'), findsOneWidget);
    expect(find.text('Running on iPhone'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
