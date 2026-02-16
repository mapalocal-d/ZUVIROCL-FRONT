import 'package:flutter/material.dart';

const String legalTexto = '''
Zuvirocl_App · Declaración Legal y Derechos del Usuario (Chile)

La utilización de esta aplicación está protegida por las leyes chilenas, incluyendo la Ley N° 19.628 sobre Protección de la Vida Privada, la Ley del Consumidor (N° 19.496) y el Código Civil.

Como usuario tienes derecho a:
- Conocer qué datos personales se recopilan, por qué y cómo se usan.
- Solicitar el acceso, corrección o eliminación de tus datos personales en cualquier momento.
- Hacer consultas o reclamos respecto al funcionamiento o cobros del servicio.

Como empresa, ZUVIROapps está obligada a:
- Usar y proteger tus datos sólo para fines necesarios y según la legislación chilena.
- Informarte claramente sobre condiciones de uso, limitaciones de responsabilidad y políticas de reembolso.
- Atender tus consultas o solicitudes en un plazo razonable y de buena fe.

El uso de Zuvirocl_App implica la aceptación de los siguientes Términos y Condiciones y Política de Privacidad, los que cumplen la normativa chilena y buenas prácticas internacionales.
Si tienes preguntas, contáctanos en zuvirocl@gmail.com.
Lee siempre estos documentos completos antes de usar el servicio.

---

# TÉRMINOS Y CONDICIONES DE USO

Fecha de entrada en vigor: 16 de febrero de 2026

## 1. DESCRIPCIÓN DEL SERVICIO
Zuvirocl_App es una plataforma de intermediación que conecta a pasajeros con conductores. No somos una empresa de transporte ni asumimos responsabilidad por los servicios que terceros (conductores/usuarios) presten.

## 2. EDAD MÍNIMA Y REGISTRO
- Para usar esta app debe tener al menos 14 años.
- Menores de 18 años solo pueden usar la app con autorización de sus padres, madres o tutores legales.
- El registro requiere entregar información verídica y actualizada.
- El usuario es responsable de la confidencialidad de sus credenciales.

## 3. CONDUCTA Y USO PERMITIDO
El usuario se compromete a:
- Usar la app solo para fines lícitos, personales y de buena fe.
- No acosar, discriminar, suplantar o engañar a otros usuarios.
- No cargar contenido ilegal, ofensivo, violento o que infrinja derechos de terceros.
- No manipular, intentar vulnerar o alterar el funcionamiento del servicio.

## 4. PROTECCIÓN DE DATOS Y PRIVACIDAD
- Se recopilan: nombre, apellido, correo; ubicación (solo si se da permiso); historial de uso y suscripciones.
- No se recopilan datos sensibles ni de menores de 14 años.
- Datos solo se utilizan para operar y mejorar el servicio, procesar pagos y gestionar suscripciones si corresponde.
- No se comparten datos con terceros salvo proveedores tecnológicos para la operación (hosting, mapas, pagos) y nunca se venden.
- Derechos del usuario: acceso, rectificación y eliminación de datos; detallado en la Política de Privacidad.
- Consultas a zuvirocl@gmail.com.

## 5. PROPIEDAD INTELECTUAL Y CONTENIDO
Todo el contenido, marcas y logos de la app son propiedad de ZUVIROapps.
La empresa puede moderar o eliminar cualquier contenido que infrinja estos términos.

## 6. LIMITACIÓN DE RESPONSABILIDAD
ZUVIROapps actúa solo como intermediario tecnológico.
No responde por accidentes, daños, pérdidas o conflictos entre usuarios, ni por información incorrecta que terceros provean a través del servicio.
El uso de la app implica aceptar estos riesgos.

## 7. PAGOS, REEMBOLSOS Y BAJA DE CUENTA

Ciertas funciones pueden requerir pagos o suscripciones.

Política de reembolsos:
- El usuario puede solicitar el reembolso de pagos o suscripciones dentro de 5 días hábiles siguientes a la compra, siempre que no haya usado el servicio ni disfrutado de los beneficios asociados.
- Para pedir reembolso, debe escribir a zuvirocl@gmail.com indicando motivo y datos del pago.
- Si el servicio ya fue usado total o parcialmente, no habrá devolución parcial ni total.
- El resultado del reembolso será comunicado en un plazo máximo de 10 días hábiles desde la solicitud.
- ZUVIROapps puede rechazar solicitudes de reembolso que no cumplan estas condiciones.

Baja y eliminación de cuenta:
El usuario puede solicitar la baja y eliminación definitiva de su cuenta y datos escribiendo a zuvirocl@gmail.com.

## 8. CAMBIOS EN LOS TÉRMINOS
ZUVIROapps puede modificar estos Términos y la Política de Privacidad en cualquier momento. Los cambios se informarán en la app. Usar el servicio después de una actualización implica aceptación de los nuevos términos.

## 9. JURISDICCIÓN Y CONTACTO
El uso de este servicio se rige por las leyes chilenas.
Consultas y reclamos: zuvirocl@gmail.com.

---

# POLÍTICA DE PRIVACIDAD

Fecha de entrada en vigor: 16 de febrero de 2026

## 1. DATOS QUE RECOPILAMOS
- Nombre, apellido, correo electrónico (al registrarse).
- Ubicación (solo si el usuario da permiso explícito).
- Historial de uso y suscripción.

No se recopilan datos sensibles ni de menores de 14 años.

## 2. USO DE LA INFORMACIÓN
Se utilizan estos datos para:
- Crear, gestionar y autenticar la cuenta.
- Prestar funciones de ubicación y conexión entre pasajeros/conductores.
- Mejorar la app y mantener la seguridad.
- Procesar pagos, suscripciones y cumplir obligaciones legales.

## 3. COMPARTICIÓN Y CONSERVACIÓN DE DATOS
- No se vende ni comparte la información personal (salvo proveedores tecnológicos para operar la app).
- Los datos se conservan solo el tiempo estrictamente necesario para prestar el servicio o cumplir la ley.

## 4. DERECHOS DEL USUARIO
Todo usuario puede:
- Acceder, corregir o eliminar sus datos enviando un email a zuvirocl@gmail.com.
- Solicitar la baja/eliminación total de su cuenta y datos personales.

## 5. SEGURIDAD
Se aplican medidas razonables para proteger la información, sin garantía absoluta.
El usuario asume los riesgos inherentes al uso de servicios en línea.

## 6. USO SOLO PARA MAYORES DE 14 AÑOS
No se permite el uso de la app por menores de 14 años.
Si descubrimos que un menor de 14 está registrado, su cuenta será eliminada.
Usuarios entre 14 y 18 años deben contar con autorización de sus padres, madres o tutores legales.

## 7. CAMBIOS Y CONTACTO
Toda modificación a esta política será informada en la app.
Consultas, pedidos de baja o reclamos: zuvirocl@gmail.com

Última actualización: 16 de febrero de 2026
''';

class PoliticaLegalScreen extends StatelessWidget {
  const PoliticaLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
        title: const Text(
          'Política Legal',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Atrás',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(17.0),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Text(
              legalTexto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
