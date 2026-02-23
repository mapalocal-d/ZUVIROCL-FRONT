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

  /// [SEMÁFORO] Evita múltiples peticiones de refresh simultáneas que bloqueen la sesión en Redis
  Future<bool>? _refreshEnCurso;

  /// Bandera para evitar múltiples redirecciones visuales al mismo tiempo
  bool _estaRedirigiendo = false;

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

  // --- CIERRE DE SESIÓN ---

  Future<void> _cerrarSesionYRedirigir() async {
    if (_estaRedirigiendo) return;
    _estaRedirigiendo = true;

    AppLogger.w('Cerrando sesión: Credenciales inválidas o expiradas.');
    await _secure.clearAll();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );

    // Resetear bandera después de un tiempo para permitir futuras acciones si re-loguea
    Future.delayed(const Duration(seconds: 2), () => _estaRedirigiendo = false);
  }

  // --- LÓGICA DE REFRESH CON SEMÁFORO (COMPATIBLE CON FASTAPI) ---

  Future<bool> _refreshToken() async {
    if (_refreshEnCurso != null) {
      AppLogger.i('🔄 Esperando al refresh que ya está en curso...');
      return _refreshEnCurso!;
    }

    _refreshEnCurso = _ejecutarPeticionRefresh();

    try {
      final resultado = await _refreshEnCurso!;
      return resultado;
    } finally {
      _refreshEnCurso = null;
    }
  }

  Future<bool> _ejecutarPeticionRefresh() async {
    final refreshToken = await _secure.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      AppLogger.i('🚀 Iniciando Refresh Token ÚNICO...');
      final resp = await http
          .post(
            Uri.parse(ApiConfig.refresh),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "refresh_token":
                  refreshToken, // Coincide con data: RefreshToken de tu backend
            }),
          )
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);

        // Extraemos las claves según el retorno de tu endpoint FastAPI
        final nuevoAccess = body['access_token'];
        final nuevoRefresh = body['refresh_token'];

        if (nuevoAccess != null) {
          await _secure.setAccessToken(nuevoAccess);
          // Actualizamos el refresh token ya que tu backend lo rota
          if (nuevoRefresh != null) {
            await _secure.setRefreshToken(nuevoRefresh);
          }
          AppLogger.i('✅ Tokens renovados y rotados exitosamente.');
          return true;
        }
      }
      AppLogger.e('❌ Refresh rechazado por el servidor: ${resp.statusCode}');
    } catch (e) {
      AppLogger.e('💥 Error crítico en _ejecutarPeticionRefresh', e);
    }
    return false;
  }

  // --- MANEJO CENTRALIZADO DE PETICIONES ---

  Future<http.Response> _procesarRespuesta(
    http.Response resp,
    Future<http.Response> Function() reintentar,
  ) async {
    // 401: Token expirado
    if (resp.statusCode == 401) {
      AppLogger.w('⚠️ Error 401 detectado. Iniciando validación...');
      final exito = await _refreshToken();
      if (exito) {
        AppLogger.i('🔁 Reintentando petición original con nuevo token...');
        return await reintentar();
      } else {
        await _cerrarSesionYRedirigir();
        return resp;
      }
    }

    // 403: Suscripción requerida (Paso 3)
    if (resp.statusCode == 403) {
      AppLogger.w('💳 Error 403: Suscripción requerida.');
      // Evitamos abrir múltiples veces la pantalla si hay varias peticiones fallando
      if (!_estaRedirigiendo) {
        _estaRedirigiendo = true;
        navigatorKey.currentState?.pushNamed('/suscripcion').then((_) {
          _estaRedirigiendo = false;
        });
      }
      return resp;
    }

    return resp;
  }

  // --- MÉTODOS HTTP ---

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
