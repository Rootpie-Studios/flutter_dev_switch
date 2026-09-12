/// Runtime API server switching and a hidden developer menu for the
/// Rootpi Flutter apps.
///
/// Wire-up, in this order:
///
/// 1. Describe the servers once: `final apiConfig = ApiConfig(environments: [...])`.
/// 2. In `main`, before the first request: `await DevTools.load(); await apiConfig.load();`.
/// 3. Read `apiConfig.baseUrl` per request in the HTTP client's interceptor.
/// 4. Wrap the logo on the login page in [DevMenuTrigger]; put a [ServerBadge]
///    under it. Add app-specific [DevMenuEntry]s for anything else testers need.
/// 5. Optionally a [DevLoginButton] with the seeded accounts, so testers get in
///    on non-production servers without typing.
library;

export 'src/api_config.dart';
export 'src/api_environment.dart';
export 'src/dev_login.dart';
export 'src/dev_menu.dart';
export 'src/dev_tools.dart';
export 'src/dev_tools_strings.dart';
export 'src/server_picker.dart';
