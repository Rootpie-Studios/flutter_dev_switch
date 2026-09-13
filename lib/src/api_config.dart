import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_environment.dart';
import 'dev_tools.dart';

/// Where API requests go, decided once at start and changeable at runtime.
///
/// Resolution, first hit wins:
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
/// Also carries the [slowdown] testers pick in the dev menu: how long every
/// request waits before it goes out, for looking at loading states. Read
/// it per request as well, and await it before sending.
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

  final String _pickedKey;
  final String _customKey;
  final String _slowdownKey;

  ApiConfig({
    required this.environments,
    ApiEnvironment? production,
    this.defineUrl = const String.fromEnvironment('API_URL'),
    String prefsPrefix = 'api',
  }) : assert(environments.isNotEmpty, 'give at least one environment'),
       production = production ?? environments.first,
       _pickedKey = '${prefsPrefix}_environment',
       _customKey = '${prefsPrefix}_custom_url',
       _slowdownKey = '${prefsPrefix}_slowdown_ms';

  ApiEnvironment? _picked;
  String? _custom;
  Duration _slowdown = Duration.zero;

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

  /// True unless requests go to production: what the badge shows.
  bool get isNonProduction => baseUrl != production.baseUrl;

  /// Short human label for what is in use, for the badge and the picker.
  String get label => environment?.label ?? baseUrl;

  /// How long every request waits before it is sent. Zero unless picked in
  /// the dev menu ([SlowdownPicker]); always zero in a store install.
  Duration get slowdown => _slowdown;

  /// Requests are being held back: what the badge shows.
  bool get hasSlowdown => _slowdown > Duration.zero;

  ApiEnvironment? _match(String url) =>
      environments.where((e) => e.baseUrl == url).firstOrNull;

  /// Read the pick back from preferences. Safe to call more than once.
  Future<void> load([Future<SharedPreferences>? prefs]) async {
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      // A store install has no picker, and must not inherit a pick left
      // behind by a TestFlight install of the same app: production only.
      if (!DevTools.enabled) {
        _picked = null;
        _custom = null;
        _slowdown = Duration.zero;
        await Future.wait([
          p.remove(_pickedKey),
          p.remove(_customKey),
          p.remove(_slowdownKey),
        ]);
        notifyListeners();
        return;
      }
      final String? key = p.getString(_pickedKey);
      _picked = environments.where((e) => e.key == key).firstOrNull;
      _custom = _picked == null ? normalizeUrl(p.getString(_customKey)) : null;
      _slowdown = Duration(milliseconds: p.getInt(_slowdownKey) ?? 0);
    } catch (_) {
      _picked = null;
      _custom = null;
      _slowdown = Duration.zero;
    }
    notifyListeners();
  }

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

  /// Hold every request back by [delay] before sending it; zero to stop.
  /// Kept in preferences like a server pick, so it survives a restart, and
  /// shown in the [ServerBadge] so it is not forgotten.
  Future<void> pickSlowdown(
    Duration delay, [
    Future<SharedPreferences>? prefs,
  ]) async {
    _slowdown = delay.isNegative ? Duration.zero : delay;
    notifyListeners();
    await _save(prefs);
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

  Future<void> _save(Future<SharedPreferences>? prefs) async {
    try {
      final SharedPreferences p =
          await (prefs ?? SharedPreferences.getInstance());
      if (_picked case ApiEnvironment e) {
        await p.setString(_pickedKey, e.key);
      } else {
        await p.remove(_pickedKey);
      }
      if (_custom case String url) {
        await p.setString(_customKey, url);
      } else {
        await p.remove(_customKey);
      }
      if (hasSlowdown) {
        await p.setInt(_slowdownKey, _slowdown.inMilliseconds);
      } else {
        await p.remove(_slowdownKey);
      }
    } catch (_) {
      // Preferences failing only means the pick does not survive a restart.
    }
  }

  /// Forget everything in memory (not in preferences), for tests.
  @visibleForTesting
  void reset() {
    _picked = null;
    _custom = null;
    _slowdown = Duration.zero;
  }
}
