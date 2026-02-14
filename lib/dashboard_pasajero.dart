import 'package:flutter/material.dart';

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
              ), // puedes cambiar dinámicamente
              accountEmail: Text(
                'correo@ejemplo.com',
              ), // puedes cambiar dinámicamente
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(
                  'assets/avatar_default.png',
                ), // o NetworkImage
              ),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Perfil'),
              onTap: () {
                // Navega a la pantalla de perfil
                Navigator.pop(context); // Cierra el drawer
                // Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Pagar suscripción'),
              onTap: () {
                // Navega a la pantalla de pagos/suscripción
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => PagoSuscripcionScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historial de pagos'),
              onTap: () {
                // Navega a la pantalla de historial de pagos
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialPagoScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Ayuda y soporte'),
              onTap: () {
                // Navega a la pantalla de ayuda/soporte
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AyudaSoporteScreen()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                // Lógica de logout y redirección a login
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Contenido principal del dashboard pasajero')),
    );
  }
}
