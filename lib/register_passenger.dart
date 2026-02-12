import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPassengerScreen extends StatefulWidget {
  const RegisterPassengerScreen({super.key});

  @override
  State<RegisterPassengerScreen> createState() =>
      _RegisterPassengerScreenState();
}

class _RegisterPassengerScreenState extends State<RegisterPassengerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _aceptaTerminos = false;
  bool _loading = false;
  String? _error;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _registerPassenger() async {
    if (!_formKey.currentState!.validate() || !_aceptaTerminos) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse(
      'https://graceful-balance-production-ef1d.up.railway.app/register/passenger',
    );
    final body = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "confirm_password": _confirmPasswordController.text,
      "acepta_terminos": _aceptaTerminos,
    };

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 201) {
        final respBody = json.decode(resp.body);

        // ====== GUARDA EL TOKEN JWT DESPUÉS DE REGISTRO ======
        final accessToken = respBody['access_token'];
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
        }
        // ======================================================

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("¡Registro exitoso!"),
            content: const Text(
              "Te hemos registrado y ya tienes 1 mes gratis de suscripción.",
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        );
      } else {
        final respBody = json.decode(resp.body);
        setState(() {
          _error =
              (respBody['detail'] ?? "Registro fallido. Intenta nuevamente.")
                  .toString();
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error de conexión";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ===== FUNCIONES DE VALIDACIÓN =====

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    if (value.length < 2) return "Debe tener al menos 2 letras";
    if (value.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(value))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(value.trim().toLowerCase()))
      return "Nombre reservado";
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu apellido";
    if (value.length < 2) return "Debe tener al menos 2 letras";
    if (value.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(value))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(value.trim().toLowerCase()))
      return "Apellido reservado";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu email";
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value))
      return "Email inválido";
    if (value.contains('..') || value.startsWith('.') || value.endsWith('.'))
      return "Email inválido";
    if (value.contains('@')) {
      final dom = value.split('@')[1];
      if (dom.endsWith('.com.com') ||
          dom.endsWith('.cl.cl') ||
          dom.endsWith('.es.es')) {
        return "Revisa el dominio de tu email";
      }
    }
    if (value.contains(' ')) return "Sin espacios en email";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 32) return "Máximo 32 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Debe tener una mayúscula";
    if (!RegExp(r'\d').hasMatch(value)) return "Debe tener un número";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text)
      return "Las contraseñas no coinciden";
    return null;
  }

  // ====== FIN VALIDACIONES ======

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Pasajero')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _validateNombre,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: _validateApellido,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                ),
                obscureText: true,
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                  ),
                  const Expanded(
                    child: Text('Acepto los términos y condiciones'),
                  ),
                ],
              ),
              if (!_aceptaTerminos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debes aceptar los términos',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _registerPassenger,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text("Registrarse"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
