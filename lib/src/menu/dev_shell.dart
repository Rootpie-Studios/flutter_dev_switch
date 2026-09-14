import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dev_tools.dart';

/// Opens the developer menu from anywhere in the app, without any page
/// knowing about it. Install once in `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   navigatorKey: navKey,
///   builder: (context, child) =>
///       DevShell(navigatorKey: navKey, open: showDevMenu, child: child!),
/// )
/// ```
///
/// Two ways in, both gone from a store build:
///
/// - a long press, anywhere, held for [hold]. The shell wraps the app in
///   a gesture detector, so it is the outermost member of the gesture
///   arena: anything underneath with a long press of its own (a text
///   field, a logo) wins as usual, a tap wins on release, a drag wins as
///   soon as it moves, and only a press held where nothing else claims it
///   opens the menu;
/// - Ctrl+Shift+D or Cmd+Shift+D on a hardware keyboard.
///
/// [open] gets the root navigator's context, so the menu shows over
/// whatever is up, nested navigators and dialogs included. While the menu
/// is open a second gesture does nothing.
class DevShell extends StatefulWidget {
  /// The gesture detector, for tests.
  @visibleForTesting
  static const Key detectorKey = Key('dev-shell-detector');

  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function(BuildContext context) open;
  final Widget child;

  /// How long the press has to be held.
  final Duration hold;
  final bool keyboard;

  const DevShell({
    super.key,
    required this.navigatorKey,
    required this.open,
    required this.child,
    this.hold = const Duration(milliseconds: 1000),
    this.keyboard = true,
  });

  @override
  State<DevShell> createState() => _DevShellState();
}

class _DevShellState extends State<DevShell> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (context == null) return;
    _opening = true;
    try {
      await widget.open(context);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DevTools.enabled) return widget.child;
    Widget shell = RawGestureDetector(
      key: DevShell.detectorKey,
      behavior: HitTestBehavior.translucent,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: widget.hold),
              (recognizer) => recognizer.onLongPress = _open,
            ),
      },
      child: widget.child,
    );
    if (widget.keyboard) {
      shell = CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.keyD,
            control: true,
            shift: true,
          ): _open,
          const SingleActivator(
            LogicalKeyboardKey.keyD,
            meta: true,
            shift: true,
          ): _open,
        },
        child: Focus(autofocus: true, child: shell),
      );
    }
    return shell;
  }
}
