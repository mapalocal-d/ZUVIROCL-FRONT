import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // 1. Llama logout al backend SOLO SI hay token
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(
            'https://graceful-balance-production-ef1d.up.railway.app/logout',
          ), // URL real de Railway
          headers: {"Authorization": "Bearer $token"},
        );
      } catch (_) {
        // Puedes ignorar el error, tu backend solo registra el evento
      }
    }

    // 2. Borra el token local
    await prefs.remove('access_token');

    // 3. Lleva al login limpiando la navegación
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () => _logout(context),
    );
  }
}
