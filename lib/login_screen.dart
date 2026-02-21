import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final logger = Logger();

const String apiBase = 'https://web-production-ba98d.up.railway.app';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = "pasajero";

  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse('$apiBase/auth/login');

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": _emailController.text.trim(),
          "contrasena": _passwordController.text,
          "rol": _selectedRole,
        }),
      );

      logger.i('STATUS: ${resp.statusCode}');
      logger.i('BODY: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        final accessToken = data['access_token'];
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('rol', _selectedRole);
        } else {
          setState(() {
            _error = "Login exitoso pero token no recibido.";
          });
          return;
        }

        _emailController.clear();
        _passwordController.clear();

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Login exitoso'),
            content: Text("Bienvenido"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_selectedRole == "conductor") {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/dashboard_conductor');
                  } else {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/dashboard_pasajero');
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          String? detail;
          try {
            final jsonBody = jsonDecode(resp.body);
            detail = jsonBody['detail'];
          } catch (_) {
            detail = resp.body;
          }
          switch (resp.statusCode) {
            case 401:
              _error = "Usuario o contraseña incorrectos";
              break;
            case 422:
              _error = "Faltan datos o son inválidos.";
              break;
            case 429:
              _error = "Demasiados intentos. Intenta más tarde.";
              break;
            default:
              _error = detail ?? "Error de autenticación";
          }
        });
      }
    } catch (e, s) {
      logger.e("EXCEPTION: $e\nSTACK: $s");
      setState(() {
        _error = "Error de conexión";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu email";
    final email = value.trim();
    final emailRegExp = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegExp.hasMatch(email)) return "Email inválido";
    if (email.contains(' ')) return "Sin espacios en email";
    if (email.length > 50) return "Email demasiado largo";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa tu contraseña";
    if (value.contains(' ')) return "Sin espacios en contraseña";
    if (value.length < 8 || value.length > 32)
      return "Debe tener entre 8 y 32 caracteres";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: _validatePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_loading) _login();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Rol",
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(value: "pasajero", child: Text("Pasajero")),
                  DropdownMenuItem(
                    value: "conductor",
                    child: Text("Conductor"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
                validator: (value) =>
                    value == null || value.isEmpty ? "Selecciona el rol" : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Iniciar sesión"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
