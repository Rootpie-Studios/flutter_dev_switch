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
  }) => tester.pumpWidget(
    shellApp(config: config, entries: entries, body: const Text('LOGO')),
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

  /// The Server section's one row is titled by the pick.
  Future<void> openServerPicker(WidgetTester tester) async {
    await openMenu(tester);
    await tester.tap(find.text(config.label));
    await tester.pumpAndSettle();
  }

  testWidgets('no entries: the menu has its Server and Faults sections', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('SERVER'), findsOneWidget);
    expect(find.text('Production'), findsOneWidget, reason: 'the pick');
    expect(find.text(production.baseUrl), findsOneWidget);
    expect(find.text('FAULTS'), findsOneWidget);
    expect(find.text('Delay'), findsOneWidget);
    expect(find.text('Off'), findsNWidgets(2), reason: 'no delay, no refusal');
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Refuse requests'), findsOneWidget);
    expect(find.text('APP'), findsNothing, reason: 'nothing to list');

    await tester.tap(find.text('Production'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing, reason: 'menu replaced');
    expect(find.text('Dev'), findsOneWidget);
    expect(find.text('Custom address'), findsOneWidget);
    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(config.picked, dev);
    await openMenu(tester);
    expect(find.text('Dev'), findsOneWidget, reason: 'the row follows');
    expect(find.text(dev.baseUrl), findsOneWidget, reason: 'server subtitle');
  });

  testWidgets('delay: picked in the Faults section, kept', (tester) async {
    await pumpLogin(tester);
    await openMenu(tester);
    final Finder off = find.descendant(
      of: find.widgetWithText(ListTile, 'Delay'),
      matching: find.text('Off'),
    );
    await tester.tap(find.text('3 s'));
    await tester.pumpAndSettle();
    expect(config.faults.delay, const Duration(seconds: 3));
    await tester.tap(off);
    await tester.pumpAndSettle();
    expect(config.faults.delay, Duration.zero);

    // A delay that is not one of the choices still shows, and can be
    // switched off.
    await config.faults.pickDelay(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('2 s'), findsOneWidget);
    await tester.tap(off);
    await tester.pumpAndSettle();
    expect(config.faults.hasDelay, isFalse);
  });

  testWidgets('with entries: an App section after the package\'s', (
    tester,
  ) async {
    await pumpLogin(tester, entries: const [noop]);
    expect(find.text('Production'), findsNothing);
    await openMenu(tester);
    expect(find.text('APP'), findsOneWidget);
    expect(find.text('Noop'), findsOneWidget);
    final Offset faults = tester.getTopLeft(find.text('FAULTS'));
    final Offset app = tester.getTopLeft(find.text('APP'));
    expect(faults.dy, lessThan(app.dy), reason: 'the app\'s rows come last');

    await tester.tap(find.text('Production'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing, reason: 'menu replaced');
    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(config.picked, dev);
  });

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
    await tester.ensureVisible(find.text('Use'));
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(config.baseUrl, 'http://192.168.55.6/api');

    await openServerPicker(tester);
    await tester.tap(find.text('Custom address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'http://');
    await tester.ensureVisible(find.text('Use'));
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
    await tester.ensureVisible(find.text('Test login'));
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    expect(seen, isNotNull);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('offline and refuse requests: picked in the menu', (
    tester,
  ) async {
    await pumpLogin(tester);
    await openMenu(tester);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(config.faults.offline, isTrue);
    await tester.tap(find.text('403'));
    await tester.pumpAndSettle();
    expect(config.faults.refuseWith, 403);
    expect(find.text('Writes get a 403; reads still work'), findsOneWidget);
    await tester.tap(find.text('401'));
    await tester.pumpAndSettle();
    expect(config.faults.refuseWith, 401);
    expect(find.textContaining('Every request gets a 401'), findsOneWidget);
    await tester.tap(find.text('500'));
    await tester.pumpAndSettle();
    expect(config.faults.refuseWith, 500);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Refuse requests'),
        matching: find.text('Off'),
      ),
    );
    await tester.pumpAndSettle();
    expect(config.faults.refusing, isFalse);
    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(config.faults.offline, isFalse);
  });

  testWidgets('the menu fits a phone: the delay row does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLogin(tester, entries: const [noop]);
    await openMenu(tester);
    expect(find.text('Delay'), findsOneWidget);
    expect(find.text('0.3 s'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store build: no gesture, no menu', (tester) async {
    DevTools.enabled = false;
    await pumpLogin(tester);
    await holdOn(tester, find.text('LOGO'));
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing);
    expect(find.text('SERVER'), findsNothing);
  });
}

Future<void> _nothing(BuildContext _) async {}

/// An app with the [DevShell] installed the way the apps do it.
Widget shellApp({
  required ApiConfig config,
  List<DevMenuEntry> entries = const [],
  required Widget body,
}) {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  return MaterialApp(
    navigatorKey: navKey,
    builder: (context, child) => DevShell(
      navigatorKey: navKey,
      open: (context) =>
          DevMenu.show(context, config: config, entries: entries),
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
