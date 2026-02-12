import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
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
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _patenteController = TextEditingController();
  final TextEditingController _lineaRecorridoController =
      TextEditingController();

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate() || !_aceptaTerminos) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse(
      'https://graceful-balance-production-ef1d.up.railway.app/register/conductor',
    ); // Cambia TU_BACKEND por tu URL real
    final body = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "confirm_password": _confirmPasswordController.text,
      "region": _regionController.text.trim(),
      "ciudad": _ciudadController.text.trim(),
      "patente": _patenteController.text.trim().toUpperCase().replaceAll(
        ' ',
        '',
      ),
      "linea_recorrido": _lineaRecorridoController.text.trim(),
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

        // ===== GUARDA EL TOKEN JWT =====
        final accessToken = respBody['access_token'];
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
        }
        // ===============================

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("¡Registro exitoso!"),
            content: const Text(
              "Conductor registrado y suscripción por 1 mes gratis.",
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

  // ==== FUNCIONES DE VALIDACIÓN ====

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
          dom.endsWith('.es.es'))
        return "Revisa el dominio de tu email";
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

  String? _validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa la región";
    if (value.length < 2) return "Al menos 2 letras";
    if (value.length > 50) return "Máx 50 letras";
    return null;
  }

  String? _validateCiudad(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa la ciudad";
    if (value.length < 2) return "Al menos 2 letras";
    if (value.length > 40) return "Máx 40 letras";
    return null;
  }

  String? _validatePatente(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa la patente";
    final cleaned = value.trim().toUpperCase().replaceAll(' ', '');
    if (cleaned.length < 6 || cleaned.length > 10)
      return "Debe tener de 6 a 10 caracteres";
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned))
      return "Solo letras mayúsculas y números";
    return null;
  }

  String? _validateLineaRecorrido(String? value) {
    if (value == null || value.trim().isEmpty)
      return "Indica la línea o recorrido";
    if (value.length < 1) return "Completa este campo";
    if (value.length > 10) return "Máx 10 caracteres";
    return null;
  }

  // ====== FIN VALIDACIONES ========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Conductor')),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: _validateApellido,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                ),
                obscureText: true,
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(labelText: 'Región'),
                validator: _validateRegion,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ciudadController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                validator: _validateCiudad,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _patenteController,
                decoration: const InputDecoration(labelText: 'Patente'),
                validator: _validatePatente,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lineaRecorridoController,
                decoration: const InputDecoration(
                  labelText: 'Línea o recorrido',
                ),
                validator: _validateLineaRecorrido,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Acepto los términos y condiciones',
                      softWrap: true,
                    ),
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
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _loading ? null : _registerDriver,
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
