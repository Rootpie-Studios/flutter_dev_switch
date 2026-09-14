import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_environment.dart';
import 'dev_tools.dart';

/// Where API requests go, decided once at start and changeable at runtime,
/// plus what the developer menu does to them on the way out.
///
/// Where requests go, first hit wins:
///  1. A server picked in the app (the hidden picker), either one of
///     [environments] or a URL typed in, e.g. a developer machine on the
///     LAN by its Bonjour name. Kept in preferences so testers stay on it
///     across restarts.
///  2. `--dart-define=API_URL=...` at build time, for developers pointing a
///     debug build at a machine on the LAN.
///  3. [production], so a release build with no define and no pick is a
///     production build by construction.
///
/// Read [baseUrl] per request (in the HTTP client's interceptor) so a change
/// applies to every request at once without recreating anything. [load]
/// must have completed before the first request; await it in `main`.
///
/// What happens to requests, all applied by a [DevFaults] interceptor:
/// [slowdown] holds every request back (kept in preferences, so a tester
/// who set it finds it again after a restart, shown in the menu so it is
/// not forgotten); [offline] and [refuseWrites] fail them (in memory only:
/// a tester who left the app offline should not find it so on restart).
class ApiConfig extends ChangeNotifier {
  /// The servers testers can pick from, in the order they are listed.
  final List<ApiEnvironment> environments;

  /// The server used when nothing is picked and no define is set.
  /// Defaults to the first of [environments].
  final ApiEnvironment production;

  /// The build-time override, empty when not given. Comes from
  /// `--dart-define=API_URL=...`, which is visible to every library in the
  /// build; pass [defineUrl] only to override it (tests).
  final String defineUrl;

  /// Prefilled into the picker's custom-address dialog, so the common case
  /// (the developer's own machine on the LAN) is one tap away.
  final String customExample;

  final String _pickedKey;
  final String _customKey;
  final String _slowdownKey;

  ApiConfig({
    required this.environments,
    ApiEnvironment? production,
    this.defineUrl = const String.fromEnvironment('API_URL'),
    this.customExample = 'http://my-macbook.local/api',
    String prefsPrefix = 'api',
  }) : assert(environments.isNotEmpty, 'give at least one environment'),
       production = production ?? environments.first,
       _pickedKey = '${prefsPrefix}_environment',
       _customKey = '${prefsPrefix}_custom_url',
       _slowdownKey = '${prefsPrefix}_slowdown_ms';

  // ---- Where requests go.

  ApiEnvironment? _picked;
  String? _custom;

  /// The known server picked in the app, if any.
  ApiEnvironment? get picked => _picked;

  /// The URL typed into the picker, if any.
  String? get custom => _custom;

  /// Something was chosen in the app, known server or typed URL.
  bool get hasPick => _picked != null || _custom != null;

  /// Where requests go right now.
  String get baseUrl =>
      _picked?.baseUrl ??
      _custom ??
      (defineUrl.isNotEmpty ? defineUrl : production.baseUrl);

  /// The known environment [baseUrl] belongs to, or null for a typed URL or
  /// a define that matches none of them.
  ApiEnvironment? get environment => _picked ?? _match(baseUrl);

  /// True unless requests go to production.
  bool get isNonProduction => baseUrl != production.baseUrl;

  /// Short human label for what is in use.
  String get label => environment?.label ?? baseUrl;

  ApiEnvironment? _match(String url) =>
      environments.where((e) => e.baseUrl == url).firstOrNull;

  /// Pick a known server, or null to fall back to the define and
  /// production. Either way a typed URL is dropped.
  Future<void> pick(
    ApiEnvironment? environment, [
    Future<SharedPreferences>? prefs,
  ]) async {
    _picked = environment;
    _custom = null;
    notifyListeners();
    await _save(prefs);
  }

  /// Use a typed-in base URL, e.g. `http://my-macbook.local/api` for a
  /// machine on the LAN by its Bonjour name, which unlike its IP stays the
  /// same. Returns false, changing nothing, when [url] is not something
  /// requests can be sent to.
  Future<bool> pickCustom(
    String url, [
    Future<SharedPreferences>? prefs,
  ]) async {
    final String? normalized = normalizeUrl(url);
    if (normalized == null) return false;
    _picked = null;
    _custom = normalized;
    notifyListeners();
    await _save(prefs);
    return true;
  }

  /// A typed URL made usable: trimmed, `http://` assumed when no scheme
  /// was given, `/api` appended when no path was, trailing slash dropped.
  /// Null when there is no host in it.
  static String? normalizeUrl(String? raw) {
    String text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    String path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (path.isEmpty) path = '/api';
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  // ---- What happens to requests (see DevFaults).

  Duration _slowdown = Duration.zero;
  bool _offline = false;
  bool _refuseWrites = false;

  /// How long every request waits before it is sent. Zero unless picked in
  /// the dev menu; always zero in a store install.
  Duration get slowdown => _slowdown;

  /// Requests are being held back.
  bool get hasSlowdown => _slowdown > Duration.zero;

  /// Hold every request back by [delay] before sending it; zero to stop.
  Future<void> pickSlowdown(
    Duration delay, [
    Future<SharedPreferences>? prefs,
  ]) async {
    _slowdown = delay.isNegative ? Duration.zero : delay;
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

  /// Requests other than GET are answered with a 500; reads still work.
  bool get refuseWrites => _refuseWrites;
  set refuseWrites(bool value) {
    if (value == _refuseWrites) return;
    _refuseWrites = value;
    notifyListeners();
  }

  // ---- Preferences.

  /// The preferences this config keeps (server pick, custom address,
  /// slowdown), so a reset of the app's data can leave them alone.
  Set<String> get preferenceKeys => {_pickedKey, _customKey, _slowdownKey};

  /// Read the picks back from preferences. Safe to call more than once.
  Future<void> load([Future<SharedPreferences>? prefs]) async {
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      // A store install has no picker, and must not inherit a pick left
      // behind by a TestFlight install of the same app: production only.
      if (!DevTools.enabled) {
        _forget();
        await Future.wait(preferenceKeys.map(p.remove));
        notifyListeners();
        return;
      }
      final String? key = p.getString(_pickedKey);
      _picked = environments.where((e) => e.key == key).firstOrNull;
      _custom = _picked == null ? normalizeUrl(p.getString(_customKey)) : null;
      _slowdown = Duration(milliseconds: p.getInt(_slowdownKey) ?? 0);
    } catch (e) {
      debugPrint('ApiConfig: preferences unreadable, using defaults ($e)');
      _forget();
    }
    notifyListeners();
  }

  Future<void> _save(Future<SharedPreferences>? prefs) async {
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      await Future.wait([
        if (_picked case ApiEnvironment e)
          p.setString(_pickedKey, e.key)
        else
          p.remove(_pickedKey),
        if (_custom case String url)
          p.setString(_customKey, url)
        else
          p.remove(_customKey),
        if (hasSlowdown)
          p.setInt(_slowdownKey, _slowdown.inMilliseconds)
        else
          p.remove(_slowdownKey),
      ]);
    } catch (e) {
      // The pick still applies; it just does not survive a restart.
      debugPrint('ApiConfig: could not save the pick ($e)');
    }
  }

  void _forget() {
    _picked = null;
    _custom = null;
    _slowdown = Duration.zero;
  }

  /// Forget everything in memory (not in preferences), for tests.
  @visibleForTesting
  void reset() => _forget();
}
