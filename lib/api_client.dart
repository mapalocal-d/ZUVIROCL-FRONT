import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
import 'secure_storage.dart';
import 'app_logger.dart';
import 'main.dart' show navigatorKey;

/// Excepción personalizada cuando no hay internet
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

  /// Verifica si hay conexión a internet
  Future<void> _verificarConexion() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      throw SinConexionException();
    }
  }

  /// Cierra sesión y redirige al home cuando el refresh también falla
  Future<void> _cerrarSesionYRedirigir() async {
    AppLogger.w('Sesión expirada. Redirigiendo al inicio.');
    await _secure.clearAll();

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _secure.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      AppLogger.w('No hay refresh token disponible.');
      return false;
    }

    try {
      AppLogger.i('Intentando renovar token...');
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
        }
        if (nuevoRefresh != null) {
          await _secure.setRefreshToken(nuevoRefresh);
        }
        AppLogger.i('Token renovado exitosamente.');
        return true;
      } else {
        AppLogger.e('Refresh falló con código: ${resp.statusCode}');
      }
    } catch (e) {
      AppLogger.e('Error al renovar token', e);
    }

    return false;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secure.getAccessToken() ?? '';
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "accept": "application/json",
    };
  }

  /// Maneja el 401: intenta refresh, si falla → cierra sesión y redirige
  Future<http.Response?> _handle401(
    Future<http.Response> Function() reintentar,
  ) async {
    final refreshed = await _refreshToken();
    if (refreshed) {
      return await reintentar();
    } else {
      await _cerrarSesionYRedirigir();
      return null;
    }
  }

  Future<http.Response> get(String url) async {
    await _verificarConexion();
    var headers = await _authHeaders();
    AppLogger.d('GET $url');
    var resp = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(_timeout);

    if (resp.statusCode == 401) {
      final reintento = await _handle401(() async {
        final h = await _authHeaders();
        return await http.get(Uri.parse(url), headers: h).timeout(_timeout);
      });
      if (reintento != null) return reintento;
    }
    return resp;
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
    AppLogger.d('POST $url');
    var resp = await http
        .post(Uri.parse(url), headers: headers, body: encodedBody)
        .timeout(_timeout);

    if (resp.statusCode == 401) {
      final reintento = await _handle401(() async {
        final h = await _authHeaders();
        return await http
            .post(Uri.parse(url), headers: h, body: encodedBody)
            .timeout(_timeout);
      });
      if (reintento != null) return reintento;
    }
    return resp;
  }

  Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
    AppLogger.d('PATCH $url');
    var resp = await http
        .patch(Uri.parse(url), headers: headers, body: encodedBody)
        .timeout(_timeout);

    if (resp.statusCode == 401) {
      final reintento = await _handle401(() async {
        final h = await _authHeaders();
        return await http
            .patch(Uri.parse(url), headers: h, body: encodedBody)
            .timeout(_timeout);
      });
      if (reintento != null) return reintento;
    }
    return resp;
  }

  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    await _verificarConexion();
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
    AppLogger.d('PUT $url');
    var resp = await http
        .put(Uri.parse(url), headers: headers, body: encodedBody)
        .timeout(_timeout);

    if (resp.statusCode == 401) {
      final reintento = await _handle401(() async {
        final h = await _authHeaders();
        return await http
            .put(Uri.parse(url), headers: h, body: encodedBody)
            .timeout(_timeout);
      });
      if (reintento != null) return reintento;
    }
    return resp;
  }

  Future<http.Response> delete(String url) async {
    await _verificarConexion();
    var headers = await _authHeaders();
    AppLogger.d('DELETE $url');
    var resp = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(_timeout);

    if (resp.statusCode == 401) {
      final reintento = await _handle401(() async {
        final h = await _authHeaders();
        return await http.delete(Uri.parse(url), headers: h).timeout(_timeout);
      });
      if (reintento != null) return reintento;
    }
    return resp;
  }
}
