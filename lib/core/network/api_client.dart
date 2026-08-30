import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_token_store.dart';
import 'api_exception.dart';

/// Dio client with courier-flow essentials:
///  - bearer JWT injection
///  - single-flight silent refresh on 401 (MOB-C-01)
///  - `Idempotency-Key` + `X-App-Version` headers (MOB-C-04)
///  - DRF error envelope mapping via [ApiException]
class ApiClient {
  ApiClient({required this.tokens, Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              headers: {'X-App-Version': '1.0.0+1'},
              validateStatus: (s) => s != null && s < 500,
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(onRequest: _injectAuth));
  }

  final SecureTokenStore tokens;
  final Dio dio;

  Future<void> Function()? onSessionExpired;

  bool _refreshing = false;

  Future<void> _injectAuth(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.startsWith('http')) {
      final base = options.path.startsWith('/api/auth/')
          ? Env.apiAuth
          : Env.apiV1;
      options.path = '$base${options.path.replaceFirst(RegExp(r'^/'), '')}';
    }
    final access = await tokens.readAccess();
    if (access != null) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  /// Send + map errors. Mutating calls may pass an idempotency key.
  Future<T> send<T>(Future<Response<T>> Function(Dio dio) call,
      {String? idempotencyKey}) async {
    Response<T>? response;
    try {
      if (idempotencyKey != null) {
        dio.options.headers['Idempotency-Key'] = idempotencyKey;
      }
      response = await call(dio);
    } on DioException catch (e) {
      final mapped = ApiException.fromDio(e);
      if (mapped.isAuthExpired && !e.requestOptions.path.contains('/auth/login')) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          try {
            response = await call(dio);
          } on DioException catch (retryError) {
            throw ApiException.fromDio(retryError);
          }
        } else {
          await tokens.clear();
          onSessionExpired?.call();
          throw mapped;
        }
      } else {
        throw mapped;
      }
    }
    if (response.statusCode! >= 400) {
      throw ApiException(
        statusCode: response.statusCode!,
        detail: 'Request failed (${response.statusCode})',
      );
    }
    return response as T;
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await tokens.readRefresh();
      if (refresh == null) return false;
      final res = await dio.post('${Env.apiAuth}token/refresh/',
          data: {'refresh': refresh});
      if (res.statusCode != 200) return false;
      final access = (res.data as Map)['access'] as String;
      await tokens.saveAccess(access);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
