import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'perfil_pasajero.dart'; // Ruta a tu archivo de Mi Cuenta
import 'logout_button.dart'; // Ruta correcta para tu logout
import 'pagar_suscripcion_pasajero.dart'; // Asegúrate que aquí está PagoSuscripcionScreen
import 'estado_suscripcion_pasajero.dart'; // Importa el widget del estado de suscripción
import 'historial_pago_pasajero.dart'; // agrega tu screen de historial de pagos aquí
import 'ayuda_soporte.dart'; // agrega tu screen de ayuda y soporte aquí
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardPasajero extends StatefulWidget {
  const DashboardPasajero({Key? key}) : super(key: key);

  @override
  State<DashboardPasajero> createState() => _DashboardPasajeroState();
}

class _DashboardPasajeroState extends State<DashboardPasajero> {
  late Future<Map<String, String>> _datosUsuarioFuture;

  @override
  void initState() {
    super.initState();
    _datosUsuarioFuture = _getNombreEmail();
  }

  Future<Map<String, String>> _getNombreEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String nombre = prefs.getString('nombre') ?? '';
    String apellido = prefs.getString('apellido') ?? '';
    String email = prefs.getString('email') ?? '';

    // Si falta alguno, consulta el endpoint y guarda los nuevos valores
    if (nombre.isEmpty || email.isEmpty) {
      final token = prefs.getString('access_token');
      if (token != null) {
        final url = Uri.parse(
          'https://graceful-balance-production-ef1d.up.railway.app/users/me',
        );
        final resp = await http.get(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "accept": "application/json",
          },
        );
        if (resp.statusCode == 200) {
          final user = jsonDecode(resp.body);
          nombre = (user['nombre'] ?? '').toString();
          apellido = (user['apellido'] ?? '').toString();
          email = (user['email'] ?? '').toString();
          await prefs.setString('nombre', nombre);
          await prefs.setString('apellido', apellido);
          await prefs.setString('email', email);
        }
      }
    }
    final String nombreCompleto =
        ((nombre.isNotEmpty ? nombre : 'Nombre') +
                (apellido.isNotEmpty ? ' $apellido' : ''))
            .trim();
    return {
      'nombre': nombreCompleto.isNotEmpty
          ? nombreCompleto
          : 'Nombre del pasajero',
      'email': email.isNotEmpty ? email : 'correo@ejemplo.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Pasajero')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _datosUsuarioFuture,
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del pasajero';
            final email = snapshot.data?['email'] ?? 'correo@ejemplo.com';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  accountEmail: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundImage: AssetImage('assets/avatar_default.png'),
                  ),
                  decoration: const BoxDecoration(color: Colors.blue),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text('Mi Cuenta'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerfilPasajeroScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Pagar suscripción'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PagoSuscripcionScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Estado de suscripción'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EstadoSuscripcionPasajeroScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial de pagos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistorialPagoPasajeroScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y soporte'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AyudaSoporteScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                const LogoutButton(),
              ],
            );
          },
        ),
      ),
      body: const Center(
        child: Text('Contenido principal del dashboard pasajero'),
      ),
    );
  }
}
