// core/validators.dart
// Versión 6.0 - Espejo exacto de Validadores en schemas.py

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

  // Mapeo de alias para regiones (espejo del backend)
  static const Map<String, String> _aliasRegiones = {
    "metropolitana": "Metropolitana de Santiago",
    "santiago": "Metropolitana de Santiago",
    "rm": "Metropolitana de Santiago",
    "ohiggins": "Libertador General Bernardo O'Higgins",
    "biobio": "Biobío",
    "biobío": "Biobío",
    "tarapaca": "Tarapacá",
    "araucania": "Araucanía",
    "aysen": "Aysén del General Carlos Ibáñez del Campo",
    "magallanes": "Magallanes y de la Antártica Chilena",
    "ñuble": "Ñuble",
    "valparaiso": "Valparaíso",
    "i": "Tarapacá",
    "ii": "Antofagasta",
    "iii": "Atacama",
    "iv": "Coquimbo",
    "v": "Valparaíso",
    "vi": "Libertador General Bernardo O'Higgins",
    "vii": "Maule",
    "viii": "Biobío",
    "ix": "Araucanía",
    "x": "Los Lagos",
    "xi": "Aysén del General Carlos Ibáñez del Campo",
    "xii": "Magallanes y de la Antártica Chilena",
    "xiv": "Los Ríos",
    "xv": "Arica y Parinacota",
    "xvi": "Ñuble",
  };

  // =========================================================
  // FUNCIÓN AUXILIAR: SANITIZACIÓN DE STRINGS
  // =========================================================

  static String _sanitizarString(String valor, {int maxLength = 255}) {
    // Eliminar etiquetas HTML (simulación básica)
    final sinHtml = valor.replaceAll(RegExp(r'<[^>]+>'), '');
    // Eliminar caracteres de control (mantener saltos de línea básicos)
    final limpio =
        sinHtml.replaceAll(RegExp(r'[^\x20-\x7E\n\r\táéíóúñüÁÉÍÓÚÑÜ]'), '');
    // Colapsar espacios múltiples
    final colapsado = limpio.replaceAll(RegExp(r'\s+'), ' ').trim();
    return colapsado.length > maxLength
        ? colapsado.substring(0, maxLength)
        : colapsado;
  }

  // =========================================================
  // VALIDACIÓN DE EMAIL
  // (Espejo exacto de Validadores.email)
  // =========================================================

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';

    final email = value.toLowerCase().trim();

    if (email.length > 254) return 'Email demasiado largo (máx 254 caracteres)';

    // Patrón básico de email (igual que backend)
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(email)) return 'Formato de email inválido';

    final partes = email.split('@');
    final local = partes[0];
    final dominio = partes[1];

    if (local.length > 64) return 'Parte local del email demasiado larga';

    if (_dominiosProhibidos.contains(dominio)) {
      return 'Correos temporales no permitidos';
    }

    if (_sufijosDobles.any((sufijo) => dominio.endsWith(sufijo))) {
      return 'Dominio duplicado detectado';
    }

    if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
      return 'Puntos mal ubicados en el email';
    }

    if (local.startsWith('-') || local.endsWith('-')) {
      return 'Guiones no permitidos al inicio/final del usuario';
    }

    if (!RegExp(r'^[a-z0-9._%+\-]+$').hasMatch(local)) {
      return 'Caracteres no permitidos en el email';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE CONTRASEÑA (NIST SP 800-63B)
  // =========================================================

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (value.length > 128) return 'Máximo 128 caracteres';

    if (value != value.trim()) {
      return 'Sin espacios al inicio o final';
    }

    if (_contrasenasComunes.contains(value.toLowerCase())) {
      return 'Contraseña demasiado común. Elige una más única.';
    }

    final lower = value.toLowerCase();
    if (_secuenciasTeclado.any((s) => lower.contains(s))) {
      return 'La contraseña contiene secuencias predecibles';
    }

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
  // CAMBIO DE CONTRASEÑA (Validación extra para formulario)
  // (Espejo de CambioContrasena en schemas.py)
  // =========================================================

  static String? validateNewPassword(String? value, String currentPassword) {
    final baseError = validatePassword(value);
    if (baseError != null) return baseError;

    if (value == currentPassword) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE NOMBRE PROPIO
  // (Espejo de Validadores.nombre_propio)
  // =========================================================

  static String? validateNombrePropio(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'El $campo es requerido';
    }

    // Sanitizar igual que backend
    final sanitizado = _sanitizarString(value, maxLength: 50);

    if (sanitizado.length < 2) {
      return 'El $campo debe tener al menos 2 caracteres válidos';
    }

    final normalizado = sanitizado.toLowerCase();

    if (_nombresReservados.contains(normalizado)) {
      return 'El $campo "$sanitizado" está reservado por el sistema';
    }

    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]+$").hasMatch(sanitizado)) {
      return 'Solo letras, espacios, apóstrofes y guiones';
    }

    // Devolver en formato Title Case (como backend)
    return null; // El controlador mostrará el valor original, pero la validación pasa
  }

  // =========================================================
  // VALIDACIÓN DE PATENTE CHILENA
  // (Espejo de Validadores.patente_chilena)
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
  // VALIDACIÓN DE REGIÓN CHILENA
  // (Espejo de Validadores.region_chilena con mapeo de alias)
  // =========================================================

  static String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La región es requerida';
    }

    final sanitizada = _sanitizarString(value, maxLength: 50);
    final normalizada = sanitizada.toLowerCase();

    // 1. Buscar en alias
    if (_aliasRegiones.containsKey(normalizada)) {
      return null; // válida
    }

    // 2. Buscar coincidencia exacta o parcial (misma lógica que backend)
    for (final region in _regionesChile) {
      if (normalizada == region ||
          region.contains(normalizada) ||
          normalizada.contains(region)) {
        return null; // válida
      }
    }

    return 'Región no reconocida. Usa nombres oficiales de Chile.';
  }

  // =========================================================
  // VALIDACIÓN DE CIUDAD
  // =========================================================

  static String? validateCiudad(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La ciudad es requerida';
    }

    final sanitizada = _sanitizarString(value, maxLength: 40);
    if (sanitizada.length < 2) {
      return 'La ciudad debe tener al menos 2 caracteres';
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

    final sanitizada = _sanitizarString(value, maxLength: 10).toUpperCase();
    if (sanitizada.isEmpty) {
      return 'La línea de recorrido no puede estar vacía';
    }

    return null;
  }

  // =========================================================
  // VALIDACIÓN DE TELÉFONO CHILENO (con normalización a +569)
  // =========================================================

  /// Versión requerida
  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    return _validarYNormalizarTelefono(value);
  }

  /// Versión opcional
  static String? validateTelefonoOpcional(String? value) {
    if (value == null || value.isEmpty) return null;
    return _validarYNormalizarTelefono(value);
  }

  static String? _validarYNormalizarTelefono(String value) {
    final soloNumeros = value.replaceAll(RegExp(r'\D'), '');

    String normalizado;
    if (soloNumeros.length == 9 && soloNumeros.startsWith('9')) {
      normalizado = '+56$soloNumeros';
    } else if (soloNumeros.length == 11 && soloNumeros.startsWith('569')) {
      normalizado = '+$soloNumeros';
    } else if (soloNumeros.length == 12 && soloNumeros.startsWith('569')) {
      // +56912345678 (12 caracteres porque incluye +)
      normalizado = '+${soloNumeros.substring(1)}';
    } else {
      return 'Formato inválido. Usa: 9 1234 5678, 56912345678 o +56912345678';
    }

    // Validar con expresión regular del backend
    if (!RegExp(r'^\+569\d{8}$').hasMatch(normalizado)) {
      return 'Formato inválido. Debe ser un número chileno válido';
    }

    return null; // Si se necesita el número normalizado, se puede obtener del controlador
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
  // (Espejo de CoordenadasGPS)
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
