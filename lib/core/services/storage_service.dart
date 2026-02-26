import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../enums.dart';

/// Estados posibles al verificar la sesión local en el splash.
enum SessionStatus {
  /// Access token válido → navegar directo al dashboard.
  valid,

  /// Access expirado pero hay refresh → intentar renovar.
  needsRefresh,

  /// Sin sesión o refresh inválido → navegar al login.
  expired,
}

/// Servicio centralizado de almacenamiento local.
///
/// Estrategia:
/// - [FlutterSecureStorage] → Tokens JWT (encriptados en hardware)
/// - [SharedPreferences] → Perfil, rol, expiración (acceso rápido y sincrónico)
class StorageService {
  // =========================================================
  // SINGLETON
  // =========================================================

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // =========================================================
  // INSTANCIAS
  // =========================================================

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SharedPreferences? _prefs;

  /// Debe llamarse UNA vez en main.dart antes de runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('🚀 [ZUVIRO] StorageService inicializado');
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() no fue llamado en main.dart');
    return _prefs!;
  }

  // =========================================================
  // KEYS (prefijo zv_ para no colisionar con paquetes terceros)
  // =========================================================

  // Secure Storage
  static const _kAccess = 'zv_access';
  static const _kRefresh = 'zv_refresh';

  // SharedPreferences — Sesión
  static const _kRol = 'zv_rol';
  static const _kExpiresAt = 'zv_exp_at';
  static const _kExpiresInSec = 'zv_exp_sec';
  static const _kIsLoggedIn = 'zv_logged';

  // SharedPreferences — Perfil
  static const _kUserJson = 'zv_user_data';
  static const _kUserUuid = 'zv_user_uuid';
  static const _kUserNombre = 'zv_user_nombre';
  static const _kUserCorreo = 'zv_user_correo';
  static const _kUserPatente = 'zv_user_patente';
  static const _kUserLinea = 'zv_user_linea';

  /// Todas las keys de SharedPreferences (para borrado selectivo).
  static const _allPrefsKeys = [
    _kRol,
    _kExpiresAt,
    _kExpiresInSec,
    _kIsLoggedIn,
    _kUserJson,
    _kUserUuid,
    _kUserNombre,
    _kUserCorreo,
    _kUserPatente,
    _kUserLinea,
  ];

  // =========================================================
  // GUARDAR SESIÓN COMPLETA (Post-Login)
  // =========================================================

  /// Persiste la sesión completa tras un login exitoso.
  ///
  /// Tokens van a secure storage (encriptado).
  /// Resto va a shared preferences (acceso rápido).
  /// Se resta un margen de 60s a la expiración para hacer refresh
  /// proactivo antes de que el servidor rechace el token.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String rol,
    required int expiresInSeconds,
    Map<String, dynamic>? usuario,
  }) async {
    // 1. Tokens sensibles → Secure Storage (en paralelo)
    await Future.wait([
      _secure.write(key: _kAccess, value: accessToken),
      _secure.write(key: _kRefresh, value: refreshToken),
    ]);

    // 2. Expiración local con margen de seguridad de 60 segundos
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .subtract(const Duration(seconds: 60));

    // 3. Datos de sesión → SharedPreferences (en paralelo)
    await Future.wait([
      _p.setString(_kRol, rol),
      _p.setInt(_kExpiresAt, expiresAt.millisecondsSinceEpoch),
      _p.setInt(_kExpiresInSec, expiresInSeconds),
      _p.setBool(_kIsLoggedIn, true),
    ]);

    // 4. Perfil del usuario
    if (usuario != null) await saveUserProfile(usuario);

    if (kDebugMode) {
      debugPrint(
          '🚀 [ZUVIRO] Sesión guardada | rol=$rol | expira=${expiresAt.toLocal()}');
    }
  }

  // =========================================================
  // ACTUALIZAR TOKENS (Post-Refresh)
  // Solo tokens y expiración, sin tocar perfil ni rol.
  // =========================================================

  /// Actualiza solo los tokens después de un refresh exitoso.
  /// Usado por el interceptor HTTP cuando detecta expiración.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    await Future.wait([
      _secure.write(key: _kAccess, value: accessToken),
      _secure.write(key: _kRefresh, value: refreshToken),
    ]);

    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .subtract(const Duration(seconds: 60));

    await Future.wait([
      _p.setInt(_kExpiresAt, expiresAt.millisecondsSinceEpoch),
      _p.setInt(_kExpiresInSec, expiresInSeconds),
    ]);

    if (kDebugMode) {
      debugPrint(
          '🚀 [ZUVIRO] Tokens actualizados | expira=${expiresAt.toLocal()}');
    }
  }

  // =========================================================
  // GUARDAR / ACTUALIZAR PERFIL
  // =========================================================

  /// Guarda datos del usuario. Extrae campos frecuentes para acceso
  /// rápido sin parsear JSON cada vez.
  Future<void> saveUserProfile(Map<String, dynamic> usuario) async {
    final futures = <Future>[
      _p.setString(_kUserJson, jsonEncode(usuario)),
    ];

    // Extraer campos frecuentes para getters rápidos
    if (usuario['uuid'] != null) {
      futures.add(_p.setString(_kUserUuid, usuario['uuid'].toString()));
    }
    if (usuario['nombre'] != null) {
      futures.add(_p.setString(_kUserNombre, usuario['nombre'].toString()));
    }
    if (usuario['correo'] != null) {
      futures.add(_p.setString(_kUserCorreo, usuario['correo'].toString()));
    }
    if (usuario['patente'] != null) {
      futures.add(_p.setString(_kUserPatente, usuario['patente'].toString()));
    }
    if (usuario['linea'] != null) {
      futures.add(_p.setString(_kUserLinea, usuario['linea'].toString()));
    }

    await Future.wait(futures);
  }

  // =========================================================
  // LECTURA DE TOKENS (Async — Secure Storage)
  // =========================================================

  /// Access token actual o null si no existe.
  Future<String?> getAccessToken() => _secure.read(key: _kAccess);

  /// Refresh token actual o null si no existe.
  Future<String?> getRefreshToken() => _secure.read(key: _kRefresh);

  // =========================================================
  // LECTURA DE SESIÓN (Sync — SharedPreferences)
  // =========================================================

  /// Rol como enum tipado (nunca un String suelto).
  UserRole get userRole => UserRole.fromJson(_p.getString(_kRol) ?? 'pasajero');

  /// Rol como String (para enviar a la API).
  String get rolString => _p.getString(_kRol) ?? 'pasajero';

  /// Helpers de rol para condicionales rápidos en la UI.
  bool get isConductor => userRole == UserRole.conductor;
  bool get isPasajero => userRole == UserRole.pasajero;

  /// Indica si hay una sesión guardada localmente.
  bool get isLoggedIn => _p.getBool(_kIsLoggedIn) ?? false;

  /// Duración original del token en segundos (como vino del servidor).
  int get expiresInSeconds => _p.getInt(_kExpiresInSec) ?? 0;

  // =========================================================
  // LECTURA DE PERFIL (Sync — sin parsear JSON)
  // =========================================================

  /// Getters rápidos para datos que se muestran frecuentemente en la UI.
  String? get userUuid => _p.getString(_kUserUuid);
  String? get userNombre => _p.getString(_kUserNombre);
  String? get userCorreo => _p.getString(_kUserCorreo);
  String? get userPatente => _p.getString(_kUserPatente);
  String? get userLinea => _p.getString(_kUserLinea);

  /// Perfil completo como Map. Retorna null si no hay datos o si
  /// el JSON está corrupto (en vez de lanzar excepción).
  Map<String, dynamic>? get userProfile {
    final data = _p.getString(_kUserJson);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      // JSON corrupto — limpiamos para evitar errores repetidos
      _p.remove(_kUserJson);
      if (kDebugMode)
        debugPrint('⚠️ [ZUVIRO] userProfile JSON corrupto, limpiado');
      return null;
    }
  }

  // =========================================================
  // LÓGICA DE EXPIRACIÓN LOCAL (Refresh Proactivo)
  // =========================================================

  /// Momento exacto de expiración local (ya con margen de 60s).
  DateTime? get _expiresAt {
    final millis = _p.getInt(_kExpiresAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  /// True si el access token ya expiró localmente.
  bool get isAccessTokenExpired {
    final exp = _expiresAt;
    return exp == null || DateTime.now().isAfter(exp);
  }

  /// True si el access token sigue válido localmente.
  bool get isAccessTokenValid => !isAccessTokenExpired;

  /// Segundos restantes antes de expiración. 0 si ya expiró.
  int get secondsUntilExpiry {
    final exp = _expiresAt;
    if (exp == null) return 0;
    final diff = exp.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// True si quedan menos de 5 minutos pero aún no expiró.
  /// Útil para refresh oportunista antes de operaciones importantes
  /// (abrir mapa, iniciar búsqueda de línea, crear suscripción).
  bool get shouldRefreshSoon =>
      secondsUntilExpiry > 0 && secondsUntilExpiry < 300;

  // =========================================================
  // VERIFICACIÓN DE SESIÓN (Para Splash Screen)
  // =========================================================

  /// Determina el estado de la sesión para que el splash decida
  /// si ir al dashboard, intentar refresh, o ir al login.
  Future<SessionStatus> checkSession() async {
    if (!isLoggedIn) return SessionStatus.expired;

    final refresh = await getRefreshToken();
    if (refresh == null) return SessionStatus.expired;

    if (isAccessTokenValid) return SessionStatus.valid;

    // Access expirado pero hay refresh → el interceptor puede renovar
    return SessionStatus.needsRefresh;
  }

  // =========================================================
  // LIMPIEZA (Logout / 401 irrecuperable / Eliminar cuenta)
  // =========================================================

  /// Borra SOLO las keys de Zuviro, sin afectar datos de otros paquetes.
  Future<void> clearSession() async {
    // 1. Borrar tokens del secure storage (solo nuestras keys)
    await Future.wait([
      _secure.delete(key: _kAccess),
      _secure.delete(key: _kRefresh),
    ]);

    // 2. Borrar datos de sesión y perfil (solo nuestras keys)
    await Future.wait(
      _allPrefsKeys.map((key) => _p.remove(key)),
    );

    if (kDebugMode)
      debugPrint('🚀 [ZUVIRO] Sesión limpiada (solo keys Zuviro)');
  }
}
