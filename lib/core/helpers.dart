import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  // =========================================================
  // SANITIZACIÓN DE DATOS (Espejo del backend Python)
  // =========================================================

  /// Limpia espacios dobles, recorta los extremos y capitaliza.
  /// Maneja correctamente apóstrofes y guiones como el backend.
  /// (Ej: "  juan   o'brien " -> "Juan O'Brien")
  /// (Ej: "maría josé" -> "María José")
  /// (Ej: "ana-maría" -> "Ana-María")
  static String sanitizarNombrePropio(String texto) {
    if (texto.trim().isEmpty) return '';
    final limpio = texto.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    // Capitaliza después de espacios, apóstrofes y guiones
    return limpio.replaceAllMapped(
      RegExp(r"(^|[\s'\-])([a-záéíóúñü])"),
      (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}',
    );
  }

  /// Normaliza la patente para que el backend la acepte siempre.
  /// (Ej: " aa - 12 . 34 " -> "AA1234")
  static String normalizarPatente(String patente) {
    if (patente.isEmpty) return '';
    return patente.replaceAll(RegExp(r'[\s.\-·]'), '').toUpperCase();
  }

  /// Transforma cualquier input telefónico al formato internacional +569XXXXXXXX.
  /// Retorna vacío si el input no se puede normalizar a un formato válido.
  static String normalizarTelefonoChileno(String telefono) {
    if (telefono.isEmpty) return '';
    final limpio = telefono.replaceAll(RegExp(r'\D'), '');

    // +569XXXXXXXX ya correcto (viene sin + por el replaceAll)
    if (limpio.startsWith('569') && limpio.length == 11) {
      return '+$limpio';
    }

    // 9XXXXXXXX → agregar prefijo
    if (limpio.startsWith('9') && limpio.length == 9) {
      return '+56$limpio';
    }

    // 09XXXXXXXX → quitar el 0 y agregar prefijo
    if (limpio.startsWith('09') && limpio.length == 10) {
      return '+56${limpio.substring(1)}';
    }

    // No se pudo normalizar — retornamos vacío para que el validador lo atrape
    return '';
  }

  /// Limpieza general para campos de texto (ciudad, dispositivo, etc.)
  static String sanitizarString(String valor, {int maxLength = 255}) {
    if (valor.isEmpty) return '';
    final limpio = valor.trim().replaceAll(RegExp(r'\s+'), ' ');
    return limpio.length > maxLength ? limpio.substring(0, maxLength) : limpio;
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
    return DateFormat("dd 'de' MMM, yyyy", 'es_CL').format(fecha);
  }

  /// Formato de fecha y hora (Ej: "23 Feb 2026, 14:30")
  /// Para sesiones activas, historial de pagos, último login.
  static String formatoFechaHora(DateTime fecha) {
    return DateFormat('dd MMM yyyy, HH:mm', 'es_CL').format(fecha);
  }

  /// Solo hora (Ej: "14:30")
  /// Para timestamps en listas o logs.
  static String formatoHora(DateTime fecha) {
    return DateFormat('HH:mm', 'es_CL').format(fecha);
  }

  /// Formatea la distancia para el mapa
  /// (Ej: 0.5 -> "500 m", 1.2 -> "1.2 km")
  static String formatoDistancia(double kilometros) {
    if (kilometros < 1) {
      return '${(kilometros * 1000).toInt()} m';
    }
    return '${kilometros.toStringAsFixed(1)} km';
  }

  /// Convierte segundos en tiempo legible relativo.
  /// Vital para la frescura de datos GPS del backend.
  /// (Ej: 5 -> "ahora", 45 -> "hace 45 seg", 120 -> "hace 2 min")
  static String formatoTiempoRelativo(int? segundos) {
    if (segundos == null || segundos < 10) return 'ahora';
    if (segundos < 60) return 'hace $segundos seg';
    final minutos = segundos ~/ 60;
    if (minutos < 60) return 'hace $minutos min';
    final horas = minutos ~/ 60;
    if (horas < 24) return 'hace $horas h';
    return 'hace +1 día';
  }

  /// Formato de días restantes para suscripción.
  /// (Ej: 0 -> "Expirada", 1 -> "1 día", 15 -> "15 días")
  static String formatoDiasRestantes(int dias) {
    if (dias <= 0) return 'Expirada';
    if (dias == 1) return '1 día';
    return '$dias días';
  }

  /// Formato de tiempo estimado de llegada para conductores cercanos.
  /// (Ej: 1 -> "1 min", 5 -> "5 min", 65 -> "+1 hora")
  static String formatoTiempoLlegada(int? minutos) {
    if (minutos == null || minutos <= 0) return 'Llegando';
    if (minutos < 60) return '$minutos min';
    return '+1 hora';
  }

  // =========================================================
  // UTILIDADES DE SISTEMA
  // =========================================================

  /// Logger profesional. Solo imprime en modo debug.
  /// Usa debugPrint para evitar problemas de rendimiento en producción
  /// y truncamiento en dispositivos con buffer limitado.
  static void logger(String mensaje, {bool error = false}) {
    if (!kDebugMode) return;
    final hora = DateFormat('HH:mm:ss').format(DateTime.now());
    final prefix = error ? '❌ [ZUVIRO ERR | $hora]' : '🚀 [ZUVIRO LOG | $hora]';
    debugPrint('$prefix $mensaje');
  }
}
