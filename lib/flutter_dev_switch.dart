/// Runtime API server switching, a hidden developer menu, and the pieces
/// of a dev catalog (a mock server with knobs, a request log, scenario
/// rows) for the Rootpi Flutter apps.
///
/// Wire-up of the hidden menu, in this order:
///
/// 1. Describe the servers once: `final apiConfig = ApiConfig(environments: [...])`.
/// 2. In `main`, before the first request: `await DevTools.load(); await apiConfig.load();`.
/// 3. Read `apiConfig.baseUrl` per request in the HTTP client's interceptor,
///    and await `apiConfig.slowdown` there too so the dev menu's request
///    slowdown applies.
/// 4. Install a [DevShell] in `MaterialApp.builder`: a triple tap on the
///    status bar's trailing end, a shake, or Ctrl+Shift+D opens the menu on every
///    screen. Add app-specific [DevMenuEntry]s for anything else testers
///    need. [DevMenuTrigger] (a long press on a logo) and [DevMenu.show]
///    (e.g. from settings) are further ways in, with a [ServerBadge] to keep
///    a non-production server visible.
/// 5. Optionally a [DevLoginButton] with the seeded accounts, so testers get in
///    on non-production servers without typing.
///
/// For a dev catalog (a separate entry point that opens every screen on
/// bundled data, no server): extend [MockServer] with the app's data, answer
/// requests through a [MockHttpAdapter], and build the catalog from
/// [DevSectionHeader], [DevScenarioTile], [MockServerPanel] and
/// [MockRequestLog].
library;

export 'src/catalog/dev_catalog_widgets.dart';
export 'src/catalog/mock_server_panel.dart';
export 'src/mock/mock_http_adapter.dart';
export 'src/mock/mock_server.dart';

export 'src/api_config.dart';
export 'src/api_environment.dart';
export 'src/dev_login.dart';
export 'src/dev_menu.dart';
export 'src/dev_shell.dart';
export 'src/dev_tools.dart';
export 'src/dev_tools_strings.dart';
export 'src/server_picker.dart';
export 'src/slowdown_picker.dart';
