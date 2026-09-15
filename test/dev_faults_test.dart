import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers everything with 200 and counts what got through.
class _Adapter implements HttpClientAdapter {
  int reached = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    reached++;
    return ResponseBody.fromString(jsonEncode({}), 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiConfig config;
  late _Adapter adapter;
  late Dio dio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    config = ApiConfig(
      environments: const [
        ApiEnvironment(key: 'p', label: 'P', baseUrl: 'https://p.example.com'),
      ],
      defineUrl: '',
    );
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://p.example.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(DevFaultsInterceptor(config.faults));
  });

  test('nothing picked: requests go through', () async {
    await dio.get('/x');
    await dio.post('/x');
    expect(adapter.reached, 2);
  });

  test(
    'offline: every request fails to connect, nothing reaches the network',
    () async {
      config.faults.offline = true;
      final DioException e = await dio
          .get('/x')
          .then<DioException>(
            (_) => fail('sent'),
            onError: (Object e) => e as DioException,
          );
      expect(e.type, DioExceptionType.connectionError);
      expect(adapter.reached, 0);
      config.faults.offline = false;
      await dio.get('/x');
      expect(adapter.reached, 1);
    },
  );

  test(
    'refuse requests: the picked status for a POST, reads still work',
    () async {
      config.faults.refuseWith = 403;
      await dio.get('/x');
      await dio.head('/x');
      final DioException e = await dio
          .post('/x')
          .then<DioException>(
            (_) => fail('sent'),
            onError: (Object e) => e as DioException,
          );
      expect(e.type, DioExceptionType.badResponse);
      expect(e.response?.statusCode, 403);
      expect((e.response?.data as Map)['message'], contains('403'));
      expect(adapter.reached, 2, reason: 'GET and HEAD went out');

      config.faults.refuseWith = 500;
      final DioException again = await dio
          .delete('/x')
          .then<DioException>(
            (_) => fail('sent'),
            onError: (Object e) => e as DioException,
          );
      expect(again.response?.statusCode, 500);

      config.faults.refuseWith = null;
      await dio.post('/x');
      expect(adapter.reached, 3);
    },
  );

  test('refuse with a 401: the session is over, so reads get it too', () async {
    config.faults.refuseWith = DevFaults.sessionOver;
    expect(config.faults.refusalFor('GET'), 401);
    expect(config.faults.refusalFor('POST'), 401);
    final DioException e = await dio
        .get('/x')
        .then<DioException>(
          (_) => fail('sent'),
          onError: (Object e) => e as DioException,
        );
    expect(e.response?.statusCode, 401);
    expect(adapter.reached, 0);
    config.faults.refuseWith = 403;
    expect(config.faults.refusalFor('GET'), isNull);
  });

  test('the switches notify', () {
    int notified = 0;
    config.faults.addListener(() => notified++);
    config.faults.offline = true;
    config.faults.offline = true;
    config.faults.refuseWith = 500;
    config.faults.refuseWith = 500;
    expect(notified, 2);
    config.faults.reset();
    expect(notified, 3);
    expect(config.faults.refusing, isFalse);
  });
}
