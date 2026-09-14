import 'dart:async';
import 'dart:math' as math;

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
/// - a triple tap on the top trailing corner, inside the status bar's safe
///   area, on every screen. The corner is a [Listener] that only counts
///   taps, so what is underneath still gets them;
/// - a shake, on a device. The simulator's shake gesture does not reach
///   the accelerometer, so there the corner is the way;
/// - Ctrl+Shift+D or Cmd+Shift+D on a hardware keyboard.
///
/// [open] gets the root navigator's context, so the menu shows over
/// whatever is up, nested navigators and dialogs included.
class DevShell extends StatefulWidget {
  /// The corner hotspot, for tests.
  @visibleForTesting
  static const Key hotspotKey = Key('dev-shell-hotspot');

  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function(BuildContext context) open;
  final Widget child;

  /// Taps within this window count as one sequence.
  final Duration tapWindow;
  final int taps;
  final double hotspotSize;
  final bool shake;
  final bool keyboard;

  const DevShell({
    super.key,
    required this.navigatorKey,
    required this.open,
    required this.child,
    this.tapWindow = const Duration(milliseconds: 1000),
    this.taps = 3,
    this.hotspotSize = 44,
    this.shake = true,
    this.keyboard = true,
  });

  @override
  State<DevShell> createState() => _DevShellState();
}

class _DevShellState extends State<DevShell> {
  int _tapCount = 0;
  Timer? _tapTimer;
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
      // No sensors on this platform: the corner and the keyboard remain.
    }
  }

  @override
  void dispose() {
    _motion?.cancel();
    _tapTimer?.cancel();
    super.dispose();
  }

  /// The first tap starts the window; the sequence is forgotten when it
  /// closes without the count being reached.
  void _tap() {
    _tapCount++;
    if (_tapCount == 1) {
      _tapTimer = Timer(widget.tapWindow, () => _tapCount = 0);
      return;
    }
    if (_tapCount < widget.taps) return;
    _tapTimer?.cancel();
    _tapCount = 0;
    _open();
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
    final double top = MediaQuery.paddingOf(context).top;
    Widget shell = Stack(
      children: [
        widget.child,
        PositionedDirectional(
          top: top,
          end: 0,
          width: widget.hotspotSize,
          height: widget.hotspotSize,
          child: Listener(
            key: DevShell.hotspotKey,
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _tap(),
          ),
        ),
      ],
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
