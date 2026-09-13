import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
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

  const DevMenuEntry noop = DevMenuEntry(
    label: 'Noop',
    icon: Icons.circle_outlined,
    onTap: _nothing,
  );

  Future<void> openServerPicker(WidgetTester tester) async {
    await openMenu(tester);
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();
  }

  testWidgets('no entries: long press opens the menu with its own rows', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('Slow requests'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget, reason: 'slowdown subtitle');

    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing, reason: 'menu replaced');
    expect(find.text('Dev'), findsOneWidget);
    expect(find.text('Custom address'), findsOneWidget);
    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(config.picked, dev);
    expect(find.text('Server: Dev'), findsOneWidget, reason: 'badge');
  });

  testWidgets('slow requests: picked in the menu, shown in the badge', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    await tester.tap(find.text('Slow requests'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing, reason: 'menu replaced');
    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('3 s'));
    await tester.pumpAndSettle();
    expect(config.slowdown, const Duration(seconds: 3));
    expect(find.text('Slow: 3 s'), findsOneWidget, reason: 'badge');

    await config.pick(dev);
    await tester.pumpAndSettle();
    expect(find.text('Server: Dev · Slow: 3 s'), findsOneWidget);

    await openMenu(tester);
    expect(find.text('3 s'), findsOneWidget, reason: 'slowdown subtitle');
    await tester.tap(find.text('Slow requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(config.slowdown, Duration.zero);
    expect(find.text('Server: Dev'), findsOneWidget);
  });

  testWidgets(
    'with entries: long press opens the menu; Server opens the picker',
    (tester) async {
      await pumpLogin(tester, entries: const [noop]);
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
    },
  );

  testWidgets('custom address: prefilled example, normalised, refused', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openServerPicker(tester);

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

    await openServerPicker(tester);
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
            entries: const [noop],
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

Future<void> _nothing(BuildContext _) async {}
