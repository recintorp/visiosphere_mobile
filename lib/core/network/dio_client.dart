import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;
  static VoidCallback? _onUnauthorized;

  static bool get hasUnauthorizedCallback => _onUnauthorized != null;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static void setUnauthorizedCallback(VoidCallback callback) {
    _onUnauthorized = callback;
  }

  static void clearUnauthorizedCallback() {
    _onUnauthorized = null;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }

    return dio;
  }

  static void reset() {
    _instance = null;
    clearUnauthorizedCallback();
  }
}

/// Lowercase because Dio normalises response header names.
const String _renewedTokenHeader = 'x-renewed-token';

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// The backend slides a live session forward by returning a replacement token
  /// on any authenticated request that is nearing its expiry (see
  /// backend/config/session.js). Storing it here means a user who keeps using
  /// the app is never signed out by a timer.
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final renewed = response.headers.value(_renewedTokenHeader);
    if (renewed != null && renewed.isNotEmpty) {
      // Deliberately not awaited: the write must never delay delivering the
      // response the caller actually asked for. A dropped renewal costs a
      // future sign-in, not this request.
      SecureStorageService.updateToken(renewed);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      SecureStorageService.clearAuthData();
      DioClient._onUnauthorized?.call();
    }
    handler.next(err);
  }
}
