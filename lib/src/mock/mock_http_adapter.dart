import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../faults/dev_faults.dart';
import 'mock_server.dart';

/// The app's routing table: what the server answers to one request, as a
/// status and a JSON body. [sent] is the request body as JSON (multipart
/// uploads are flattened to their fields plus the file names). Return a
/// 404 for anything the mock does not cover.
typedef MockHandler =
    Future<(int, Object?)> Function(RequestOptions options, Object? sent);

/// Dio's transport, answered by [handler] and behaving as the server's
/// [MockServer.faults] say: every request waits the delay, fails to
/// connect when offline, gets the picked 403 or 500 when it is a refused
/// write (the picked 401 whatever it is), and is recorded either way.
///
/// ```dart
/// final Dio dio = Dio(BaseOptions(baseUrl: 'http://mock'))
///   ..httpClientAdapter = MockHttpAdapter(server, myRoutes.handle);
/// ```
class MockHttpAdapter implements HttpClientAdapter {
  final MockServer server;
  final MockHandler handler;

  const MockHttpAdapter(this.server, this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final DevFaults faults = server.faults;
    if (faults.hasDelay) await Future.delayed(faults.delay);
    final Uri uri = options.uri;
    final String path = uri.query.isEmpty
        ? uri.path
        : '${uri.path}?${uri.query}';
    final Object? sent = sentBody(options.data);
    if (faults.offline) {
      server.record(
        MockRequest(
          at: DateTime.now(),
          method: options.method,
          path: path,
          body: sent,
          status: 0,
        ),
      );
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'mock server offline',
      );
    }
    final (int status, Object? body) = switch (faults.refusalFor(
      options.method,
    )) {
      final int refused => (
        refused,
        {
          'message':
              'The mock server refuses writes with a $refused right now.',
        },
      ),
      null => await handler(options, sent),
    };
    server.record(
      MockRequest(
        at: DateTime.now(),
        method: options.method,
        path: path,
        body: sent,
        status: status,
      ),
    );
    debugPrint('mock ${options.method} $path -> $status');
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  /// What the app sent, as JSON: multipart uploads become their text
  /// fields plus the file names.
  @visibleForTesting
  static Object? sentBody(Object? data) {
    if (data is! FormData) return data;
    return {
      for (final MapEntry<String, String> f in data.fields) f.key: f.value,
      for (final MapEntry<String, MultipartFile> f in data.files)
        f.key: '<file ${f.value.filename}, ${f.value.length} bytes>',
    };
  }

  @override
  void close({bool force = false}) {}
}
