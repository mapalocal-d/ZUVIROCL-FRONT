import 'package:flutter/material.dart';
import 'dart:convert';
import 'api_client.dart';
import 'api_config.dart';
import 'secure_storage.dart';
import 'app_logger.dart';

// Alineado al backend: Validadores
final Set<String> nombresReservados = {
  'admin',
  'administrador',
  'soporte',
  'root',
  'moderador',
  'zuviro',
  'sistema',
  'test',
  'null',
  'undefined',
  'api',
  'webhook',
  'notification',
  'user',
  'usuario',
  'guest',
  'invitado',
  'support',
  'help',
  'info',
  'contact',
  'noreply',
  'no-reply',
  'postmaster',
  'hostmaster',
  'webmaster',
  'abuse',
};

final Set<String> contrasenasComunes = {
  'password',
  '123456',
  '12345678',
  'qwerty',
  'abc123',
  'zuviro123',
  'password123',
  'admin123',
  'letmein',
  'welcome',
  'monkey',
  '1234567890',
  'football',
  'iloveyou',
};

final List<String> secuenciasTeclado = [
  'qwerty',
  'asdfgh',
  'zxcvbn',
  '123456',
  '654321',
];

class PerfilPasajeroScreen extends StatefulWidget {
  const PerfilPasajeroScreen({super.key});

  @override
  State<PerfilPasajeroScreen> createState() => _PerfilPasajeroScreenState();
}

class _PerfilPasajeroScreenState extends State<PerfilPasajeroScreen> {
  final _api = ApiClient();
  final _secure = SecureStorage();
  Map<String, dynamic>? _userData;
  bool _loading = true;

  static const emeraldGreen = Color(0xFF2ecc71);

  @override
  void initState() {
    super.initState();
    _fetchPerfil();
  }

  Future<void> _fetchPerfil() async {
    try {
      final resp = await _api.get(ApiConfig.usuarioMe);
      if (resp.statusCode == 200) {
        final user = jsonDecode(resp.body);
        await _secure.guardarDatosUsuario(user);
        AppLogger.i('Perfil pasajero cargado y caché actualizado.');
        setState(() {
          _userData = user;
          _loading = false;
        });
      } else {
        AppLogger.w('Error cargando perfil pasajero: ${resp.statusCode}');
        setState(() {
          _userData = null;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error en _fetchPerfil pasajero', e);
      setState(() {
        _loading = false;
      });
    }
  }

  // ========== VALIDACIONES ALINEADAS AL BACKEND ==========

  // Backend: Validadores.nombre_propio
  String? _validarNombre(String valor, String campo) {
    final limpio = valor.trim();
    if (limpio.isEmpty) return "El $campo es requerido";
    if (limpio.length < 2) return "El $campo debe tener al menos 2 caracteres";
    if (limpio.length > 50) return "El $campo no puede superar 50 caracteres";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]+$").hasMatch(limpio))
      return "Solo letras, espacios, apóstrofes y guiones";
    if (nombresReservados.contains(limpio.toLowerCase()))
      return "$campo reservado por el sistema";
    return null;
  }

  // Backend: Validadores.contrasena (NIST SP 800-63B)
  String? _validarPassword(String password) {
    if (password.isEmpty) return "La contraseña es requerida";
    if (password.length < 8) return "Mínimo 8 caracteres";
    if (password.length > 128) return "Máximo 128 caracteres";
    if (password != password.trim())
      return "No debe tener espacios al inicio o final";

    int cumple = 0;
    if (RegExp(r'[A-Z]').hasMatch(password)) cumple++;
    if (RegExp(r'[a-z]').hasMatch(password)) cumple++;
    if (RegExp(r'[0-9]').hasMatch(password)) cumple++;
    if (RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) cumple++;

    if (cumple < 3)
      return "Debe contener al menos 3 de: mayúsculas, minúsculas, números y símbolos";

    if (contrasenasComunes.contains(password.toLowerCase()))
      return "Contraseña demasiado común";

    for (final seq in secuenciasTeclado) {
      if (password.toLowerCase().contains(seq))
        return "Contiene secuencias de teclado predecibles";
    }

    return null;
  }

  // ========== EDITAR PERFIL ==========

  Future<void> _editarPerfil() async {
    final formKey = GlobalKey<FormState>();

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
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => _validarNombre(v ?? '', 'nombre'),
                ),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => _validarNombre(v ?? '', 'apellido'),
                ),
              ],
            ),
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
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
      try {
        final datosEditados = {
          "nombre": nombreController.text.trim(),
          "apellido": apellidoController.text.trim(),
        };
        final resp = await _api.patch(
          ApiConfig.perfilPasajero,
          body: datosEditados,
        );
        if (resp.statusCode == 200) {
          await _secure.guardarDatosUsuario(datosEditados);
          AppLogger.i('Perfil pasajero editado y caché actualizado.');
          _fetchPerfil();
          _showSuccess('¡Datos actualizados!');
        } else {
          final body = jsonDecode(resp.body);
          _showError(body['detail'] ?? 'No se pudieron actualizar los datos.');
        }
      } catch (e) {
        AppLogger.e('Error editando perfil pasajero', e);
        _showError('Ocurrió un error al actualizar.');
      }
    }
  }

  // ========== CAMBIAR CONTRASEÑA ==========

  Future<void> _cambiarContrasena() async {
    final formKey = GlobalKey<FormState>();

    TextEditingController actualController = TextEditingController();
    TextEditingController nuevaController = TextEditingController();
    TextEditingController confirmarController = TextEditingController();
    bool showActual = false;
    bool showNueva = false;
    bool showConfirmar = false;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text(
              'Cambiar contraseña',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: actualController,
                      obscureText: !showActual,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showActual
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setDialogState(() => showActual = !showActual);
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return "Ingresa tu contraseña actual";
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nuevaController,
                      obscureText: !showNueva,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        labelStyle: const TextStyle(color: Colors.white70),
                        helperText:
                            '8-128 chars. Al menos 3 de: mayúsculas,\nminúsculas, números y símbolos.',
                        helperStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNueva ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setDialogState(() => showNueva = !showNueva);
                          },
                        ),
                      ),
                      validator: (v) => _validarPassword(v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmarController,
                      obscureText: !showConfirmar,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirmar
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setDialogState(
                              () => showConfirmar = !showConfirmar,
                            );
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v != nuevaController.text)
                          return "Las contraseñas no coinciden";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
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
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
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
      try {
        final resp = await _api.put(
          ApiConfig.cambiarContrasena,
          body: {
            "contrasena_actual": actualController.text,
            "contrasena_nueva": nuevaController.text,
            "confirmar_contrasena": confirmarController.text,
          },
        );
        if (resp.statusCode == 200) {
          _showSuccess('¡Contraseña cambiada exitosamente!');
        } else {
          final body = jsonDecode(resp.body);
          _showError(body['detail'] ?? 'No se pudo cambiar la contraseña.');
        }
      } catch (err) {
        _showError('Ocurrió un error al cambiar la contraseña.');
      }
    }
  }

  // ========== BORRAR CUENTA ==========

  Future<void> _borrarCuenta() async {
    try {
      final resp = await _api.delete(ApiConfig.eliminarCuenta);
      if (resp.statusCode == 200) {
        await _secure.clearAll();
        AppLogger.i('Cuenta pasajero eliminada.');
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      AppLogger.e('Error borrando cuenta pasajero', e);
    }
  }

  // ========== UTILIDADES UI ==========

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: emeraldGreen));
  }

  // ========== UI ==========

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
        child: SingleChildScrollView(
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
      ),
    );
  }
}
