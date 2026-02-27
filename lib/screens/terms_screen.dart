import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _termsText = """
TÉRMINOS Y CONDICIONES DE USO

Fecha de entrada en vigor: 16 de febrero de 2026

1. DESCRIPCIÓN DEL SERVICIO
Zuvirocl_App es una plataforma de intermediación que conecta a pasajeros con conductores. No somos una empresa de transporte ni asumimos responsabilidad por los servicios que terceros (conductores/usuarios) presten.

2. EDAD MÍNIMA Y REGISTRO
- Para usar esta app debe tener al menos 14 años.
- Menores de 18 años solo pueden usar la app con autorización de sus padres, madres o tutores legales.
- El registro requiere entregar información verídica y actualizada.
- El usuario es responsable de la confidencialidad de sus credenciales.

3. CONDUCTA Y USO PERMITIDO
El usuario se compromete a:
- Usar la app solo para fines lícitos, personales y de buena fe.
- No acosar, discriminar, suplantar o engañar a otros usuarios.
- No cargar contenido ilegal, ofensivo, violento o que infrinja derechos de terceros.
- No manipular, intentar vulnerar o alterar el funcionamiento del servicio.

4. PROPIEDAD INTELECTUAL Y CONTENIDO
Todo el contenido, marcas y logos de la app son propiedad de ZUVIROapps. La empresa puede moderar o eliminar cualquier contenido que infrinja estos términos.

5. LIMITACIÓN DE RESPONSABILIDAD
ZUVIROapps actúa solo como intermediario tecnológico. No responde por accidentes, daños, pérdidas o conflictos entre usuarios, ni por información incorrecta que terceros provean a través del servicio. El uso de la app implica aceptar estos riesgos.

6. PAGOS, REEMBOLSOS Y BAJA DE CUENTA
Ciertas funciones pueden requerir pagos o suscripciones.

Política de reembolsos:
- El usuario puede solicitar el reembolso de pagos o suscripciones dentro de 5 días hábiles siguientes a la compra, siempre que no haya usado el servicio ni disfrutado de los beneficios asociados.
- Para pedir reembolso, debe escribir a zuvirocl@gmail.com indicando motivo y datos del pago.
- Si el servicio ya fue usado total o parcialmente, no habrá devolución parcial ni total.
- El resultado del reembolso será comunicado en un plazo máximo de 10 días hábiles desde la solicitud.
- ZUVIROapps puede rechazar solicitudes de reembolso que no cumplan estas condiciones.

Baja y eliminación de cuenta:
El usuario puede solicitar la baja y eliminación definitiva de su cuenta y datos escribiendo a zuvirocl@gmail.com.

7. CAMBIOS EN LOS TÉRMINOS
ZUVIROapps puede modificar estos Términos en cualquier momento. Los cambios se informarán en la app. Usar el servicio después de una actualización implica aceptación de los nuevos términos.

8. JURISDICCIÓN Y CONTACTO
El uso de este servicio se rige por las leyes chilenas. Consultas y reclamos: zuvirocl@gmail.com.
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
          'Términos y Condiciones',
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
            _termsText,
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
