## 0.7.0

- `DevFaults`, a Dio interceptor for the live API: the slowdown, and the
  menu's new "Offline" and "Refuse writes" switches (`ApiConfig.offline`,
  `ApiConfig.refuseWrites`, in memory only), so retry paths can be tried
  against real servers.
- `devResetEntry` and `DevResetStep`: a row that wipes the app's stores as
  freshly installed, after a confirmation naming them.
  `DevResetStep.preferences` clears every preference but the menu's own.

## 0.6.0

- `DevLoginButton` and `ServerBadge` are gone: test login is a row in the
  menu (`devLoginEntry`, listed only off production) and the menu's Server
  row shows the pick, so login pages carry nothing for developers.
- `DevMenuEntry.when`: a row can be listed only when a condition holds,
  asked again whenever the menu rebuilds.

## 0.5.0

- `DevMenuTrigger` is gone: the DevShell opens the menu from every screen,
  so a logo no longer has to. Put a `ServerBadge` under the logo as before.

## 0.4.0

- `DevShell`, installed once in `MaterialApp.builder`: a press held for a
  second anywhere, a shake on a device, or Ctrl+Shift+D / Cmd+Shift+D opens
  the DevMenu on every screen, over nested navigators and dialogs. Nothing
  is attached in a store build. Adds a dependency on sensors_plus.

## 0.3.0

- Request slowdown: `ApiConfig.slowdown` / `pickSlowdown`, a "Slow requests"
  row in DevMenu opening the new SlowdownPicker, shown in ServerBadge.
- DevMenu always opens as a menu (it has two rows of its own now), so
  `DevMenu.show` suits a settings page as well as the logo long press.
- Dev catalog pieces, extracted from lekaos: `MockServer` (latency, offline,
  refuse writes, request log), `MockHttpAdapter` for Dio with an app-supplied
  routing handler, and the widgets `MockServerPanel`, `MockRequestLog`,
  `DevSectionHeader`, `DevScenarioTile`. Adds a dependency on dio.

## 0.2.0

- DevLoginButton, devLoginEntry and DevAccount: test login with seeded accounts.
- DevMenu opens the server picker directly when it has no entries.

## 0.1.0

- Initial extraction from mapp_time: ApiConfig, DevTools, ServerPicker,
  ServerBadge, plus a generic DevMenu with app-defined entries.
