import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';

class PerfilPasajeroScreen extends StatefulWidget {
  const PerfilPasajeroScreen({super.key});

  @override
  State<PerfilPasajeroScreen> createState() => _PerfilPasajeroScreenState();
}

class _PerfilPasajeroScreenState extends State<PerfilPasajeroScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  static const emeraldGreen = Color(0xFF2ecc71);

  @override
  void initState() {
    super.initState();
    _fetchPerfil();
  }

  Future<void> _fetchPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;
    final url = Uri.parse(ApiConfig.usuarioMe);
    try {
      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (resp.statusCode == 200) {
        setState(() {
          _userData = jsonDecode(resp.body);
          _loading = false;
        });
      } else {
        setState(() {
          _userData = null;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _editarPerfil() async {
    TextEditingController nombreController = TextEditingController(
      text: _userData?['nombre'] ?? '',
    );
    TextEditingController apellidoController = TextEditingController(
      text: _userData?['apellido'] ?? '',
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Editar datos',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Guardar',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );

    if (resultado == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;
      final url = Uri.parse(ApiConfig.perfilPasajero);
      try {
        final resp = await http.patch(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "nombre": nombreController.text,
            "apellido": apellidoController.text,
          }),
        );
        if (resp.statusCode == 200) {
          _fetchPerfil();
          _showSuccess('¡Datos actualizados!');
        } else {
          _showError('No se pudieron actualizar los datos.');
        }
      } catch (_) {
        _showError('Ocurrió un error al actualizar.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showHelp(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: emeraldGreen));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: emeraldGreen));
  }

  bool _validarPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'\d'));
    return hasMinLength && hasUppercase && hasNumber;
  }

  Future<void> _cambiarContrasena() async {
    TextEditingController actualController = TextEditingController();
    TextEditingController nuevaController = TextEditingController();
    TextEditingController confirmarController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        String helpMessage = "Mínimo 8 caracteres, una mayúscula y un número.";
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text(
              'Cambiar contraseña',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: actualController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: nuevaController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (!_validarPassword(val)) {
                        helpMessage =
                            "Mínimo 8 caracteres, una mayúscula y un número.";
                      } else {
                        helpMessage = "Contraseña válida ✔";
                      }
                    });
                  },
                ),
                TextField(
                  controller: confirmarController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (_) {
                    return Text(
                      helpMessage,
                      style: TextStyle(
                        color: helpMessage.contains('✔')
                            ? emeraldGreen
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Guardar',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (resultado == true) {
      final nueva = nuevaController.text;
      final confirmar = confirmarController.text;

      if (!_validarPassword(nueva)) {
        _showHelp(
          'La contraseña debe tener mínimo 8 caracteres, una mayúscula y un número.',
        );
        return;
      }
      if (nueva != confirmar) {
        _showError('Las contraseñas no coinciden.');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      final url = Uri.parse(ApiConfig.cambiarContrasena);
      try {
        final resp = await http.put(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "contrasena_actual": actualController.text,
            "contrasena_nueva": nueva,
            "confirmar_contrasena": confirmar,
          }),
        );
        if (resp.statusCode == 200) {
          _showSuccess('¡Contraseña cambiada exitosamente!');
        } else {
          _showError(
            'No se pudo cambiar la contraseña. Código: ${resp.statusCode}',
          );
        }
      } catch (err) {
        _showError('Ocurrió un error al cambiar la contraseña.');
      }
    }
  }

  Future<void> _borrarCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;
    final url = Uri.parse(ApiConfig.eliminarCuenta);
    try {
      final resp = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (resp.statusCode == 200) {
        await prefs.clear();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No se pudo cargar el perfil',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Perfil del Pasajero'),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 46,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Nombre: ${_userData!['nombre'] ?? ''}",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              "Apellido: ${_userData!['apellido'] ?? ''}",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              "Email: ${_userData!['correo'] ?? ''}",
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              "Ciudad: ${_userData!['ciudad'] ?? ''}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Rol: ${_userData!['rol'] ?? ''}",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _editarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Editar datos'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _cambiarContrasena,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Cambiar contraseña'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.black87,
                    title: const Text(
                      'Borrar cuenta',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '¿Seguro que quieres borrar tu cuenta? Esta acción no se puede deshacer.',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Borrar',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm ?? false) _borrarCuenta();
              },
              child: const Text('Borrar cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
