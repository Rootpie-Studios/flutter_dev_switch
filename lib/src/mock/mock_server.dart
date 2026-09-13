import 'package:flutter/foundation.dart';

/// A call the app made to a [MockServer] and how it was answered.
/// [status] is 0 when the server was offline.
class MockRequest {
  final DateTime at;
  final String method;
  final String path;
  final Object? body;
  final int status;

  const MockRequest({
    required this.at,
    required this.method,
    required this.path,
    required this.body,
    required this.status,
  });

  bool get isWrite => method != 'GET';
  bool get failed => status == 0 || status >= 400;
}

/// How a fake server behaves, and what it has been asked. The knobs a
/// dev catalog needs to look at loading, offline and failure states:
/// [latency], [offline], [failWrites]. Every request goes into [requests]
/// so a screen's traffic can be read afterwards ([MockRequestLog]).
///
/// Extend it with the app's own data and quirks, and answer requests
/// through a [MockHttpAdapter]. Control it with a [MockServerPanel].
class MockServer extends ChangeNotifier {
  MockServer({Duration latency = const Duration(milliseconds: 300)})
    : _latency = latency;

  Duration _latency;

  /// How long every answer takes.
  Duration get latency => _latency;
  set latency(Duration value) {
    _latency = value;
    notifyListeners();
  }

  bool _offline = false;

  /// Every request fails as if there were no connection.
  bool get offline => _offline;
  set offline(bool value) {
    _offline = value;
    notifyListeners();
  }

  bool _failWrites = false;

  /// Anything but a GET is answered with a 500; reads still work.
  bool get failWrites => _failWrites;
  set failWrites(bool value) {
    _failWrites = value;
    notifyListeners();
  }

  final List<MockRequest> _requests = [];

  /// Everything asked so far, newest first.
  List<MockRequest> get requests => List.unmodifiable(_requests);

  /// Called by the adapter for every request, answered or not.
  void record(MockRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }

  void clearRequests() {
    _requests.clear();
    notifyListeners();
  }
}
