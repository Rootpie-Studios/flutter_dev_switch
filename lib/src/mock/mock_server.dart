import 'package:flutter/foundation.dart';

import '../faults/dev_faults.dart';

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

/// A fake server for a dev catalog: how it behaves ([faults], the same
/// delay, offline and refuse-writes knobs the developer menu has for the
/// live API) and what it has been asked ([requests], so a screen's traffic
/// can be read afterwards in a MockRequestLog).
///
/// Extend it with the app's own data and quirks, and answer requests
/// through a MockHttpAdapter. Control it with a DevFaultsPanel on [faults].
class MockServer extends ChangeNotifier {
  /// What happens to requests. Starts with a realistic round trip.
  final DevFaults faults;

  MockServer({Duration delay = const Duration(milliseconds: 300)})
    : faults = DevFaults(delay: delay);

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

  @override
  void dispose() {
    faults.dispose();
    super.dispose();
  }
}
