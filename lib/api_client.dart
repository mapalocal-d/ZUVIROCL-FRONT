import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';
import 'main.dart' show navigatorKey;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const Duration _timeout = Duration(seconds: 15);

  /// Cierra sesión y redirige al home cuando el refresh también falla
  Future<void> _cerrarSesionYRedirigir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
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
          await prefs.setString('access_token', nuevoAccess);
        }
        if (nuevoRefresh != null) {
          await prefs.setString('refresh_token', nuevoRefresh);
        }
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
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
    var headers = await _authHeaders();
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
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
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
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
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
    var headers = await _authHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
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
    var headers = await _authHeaders();
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
