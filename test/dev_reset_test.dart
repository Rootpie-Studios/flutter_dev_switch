import 'package:flutter/material.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets_test.dart' show shellApp, holdOn;

void main() {
  late ApiConfig config;
  final List<String> ran = [];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_setting': 'x',
      'api_environment': 'dev',
    });
    DevTools.enabled = true;
    ran.clear();
    config = ApiConfig(
      environments: const [
        ApiEnvironment(key: 'production', label: 'P', baseUrl: 'https://p'),
        ApiEnvironment(key: 'dev', label: 'Dev', baseUrl: 'https://d'),
      ],
      defineUrl: '',
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    shellApp(
      config: config,
      entries: [
        devResetEntry(
          steps: [
            DevResetStep('Session', () async => ran.add('session')),
            DevResetStep.preferences(config),
            DevResetStep('Cache', () async => ran.add('cache')),
          ],
        ),
      ],
      body: const Text('LOGO'),
    ),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await holdOn(tester, find.text('LOGO'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks first, naming the steps; cancel runs nothing', (
    tester,
  ) async {
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text('Reset app data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('• Session'), findsOneWidget);
    expect(find.textContaining('• Preferences'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(ran, isEmpty);
  });

  testWidgets(
    'confirmed: runs the steps in order, keeps the menu\'s own keys',
    (tester) async {
      await config.load();
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.text('Reset app data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(ran, ['session', 'cache']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_setting'), isNull);
      expect(prefs.getString('api_environment'), 'dev', reason: 'kept');
      expect(find.textContaining('Restart the app'), findsOneWidget);
    },
  );
}
