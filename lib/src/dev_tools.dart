import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Whether the app may show its developer conveniences: the server picker,
/// the dev menu and whatever an app adds to it. On for a debug build, for a
/// build made with `--dart-define=DEV_TOOLS=true`, and for a TestFlight
/// install; off for an App Store or Play Store install, where none of these
/// must exist.
///
/// A TestFlight install is told apart from the App Store by its sandbox
/// receipt (package_info_plus reports installer "com.apple.testflight").
/// Google Play offers no such signal: an internal-testing install looks
/// exactly like a production one, so Android testers get the tools from a
/// build with the define, not from the store track.
///
/// Read once at start ([load]); everything else checks [enabled].
abstract final class DevTools {
  static bool _enabled = kDebugMode || const bool.fromEnvironment('DEV_TOOLS');

  static bool get enabled => _enabled;

  static Future<void> load() async {
    if (_enabled) return;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _enabled = info.installerStore == 'com.apple.testflight';
    } catch (_) {
      _enabled = false;
    }
  }

  /// Running in the iOS simulator.
  static bool get isSimulator =>
      !kIsWeb &&
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  /// For tests.
  @visibleForTesting
  static set enabled(bool value) => _enabled = value;
}
