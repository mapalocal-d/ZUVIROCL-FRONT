import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
import 'secure_storage.dart';
import 'app_logger.dart';
import 'main.dart' show navigatorKey;

class SinConexionException implements Exception {
  @override
  String toString() => 'Sin conexión a internet';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _secure = SecureStorage();
  static const Duration _timeout = Duration(seconds: 15);

  // --- UTILIDADES ---

  Future<void> _verificarConexion() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      throw SinConexionException();
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secure.getAccessToken() ?? '';
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // --- LÓGICA DE CIERRE DE SESIÓN ---

  Future<void> _cerrarSesionYRedirigir() async {
    AppLogger.w('Sesión irrecuperable. Redirigiendo al inicio.');
    await _secure.clearAll();
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Te manda al home/login y borra todo el historial de navegación
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  // --- REFRESH TOKEN (EL CORAZÓN DEL PROBLEMA) ---

  Future<bool> _refreshToken() async {
    final refreshToken = await _secure.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      AppLogger.i('Intentando renovar token en el backend...');
      final resp = await http
          .post(
            Uri.parse(ApiConfig.refresh),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refresh_token": refreshToken}),
          )
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final nuevoAccess = body['access_token'];
        final nuevoRefresh = body['refresh_token'];

        if (nuevoAccess != null) {
          await _secure.setAccessToken(nuevoAccess);
          if (nuevoRefresh != null) await _secure.setRefreshToken(nuevoRefresh);
          AppLogger.i('Tokens actualizados correctamente.');
          return true;
        }
      }
      AppLogger.e('Refresh falló: ${resp.statusCode}');
    } catch (e) {
      AppLogger.e('Error en _refreshToken', e);
    }
    return false;
  }

  // --- INTERCEPTOR DE ERRORES (EL GUARDIÁN) ---

  /// Esta función centraliza la lógica. Si es 401, refresca. Si es 403, avisa suscripción.
  Future<http.Response> _procesarRespuesta(
    http.Response resp,
    Future<http.Response> Function() reintentar,
  ) async {
    // Caso 401: Token Vencido
    if (resp.statusCode == 401) {
      final exito = await _refreshToken();
      if (exito) {
        return await reintentar();
      } else {
        await _cerrarSesionYRedirigir();
        return resp;
      }
    }

    // Caso 403: Falta de pago / Suscripción (Paso 3)
    if (resp.statusCode == 403) {
      AppLogger.w('Usuario sin suscripción activa.');
      // Aquí podrías redirigir a la pantalla de pago
      navigatorKey.currentState?.pushNamed('/suscripcion');
      return resp;
    }

    return resp;
  }

  // --- MÉTODOS PÚBLICOS ---

  Future<http.Response> get(String url) async {
    await _verificarConexion();
    final h = await _authHeaders();
    final resp = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
    return _procesarRespuesta(resp, () async {
      final newH = await _authHeaders();
      return await http.get(Uri.parse(url), headers: newH).timeout(_timeout);
    });
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    final h = await _authHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    final resp = await http
        .post(Uri.parse(url), headers: h, body: encoded)
        .timeout(_timeout);
    return _procesarRespuesta(resp, () async {
      final newH = await _authHeaders();
      return await http
          .post(Uri.parse(url), headers: newH, body: encoded)
          .timeout(_timeout);
    });
  }

  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    final h = await _authHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    final resp = await http
        .patch(Uri.parse(url), headers: h, body: encoded)
        .timeout(_timeout);
    return _procesarRespuesta(resp, () async {
      final newH = await _authHeaders();
      return await http
          .patch(Uri.parse(url), headers: newH, body: encoded)
          .timeout(_timeout);
    });
  }

  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    final h = await _authHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    final resp = await http
        .put(Uri.parse(url), headers: h, body: encoded)
        .timeout(_timeout);
    return _procesarRespuesta(resp, () async {
      final newH = await _authHeaders();
      return await http
          .put(Uri.parse(url), headers: newH, body: encoded)
          .timeout(_timeout);
    });
  }

  Future<http.Response> delete(String url) async {
    await _verificarConexion();
    final h = await _authHeaders();
    final resp = await http
        .delete(Uri.parse(url), headers: h)
        .timeout(_timeout);
    return _procesarRespuesta(resp, () async {
      final newH = await _authHeaders();
      return await http.delete(Uri.parse(url), headers: newH).timeout(_timeout);
    });
  }
}
