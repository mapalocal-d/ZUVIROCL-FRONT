class AppValidators {
  // =========================================================
  // LISTAS NEGRAS (Espejo exacto del backend V6.0)
  // =========================================================

  static const Set<String> _dominiosProhibidos = {
    "tempmail.com",
    "10minutemail.com",
    "guerrillamail.com",
    "throwawaymail.com",
    "mailinator.com",
    "yopmail.com",
    "sharklasers.com",
    "getairmail.com",
    "dispostable.com",
  };

  static const Set<String> _nombresReservados = {
    "admin",
    "administrador",
    "soporte",
    "root",
    "moderador",
    "zuviro",
    "sistema",
    "test",
    "null",
    "undefined",
    "api",
    "webhook",
    "notification",
    "user",
    "usuario",
    "guest",
    "invitado",
    "support",
    "help",
    "info",
    "contact",
    "noreply",
    "no-reply",
    "postmaster",
    "hostmaster",
    "webmaster",
    "abuse",
  };

  static const Set<String> _contrasenasComunes = {
    "password",
    "123456",
    "12345678",
    "qwerty",
    "abc123",
    "zuviro123",
    "password123",
    "admin123",
    "letmein",
    "welcome",
    "monkey",
    "1234567890",
    "football",
    "iloveyou",
  };

  static const List<String> _secuenciasTeclado = [
    "qwerty",
    "asdfgh",
    "zxcvbn",
    "123456",
    "654321",
  ];

  static const Set<String> _regionesChile = {
    "arica y parinacota",
    "tarapacá",
    "antofagasta",
    "atacama",
    "coquimbo",
    "valparaíso",
    "metropolitana",
    "metropolitana de santiago",
    "ohiggins",
    "libertador general bernardo o'higgins",
    "maule",
    "ñuble",
    "biobío",
    "araucanía",
    "los ríos",
    "los lagos",
    "aysén",
    "aysén del general carlos ibáñez del campo",
    "magallanes",
    "magallanes y de la antártica chilena",
  };

  static const List<String> _sufijosDobles = [
    ".com.com",
    ".cl.cl",
    ".es.es",
    ".net.net",
  ];

  // =========================================================
  // VALIDACIÓN DE EMAIL
  // (Espejo de Validadores.email en schemas.py)
  // =========================================================

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';

    final email = value.toLowerCase().trim();

    if (email.length > 254) return 'Email demasiado largo (máx 254 caracteres)';

    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(email)) return 'Formato de email inválido';

    final partes = email.split('@');
    final local = partes[0];
    final dominio = partes[1];

    // Largo máximo de la parte local
    if (local.length > 64) return 'Parte local del email demasiado larga';

    // Dominio prohibido (temporales)
    if (_dominiosProhibidos.contains(dominio)) {
      return 'Correos temporales no permitidos';
    }

    // Dominio duplicado
    if (_sufijosDobles.any((sufijo) => dominio.endsWith(sufijo))) {
      return 'Dominio duplicado detectado';
    }

    // Puntos mal ubicados
    if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
      return 'Puntos mal ubicados en el email';
    }

    // Guiones al inicio/final
    if (local.startsWith('-') || local.endsWith('-')) {
      return 'Guiones no permitidos al inicio/final del usuario';
    }

    // Caracteres permitidos en la parte local
    if (!RegExp(r'^[a-z0-9._%+\-]+$').hasMatch(local)) {
      return 'Caracteres no permitidos en el email';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE CONTRASEÑA
  // (Espejo de Validadores.contrasena — NIST SP 800-63B)
  // =========================================================

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (value.length > 128) return 'Máximo 128 caracteres';

    // Sin espacios al inicio o final
    if (value != value.trim()) {
      return 'Sin espacios al inicio o final';
    }

    // Contraseñas comunes
    if (_contrasenasComunes.contains(value.toLowerCase())) {
      return 'Contraseña demasiado común. Elige una más única.';
    }

    // Secuencias de teclado predecibles
    final lower = value.toLowerCase();
    if (_secuenciasTeclado.any((s) => lower.contains(s))) {
      return 'La contraseña contiene secuencias predecibles';
    }

    // Regla NIST: al menos 3 de 4 tipos
    int cumple = 0;
    if (RegExp(r'[A-Z]').hasMatch(value)) cumple++;
    if (RegExp(r'[a-z]').hasMatch(value)) cumple++;
    if (RegExp(r'[0-9]').hasMatch(value)) cumple++;
    if (RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) cumple++;

    if (cumple < 3) {
      return 'Usa al menos 3 de: mayúsculas, minúsculas, números o símbolos';
    }

    return null;
  }

  // =========================================================
  // CONFIRMAR CONTRASEÑA
  // =========================================================

  static String? validateConfirmPassword(
      String? value, String originalPassword) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != originalPassword) return 'Las contraseñas no coinciden';
    return null;
  }

  // =========================================================
  // CAMBIO DE CONTRASEÑA (Validación extra para el form)
  // (Espejo de CambioContrasena en schemas.py)
  // =========================================================

  static String? validateNewPassword(String? value, String currentPassword) {
    // Primero aplicar las reglas estándar
    final baseError = validatePassword(value);
    if (baseError != null) return baseError;

    // La nueva contraseña debe ser diferente a la actual
    if (value == currentPassword) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE NOMBRE PROPIO
  // (Espejo de Validadores.nombre_propio en schemas.py)
  // =========================================================

  static String? validateNombrePropio(String? value, String campo) {
    if (value == null || value.trim().length < 2) {
      return 'El $campo debe tener al menos 2 caracteres';
    }

    final limpio = value.trim().toLowerCase();

    if (_nombresReservados.contains(limpio)) {
      return 'El $campo "$value" está reservado por el sistema';
    }

    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]+$").hasMatch(value.trim())) {
      return 'Solo letras, espacios, apóstrofes y guiones';
    }

    if (value.trim().length > 50) {
      return 'El $campo es demasiado largo (máx 50 caracteres)';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE PATENTE CHILENA
  // (Espejo de Validadores.patente_chilena en schemas.py)
  // =========================================================

  static String? validatePatente(String? value) {
    if (value == null || value.isEmpty) return 'La patente es requerida';

    final limpia = value.replaceAll(RegExp(r'[\s.\-·]'), '').toUpperCase();

    if (limpia.length < 5 || limpia.length > 6) {
      return 'Longitud de patente inválida';
    }

    final moderna = RegExp(r'^[A-Z]{4}[0-9]{2}$'); // AABB12
    final antigua = RegExp(r'^[A-Z]{2}[0-9]{4}$'); // AA1234
    final moto = RegExp(r'^[A-Z]{3}[0-9]{2}$'); // AAA12

    if (limpia.length == 6 &&
        (moderna.hasMatch(limpia) || antigua.hasMatch(limpia))) {
      return null;
    }

    if (limpia.length == 5 && moto.hasMatch(limpia)) {
      return null;
    }

    return 'Formato inválido. Aceptados: ABCD12, AA1234 o AAA12';
  }

  // =========================================================
  // VALIDACIÓN DE REGIÓN
  // (Espejo de Validadores.region_chilena en schemas.py)
  // =========================================================

  static String? validateRegion(String? value) {
    if (value == null || value.trim().length < 3) {
      return 'La región es requerida';
    }

    final normalizada = value.trim().toLowerCase();

    // Match exacto o contenido parcial (mínimo 3 chars evita falsos positivos)
    final isValid = _regionesChile
        .any((region) => normalizada == region || region.contains(normalizada));

    if (!isValid)
      return 'Región no reconocida. Usa nombres oficiales de Chile.';
    return null;
  }

  // =========================================================
  // VALIDACIÓN DE CIUDAD
  // =========================================================

  static String? validateCiudad(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'La ciudad debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 40) {
      return 'Nombre de ciudad demasiado largo (máx 40 caracteres)';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE LÍNEA DE RECORRIDO
  // =========================================================

  static String? validateLineaRecorrido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La línea de recorrido es requerida';
    }

    if (value.trim().length > 10) {
      return 'Línea demasiado larga (máx 10 caracteres)';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE TELÉFONO CHILENO
  // (Espejo de Validadores.telefono_chileno en schemas.py)
  // =========================================================

  /// Versión requerida (para campos obligatorios)
  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    return _validarFormatoTelefono(value);
  }

  /// Versión opcional (para edición de perfil donde es Optional)
  static String? validateTelefonoOpcional(String? value) {
    if (value == null || value.isEmpty) return null;
    return _validarFormatoTelefono(value);
  }

  /// Lógica interna compartida de validación de teléfono
  static String? _validarFormatoTelefono(String value) {
    final soloNumeros = value.replaceAll(RegExp(r'\D'), '');

    // 9XXXXXXXX (9 dígitos empezando con 9)
    if (soloNumeros.length == 9 && soloNumeros.startsWith('9')) return null;

    // 569XXXXXXXX (11 dígitos empezando con 569)
    if (soloNumeros.length == 11 && soloNumeros.startsWith('569')) return null;

    return 'Formato inválido. Usa: 9 1234 5678 o +569 1234 5678';
  }

  // =========================================================
  // VALIDACIÓN DE TÉRMINOS Y CONDICIONES
  // =========================================================

  static String? validateTerminos(bool? value) {
    if (value != true) return 'Debes aceptar los términos y condiciones';
    return null;
  }

  // =========================================================
  // VALIDACIÓN DE COORDENADAS GPS
  // (Espejo de CoordenadasGPS en schemas.py)
  // =========================================================

  static String? validateLatitud(double? value) {
    if (value == null) return 'Latitud requerida';
    if (value < -90 || value > 90) return 'Latitud fuera de rango (-90 a 90)';
    return null;
  }

  static String? validateLongitud(double? value) {
    if (value == null) return 'Longitud requerida';
    if (value < -180 || value > 180)
      return 'Longitud fuera de rango (-180 a 180)';
    return null;
  }

  static String? validateCoordenadas(double? lat, double? lng) {
    final latError = validateLatitud(lat);
    if (latError != null) return latError;

    final lngError = validateLongitud(lng);
    if (lngError != null) return lngError;

    if (lat == 0.0 && lng == 0.0) {
      return 'Coordenadas (0, 0) no válidas. Verifica que el GPS esté activo.';
    }

    return null;
  }
}
