/// Runtime API server switching, a hidden developer menu, and the pieces
/// of a dev catalog (a mock server with the same knobs, a request log,
/// scenario rows) for the Rootpi Flutter apps.
///
/// The package never reaches into the app. It owns a state object
/// ([ApiConfig]) and some widgets; the app composes them:
///
/// 1. Describe the servers once: `final apiConfig = ApiConfig(environments: [...])`.
/// 2. In `main`, before the first request: `await DevTools.load(); await apiConfig.load();`.
/// 3. In the HTTP client, read `apiConfig.baseUrl` per request, and add a
///    `DevFaultsInterceptor(apiConfig.faults)` in front of the app's own,
///    so the menu's delay, "offline" and "refuse writes" apply to the
///    live API.
/// 4. Install a [DevShell] in `MaterialApp.builder`: a press held for a
///    second anywhere, or Ctrl+Shift+D, opens the [DevMenu] on every
///    screen. Add app-specific [DevMenuEntry]s for anything else testers
///    need: [devLoginEntry] with the seeded accounts gets them in on
///    non-production servers without typing, and [devResetEntry] wipes
///    the app's stores as freshly installed. Both take the app's own
///    operations as callbacks and report their failures to the tester.
///
/// For a dev catalog (a separate entry point that opens every screen on
/// bundled data, no server): extend [MockServer] with the app's data, answer
/// requests through a [MockHttpAdapter], and build the catalog from
/// [DevSectionHeader], [DevScenarioTile], a [DevFaultsPanel] on the
/// server's faults, and [MockRequestLog].
///
/// The sources are laid out by concern: `api/` (where requests go),
/// `faults/` (what happens to them), `menu/` (the shell, the menu and its
/// rows) and `mock/` (the catalog's fake server).
library;

export 'src/api/api_config.dart';
export 'src/api/api_environment.dart';
export 'src/api/server_picker.dart';
export 'src/dev_tools.dart';
export 'src/faults/dev_faults.dart';
export 'src/faults/dev_faults_interceptor.dart';
export 'src/faults/dev_faults_panel.dart';
export 'src/menu/dev_login.dart';
export 'src/menu/dev_menu.dart';
export 'src/menu/dev_reset.dart';
export 'src/menu/dev_sheet.dart';
export 'src/menu/dev_shell.dart';
export 'src/mock/dev_scenario_tile.dart';
export 'src/mock/mock_http_adapter.dart';
export 'src/mock/mock_request_log.dart';
export 'src/mock/mock_server.dart';
