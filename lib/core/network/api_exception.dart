import 'package:dio/dio.dart';

/// TRADUCTOR DEFINITIVO: Sincronizado con los Exception Handlers de Zuviro Backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  ApiException({required this.message, this.statusCode, this.requestId});

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: "Servidor fuera de alcance. Revisa tu conexión.",
        );
      case DioExceptionType.connectionError:
        return ApiException(message: "No tienes acceso a internet.");
      case DioExceptionType.badResponse:
        return _handleStatusCode(
          dioError.response?.statusCode,
          dioError.response?.data,
        );
      default:
        return ApiException(message: "Error de red inesperado.");
    }
  }

  static ApiException _handleStatusCode(int? statusCode, dynamic data) {
    String serverMessage = "";
    String? reqId;

    // 🕵️ LÓGICA DE EXTRACCIÓN SEGÚN TU OBJETO "error" EN PYTHON
    if (data is Map && data.containsKey('error')) {
      final errorObj = data['error'];
      if (errorObj is Map) {
        serverMessage = errorObj['message']?.toString() ?? "";
        reqId = errorObj['request_id']?.toString();
      }
    }
    // Fallback para errores de validación automáticos de FastAPI/Pydantic (422)
    else if (data is Map && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) {
        serverMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        serverMessage = detail[0]['msg'] ?? "Datos inválidos.";
      }
    }

    switch (statusCode) {
      case 400: // Negocio: "Línea no disponible", "Ya tienes suscripción", etc.
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : "Solicitud incorrecta.",
          statusCode: 400,
          requestId: reqId,
        );
      case 401: // Seguridad: "Credenciales incorrectas", "Firma inválida"
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : "Sesión no válida.",
          statusCode: 401,
          requestId: reqId,
        );
      case 403: // Permisos: "Solo conductores", "Suscripción requerida"
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : "Acceso denegado.",
          statusCode: 403,
          requestId: reqId,
        );
      case 404: // Recursos: "Usuario no encontrado", "Registro no encontrado"
        return ApiException(
          message: serverMessage.isNotEmpty ? serverMessage : "No encontrado.",
          statusCode: 404,
          requestId: reqId,
        );
      case 409: // Conflictos: "Correo ya registrado", "Patente duplicada"
        return ApiException(
          message: serverMessage,
          statusCode: 409,
          requestId: reqId,
        );
      case 429: // Rate Limit: "Cuenta bloqueada temporalmente"
        return ApiException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : "Demasiadas peticiones.",
          statusCode: 429,
          requestId: reqId,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: "El servidor tiene problemas técnicos (Ref: $reqId)",
          statusCode: statusCode,
          requestId: reqId,
        );
      default:
        return ApiException(
          message: "Error desconocido ($statusCode).",
          statusCode: statusCode,
          requestId: reqId,
        );
    }
  }

  @override
  String toString() => message;
}
