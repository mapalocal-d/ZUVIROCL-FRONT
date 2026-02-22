import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro centralizado para tokens y datos sensibles.
/// Los tokens se guardan encriptados en el dispositivo.
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- Tokens ---
  Future<void> setAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);

  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  // --- Datos de sesión ---
  Future<void> setRol(String rol) => _storage.write(key: 'rol', value: rol);

  Future<String?> getRol() => _storage.read(key: 'rol');

  // --- Datos del usuario (caché) ---
  Future<void> setNombre(String nombre) =>
      _storage.write(key: 'nombre', value: nombre);

  Future<String?> getNombre() => _storage.read(key: 'nombre');

  Future<void> setApellido(String apellido) =>
      _storage.write(key: 'apellido', value: apellido);

  Future<String?> getApellido() => _storage.read(key: 'apellido');

  Future<void> setCorreo(String correo) =>
      _storage.write(key: 'correo', value: correo);

  Future<String?> getCorreo() => _storage.read(key: 'correo');

  Future<void> setUuid(String uuid) => _storage.write(key: 'uuid', value: uuid);

  Future<String?> getUuid() => _storage.read(key: 'uuid');

  // --- Guardar datos del usuario de una vez ---
  Future<void> guardarDatosUsuario(Map<String, dynamic> usuario) async {
    if (usuario['nombre'] != null)
      await setNombre(usuario['nombre'].toString());
    if (usuario['apellido'] != null)
      await setApellido(usuario['apellido'].toString());
    if (usuario['correo'] != null)
      await setCorreo(usuario['correo'].toString());
    if (usuario['uuid'] != null) await setUuid(usuario['uuid'].toString());
  }

  // --- Limpiar todo (logout) ---
  Future<void> clearAll() => _storage.deleteAll();

  // --- Verificar si hay sesión activa ---
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    final rol = await getRol();
    return token != null && token.isNotEmpty && rol != null && rol.isNotEmpty;
  }
}
