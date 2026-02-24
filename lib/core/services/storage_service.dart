import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  StorageService(this._secure, this._prefs);

  // Llaves exactas de tu JSON de Python
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'rol';
  static const _kUUID = 'uuid';
  static const _kName = 'nombre';
  static const _kEmail = 'correo';

  // =========================================================
  // 🔐 CAJA FUERTE (Tokens JWT)
  // =========================================================

  /// Guarda los tokens de acceso y refresh. Se usa en Login y Refresh.
  Future<void> saveTokens(String access, String refresh) async {
    await _secure.write(key: _kAccess, value: access);
    await _secure.write(key: _kRefresh, value: refresh);
  }

  Future<String?> getAccessToken() => _secure.read(key: _kAccess);
  Future<String?> getRefreshToken() => _secure.read(key: _kRefresh);

  // =========================================================
  // ⚡ MEMORIA RÁPIDA (Perfil de Usuario)
  // =========================================================

  /// Guarda los datos del perfil. Se llama en Login o al actualizar perfil.
  /// No se llama en el Refresh para no sobreescribir con datos vacíos.
  Future<void> saveProfile({
    required String uuid,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    await _prefs.setString(_kUUID, uuid);
    await _prefs.setString(_kName, nombre);
    await _prefs.setString(_kEmail, correo);
    await _prefs.setString(_kRole, rol);
  }

  // Getters para la interfaz de usuario
  String? getRole() => _prefs.getString(_kRole);
  String? getUUID() => _prefs.getString(_kUUID);
  String? getUserName() => _prefs.getString(_kName); // Agregado para el UI
  String? getUserEmail() => _prefs.getString(_kEmail); // Agregado para el UI

  // =========================================================
  // 🧹 LIMPIEZA (Logout)
  // =========================================================

  Future<void> logout() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}
