import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'perfil_pasajero.dart'; // Ruta a tu archivo de Mi Cuenta
import 'logout_button.dart'; // Ruta correcta para tu logout
import 'pagar_suscripcion_pasajero.dart'; // Asegúrate que aquí está PagoSuscripcionScreen
import 'estado_suscripcion_pasajero.dart'; // Importa el widget del estado de suscripción

class DashboardPasajero extends StatelessWidget {
  const DashboardPasajero({Key? key}) : super(key: key);

  Future<Map<String, String>> _getNombreEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Nombre del pasajero';
    final apellido = prefs.getString('apellido') ?? '';
    final email = prefs.getString('email') ?? 'correo@ejemplo.com';
    return {'nombre': '$nombre $apellido', 'email': email};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Pasajero')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _getNombreEmail(),
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del pasajero';
            final email = snapshot.data?['email'] ?? 'correo@ejemplo.com';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(nombre),
                  accountEmail: Text(email),
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
                    // Aquí deberías enlazar tu HistorialPagoScreen cuando lo tengas:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialPagoScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y soporte'),
                  onTap: () {
                    Navigator.pop(context);
                    // Aquí deberías enlazar tu AyudaSoporteScreen cuando lo tengas:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => AyudaSoporteScreen()));
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
