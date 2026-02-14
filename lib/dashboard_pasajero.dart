import 'package:flutter/material.dart';
import 'logout_button.dart'; // Asegúrate de que la ruta sea la correcta

class DashboardPasajero extends StatelessWidget {
  const DashboardPasajero({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Pasajero')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del drawer (perfil)
            UserAccountsDrawerHeader(
              accountName: Text(
                'Nombre del pasajero',
              ), // Puedes cambiar dinámicamente
              accountEmail: Text(
                'correo@ejemplo.com',
              ), // Puedes cambiar dinámicamente
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/avatar_default.png'),
              ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Pagar suscripción'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => PagoSuscripcionScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historial de pagos'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialPagoScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Ayuda y soporte'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AyudaSoporteScreen()));
              },
            ),
            Divider(),
            const LogoutButton(), // 👈 Botón de logout reutilizable
          ],
        ),
      ),
      body: Center(child: Text('Contenido principal del dashboard pasajero')),
    );
  }
}
