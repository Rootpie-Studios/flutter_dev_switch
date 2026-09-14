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
    DevToolsStrings strings = const DevToolsStrings(),
  }) => tester.pumpWidget(
    shellApp(
      config: config,
      entries: entries,
      strings: strings,
      body: const Text('LOGO'),
    ),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await holdOn(tester, find.text('LOGO'));
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
    await openMenu(tester);
    expect(find.text(dev.baseUrl), findsOneWidget, reason: 'server subtitle');
  });

  testWidgets('slow requests: picked in the menu, shown in its row', (
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

    await openMenu(tester);
    expect(find.text('3 s'), findsOneWidget, reason: 'slowdown subtitle');
    await tester.tap(find.text('Slow requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(config.slowdown, Duration.zero);
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
      await openMenu(tester);
      expect(find.text(dev.baseUrl), findsOneWidget, reason: 'server subtitle');
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

  testWidgets('offline and refuse writes: switches in the menu', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(config.offline, isTrue);
    await tester.tap(find.text('Refuse writes'));
    await tester.pumpAndSettle();
    expect(config.refuseWrites, isTrue);
    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(config.offline, isFalse);
  });

  testWidgets('store build: no gesture, no menu', (tester) async {
    DevTools.enabled = false;
    await pumpLogin(tester);
    await holdOn(tester, find.text('LOGO'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing);
    expect(find.textContaining('Server'), findsNothing);
  });

  testWidgets('Swedish strings', (tester) async {
    await pumpLogin(
      tester,
      entries: const [noop],
      strings: const DevToolsStrings.sv(),
    );
    await openMenu(tester);
    expect(find.text('Utvecklare'), findsOneWidget);
  });
}

Future<void> _nothing(BuildContext _) async {}

/// An app with the [DevShell] installed the way the apps do it.
Widget shellApp({
  required ApiConfig config,
  List<DevMenuEntry> entries = const [],
  DevToolsStrings strings = const DevToolsStrings(),
  required Widget body,
}) {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  return MaterialApp(
    navigatorKey: navKey,
    builder: (context, child) => DevShell(
      navigatorKey: navKey,
      open: (context) => DevMenu.show(
        context,
        config: config,
        entries: entries,
        strings: strings,
      ),
      child: child!,
    ),
    home: Scaffold(body: body),
  );
}

/// The shell's press: held longer than a plain long press.
Future<void> holdOn(WidgetTester tester, Finder finder) async {
  final TestGesture press = await tester.startGesture(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 1200));
  await press.up();
}
