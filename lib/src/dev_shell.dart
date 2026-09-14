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
/// - two fingers held still on the screen for [hold], anywhere. A pinch
///   moves at once, so it never counts. The whole screen is a [Listener]
///   that only watches the pointers, so nothing underneath is blocked.
///   (A corner spot was tried first: iOS keeps taps in the status bar and
///   beside the home indicator, and every corner inside the safe area
///   has a button on some screen.);
/// - a shake, on a device. The simulator's shake gesture does not reach
///   the accelerometer, so there the hold is the way;
/// - Ctrl+Shift+D or Cmd+Shift+D on a hardware keyboard.
///
/// [open] gets the root navigator's context, so the menu shows over
/// whatever is up, nested navigators and dialogs included.
class DevShell extends StatefulWidget {
  /// The pointer watcher, for tests.
  @visibleForTesting
  static const Key listenerKey = Key('dev-shell-listener');

  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function(BuildContext context) open;
  final Widget child;

  /// How long two fingers have to stay put.
  final Duration hold;

  /// How far a finger may drift during the hold.
  final double slop;
  final bool shake;
  final bool keyboard;

  const DevShell({
    super.key,
    required this.navigatorKey,
    required this.open,
    required this.child,
    this.hold = const Duration(milliseconds: 1500),
    this.slop = 24,
    this.shake = true,
    this.keyboard = true,
  });

  @override
  State<DevShell> createState() => _DevShellState();
}

class _DevShellState extends State<DevShell> {
  /// Where each pointer went down, by pointer id.
  final Map<int, Offset> _down = {};
  Timer? _holdTimer;
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
    _holdTimer?.cancel();
    super.dispose();
  }

  // ---- The two-finger hold. Exactly two pointers down, none of them
  // drifting, for the whole of [DevShell.hold].

  void _pointerDown(PointerDownEvent e) {
    _down[e.pointer] = e.position;
    _holdTimer?.cancel();
    if (_down.length != 2) return;
    _holdTimer = Timer(widget.hold, () {
      _down.clear();
      _open();
    });
  }

  void _pointerMove(PointerMoveEvent e) {
    final Offset? start = _down[e.pointer];
    if (start == null) return;
    if ((e.position - start).distance > widget.slop) _holdTimer?.cancel();
  }

  void _pointerEnd(PointerEvent e) {
    _down.remove(e.pointer);
    _holdTimer?.cancel();
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
    Widget shell = Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Listener(
            key: DevShell.listenerKey,
            behavior: HitTestBehavior.translucent,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerEnd,
            onPointerCancel: _pointerEnd,
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
