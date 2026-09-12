import 'package:flutter_test/flutter_test.dart';
import 'package:rootpi_devtools/rootpi_devtools.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ApiEnvironment production = ApiEnvironment(
  key: 'production',
  label: 'Production',
  baseUrl: 'https://example.com/api',
);
const ApiEnvironment staging = ApiEnvironment(
  key: 'staging',
  label: 'Staging',
  baseUrl: 'https://staging.example.com/api',
);
const ApiEnvironment dev = ApiEnvironment(
  key: 'dev',
  label: 'Dev',
  baseUrl: 'https://dev.example.com/api',
);
const ApiEnvironment local = ApiEnvironment(
  key: 'local',
  label: 'Local',
  baseUrl: 'http://localhost/api',
);

ApiConfig newConfig({String defineUrl = ''}) => ApiConfig(
  environments: const [production, staging, dev, local],
  defineUrl: defineUrl,
);

void main() {
  late ApiConfig config;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DevTools.enabled = true;
    config = newConfig();
  });

  test('production is the default and shows no badge', () async {
    await config.load();
    expect(config.baseUrl, production.baseUrl);
    expect(config.environment, production);
    expect(config.isNonProduction, isFalse);
    expect(config.picked, isNull);
  });

  test('the first environment is production unless told otherwise', () {
    expect(newConfig().production, production);
    final ApiConfig c = ApiConfig(
      environments: const [local, production],
      production: production,
    );
    expect(c.baseUrl, production.baseUrl);
  });

  test('a define wins over production but loses to a pick', () async {
    final ApiConfig c = newConfig(defineUrl: 'http://10.0.0.5/api');
    await c.load();
    expect(c.baseUrl, 'http://10.0.0.5/api');
    expect(c.environment, isNull);
    expect(c.isNonProduction, isTrue);
    await c.pick(staging);
    expect(c.baseUrl, staging.baseUrl);
  });

  test('a pick wins, is labelled, and survives a restart', () async {
    await config.pick(dev);
    expect(config.baseUrl, dev.baseUrl);
    expect(config.isNonProduction, isTrue);
    expect(config.label, 'Dev');

    final ApiConfig fresh = newConfig();
    expect(fresh.baseUrl, production.baseUrl);
    await fresh.load();
    expect(fresh.picked, dev, reason: 'read back from prefs by key');
  });

  test('resetting the pick falls back to the default', () async {
    await config.pick(local);
    await config.pick(null);
    expect(config.picked, isNull);
    expect(config.baseUrl, production.baseUrl);
    final ApiConfig fresh = newConfig();
    await fresh.load();
    expect(fresh.picked, isNull, reason: 'removed from prefs');
  });

  test('notifies listeners on pick', () async {
    int calls = 0;
    config.addListener(() => calls++);
    await config.pick(dev);
    expect(calls, 1);
  });

  test('a typed URL is normalised, wins, and survives a restart', () async {
    expect(await config.pickCustom('my-macbook.local'), isTrue);
    expect(config.baseUrl, 'http://my-macbook.local/api');
    expect(config.picked, isNull);
    expect(config.environment, isNull);
    expect(config.isNonProduction, isTrue);
    expect(config.label, 'http://my-macbook.local/api');
    expect(config.hasPick, isTrue);

    final ApiConfig fresh = newConfig();
    await fresh.load();
    expect(fresh.custom, 'http://my-macbook.local/api');
  });

  test('a known server and a typed URL replace each other', () async {
    await config.pickCustom('http://192.168.55.6/api');
    await config.pick(staging);
    expect(config.custom, isNull);
    expect(config.baseUrl, staging.baseUrl);

    await config.pickCustom('192.168.55.6');
    expect(config.picked, isNull);
    expect(config.baseUrl, 'http://192.168.55.6/api');
  });

  test('two configs with different prefixes do not share a pick', () async {
    final ApiConfig other = ApiConfig(
      environments: const [production, dev],
      prefsPrefix: 'other',
    );
    await config.pick(dev);
    await other.load();
    expect(other.picked, isNull);
  });

  test('normalizeUrl', () {
    expect(ApiConfig.normalizeUrl(' 192.168.55.6 '), 'http://192.168.55.6/api');
    expect(
      ApiConfig.normalizeUrl('https://dev.example.com/api/'),
      'https://dev.example.com/api',
    );
    expect(
      ApiConfig.normalizeUrl('http://host.local:8080/v2'),
      'http://host.local:8080/v2',
    );
    expect(ApiConfig.normalizeUrl(''), isNull);
    expect(ApiConfig.normalizeUrl('   '), isNull);
    expect(ApiConfig.normalizeUrl('ftp://host/api'), isNull);
    expect(ApiConfig.normalizeUrl('http://'), isNull);
  });

  test('an unusable typed URL changes nothing', () async {
    await config.pick(dev);
    expect(await config.pickCustom('   '), isFalse);
    expect(config.picked, dev);
    expect(config.custom, isNull);
  });

  test('a store install ignores and forgets a picked server', () async {
    await config.pick(dev);
    DevTools.enabled = false;

    final ApiConfig store = newConfig();
    await store.load();
    expect(store.baseUrl, production.baseUrl);
    expect(store.picked, isNull);

    DevTools.enabled = true;
    final ApiConfig again = newConfig();
    await again.load();
    expect(again.picked, isNull, reason: 'the pick was dropped, not hidden');
  });
}
