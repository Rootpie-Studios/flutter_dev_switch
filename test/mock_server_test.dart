import 'package:dio/dio.dart';
import 'package:flutter_dev_switch/flutter_dev_switch.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers /things with a list and everything else with 404.
Future<(int, Object?)> routes(RequestOptions o, Object? sent) async =>
    switch ((o.method, o.uri.pathSegments)) {
      ('GET', ['things']) => (200, const ['a', 'b']),
      ('POST', ['things']) => (201, {'echo': sent}),
      _ => (404, {'message': 'Not mocked: ${o.uri.path}'}),
    };

void main() {
  late MockServer server;
  late Dio dio;

  setUp(() {
    server = MockServer(latency: Duration.zero);
    dio = Dio(BaseOptions(baseUrl: 'http://mock'))
      ..httpClientAdapter = MockHttpAdapter(server, routes);
  });

  test('answers through the handler and records the request', () async {
    final Response<dynamic> r = await dio.get('/things?page=2');
    expect(r.data, ['a', 'b']);
    expect(server.requests, hasLength(1));
    final MockRequest logged = server.requests.single;
    expect(logged.method, 'GET');
    expect(logged.path, '/things?page=2');
    expect(logged.status, 200);
    expect(logged.isWrite, isFalse);
    expect(logged.failed, isFalse);
  });

  test('a write carries its body and comes first in the log', () async {
    await dio.get('/things');
    final Response<dynamic> r = await dio.post('/things', data: {'x': 1});
    expect(r.statusCode, 201);
    expect(r.data, {
      'echo': {'x': 1},
    });
    expect(server.requests.first.method, 'POST');
    expect(server.requests.first.body, {'x': 1});
  });

  test('multipart bodies are flattened to fields and file names', () {
    final FormData form = FormData.fromMap({
      'name': 'Wall',
      'photo': MultipartFile.fromBytes([1, 2, 3], filename: 'wall.jpg'),
    });
    expect(MockHttpAdapter.sentBody(form), {
      'name': 'Wall',
      'photo': '<file wall.jpg, 3 bytes>',
    });
  });

  test('offline: every request fails to connect and is logged as 0', () async {
    server.offline = true;
    await expectLater(
      dio.get('/things'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(server.requests.single.status, 0);
    expect(server.requests.single.failed, isTrue);
  });

  test('refuse writes: writes get a 500, reads still work', () async {
    server.failWrites = true;
    expect((await dio.get('/things')).statusCode, 200);
    await expectLater(
      dio.post('/things', data: {'x': 1}),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    expect(server.requests.first.status, 500);
  });

  test('the handler decides what is not mocked', () async {
    await expectLater(
      dio.get('/nowhere'),
      throwsA(
        isA<DioException>().having((e) => e.response?.data, 'body', {
          'message': 'Not mocked: /nowhere',
        }),
      ),
    );
  });

  test('latency is waited for', () async {
    server.latency = const Duration(milliseconds: 50);
    final Stopwatch watch = Stopwatch()..start();
    await dio.get('/things');
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(45));
  });

  test('clearing forgets the log and notifies', () async {
    int notified = 0;
    server.addListener(() => notified++);
    await dio.get('/things');
    server.clearRequests();
    expect(server.requests, isEmpty);
    expect(notified, 2);
  });
}
