import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_test.dart' show shellApp, holdOn;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';

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
const List<DevAccount> accounts = [
  DevAccount(label: 'Admin', email: 'admin@example.com', password: 'password'),
  DevAccount(label: 'User', email: 'user@example.com', password: 'password'),
];

void main() {
  late ApiConfig config;
  final List<DevAccount> attempted = [];
  Future<String?> Function(DevAccount account) outcome = (_) async => null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DevTools.enabled = true;
    config = ApiConfig(environments: const [production, dev], defineUrl: '');
    attempted.clear();
    outcome = (_) async => null;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    shellApp(
      config: config,
      entries: [
        devLoginEntry(
          config: config,
          accounts: accounts,
          login: (_, account) {
            attempted.add(account);
            return outcome(account);
          },
        ),
      ],
      body: const Text('LOGO'),
    ),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await holdOn(tester, find.text('LOGO'));
    await tester.pumpAndSettle();
  }

  testWidgets('not listed on production, listed on a picked server', (
    tester,
  ) async {
    await pump(tester);
    await openMenu(tester);
    expect(find.text('Test login'), findsNothing);
    await config.pick(dev);
    await tester.pumpAndSettle();
    expect(find.text('Test login'), findsOneWidget, reason: 'menu follows');
  });

  testWidgets('picks an account and logs in with it', (tester) async {
    await config.pick(dev);
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    expect(find.text('Test login on Dev'), findsOneWidget);
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(attempted.single.email, 'user@example.com');
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('a failed login says why', (tester) async {
    outcome = (_) async => 'Wrong password.';
    await config.pick(dev);
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Test login as admin@example.com failed on Dev: Wrong password.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a handler that throws is reported, not rethrown', (
    tester,
  ) async {
    outcome = (_) async => throw StateError('no network');
    await config.pick(dev);
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no network'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screen is blocked while logging in', (tester) async {
    final Completer<String?> pending = Completer<String?>();
    outcome = (_) => pending.future;
    await config.pick(dev);
    await pump(tester);
    await openMenu(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Logging in as admin@example.com…'), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Logging in as admin@example.com…'), findsNothing);
  });

  testWidgets('store build shows nothing even off production', (tester) async {
    DevTools.enabled = false;
    await config.pick(dev);
    await pump(tester);
    await openMenu(tester);
    expect(find.text('Test login'), findsNothing);
  });
}
