import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  int opened = 0;
  int buttonTaps = 0;
  int buttonLongPresses = 0;

  Widget app() => MaterialApp(
    navigatorKey: navKey,
    builder: (context, child) => DevShell(
      navigatorKey: navKey,
      shake: false,
      open: (_) async => opened++,
      child: child!,
    ),
    home: Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => buttonTaps++,
            onLongPress: () => buttonLongPresses++,
            child: const Text('button'),
          ),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    ),
  );

  setUp(() {
    opened = 0;
    buttonTaps = 0;
    buttonLongPresses = 0;
    DevTools.enabled = true;
  });

  const Offset empty = Offset(200, 400);

  testWidgets('a press held on empty space opens the menu', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture press = await tester.startGesture(empty);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(opened, 1);
    await press.up();
  });

  testWidgets('a short press does not', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture press = await tester.startGesture(empty);
    await tester.pump(const Duration(milliseconds: 300));
    await press.up();
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
  });

  testWidgets('a drag does not', (tester) async {
    await tester.pumpWidget(app());
    final TestGesture press = await tester.startGesture(empty);
    await tester.pump(const Duration(milliseconds: 200));
    await press.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await press.up();
  });

  testWidgets("a widget's own long press wins", (tester) async {
    await tester.pumpWidget(app());
    await tester.longPress(find.text('button'));
    await tester.pump(const Duration(seconds: 2));
    expect(buttonLongPresses, 1);
    expect(opened, 0);
  });

  testWidgets('taps still reach the app', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('button'));
    expect(buttonTaps, 1);
    expect(opened, 0);
  });

  testWidgets('nothing is attached in a store build', (tester) async {
    DevTools.enabled = false;
    await tester.pumpWidget(app());
    expect(find.byKey(DevShell.detectorKey), findsNothing);
    final TestGesture press = await tester.startGesture(empty);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
    await press.up();
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
