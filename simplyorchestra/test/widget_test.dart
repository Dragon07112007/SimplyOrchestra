import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplyorchestra/main.dart';

Future<void> pumpEventOps(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final store = await EventStore.load();
  await tester.pumpWidget(EventOpsApp(store: store));
  await tester.pumpAndSettle();
}

Future<void> scrollToText(
  WidgetTester tester,
  String text, {
  double delta = 260,
}) async {
  await tester.scrollUntilVisible(
    find.text(text),
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> scrollToKey(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders dashboard and event metrics', (tester) async {
    await pumpEventOps(tester);

    expect(find.text('EventOps'), findsOneWidget);
    expect(find.text('Abiparty März'), findsOneWidget);
    expect(find.text('184 / 300'), findsOneWidget);
    expect(find.text('1,840 €'), findsOneWidget);
  });

  testWidgets('settings exposes every role', (tester) async {
    await pumpEventOps(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    for (final role in EventRole.values) {
      expect(find.text(role.label, skipOffstage: false), findsWidgets);
    }
  });

  testWidgets('guest counter can increase and decrease', (tester) async {
    await pumpEventOps(tester);

    await scrollToText(tester, 'Add Guest');
    await tester.tap(find.text('Add Guest'));
    await tester.pumpAndSettle();
    await scrollToText(tester, 'Visitors', delta: -260);
    expect(find.text('185 / 300'), findsOneWidget);

    await scrollToText(tester, 'Remove Guest');
    await tester.tap(find.text('Remove Guest'));
    await tester.pumpAndSettle();
    await scrollToText(tester, 'Visitors', delta: -260);
    expect(find.text('184 / 300'), findsOneWidget);
  });

  testWidgets('revenue can be added from dashboard action', (tester) async {
    await pumpEventOps(tester);

    await scrollToText(tester, 'Add Revenue');
    await tester.tap(find.text('Add Revenue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add revenue'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Revenue', delta: -260);
    expect(find.text('1,890 €'), findsOneWidget);
  });

  testWidgets('task can be created', (tester) async {
    await pumpEventOps(tester);

    await scrollToText(tester, 'Create Task');
    await tester.tap(find.text('Create Task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title')),
      'Check cloakroom',
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Check cloakroom'), findsOneWidget);
  });

  testWidgets('issue can be created', (tester) async {
    await pumpEventOps(tester);

    await scrollToText(tester, 'Report Problem');
    await tester.tap(find.text('Report Problem'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('issue-title')),
      'Back door blocked',
    );
    await tester.tap(find.text('Create issue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(find.text('Back door blocked'), findsOneWidget);
  });

  testWidgets('task can be marked done', (tester) async {
    await pumpEventOps(tester);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await scrollToKey(tester, const Key('mark-done-task-exits'));
    await tester.tap(find.byKey(const Key('mark-done-task-exits')));
    await tester.pumpAndSettle();

    expect(find.text('Check emergency exits'), findsOneWidget);
    expect(find.text('Done'), findsWidgets);
  });

  testWidgets('issue can be resolved', (tester) async {
    await pumpEventOps(tester);

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    await scrollToKey(tester, const Key('resolve-issue-change-money'));
    await tester.tap(find.byKey(const Key('resolve-issue-change-money')));
    await tester.pumpAndSettle();

    expect(find.text('Cash desk needs change money'), findsOneWidget);
    expect(find.text('Resolved'), findsWidgets);
  });

  test('local persistence survives a store reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await EventStore.load();

    await store.setRole(EventRole.tech);
    await store.changeGuests(3);
    await store.addRevenue(160);
    await store.updateTaskStatus('task-mic', TaskStatus.done);
    await store.updateIssueStatus('issue-mic-noisy', IssueStatus.resolved);

    final restored = await EventStore.load();

    expect(restored.role, EventRole.tech);
    expect(restored.guestCount, 187);
    expect(restored.revenue, 2000);
    expect(
      restored.tasks.singleWhere((task) => task.id == 'task-mic').status,
      TaskStatus.done,
    );
    expect(
      restored.issues
          .singleWhere((issue) => issue.id == 'issue-mic-noisy')
          .status,
      IssueStatus.resolved,
    );
  });
}
