/// Configuración centralizada de la API.
/// Cambia solo aquí la URL base cuando migres de entorno.
class ApiConfig {
  static const String baseUrl = 'https://web-production-ba98d.up.railway.app';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String registerPasajero = '$baseUrl/auth/register/pasajero';
  static const String registerConductor = '$baseUrl/auth/register/conductor';
  static const String logout = '$baseUrl/auth/logout';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String checkEmail = '$baseUrl/auth/check-email';
  static const String sessions = '$baseUrl/auth/sessions';

  // Recuperación
  static const String recuperarSolicitar =
      '$baseUrl/auth/recuperar-contrasena/solicitar';
  static const String recuperarConfirmar =
      '$baseUrl/auth/recuperar-contrasena/confirmar';

  // Usuario
  static const String usuarioMe = '$baseUrl/usuarios/me';
  static const String perfilPasajero = '$baseUrl/usuarios/me/perfil/pasajero';
  static const String perfilConductor = '$baseUrl/usuarios/me/perfil/conductor';
  static const String cambiarContrasena = '$baseUrl/usuarios/me/contrasena';
  static const String eliminarCuenta = '$baseUrl/usuarios/me';

  // Suscripciones
  static const String suscripcionCrear = '$baseUrl/suscripciones/crear';
  static const String suscripcionRenovar = '$baseUrl/suscripciones/renovar';
  static const String suscripcionEstado = '$baseUrl/suscripciones/estado';
  static const String suscripcionHistorial = '$baseUrl/suscripciones/historial';

  // Geolocalización
  static const String geoActualizar = '$baseUrl/geo/actualizar-ubicacion';
  static const String geoConductoresCercanos =
      '$baseUrl/geo/conductores-cercanos';
  static const String geoPasajerosCercanos = '$baseUrl/geo/pasajeros-cercanos';
  static const String geoBuscarLinea = '$baseUrl/geo/buscar-linea';
  static const String geoDejarBuscar = '$baseUrl/geo/dejar-de-buscar';
  static const String geoMiEstado = '$baseUrl/geo/mi-estado';
  static const String geoEstadoVehiculo = '$baseUrl/geo/estado-vehiculo';
  static const String geoEstadoTrabajo = '$baseUrl/geo/estado-trabajo';

  // Configuración
  static const String configCiudades = '$baseUrl/config/ciudades';
  static const String configLineas = '$baseUrl/config/lineas';
}
