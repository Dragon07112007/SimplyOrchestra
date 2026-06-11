import 'package:flutter_test/flutter_test.dart';

import 'package:sideload_dummy/app.dart';

void main() {
  testWidgets('shows trainer controls', (WidgetTester tester) async {
    await tester.pumpWidget(const TaktstockTrainerApp());

    expect(find.text('Taktstock Trainer'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);
    expect(find.text('Beat 1 / 4'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Start Training'), findsOneWidget);
  });
}
