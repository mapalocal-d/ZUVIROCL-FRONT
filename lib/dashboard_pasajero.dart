import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'perfil_pasajero.dart'; // Ruta correcta de tu archivo con PerfilPasajeroScreen
import 'logout_button.dart'; // Ruta correcta de tu logout

class DashboardPasajero extends StatelessWidget {
  const DashboardPasajero({Key? key}) : super(key: key);

  // Puedes obtener nombre/email desde SharedPreferences para el drawer:
  Future<Map<String, String>> _getNombreEmail() async {
    final prefs = await SharedPreferences.getInstance();
    // Si guardas los datos en prefs; sino, puedes dejar por defecto/después vincular desde Provider.
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
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Perfil'),
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
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Pagar suscripción'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => PagoSuscripcionScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial de pagos'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialPagoScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y soporte'),
                  onTap: () {
                    Navigator.pop(context);
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
