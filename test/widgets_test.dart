import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_devtools/url_devtools.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ApiEnvironment production = ApiEnvironment(
  key: 'production',
  label: 'Production',
  baseUrl: 'https://example.com/api',
);
const ApiEnvironment dev = ApiEnvironment(
  key: 'dev',
  label: 'Dev',
  baseUrl: 'https://dev.example.com/api',
);

void main() {
  late ApiConfig config;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DevTools.enabled = true;
    config = ApiConfig(environments: const [production, dev], defineUrl: '');
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    List<DevMenuEntry> entries = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DevMenuTrigger(
                config: config,
                entries: entries,
                child: const Text('LOGO'),
              ),
              ServerBadge(config: config),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.longPress(find.text('LOGO'));
    await tester.pumpAndSettle();
  }

  testWidgets('long press opens the menu; Server opens the picker', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.text('Server'), findsNothing);
    await openMenu(tester);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);

    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing, reason: 'menu replaced');
    expect(find.text('Dev'), findsOneWidget);

    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(config.picked, dev);
    expect(find.text('Server: Dev'), findsOneWidget, reason: 'badge');
  });

  testWidgets('custom address: prefilled example, normalised, refused', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom address'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'http://my-macbook.local/api',
    );
    await tester.enterText(find.byType(TextField), '192.168.55.6');
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(config.baseUrl, 'http://192.168.55.6/api');
    expect(find.text('Server: http://192.168.55.6/api'), findsOneWidget);

    await openMenu(tester);
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'http://');
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(config.baseUrl, 'http://192.168.55.6/api', reason: 'unchanged');
    expect(find.text('That is not a valid address'), findsOneWidget);
  });

  testWidgets('app entries run after the menu closes', (tester) async {
    BuildContext? seen;
    await pumpLogin(
      tester,
      entries: [
        DevMenuEntry(
          label: 'Test login',
          icon: Icons.person,
          onTap: (ctx) async => seen = ctx,
        ),
      ],
    );
    await openMenu(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    expect(seen, isNotNull);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('store build: no gesture, no badge', (tester) async {
    DevTools.enabled = false;
    await pumpLogin(tester);
    await tester.longPress(find.text('LOGO'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing);
    expect(find.textContaining('Server'), findsNothing);
  });

  testWidgets('Swedish strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevMenuTrigger(
            config: config,
            strings: const DevToolsStrings.sv(),
            child: const Text('LOGO'),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('LOGO'));
    await tester.pumpAndSettle();
    expect(find.text('Utvecklare'), findsOneWidget);
  });
}
