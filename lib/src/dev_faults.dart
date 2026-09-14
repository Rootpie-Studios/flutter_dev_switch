import 'package:dio/dio.dart';

import 'api_config.dart';

/// What the developer menu does to the live API, as one Dio interceptor:
/// the request slowdown, "offline" (every request fails to connect) and
/// "refuse writes" (anything but GET gets a 500), all read from [config]
/// per request so a pick applies at once. Add it before the app's own
/// interceptors, so a refused request never reaches them or the network:
///
/// ```dart
/// dio.interceptors.add(DevFaults(apiConfig));
/// ```
///
/// Does nothing until something is picked, so it can stay in every build.
class DevFaults extends Interceptor {
  final ApiConfig config;
  const DevFaults(this.config);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final Duration wait = config.slowdown;
    if (wait > Duration.zero) await Future.delayed(wait);
    if (config.offline) {
      return handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'Offline, by the developer menu.',
        ),
      );
    }
    if (config.refuseWrites && options.method.toUpperCase() != 'GET') {
      return handler.reject(
        DioException.badResponse(
          statusCode: 500,
          requestOptions: options,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 500,
            data: const {'message': 'Refused by the developer menu.'},
          ),
        ),
      );
    }
    handler.next(options);
  }
}
