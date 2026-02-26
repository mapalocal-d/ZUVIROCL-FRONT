class ApiConstants {
  static const String baseUrl = 'https://web-production-ba98d.up.railway.app';

  // --- AUTH ---
  static const String login = '/auth/login'; // POST
  static const String refresh = '/auth/refresh'; // POST
  static const String registerPasajero = '/auth/register/pasajero'; // POST
  static const String registerConductor = '/auth/register/conductor'; // POST
  static const String logout = '/auth/logout'; // POST
  static const String checkEmail = '/auth/check-email'; // GET
  static const String sessions = '/auth/sessions'; // GET

  // --- RECUPERACIÓN ---
  // IMPORTANTE: Requieren ?rol=pasajero o ?rol=conductor
  static const String recuperarSolicitar =
      '/auth/recuperar-contrasena/solicitar'; // POST
  static const String recuperarConfirmar =
      '/auth/recuperar-contrasena/confirmar'; // POST

  // --- SUSCRIPCIONES ---
  static const String suscripcionCrear = '/suscripciones/crear'; // POST
  static const String suscripcionRenovar = '/suscripciones/renovar'; // POST
  static const String suscripcionEstado = '/suscripciones/estado'; // GET
  static const String suscripcionHistorial = '/suscripciones/historial'; // GET

  // --- GEOLOCALIZACIÓN (PASAJERO & CONDUCTOR) ---
  static const String geoActualizar = '/geo/actualizar-ubicacion'; // PATCH
  static const String geoConductoresCercanos =
      '/geo/conductores-cercanos'; // GET
  static const String geoPasajerosCercanos = '/geo/pasajeros-cercanos'; // GET
  static const String geoBuscarLinea = '/geo/buscar-linea'; // PATCH
  static const String geoDejarBuscar = '/geo/dejar-de-buscar'; // PATCH
  static const String geoMiEstadoPasajero = '/geo/mi-estado'; // GET
  static const String geoEstadoVehiculo = '/geo/estado-vehiculo'; // GET y PATCH
  static const String geoEstadoTrabajo = '/geo/estado-trabajo'; // PATCH

  // --- USUARIO ---
  static const String usuarioMe = '/usuarios/me'; // GET y DELETE
  static const String perfilPasajero = '/usuarios/me/perfil/pasajero'; // PATCH
  static const String perfilConductor =
      '/usuarios/me/perfil/conductor'; // PATCH
  static const String cambiarContrasena = '/usuarios/me/contrasena'; // PUT

  // --- CONFIGURACIÓN & SISTEMA ---
  static const String ciudades = '/config/ciudades'; // GET
  static const String lineas = '/config/lineas'; // GET
  static const String health = '/health'; // GET

  // =========================================================
  // CONFIGURACIÓN DE RED (Timeouts)
  // =========================================================

  /// Tiempo máximo esperando conectar con el servidor (15 segundos)
  static const int connectionTimeout = 15000;

  /// Tiempo máximo enviando datos al servidor (15 segundos)
  static const int sendTimeout = 15000;

  /// Tiempo máximo esperando recibir la respuesta del servidor (15 segundos)
  static const int receiveTimeout = 15000;
}
