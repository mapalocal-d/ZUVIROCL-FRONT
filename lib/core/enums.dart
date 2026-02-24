import 'package:flutter/material.dart';

/// Roles de Usuario en el sistema (Sincronizado con backend)
enum UserRole {
  pasajero('pasajero'),
  conductor('conductor');

  final String value;
  const UserRole(this.value);

  String toJson() => value;
  static UserRole fromJson(String json) => values.firstWhere(
    (e) => e.value == json,
    orElse: () => UserRole.pasajero,
  );
}

/// Estados de Suscripción (Sincronizado con EstadoSuscripcion en Python)
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
    orElse: () => SubscriptionStatus.pendiente,
  );
}

/// Único plan permitido (Sincronizado con TipoPlan)
enum PlanType {
  mensual('mensual', 'Mensual');

  final String value;
  final String label;
  const PlanType(this.value, this.label);

  String toJson() => value;
  static PlanType fromJson(String json) =>
      values.firstWhere((e) => e.value == json, orElse: () => PlanType.mensual);
}

/// Estados de Pago (Sincronizado con EstadoPago)
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
    orElse: () => PaymentStatus.pendiente,
  );
}

/// Estados de Trabajo del Conductor (Sincronizado con EstadoTrabajoConductor)
enum WorkStatus {
  fueraDeRuta('fuera_de_ruta', 'Fuera de Ruta'),
  enRuta('en_ruta', 'En Ruta');

  final String value;
  final String label;
  const WorkStatus(this.value, this.label);

  String toJson() => value;
  static WorkStatus fromJson(String json) => values.firstWhere(
    (e) => e.value == json,
    orElse: () => WorkStatus.fueraDeRuta,
  );
}

/// Capacidad del Vehículo (Ajustado para permitir estado intermedio)
enum VehicleStatus {
  vacio('vacio', 'Vacío'),
  conEspacio(
    'con_espacio',
    'Con Espacio',
  ), // <--- Agregado para coincidir con lógica de negocio
  lleno('lleno', 'Lleno');

  final String value;
  final String label;
  const VehicleStatus(this.value, this.label);

  String toJson() => value;
  static VehicleStatus fromJson(String json) => values.firstWhere(
    (e) => e.value == json,
    orElse: () => VehicleStatus.vacio,
  );
}

/// Estados del Pasajero (Sincronizado con EstadoPasajero)
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
    orElse: () => PassengerStatus.sinActividad,
  );
}

/// Tipos de Dispositivo (Sincronizado con modelos de Sesión)
enum DeviceType {
  android('android'),
  ios('ios'),
  web('web');

  final String value;
  const DeviceType(this.value);

  String toJson() => value;
  static DeviceType fromJson(String json) => values.firstWhere(
    (e) => e.value == json,
    orElse: () => DeviceType.android,
  );
}
