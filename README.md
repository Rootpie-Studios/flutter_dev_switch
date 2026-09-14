# flutter_dev_switch

Hidden developer tools for Flutter apps talking to an API: switch server at
runtime, slow every request down or fail it to look at loading and error
states, log in as a seeded test account, wipe the app's data. Only active in
debug builds, builds with `--dart-define=DEV_TOOLS=true`, and TestFlight
installs; store installs get nothing.

The package never reaches into the app. It owns one state object
(`ApiConfig`) and some widgets; the app reads the config in its HTTP client
and hands the menu callbacks for the few things only the app can do (log in,
wipe its stores). Failures in those callbacks are shown to the tester.

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
    ApiEnvironment(key: 'local', label: 'Local', baseUrl: 'http://localhost:8000/api'),
  ],
  customExample: 'http://my-macbook.local:8000/api',   // prefilled in the picker's address dialog
);

// main()
await DevTools.load();
await apiConfig.load();

// HTTP client
dio.interceptors.add(DevFaults(apiConfig));   // slowdown, offline, refuse writes, as picked in the menu
// and per request, in the app's own interceptor:
options.baseUrl = apiConfig.baseUrl;

// MaterialApp: the menu from every screen (press and hold anywhere for
// a second, or Ctrl+Shift+D)
MaterialApp(
  navigatorKey: navKey,
  builder: (context, child) => DevShell(
    navigatorKey: navKey,
    open: (context) => DevMenu.show(
      context,
      config: apiConfig,
      entries: [
        devLoginEntry(                                   // seeded accounts, not on production
          config: apiConfig,
          accounts: const [DevAccount(label: 'Admin', email: 'admin@example.com', password: 'password')],
          login: (context, account) => devActions.loginAs(account),   // null when logged in, else why not
        ),
        devResetEntry(steps: [                             // "as freshly installed", after a confirmation
          DevResetStep('Session', devActions.forgetSession),
          DevResetStep.preferences(apiConfig),
        ]),
      ],
    ),
    child: child!,
  ),
);
```

`devActions` above stands for whatever object the app builds once from its
repositories to do these things; keeping them in one place keeps the menu
file to a list of rows.

The picker also accepts a typed URL (a `.local` name or an IP; `http://` and
`/api` are filled in). Picks persist across restarts, the request slowdown
too; the menu's own rows show both. "Offline" and "Refuse writes" last until
the app restarts. `--dart-define=API_URL=…` sets the default for a debug
build. Pass `entries:` to `DevMenu.show` to add your own rows after the
package's; `showDevSheet`, `DevSheetBody` and `DevChoiceTile` build a sheet
in the same style. Swedish texts: `strings: const DevToolsStrings.sv()`.

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
