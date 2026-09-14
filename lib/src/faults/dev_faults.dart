import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dev_tools.dart';

/// What the developer menu does to requests on the way out: every one is
/// held back by [delay], fails to connect when [offline], and a write is
/// answered with [refuseWith] (a 403 or a 500) instead of being sent. The
/// same three knobs serve the live API (as `ApiConfig.faults`, applied by
/// a `DevFaultsInterceptor`) and a `MockServer` in a dev catalog; a
/// `DevFaultsPanel` shows them either way.
///
/// The delay is kept in preferences when [prefsKey] is given, so a tester
/// who set it finds it again after a restart, and sees it in the menu so
/// it is not forgotten. Offline and refused writes are in memory only: a
/// tester who left the app offline should not find it so on restart.
class DevFaults extends ChangeNotifier {
  /// Off, a realistic round trip, long enough to see a spinner, and long
  /// enough to do something else meanwhile.
  static const List<Duration> delays = [
    Duration.zero,
    Duration(milliseconds: 300),
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  /// What a refused write can be answered with: not allowed, or the
  /// server's fault. The two an app reacts to differently.
  static const List<int> refusals = [403, 500];

  /// Requests that only read; the rest are writes to [refuseWith].
  static const Set<String> reads = {'GET', 'HEAD', 'OPTIONS'};

  /// The preference the delay is kept under; null keeps nothing.
  final String? prefsKey;

  DevFaults({Duration delay = Duration.zero, this.prefsKey}) : _delay = delay;

  Duration _delay;
  bool _offline = false;
  int? _refuseWith;

  /// How long every request waits before it is sent.
  Duration get delay => _delay;

  /// Requests are being held back.
  bool get hasDelay => _delay > Duration.zero;

  /// Hold every request back by [delay]; zero to stop. Saved when there is
  /// a [prefsKey].
  Future<void> pickDelay(
    Duration delay, [
    Future<SharedPreferences>? prefs,
  ]) async {
    _delay = delay.isNegative ? Duration.zero : delay;
    notifyListeners();
    await _save(prefs);
  }

  /// Every request fails as if there were no connection.
  bool get offline => _offline;
  set offline(bool value) {
    if (value == _offline) return;
    _offline = value;
    notifyListeners();
  }

  /// The status every write is answered with instead of being sent, one
  /// of [refusals]; null lets writes through. Reads work either way.
  int? get refuseWith => _refuseWith;
  set refuseWith(int? status) {
    if (status == _refuseWith) return;
    _refuseWith = status;
    notifyListeners();
  }

  /// Writes are being refused.
  bool get refuseWrites => _refuseWith != null;

  /// The status a request with [method] is refused with right now, or
  /// null when it may go out.
  int? refusalFor(String method) =>
      reads.contains(method.toUpperCase()) ? null : _refuseWith;

  /// Read the delay back from preferences; nothing to do without a
  /// [prefsKey]. A store install keeps no delay and drops one left behind
  /// by a TestFlight install of the same app.
  Future<void> load([Future<SharedPreferences>? prefs]) async {
    final String? key = prefsKey;
    if (key == null) return;
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      if (!DevTools.enabled) {
        _delay = Duration.zero;
        await p.remove(key);
      } else {
        _delay = Duration(milliseconds: p.getInt(key) ?? 0);
      }
    } catch (e) {
      debugPrint('DevFaults: preferences unreadable, no delay ($e)');
      _delay = Duration.zero;
    }
    notifyListeners();
  }

  Future<void> _save(Future<SharedPreferences>? prefs) async {
    final String? key = prefsKey;
    if (key == null) return;
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      if (hasDelay) {
        await p.setInt(key, _delay.inMilliseconds);
      } else {
        await p.remove(key);
      }
    } catch (e) {
      // The delay still applies; it just does not survive a restart.
      debugPrint('DevFaults: could not save the delay ($e)');
    }
  }

  /// Forget everything in memory (not in preferences).
  void reset() {
    _delay = Duration.zero;
    _offline = false;
    _refuseWith = null;
    notifyListeners();
  }
}

/// "Off" for zero, otherwise the seconds: "3 s", "0.3 s".
String formatDelay(Duration delay) {
  if (delay <= Duration.zero) return 'Off';
  final double s = delay.inMilliseconds / 1000;
  return '${s == s.roundToDouble() ? s.toInt() : s} s';
}
