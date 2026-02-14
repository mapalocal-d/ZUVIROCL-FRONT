import 'package:flutter/material.dart';

class DashboardConductor extends StatelessWidget {
  const DashboardConductor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Conductor')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del drawer (perfil del conductor)
            UserAccountsDrawerHeader(
              accountName: Text(
                'Nombre del conductor',
              ), // puedes cambiar dinámicamente
              accountEmail: Text(
                'correo@ejemplo.com',
              ), // puedes cambiar dinámicamente
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(
                  'assets/avatar_default.png',
                ), // o NetworkImage
              ),
              decoration: BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              leading: Icon(Icons.route),
              title: Text('Mis Rutas'),
              onTap: () {
                // Navega a la pantalla de rutas del conductor
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => MisRutasScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Ver ingresos'),
              onTap: () {
                // Navega a la pantalla de ingresos/finanzas
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => IngresosScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historial de viajes'),
              onTap: () {
                // Navega a la pantalla de historial de viajes del conductor
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialViajesScreen()));
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
      body: Center(child: Text('Contenido principal del dashboard conductor')),
    );
  }
}
