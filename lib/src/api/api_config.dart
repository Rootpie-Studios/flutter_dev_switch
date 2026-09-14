import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dev_tools.dart';
import '../faults/dev_faults.dart';
import 'api_environment.dart';

/// Where API requests go, decided once at start and changeable at runtime,
/// and what the developer menu does to them on the way out ([faults]).
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

  /// What happens to requests: the delay, "offline" and "refuse writes",
  /// applied by a `DevFaultsInterceptor` in the HTTP client. Loaded and
  /// saved along with the server pick.
  final DevFaults faults;

  final String _pickedKey;
  final String _customKey;

  ApiConfig({
    required this.environments,
    ApiEnvironment? production,
    this.defineUrl = const String.fromEnvironment('API_URL'),
    this.customExample = 'http://my-macbook.local/api',
    String prefsPrefix = 'api',
  }) : assert(environments.isNotEmpty, 'give at least one environment'),
       production = production ?? environments.first,
       faults = DevFaults(prefsKey: '${prefsPrefix}_delay_ms'),
       _pickedKey = '${prefsPrefix}_environment',
       _customKey = '${prefsPrefix}_custom_url';

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

  // ---- Preferences.

  /// The preferences this config keeps (server pick, custom address, the
  /// faults' delay), so a reset of the app's data can leave them alone.
  Set<String> get preferenceKeys => {
    _pickedKey,
    _customKey,
    if (faults.prefsKey case final String key) key,
  };

  /// Read the picks back from preferences, the faults' too. Safe to call
  /// more than once.
  Future<void> load([Future<SharedPreferences>? prefs]) async {
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      if (DevTools.enabled) {
        final String? key = p.getString(_pickedKey);
        _picked = environments.where((e) => e.key == key).firstOrNull;
        _custom = _picked == null
            ? normalizeUrl(p.getString(_customKey))
            : null;
      } else {
        // A store install has no picker, and must not inherit a pick left
        // behind by a TestFlight install of the same app: production only.
        _forget();
        await Future.wait([p.remove(_pickedKey), p.remove(_customKey)]);
      }
      await faults.load(Future.value(p));
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
      ]);
    } catch (e) {
      // The pick still applies; it just does not survive a restart.
      debugPrint('ApiConfig: could not save the pick ($e)');
    }
  }

  void _forget() {
    _picked = null;
    _custom = null;
  }

  /// Forget everything in memory (not in preferences), for tests.
  @visibleForTesting
  void reset() {
    _forget();
    faults.reset();
  }

  @override
  void dispose() {
    faults.dispose();
    super.dispose();
  }
}
