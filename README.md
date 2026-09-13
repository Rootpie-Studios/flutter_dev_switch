# flutter_dev_switch

Hidden developer tools for Flutter apps talking to an API: switch server at
runtime, show which one is in use, slow every request down to look at loading
states, and log in as a seeded test account. Only
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
await Future.delayed(apiConfig.slowdown);   // zero unless picked in the menu
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
`/api` are filled in). Picks persist across restarts, the request slowdown
too, and the badge shows both. `--dart-define=API_URL=…` sets the default for
a debug build. Pass `entries:` to `DevMenuTrigger` to add your own rows after
Server and Slow requests. `DevMenu.show(context, config: apiConfig, …)` opens
the same menu from a settings page. Swedish texts:
`strings: const DevToolsStrings.sv()`.

## Dev catalog

A second entry point (`lib/dev/main_dev.dart`, run with its own flavor so
the bundled data stays out of store builds) that opens every screen on
exported data, with no server and no login. The package provides the fake
server's knobs and the catalog's building blocks; the app provides the data
and the routing.

```dart
// lib/dev/mock_api.dart: the app's server, its data on top of the knobs
class AppMockServer extends MockServer {
  final MockData data;                       // the app's bundled JSON
  AppMockServer(this.data);
}

Future<(int, Object?)> handle(RequestOptions o, Object? sent) async =>
    switch ((o.method, o.uri.pathSegments)) {
      ('GET', ['me']) => (200, await data.user()),
      ('PUT', ['me']) => (200, {...await data.user(), 'name': (sent as Map)['name']}),
      _ => (404, {'message': 'Not mocked: ${o.method} ${o.uri.path}'}),
    };

// lib/dev/main_dev.dart
final AppMockServer server = AppMockServer(MockData('assets/mock/gym'));
final Dio dio = Dio(BaseOptions(baseUrl: 'http://mock'))
  ..httpClientAdapter = MockHttpAdapter(server, handle);
// ...build the app's repositories on this Dio, then:

ListView(children: [
  const DevSectionHeader('Mock server'),
  MockServerPanel(server: server),           // latency, offline, refuse writes
  const DevSectionHeader('Problems'),
  DevScenarioTile(
    icon: Icons.add,
    title: 'New problem',
    subtitle: 'Pick holds, name it, upload',
    onTap: () => CreateProblem.navigate(context),
  ),
  DevScenarioTile(
    icon: Icons.edit,
    title: 'Edit my problem',
    subtitle: 'None in the mock data',
    onTap: null,                             // greyed out, subtitle says why
  ),
  const DevSectionHeader('Requests'),
  MockRequestLog(server: server),            // what each screen sent
]);
```

`MockHttpAdapter` waits the latency, fails to connect when offline, answers
writes with a 500 when told to refuse them, records every request, and
flattens multipart uploads to their fields and file names before calling
the handler. The handler only has to route. Push scenarios through the
screens' real entry points (`Screen.navigate(context)`), so the catalog
cannot drift from the app.

## Develop

```bash
flutter analyze && flutter test
```
