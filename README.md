# flutter_dev_switch

Runtime API server switching plus a hidden developer menu, shared by the
Rootpi Flutter apps (mapp_time, lekaos). Private; not on pub.dev.

What you get:

- `ApiConfig` – which server requests go to: a pick made in the app, else
  `--dart-define=API_URL`, else production. Persisted with shared_preferences.
- `DevTools` – on in debug builds, with `--dart-define=DEV_TOOLS=true`, and in
  TestFlight installs; off in store installs (a store install also forgets any pick).
- `ServerPicker` / `ServerBadge` – the bottom sheet to switch servers and the
  pill that says which non-production server is in use.
- `DevMenu` / `DevMenuTrigger` / `DevMenuEntry` – long-press a logo to open a
  menu with the Server row plus whatever the app adds (test login, data
  generators, cache wipes). With no entries the long press opens the server
  picker directly, so an app that only needs server switching gets no extra step.
- `DevLoginButton` / `devLoginEntry` / `DevAccount` – "Test login" as a button
  (shown only on a non-production server) or as a menu entry: pick a seeded
  account, the app's own `login` callback does the rest.
- `DevToolsStrings` – English by default, `DevToolsStrings.sv()` for Swedish.

## Use in an app

`pubspec.yaml`, during development next to the checkout:

```yaml
dependencies:
  flutter_dev_switch:
    path: ../flutter_dev_switch
```

or pinned to a tag of the private repo (needs git access on the machine that builds):

```yaml
dependencies:
  flutter_dev_switch:
    git:
      url: git@github.com:Rootpie-Studios/flutter_dev_switch.git
      ref: v0.1.0
```

`lib/config/api.dart`:

```dart
final ApiConfig apiConfig = ApiConfig(
  environments: const [
    ApiEnvironment(key: 'production', label: 'Production', baseUrl: 'https://example.com/api'),
    ApiEnvironment(key: 'staging', label: 'Staging', baseUrl: 'https://staging.example.com/api'),
    ApiEnvironment(key: 'local', label: 'Local (simulator)', baseUrl: 'http://localhost/api'),
  ],
);
```

`main.dart`, before the first request:

```dart
await DevTools.load();
await apiConfig.load();
```

HTTP client – read the URL per request so a switch applies immediately:

```dart
onRequest: (options, handler) {
  options.baseUrl = apiConfig.baseUrl;
  ...
}
```

Login page:

```dart
Column(children: [
  DevMenuTrigger(
    config: apiConfig,
    entries: [
      DevMenuEntry(label: 'Log in as test user', icon: Icons.person, onTap: (ctx) async { ... }),
    ],
    child: const Logo(),
  ),
  ServerBadge(config: apiConfig),
])
```

Test login with seeded accounts (button under the logo, or `devLoginEntry(...)`
in `DevMenuTrigger.entries`):

```dart
DevLoginButton(
  config: apiConfig,
  accounts: const [
    DevAccount(label: 'Admin', email: 'admin@example.com', password: 'password'),
  ],
  login: (context, account) async {
    final user = await api.login(account.email, account.password);
    if (user == null) return false;
    if (context.mounted) context.read<UserState>().setUser(user);
    return true;
  },
)
```

Pass `strings: const DevToolsStrings.sv()` to the widgets for Swedish.

## Checks

```bash
flutter analyze && flutter test
```
