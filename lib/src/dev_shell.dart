import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'dev_tools.dart';

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
/// Three ways in, all of them gone from a store build:
///
/// - a long press, anywhere, held for [hold]. The shell wraps the app in
///   a gesture detector, so it is the outermost member of the gesture
///   arena: anything underneath with a long press of its own (a text
///   field, a logo) wins as usual, a tap wins on release, a drag wins as
///   soon as it moves, and only a press held where nothing else claims it
///   opens the menu. (A corner spot was tried first: iOS keeps taps in the
///   status bar and beside the home indicator, and every corner inside
///   the safe area has a button on some screen.);
/// - a shake, on a device. The simulator's shake gesture does not reach
///   the accelerometer, so there the press is the way;
/// - Ctrl+Shift+D or Cmd+Shift+D on a hardware keyboard.
///
/// [open] gets the root navigator's context, so the menu shows over
/// whatever is up, nested navigators and dialogs included.
class DevShell extends StatefulWidget {
  /// The gesture detector, for tests.
  @visibleForTesting
  static const Key detectorKey = Key('dev-shell-detector');

  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function(BuildContext context) open;
  final Widget child;

  /// How long the press has to be held.
  final Duration hold;
  final bool shake;
  final bool keyboard;

  const DevShell({
    super.key,
    required this.navigatorKey,
    required this.open,
    required this.child,
    this.hold = const Duration(milliseconds: 1000),
    this.shake = true,
    this.keyboard = true,
  });

  @override
  State<DevShell> createState() => _DevShellState();
}

class _DevShellState extends State<DevShell> {
  bool _opening = false;
  StreamSubscription<UserAccelerometerEvent>? _motion;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  /// Shake: acceleration without gravity above this, in m/s².
  static const double _shakeThreshold = 18;
  static const Duration _shakeCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    if (DevTools.enabled && widget.shake) _listenForShake();
  }

  void _listenForShake() {
    try {
      _motion = userAccelerometerEventStream().listen(
        (event) {
          final double g = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          if (g < _shakeThreshold) return;
          final DateTime now = DateTime.now();
          if (now.difference(_lastShake) < _shakeCooldown) return;
          _lastShake = now;
          _open();
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {
      // No sensors on this platform: the hold and the keyboard remain.
    }
  }

  @override
  void dispose() {
    _motion?.cancel();
    super.dispose();
  }

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
