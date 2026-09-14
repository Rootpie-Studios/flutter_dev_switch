import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  int opened = 0;
  int buttonTaps = 0;

  Widget app({bool shake = false}) => MaterialApp(
    navigatorKey: navKey,
    builder: (context, child) => DevShell(
      navigatorKey: navKey,
      shake: shake,
      open: (_) async => opened++,
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 44,
          height: 44,
          child: TextButton(
            onPressed: () => buttonTaps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );

  setUp(() {
    opened = 0;
    buttonTaps = 0;
    DevTools.enabled = true;
  });

  Offset corner(WidgetTester tester) {
    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    return Offset(size.width - 10, 10);
  }

  testWidgets('three quick taps on the corner open the menu', (tester) async {
    await tester.pumpWidget(app());
    for (int i = 0; i < 3; i++) {
      await tester.tapAt(corner(tester));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(opened, 1);
  });

  testWidgets('the taps still reach what is under the corner', (tester) async {
    await tester.pumpWidget(app());
    for (int i = 0; i < 3; i++) {
      await tester.tapAt(corner(tester));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(buttonTaps, 3);
  });

  testWidgets('slow taps do not count', (tester) async {
    await tester.pumpWidget(app());
    await tester.tapAt(corner(tester));
    await tester.tapAt(corner(tester));
    await tester.pump(const Duration(seconds: 2));
    await tester.tapAt(corner(tester));
    expect(opened, 0);
  });

  testWidgets('nothing is attached in a store build', (tester) async {
    DevTools.enabled = false;
    await tester.pumpWidget(app());
    for (int i = 0; i < 3; i++) {
      await tester.tapAt(corner(tester));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(opened, 0);
    expect(find.byKey(DevShell.hotspotKey), findsNothing);
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
