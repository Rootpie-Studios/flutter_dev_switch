import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  bool succeed = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DevTools.enabled = true;
    config = ApiConfig(environments: const [production, dev], defineUrl: '');
    attempted.clear();
    succeed = true;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DevLoginButton(
          config: config,
          accounts: accounts,
          login: (_, account) async {
            attempted.add(account);
            return succeed;
          },
        ),
      ),
    ),
  );

  testWidgets('hidden on production, shown on a picked server', (tester) async {
    await pump(tester);
    expect(find.text('Test login'), findsNothing);
    await config.pick(dev);
    await tester.pumpAndSettle();
    expect(find.text('Test login'), findsOneWidget);
  });

  testWidgets('picks an account and logs in with it', (tester) async {
    await config.pick(dev);
    await pump(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    expect(find.text('Test login on Dev'), findsOneWidget);
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    expect(attempted.single.email, 'user@example.com');
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('a failed login says so', (tester) async {
    succeed = false;
    await config.pick(dev);
    await pump(tester);
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(
      find.text('Test login as admin@example.com failed on Dev.'),
      findsOneWidget,
    );
  });

  testWidgets('store build shows nothing even off production', (tester) async {
    DevTools.enabled = false;
    await config.pick(dev);
    await pump(tester);
    expect(find.text('Test login'), findsNothing);
  });

  testWidgets('as a menu entry', (tester) async {
    await config.pick(dev);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevMenuTrigger(
            config: config,
            entries: [
              devLoginEntry(
                config: config,
                accounts: accounts,
                login: (_, a) async {
                  attempted.add(a);
                  return true;
                },
              ),
            ],
            child: const Text('LOGO'),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('LOGO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(attempted.single.email, 'admin@example.com');
  });
}
