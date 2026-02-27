import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String _privacyText = """
POLÍTICA DE PRIVACIDAD

Fecha de entrada en vigor: 16 de febrero de 2026

1. DATOS QUE RECOPILAMOS
- Nombre, apellido, correo electrónico (al registrarse).
- Ubicación (solo si el usuario da permiso explícito).
- Historial de uso y suscripción.

No se recopilan datos sensibles ni de menores de 14 años.

2. USO DE LA INFORMACIÓN
Se utilizan estos datos para:
- Crear, gestionar y autenticar la cuenta.
- Prestar funciones de ubicación y conexión entre pasajeros/conductores.
- Mejorar la app y mantener la seguridad.
- Procesar pagos, suscripciones y cumplir obligaciones legales.

3. COMPARTICIÓN Y CONSERVACIÓN DE DATOS
- No se vende ni comparte la información personal (salvo proveedores tecnológicos para operar la app).
- Los datos se conservan solo el tiempo estrictamente necesario para prestar el servicio o cumplir la ley.

4. DERECHOS DEL USUARIO
Todo usuario puede:
- Acceder, corregir o eliminar sus datos enviando un email a zuvirocl@gmail.com.
- Solicitar la baja/eliminación total de su cuenta y datos personales.

5. SEGURIDAD
Se aplican medidas razonables para proteger la información, sin garantía absoluta. El usuario asume los riesgos inherentes al uso de servicios en línea.

6. USO SOLO PARA MAYORES DE 14 AÑOS
No se permite el uso de la app por menores de 14 años. Si descubrimos que un menor de 14 está registrado, su cuenta será eliminada. Usuarios entre 14 y 18 años deben contar con autorización de sus padres, madres o tutores legales.

7. CAMBIOS Y CONTACTO
Toda modificación a esta política será informada en la app. Consultas, pedidos de baja o reclamos: zuvirocl@gmail.com
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _privacyText,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
