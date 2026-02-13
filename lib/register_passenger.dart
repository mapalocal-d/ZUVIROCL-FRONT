import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

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

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ========= VALIDACIONES según tu schema =========
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    final nombre = value.trim();
    if (nombre.length < 2) return "Debe tener al menos 2 letras";
    if (nombre.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(nombre))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(nombre.toLowerCase()))
      return "Nombre reservado por el sistema";
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu apellido";
    final apellido = value.trim();
    if (apellido.length < 2) return "Debe tener al menos 2 letras";
    if (apellido.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(apellido))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(apellido.toLowerCase()))
      return "Apellido reservado por el sistema";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu email";
    final email = value.trim().toLowerCase();
    if (email.contains(' ')) return "El email no puede contener espacios";
    if (!email.contains('@')) return "Formato de email inválido";
    final parts = email.split('@');
    if (parts.length != 2) return "Email inválido (debe tener solo un @)";
    final parte_local = parts[0];
    final dominio = parts[1];
    if (email.contains('..'))
      return "El email no puede contener puntos consecutivos";
    if (parte_local.startsWith('.') || parte_local.endsWith('.'))
      return "La parte antes del @ no puede empezar ni terminar con punto.";
    if (dominio.endsWith('.com.com') ||
        dominio.endsWith('.cl.cl') ||
        dominio.endsWith('.es.es'))
      return "Dominio de email inválido. Verifica que esté escrito correctamente.";
    if (!dominio.contains('.')) return "Falta punto en el dominio";
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email))
      return "Email inválido";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 32) return "Máximo 32 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return "La contraseña debe contener al menos una letra mayúscula (A-Z)";
    if (!RegExp(r'\d').hasMatch(value))
      return "La contraseña debe contener al menos un número (0-9)";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text)
      return "Las contraseñas no coinciden";
    return null;
  }

  // ========= REGISTRO Y NAVEGACIÓN =========
  Future<void> _registerPassenger() async {
    if (!_formKey.currentState!.validate() || !_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos y acepta los términos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
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
      final messenger = ScaffoldMessenger.of(context);
      if (resp.statusCode == 201) {
        final respBody = json.decode(resp.body);
        final accessToken = respBody['access_token'];
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text("¡Registro exitoso! Bienvenido a tu cuenta."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        }
      } else {
        final respBody = json.decode(resp.body);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              respBody['detail'] ?? "Registro fallido. Intenta nuevamente.",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Error de conexión."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF50C878); // Verde esmeralda

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Registro Pasajero',
          style: TextStyle(fontSize: 20), // Título estándar
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //--- NOMBRE ---
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 11,
                  ),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                validator: _validateNombre,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 7),
              //--- APELLIDO ---
              TextFormField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 11,
                  ),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                validator: _validateApellido,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 7),
              //--- EMAIL ---
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 11,
                  ),
                  helperText: "Debe ser válido (ejemplo@correo.com)",
                  helperStyle: TextStyle(color: emeraldGreen, fontSize: 13.5),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 7),
              //--- CONTRASEÑA ---
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 11,
                  ),
                  helperText:
                      "Debe tener entre 8 y 32 caracteres, al menos una mayúscula y un número.",
                  helperStyle: TextStyle(color: emeraldGreen, fontSize: 13.5),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                obscureText: true,
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 7),
              // --- CONFIRMAR CONTRASEÑA ---
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 11,
                  ),
                  helperText: "Debe coincidir con tu contraseña.",
                  helperStyle: TextStyle(color: emeraldGreen, fontSize: 13.5),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                obscureText: true,
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 11),
              // --- TÉRMINOS ---
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                    activeColor: Colors.blue,
                    checkColor: Colors.black,
                  ),
                  const Expanded(
                    child: Text(
                      'Acepto los términos y condiciones',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (!_aceptaTerminos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debes aceptar los términos',
                    style: TextStyle(color: Colors.red, fontSize: 13.5),
                  ),
                ),
              const SizedBox(height: 11),
              // --- BOTÓN REGISTRARSE ---
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _loading ? null : _registerPassenger,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Registrarse"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
