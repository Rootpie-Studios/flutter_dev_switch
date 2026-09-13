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
