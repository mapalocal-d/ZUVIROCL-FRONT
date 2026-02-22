import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // 1. Llama logout al backend SOLO SI hay token
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: {"Authorization": "Bearer $token"},
        );
      } catch (_) {
        // Ignora error: solo para registro en backend
      }
    }

    // 2. Borra toda la sesión local
    await prefs.clear();

    // 3. Redirige limpiando todo el stack a la pantalla inicial
    Navigator.of(context).pop();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Cerrar sesión'),
      onTap: () async {
        await _logout(context);
      },
    );
  }
}
