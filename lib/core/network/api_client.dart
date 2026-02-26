import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'api_exception.dart';

/// Cliente HTTP centralizado para el backend Zuviro.
///
/// Incluye internamente:
/// - Inyección automática de Authorization y X-Request-ID
/// - Refresh proactivo cuando el token está por expirar
/// - Refresh reactivo cuando el servidor devuelve 401
/// - Cola de espera para evitar refreshes concurrentes
/// - Dio separado para refresh (evita loop infinito)
/// - ForceLogout cuando el refresh falla
class ApiClient {
  final StorageService _storage;
  final Dio _dio;
  final Dio _refreshDio;
  final _uuid = const Uuid();

  // Control de refresh concurrente
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiClient(this._storage)
      : _dio = Dio(_baseOptions()),
        _refreshDio = Dio(_baseOptions()) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // =========================================================
  // INTERCEPTOR: ANTES DE CADA REQUEST
  // =========================================================

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. X-Request-ID para el middleware de observabilidad del backend
    options.headers['X-Request-ID'] = _uuid.v4();

    // 2. Refresh proactivo si el token está por expirar
    if (_storage.shouldRefreshSoon && !_isRefreshing) {
      if (kDebugMode)
        debugPrint('🔄 [ZUVIRO] Refresh proactivo (token por expirar)');
      final success = await _attemptRefresh();
      // CORRECCIÓN: Si falla y el token expiró, forzar logout inmediatamente
      if (!success && _storage.isAccessTokenExpired) {
        await _forceLogout();
        return handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.cancel),
        );
      }
    }

    // 3. Inyectar token actual
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  // =========================================================
  // INTERCEPTOR: MANEJO DE ERRORES
  // =========================================================

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Si es 401, intentar refresh y reintentar el request original
    if (error.response?.statusCode == 401) {
      if (kDebugMode)
        debugPrint('⚠️ [ZUVIRO] 401 detectado, intentando refresh...');

      final success = await _attemptRefresh();

      if (success) {
        try {
          final token = await _storage.getAccessToken();
          error.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      } else {
        await _forceLogout();
        // CORRECCIÓN: Propagar el error como ApiException de sesión expirada
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            error: ApiException.sessionExpired(),
            response: error.response,
            type: error.type,
          ),
        );
      }
    }

    // Traducir error de Dio a ApiException
    return handler.next(
      DioException(
        requestOptions: error.requestOptions,
        error: ApiException.fromDioError(error),
        response: error.response,
        type: error.type,
      ),
    );
  }

  // =========================================================
  // REFRESH TOKEN (Con cola de espera)
  // =========================================================

  Future<bool> _attemptRefresh() async {
    // Si ya hay un refresh en curso, esperar a que termine
    if (_isRefreshing) {
      if (kDebugMode) debugPrint('⏳ [ZUVIRO] Esperando refresh en curso...');
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        if (kDebugMode) debugPrint('❌ [ZUVIRO] No hay refresh token');
        _completeRefresh(false);
        return false;
      }

      // Usar _refreshDio (sin interceptores) para evitar loop infinito
      final response = await _refreshDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      final expiresIn = data['expira_en'] as int?;

      if (newAccess == null || newRefresh == null || expiresIn == null) {
        if (kDebugMode) debugPrint('❌ [ZUVIRO] Refresh: respuesta incompleta');
        _completeRefresh(false);
        return false;
      }

      await _storage.updateTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresInSeconds: expiresIn,
      );

      if (kDebugMode) debugPrint('✅ [ZUVIRO] Token renovado exitosamente');
      _completeRefresh(true);
      return true;
    } on DioException catch (e) {
      // MEJORA: Manejo específico de errores de red vs errores del servidor
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        if (kDebugMode) debugPrint('❌ [ZUVIRO] Refresh: error de red - $e');
      } else if (e.response?.statusCode == 401) {
        if (kDebugMode)
          debugPrint('❌ [ZUVIRO] Refresh token inválido o expirado');
      } else {
        if (kDebugMode) debugPrint('❌ [ZUVIRO] Refresh falló: $e');
      }
      _completeRefresh(false);
      return false;
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ [ZUVIRO] Refresh falló inesperadamente: $e');
      _completeRefresh(false);
      return false;
    }
  }

  void _completeRefresh(bool success) {
    _isRefreshing = false;
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete(success);
    }
    _refreshCompleter = null;
  }

  // =========================================================
  // FORCE LOGOUT
  // =========================================================

  Future<void> _forceLogout() async {
    if (kDebugMode)
      debugPrint('🚪 [ZUVIRO] Sesión expirada → redirigido a login');
    await _storage.clearSession();
    AppNavigator.forceLogout();
  }

  // =========================================================
  // MÉTODOS CRUD
  // =========================================================

  Future<Response> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: query);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: query);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  // =========================================================
  // EXTRACCIÓN SEGURA DE EXCEPCIÓN
  // =========================================================

  ApiException _extractException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException.fromDioError(e);
  }
}
