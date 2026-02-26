import 'package:flutter/foundation.dart';

/// Roles de Usuario en el sistema (Sincronizado con backend)
enum UserRole {
  pasajero('pasajero'),
  conductor('conductor');

  final String value;
  const UserRole(this.value);

  String toJson() => value;
  static UserRole fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint(
                '⚠️ [ZUVIRO] UserRole desconocido: "$json", usando pasajero');
          return UserRole.pasajero;
        },
      );
}

/// Estados de Suscripción (Sincronizado con EstadoSuscripcionEnum en schemas.py)
enum SubscriptionStatus {
  pendiente('pendiente', 'Pendiente'),
  activa('activa', 'Activa'),
  cancelada('cancelada', 'Cancelada'),
  expirada('expirada', 'Expirada');

  final String value;
  final String label;
  const SubscriptionStatus(this.value, this.label);

  String toJson() => value;
  static SubscriptionStatus fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] SubscriptionStatus desconocido: "$json"');
          return SubscriptionStatus.pendiente;
        },
      );
}

/// Único plan permitido (Sincronizado con TipoPlanEnum en schemas.py)
enum PlanType {
  mensual('mensual', 'Mensual');

  final String value;
  final String label;
  const PlanType(this.value, this.label);

  String toJson() => value;
  static PlanType fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] PlanType desconocido: "$json"');
          return PlanType.mensual;
        },
      );
}

/// Estados de Pago (Sincronizado con EstadoPagoEnum en schemas.py)
enum PaymentStatus {
  aprobado('aprobado', 'Aprobado'),
  pendiente('pendiente', 'Pendiente'),
  rechazado('rechazado', 'Rechazado');

  final String value;
  final String label;
  const PaymentStatus(this.value, this.label);

  String toJson() => value;
  static PaymentStatus fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] PaymentStatus desconocido: "$json"');
          return PaymentStatus.pendiente;
        },
      );
}

/// Estados de Trabajo del Conductor (Sincronizado con EstadoTrabajoConductorEnum)
enum WorkStatus {
  fueraDeRuta('fuera_de_ruta', 'Fuera de Ruta'),
  enRuta('en_ruta', 'En Ruta');

  final String value;
  final String label;
  const WorkStatus(this.value, this.label);

  String toJson() => value;
  static WorkStatus fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] WorkStatus desconocido: "$json"');
          return WorkStatus.fueraDeRuta;
        },
      );
}

/// Capacidad del Vehículo (Sincronizado con EstadoVehiculoEnum en schemas.py)
///
/// Backend V6.0 solo soporta: vacio, lleno.
/// NO agregar valores que el backend no reconozca o devolverá 422.
enum VehicleStatus {
  vacio('vacio', 'Vacío'),
  lleno('lleno', 'Lleno');

  final String value;
  final String label;
  const VehicleStatus(this.value, this.label);

  String toJson() => value;
  static VehicleStatus fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] VehicleStatus desconocido: "$json"');
          return VehicleStatus.vacio;
        },
      );
}

/// Estados del Pasajero (Sincronizado con EstadoPasajeroEnum en schemas.py)
enum PassengerStatus {
  sinActividad('sin_actividad', 'Sin Actividad'),
  buscandoConductor('buscando_conductor', 'Buscando Conductor'),
  esperandoConductor('esperando_conductor', 'Esperando Conductor');

  final String value;
  final String label;
  const PassengerStatus(this.value, this.label);

  String toJson() => value;
  static PassengerStatus fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] PassengerStatus desconocido: "$json"');
          return PassengerStatus.sinActividad;
        },
      );
}

/// Tipos de Dispositivo (Sincronizado con TipoDispositivoEnum en schemas.py)
enum DeviceType {
  android('android'),
  ios('ios'),
  web('web');

  final String value;
  const DeviceType(this.value);

  String toJson() => value;
  static DeviceType fromJson(String json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () {
          if (kDebugMode)
            debugPrint('⚠️ [ZUVIRO] DeviceType desconocido: "$json"');
          return DeviceType.android;
        },
      );
}
