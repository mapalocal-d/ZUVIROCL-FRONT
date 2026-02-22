import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'secure_storage.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'app_logger.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  String _mensaje = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final secure = SecureStorage();

    try {
      final hasSession = await secure.hasSession();

      if (!hasSession) {
        AppLogger.i('Sin sesión guardada. Redirigiendo a /home.');
        _irA('/home');
        return;
      }

      setState(() => _mensaje = 'Verificando sesión...');

      // Verificar que el token aún es válido llamando al backend
      try {
        final resp = await ApiClient().get(ApiConfig.usuarioMe);

        if (resp.statusCode == 200) {
          AppLogger.i('Sesión válida. Entrando al dashboard.');
          final rol = await secure.getRol();
          if (rol == 'conductor') {
            _irA('/dashboard_conductor');
          } else {
            _irA('/dashboard_pasajero');
          }
        } else {
          // El ApiClient ya intentó refresh. Si llegó aquí con error, sesión inválida.
          AppLogger.w('Token inválido. Redirigiendo a /home.');
          await secure.clearAll();
          _irA('/home');
        }
      } on SinConexionException {
        // Sin internet pero tiene sesión guardada → entrar igual con datos locales
        AppLogger.w('Sin internet. Entrando con datos locales.');
        final rol = await secure.getRol();
        if (rol == 'conductor') {
          _irA('/dashboard_conductor');
        } else {
          _irA('/dashboard_pasajero');
        }
      }
    } catch (e) {
      AppLogger.e('Error en inicio', e);
      await secure.clearAll();
      _irA('/home');
    }
  }

  void _irA(String ruta) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(ruta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ZUVIRO',
              style: GoogleFonts.dmSerifDisplay(
                color: const Color(0xFF007AFF),
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3CDFFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _mensaje,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
