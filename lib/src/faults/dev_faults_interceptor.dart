import 'package:dio/dio.dart';

import 'dev_faults.dart';

/// [DevFaults] applied to the live API, as one Dio interceptor: the delay,
/// "offline" (every request fails to connect) and "refuse requests" (a
/// write gets the picked 403 or 500, every request the picked 401),
/// read per request so a pick applies at once. A refused request never
/// reaches the network. Add it after the interceptor that attaches the
/// app's token, if the app tells a 401 that used its token from one that
/// did not, so a refused 401 ends the session as a real one would:
///
/// ```dart
/// dio.interceptors.add(DevFaultsInterceptor(apiConfig.faults));
/// ```
///
/// Does nothing until something is picked, so it can stay in every build.
class DevFaultsInterceptor extends Interceptor {
  final DevFaults faults;
  const DevFaultsInterceptor(this.faults);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (faults.hasDelay) await Future.delayed(faults.delay);
    if (faults.offline) {
      return handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'Offline, by the developer menu.',
        ),
      );
    }
    if (faults.refusalFor(options.method) case final int status) {
      return handler.reject(
        DioException.badResponse(
          statusCode: status,
          requestOptions: options,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: status,
            data: {'message': 'Refused with a $status by the developer menu.'},
          ),
        ),
      );
    }
    handler.next(options);
  }
}
