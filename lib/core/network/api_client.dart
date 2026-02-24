import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storage;
  final _uuid = const Uuid();

  ApiClient(this._storage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(
            milliseconds: ApiConstants.connectionTimeout,
          ),
          receiveTimeout: const Duration(
            milliseconds: ApiConstants.receiveTimeout,
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 1. ANTES DE ENVIAR LA PETICIÓN
        onRequest: (options, handler) async {
          // Inyectamos el X-Request-ID para tu middleware de Python
          options.headers['X-Request-ID'] = _uuid.v4();

          // Buscamos el token en la "caja fuerte"
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        // 2. AL RECIBIR UN ERROR (Manejo de 401 y Refresh)
        onError: (DioException e, handler) async {
          // Si el servidor dice 401 (Unauthorized), intentamos renovar el token
          if (e.response?.statusCode == 401) {
            final refreshToken = await _storage.getRefreshToken();

            if (refreshToken != null) {
              try {
                // Llamamos a tu endpoint /auth/refresh en Railway
                final response = await _dio.post(
                  ApiConstants.refresh,
                  data: {'refresh_token': refreshToken},
                );

                final newAccessToken = response.data['access_token'];
                final newRefreshToken = response.data['refresh_token'];

                // Guardamos las llaves nuevas en la caja fuerte
                await _storage.saveTokens(newAccessToken, newRefreshToken);

                // Reintentamos la petición original que falló
                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final clonedRequest = await _dio.fetch(e.requestOptions);
                return handler.resolve(clonedRequest);
              } catch (refreshError) {
                // Si el refresh también falla, forzamos el logout
                await _storage.logout();
              }
            }
          }

          // Si no fue un 401 o el refresh falló, traducimos el error
          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              error: ApiException.fromDioError(e),
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  // Métodos CRUD simplificados
  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw e.error as ApiException;
    }
  }
}
