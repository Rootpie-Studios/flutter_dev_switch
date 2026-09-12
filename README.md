# flutter_dev_switch

Hidden developer tools for Flutter apps talking to an API: switch server at
runtime, show which one is in use, and log in as a seeded test account. Only
active in debug builds, builds with `--dart-define=DEV_TOOLS=true`, and
TestFlight installs; store installs get nothing.

## Install

```yaml
dependencies:
  flutter_dev_switch:
    git:
      url: https://github.com/Rootpie-Studios/flutter_dev_switch.git
      ref: main
```

## Use

```dart
// lib/config/api.dart
final apiConfig = ApiConfig(
  environments: const [
    ApiEnvironment(key: 'production', label: 'Production', baseUrl: 'https://example.com/api'),
    ApiEnvironment(key: 'local', label: 'Local', baseUrl: 'http://localhost/api'),
  ],
);

// main()
await DevTools.load();
await apiConfig.load();

// HTTP client, per request
options.baseUrl = apiConfig.baseUrl;

// Login page
DevMenuTrigger(config: apiConfig, child: const Logo());   // long press opens the picker
ServerBadge(config: apiConfig);                            // "Server: Local" when not on production
DevLoginButton(                                            // seeded accounts, hidden on production
  config: apiConfig,
  accounts: const [DevAccount(label: 'Admin', email: 'admin@example.com', password: 'password')],
  login: (context, account) => context.read<UserState>().login(account.email, account.password),
);
```

The picker also accepts a typed URL (a `.local` name or an IP; `http://` and
`/api` are filled in). Picks persist across restarts. `--dart-define=API_URL=…`
sets the default for a debug build. Pass `entries:` to `DevMenuTrigger` to add
your own rows; the long press then opens a menu with Server first. Swedish
texts: `strings: const DevToolsStrings.sv()`.

## Develop

```bash
flutter analyze && flutter test
```
