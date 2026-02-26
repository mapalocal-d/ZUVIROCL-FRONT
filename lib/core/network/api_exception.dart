import 'package:dio/dio.dart';

/// Traductor de errores HTTP sincronizado con los Exception Handlers del backend.
///
/// Convierte errores de Dio y respuestas del servidor en mensajes
/// amigables para mostrar en la UI de la app.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  ApiException({required this.message, this.statusCode, this.requestId});

  /// Factory para sesión expirada (usado por ApiClient cuando el refresh falla).
  factory ApiException.sessionExpired() {
    return ApiException(
      message: 'Tu sesión ha expirado. Inicia sesión nuevamente.',
      statusCode: 401,
    );
  }

  /// Factory principal: convierte cualquier DioException en un ApiException legible.
  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Servidor fuera de alcance. Revisa tu conexión.',
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'El servidor tardó demasiado en responder.',
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Tiempo agotado enviando datos al servidor.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No tienes acceso a internet.',
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Petición cancelada.',
        );
      case DioExceptionType.badResponse:
        return _handleStatusCode(
          dioError.response?.statusCode,
          dioError.response?.data,
        );
      default:
        return ApiException(
          message: 'Error de red inesperado.',
        );
    }
  }

  /// Extrae el mensaje y request_id del cuerpo de respuesta del backend.
  ///
  /// El backend tiene dos formatos de error:
  /// 1. Errores de negocio: {"error": {"code": 400, "message": "...", "request_id": "..."}}
  /// 2. Errores de validación Pydantic (422): {"detail": [{"msg": "...", "type": "..."}]}
  static ApiException _handleStatusCode(int? statusCode, dynamic data) {
    String serverMessage = '';
    String? reqId;

    if (data is Map) {
      // Formato 1: Exception handlers personalizados del backend
      if (data.containsKey('error')) {
        final errorObj = data['error'];
        if (errorObj is Map) {
          serverMessage = errorObj['message']?.toString() ?? '';
          reqId = errorObj['request_id']?.toString();
        }
      }
      // Formato 2: Errores de validación automáticos de FastAPI/Pydantic (422)
      else if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          serverMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          // Unir todos los errores de validación, no solo el primero
          serverMessage = detail
              .map((e) => e['msg']?.toString() ?? '')
              .where((m) => m.isNotEmpty)
              .join('. ');
          if (serverMessage.isEmpty) serverMessage = 'Datos inválidos.';
        }
      }
      // Formato 3: Respuesta simple {"mensaje": "..."}
      else if (data.containsKey('mensaje')) {
        serverMessage = data['mensaje']?.toString() ?? '';
      }
    }

    switch (statusCode) {
      // 400 — Negocio: "Línea no disponible", "Ya tienes suscripción", etc.
      case 400:
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Solicitud incorrecta.',
          statusCode: 400,
          requestId: reqId,
        );

      // 401 — Seguridad: "Credenciales incorrectas", "Token expirado"
      case 401:
        return ApiException(
          message:
              serverMessage.isNotEmpty ? serverMessage : 'Sesión no válida.',
          statusCode: 401,
          requestId: reqId,
        );

      // 403 — Permisos: "Solo conductores", "Suscripción requerida"
      case 403:
        return ApiException(
          message:
              serverMessage.isNotEmpty ? serverMessage : 'Acceso denegado.',
          statusCode: 403,
          requestId: reqId,
        );

      // 404 — Recursos: "Usuario no encontrado", "Registro no encontrado"
      case 404:
        return ApiException(
          message: serverMessage.isNotEmpty ? serverMessage : 'No encontrado.',
          statusCode: 404,
          requestId: reqId,
        );

      // 409 — Conflictos: "Correo ya registrado", "Patente duplicada"
      case 409:
        return ApiException(
          message:
              serverMessage.isNotEmpty ? serverMessage : 'Datos duplicados.',
          statusCode: 409,
          requestId: reqId,
        );

      // 422 — Validación Pydantic: Datos que no pasan los schemas
      case 422:
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Datos inválidos. Revisa los campos del formulario.',
          statusCode: 422,
          requestId: reqId,
        );

      // 429 — Rate Limit: "Cuenta bloqueada temporalmente"
      case 429:
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Demasiadas peticiones. Espera un momento.',
          statusCode: 429,
          requestId: reqId,
        );

      // 5xx — Errores del servidor
      case 500:
      case 502:
      case 503:
        final ref = reqId != null ? ' (Ref: $reqId)' : '';
        return ApiException(
          message: 'El servidor tiene problemas técnicos$ref',
          statusCode: statusCode,
          requestId: reqId,
        );

      // Cualquier otro código
      default:
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Error desconocido ($statusCode).',
          statusCode: statusCode,
          requestId: reqId,
        );
    }
  }

  // =========================================================
  // HELPERS PARA LA UI
  // =========================================================

  /// True si el error es de autenticación (token expirado, credenciales inválidas).
  bool get isAuthError => statusCode == 401;

  /// True si el error es de permisos o suscripción.
  bool get isForbidden => statusCode == 403;

  /// True si el error es por rate limiting.
  bool get isRateLimited => statusCode == 429;

  /// True si el error es del servidor (no es culpa del usuario).
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// True si es un error de red (sin internet, timeout).
  bool get isNetworkError => statusCode == null;

  /// True si el error es un conflicto de datos (duplicado).
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
