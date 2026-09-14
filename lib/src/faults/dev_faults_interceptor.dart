import 'package:dio/dio.dart';

import 'dev_faults.dart';

/// [DevFaults] applied to the live API, as one Dio interceptor: the delay,
/// "offline" (every request fails to connect) and "refuse writes" (a
/// write gets the picked 403 or 500), read per request so a pick applies
/// at once. Add it before the app's own interceptors, so a refused request
/// never reaches them or the network:
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
