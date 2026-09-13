import 'package:flutter/material.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockServer server;

  setUp(() => server = MockServer(latency: Duration.zero));

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ListView(children: [child])),
    ),
  );

  testWidgets('the panel drives the server', (tester) async {
    await pump(tester, MockServerPanel(server: server));
    expect(find.text('Instant'), findsOneWidget);
    expect(find.text('0.3 s'), findsOneWidget);
    expect(find.text('3 s'), findsOneWidget);

    await tester.tap(find.text('3 s'));
    await tester.pump();
    expect(server.latency, const Duration(seconds: 3));

    await tester.tap(find.text('Offline'));
    await tester.pump();
    expect(server.offline, isTrue);

    await tester.tap(find.text('Refuse writes'));
    await tester.pump();
    expect(server.failWrites, isTrue);

    // A change made elsewhere shows up too.
    server.offline = false;
    await tester.pump();
    final SwitchListTile offline = tester.widget(
      find.widgetWithText(SwitchListTile, 'Offline'),
    );
    expect(offline.value, isFalse);
  });

  testWidgets('the log lists requests newest first and clears', (tester) async {
    await pump(tester, MockRequestLog(server: server));
    expect(find.textContaining('Nothing yet'), findsOneWidget);

    server.record(
      MockRequest(
        at: DateTime(2026, 1, 1, 10),
        method: 'GET',
        path: '/gyms',
        body: null,
        status: 200,
      ),
    );
    server.record(
      MockRequest(
        at: DateTime(2026, 1, 1, 10, 1),
        method: 'PUT',
        path: '/me',
        body: {'name': 'Ali'},
        status: 500,
      ),
    );
    await tester.pump();
    expect(find.text('2 requests'), findsOneWidget);
    final Offset put = tester.getTopLeft(find.text('/me'));
    final Offset get = tester.getTopLeft(find.text('/gyms'));
    expect(put.dy, lessThan(get.dy), reason: 'newest first');

    await tester.tap(find.text('/me'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"name": "Ali"'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(server.requests, isEmpty);
    expect(find.textContaining('Nothing yet'), findsOneWidget);
  });

  testWidgets('a scenario row without a tap is disabled', (tester) async {
    bool opened = false;
    await pump(
      tester,
      Column(
        children: [
          const DevSectionHeader('Problems'),
          DevScenarioTile(
            icon: Icons.add,
            title: 'New problem',
            subtitle: 'Pick holds',
            onTap: () => opened = true,
          ),
          const DevScenarioTile(
            icon: Icons.edit,
            title: 'Edit my problem',
            subtitle: 'None in the mock data',
            onTap: null,
          ),
        ],
      ),
    );
    expect(find.text('PROBLEMS'), findsOneWidget);
    await tester.tap(find.text('New problem'));
    expect(opened, isTrue);
    final ListTile disabled = tester.widget(
      find.widgetWithText(ListTile, 'Edit my problem'),
    );
    expect(disabled.enabled, isFalse);
  });
}
