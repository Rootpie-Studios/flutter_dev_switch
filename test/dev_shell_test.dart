import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  int opened = 0;
  int buttonTaps = 0;

  Widget app() => MaterialApp(
    navigatorKey: navKey,
    builder: (context, child) => DevShell(
      navigatorKey: navKey,
      shake: false,
      open: (_) async => opened++,
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => buttonTaps++,
          child: const Text('button'),
        ),
      ),
    ),
  );

  setUp(() {
    opened = 0;
    buttonTaps = 0;
    DevTools.enabled = true;
  });

  const Offset a = Offset(100, 300);
  const Offset b = Offset(200, 300);

  testWidgets('two fingers held still open the menu', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture one = await tester.startGesture(a, pointer: 1);
    final TestGesture two = await tester.startGesture(b, pointer: 2);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 1);
    await one.up();
    await two.up();
  });

  testWidgets('one finger is not enough', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture one = await tester.startGesture(a, pointer: 1);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await one.up();
  });

  testWidgets('a pinch does not count', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture one = await tester.startGesture(a, pointer: 1);
    final TestGesture two = await tester.startGesture(b, pointer: 2);
    await tester.pump(const Duration(milliseconds: 500));
    await two.moveBy(const Offset(60, 0));
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await one.up();
    await two.up();
  });

  testWidgets('lifting a finger early cancels', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture one = await tester.startGesture(a, pointer: 1);
    final TestGesture two = await tester.startGesture(b, pointer: 2);
    await tester.pump(const Duration(milliseconds: 500));
    await two.up();
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await one.up();
  });

  testWidgets('the app underneath still gets its taps', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('button'));
    expect(buttonTaps, 1);
  });

  testWidgets('nothing is attached in a store build', (tester) async {
    DevTools.enabled = false;
    await tester.pumpWidget(app());
    expect(find.byKey(DevShell.listenerKey), findsNothing);
    final TestGesture one = await tester.startGesture(a, pointer: 1);
    final TestGesture two = await tester.startGesture(b, pointer: 2);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await one.up();
    await two.up();
  });

  testWidgets('Ctrl+Shift+D opens the menu', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(opened, 1);
  });
}
