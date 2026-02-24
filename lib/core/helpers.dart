import 'package:intl/intl.dart';

class AppHelpers {
  // =========================================================
  // SANITIZACIÓN DE DATOS (Espejo de tu backend Python)
  // =========================================================

  /// Limpia espacios dobles, recorta los extremos y capitaliza.
  /// (Ej: "  juan   perez " -> "Juan Perez")
  static String sanitizarNombrePropio(String texto) {
    if (texto.trim().isEmpty) return '';
    final limpio = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    return limpio
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Normaliza la patente para que el backend la acepte siempre.
  /// (Ej: " aa - 12 . 34 " -> "AA1234")
  static String normalizarPatente(String patente) {
    if (patente.isEmpty) return '';
    return patente.replaceAll(RegExp(r'[\s.\-·]'), '').toUpperCase();
  }

  /// Transforma cualquier input telefónico al formato internacional +569XXXXXXXX
  static String normalizarTelefonoChileno(String telefono) {
    if (telefono.isEmpty) return '';
    String limpio = telefono.replaceAll(RegExp(r'\D'), '');

    if (limpio.startsWith('569') && limpio.length == 11) {
      return '+$limpio';
    } else if (limpio.startsWith('9') && limpio.length == 9) {
      return '+56$limpio';
    }
    return limpio.startsWith('+') ? limpio : '+$limpio';
  }

  // =========================================================
  // FORMATEO VISUAL (UI de la App)
  // =========================================================

  /// Formato de pesos chilenos (Ej: 1500 -> "$ 1.500")
  static String formatoDineroCLP(int monto) {
    final formatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(monto);
  }

  /// Formato de fecha chilena (Ej: "23 de Feb, 2026")
  static String formatoFecha(DateTime fecha) {
    return DateFormat('dd \'de\' MMM, yyyy', 'es_CL').format(fecha);
  }

  /// Formatea la distancia para el mapa (Ej: 0.5 -> "500 m", 1.2 -> "1.2 km")
  static String formatoDistancia(double kilometros) {
    if (kilometros < 1) {
      return '${(kilometros * 1000).toInt()} m';
    }
    return '${kilometros.toStringAsFixed(1)} km';
  }

  /// Convierte segundos en tiempo legible (Ej: 120 -> "hace 2 min")
  /// Vital para la frescura de datos GPS del backend.
  static String formatoTiempoRelativo(int? segundos) {
    if (segundos == null || segundos < 10) return 'ahora';
    if (segundos < 60) return 'hace $segundos seg';
    final minutos = segundos ~/ 60;
    if (minutos < 60) return 'hace $minutos min';
    return 'hace +1 hora';
  }

  // =========================================================
  // UTILIDADES DE SISTEMA
  // =========================================================

  /// Logger profesional con marca de tiempo para depuración en consola
  static void logger(String mensaje, {bool error = false}) {
    final hora = DateFormat('HH:mm:ss').format(DateTime.now());
    if (error) {
      print('❌ [ZUVIRO ERR | $hora] $mensaje');
    } else {
      print('🚀 [ZUVIRO LOG | $hora] $mensaje');
    }
  }
}
