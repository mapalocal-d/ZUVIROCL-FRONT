import 'package:flutter/material.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'secure_storage.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    // 1. Llama logout al backend con ApiClient
    try {
      await ApiClient().post(ApiConfig.logout);
    } catch (_) {
      // Ignora error: solo para registro en backend
    }

    // 2. Borra toda la sesión segura
    await SecureStorage().clearAll();

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
