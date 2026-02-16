import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'politica_legal.dart'; // Importa la pantalla de políticas legales

class AyudaSoporteScreen extends StatelessWidget {
  const AyudaSoporteScreen({Key? key}) : super(key: key);

  static const String correoSoporte = 'zuvirocl@gmail.com'; // ← CORREO REAL

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: correoSoporte,
      query: 'subject=Consulta%20de%20soporte%20ZUVIROapps',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 95,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.only(left: 5, right: 8),
            textStyle: const TextStyle(fontSize: 14),
          ),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          label: const Text("ATRÁS", style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              "ZUVIROapps",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1476FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
        title: null,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 5),
              const Text(
                "Centro de Ayuda y Soporte",
                style: TextStyle(
                  fontSize: 21,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              const Card(
                color: Colors.black87,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "¡Queremos que tu experiencia en ZUVIROapps sea siempre la mejor!\n\nCualquier duda, consulta o sugerencia será bienvenida. Nuestro equipo está disponible para ayudarte y escucharte.\n\n¡Gracias por ser parte de nuestra comunidad!",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "¿Necesitas ayuda personalizada?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1476FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Puedes escribirnos a nuestro correo electrónico:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _launchEmail,
                        child: Text(
                          correoSoporte,
                          style: const TextStyle(
                            color: Color(0xFF1476FF),
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Atención disponible de lunes a viernes, de 09:00 a 18:00 hrs.",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ), // espacio para que no tape el botón fijo
            ],
          ),
          // Botón fijo abajo a la izquierda para políticas legales
          Positioned(
            left: 10,
            bottom: 16,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Color(0xFF50C878),
                minimumSize: const Size(148, 42),
              ),
              icon: const Icon(
                Icons.policy,
                size: 21,
                color: Color(0xFF50C878),
              ),
              label: const Text(
                "Política legal",
                style: TextStyle(
                  color: Color(0xFF50C878),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PoliticaLegalScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
