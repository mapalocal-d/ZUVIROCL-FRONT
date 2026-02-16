import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'politica_legal.dart'; // Importa la pantalla de Políticas

const emeraldGreen = Color(0xFF50C878);
final List<String> dominiosProhibidos = [
  'mailinator',
  'yopmail',
  'tempmail',
  'guerrillamail',
];
final List<String> palabrasProhibidas = [
  'admin',
  'root',
  'soporte',
  'moderador',
  'appcl',
];
final List<String> contrasenasDebiles = [
  'password',
  '123456',
  'contraseña',
  '12345678',
  'qwerty',
];

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
  String? _emailErrorText;
  bool _checkingEmail = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ========= VALIDACIÓN EMAIL EXISTE EN BACKEND =========
  Future<bool> emailExisteEnBackend(String email) async {
    final response = await http.get(
      Uri.parse(
        'https://graceful-balance-production-ef1d.up.railway.app/auth/check-email?email=$email',
      ),
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      // El backend retorna un string: "EXISTS" o "AVAILABLE"
      final String result = response.body.replaceAll('"', '').trim();
      return result.toLowerCase().contains('exist'); // "EXISTS"
    }
    if (response.statusCode == 422) {
      // Email mal formado
      return false;
    }
    throw Exception('Error consultando disponibilidad');
  }

  void _onEmailChanged(String value) async {
    final email = value.trim();
    if (email.isEmpty) {
      setState(() => _emailErrorText = "Ingresa tu email");
      return;
    }
    if (!_validateFormatoEmail(email)) {
      setState(() => _emailErrorText = "Formato de email inválido");
      return;
    }
    // Dominio prohibido
    if (dominiosProhibidos.any((d) => email.contains(d))) {
      setState(() => _emailErrorText = "No se permiten emails temporales.");
      return;
    }

    setState(() => _checkingEmail = true);
    try {
      bool exists = await emailExisteEnBackend(email);
      setState(() {
        _emailErrorText = exists ? "Este email ya está registrado" : null;
      });
    } catch (e) {
      setState(() => _emailErrorText = "Error verificando email");
    }
    setState(() => _checkingEmail = false);
  }

  // ========= VALIDACIONES =========
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    final nombre = value.trim();
    if (nombre.length < 2) return "Debe tener al menos 2 letras";
    if (nombre.length > 50) return "Máximo 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(nombre))
      return "Solo letras y espacios";
    if (palabrasProhibidas.contains(nombre.toLowerCase()))
      return "Nombre reservado por el sistema";
    if (RegExp(r"(.)\1{3,}").hasMatch(nombre))
      return "No usar muchas repeticiones";
    if (nombre == nombre.toUpperCase()) return "No todo en mayúsculas";
    if (nombre == nombre.toLowerCase()) return "No todo en minúsculas";
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu apellido";
    final apellido = value.trim();
    if (apellido.length < 2) return "Debe tener al menos 2 letras";
    if (apellido.length > 50) return "Máximo 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(apellido))
      return "Solo letras y espacios";
    if (palabrasProhibidas.contains(apellido.toLowerCase()))
      return "Apellido reservado por el sistema";
    if (RegExp(r"(.)\1{3,}").hasMatch(apellido))
      return "No usar muchas repeticiones";
    if (apellido == apellido.toUpperCase()) return "No todo en mayúsculas";
    if (apellido == apellido.toLowerCase()) return "No todo en minúsculas";
    return null;
  }

  // Validación local de email (formato, dominio, caracteres)
  bool _validateFormatoEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final email = value.trim();
    if (email.contains(' ')) return false;
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) return false;
    if (dominiosProhibidos.any((d) => email.contains(d))) return false;
    if (RegExp(r'[^\x00-\x7F]').hasMatch(email)) return false; // Emojis/raros
    return true;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim();
    if (email == null || email.isEmpty) return "Ingresa tu email";
    if (!_validateFormatoEmail(email)) return "Email inválido";
    if (_emailErrorText != null) return _emailErrorText;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 32) return "Máximo 32 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return "Debe tener una letra mayúscula";
    if (!RegExp(r'[a-z]').hasMatch(value))
      return "Debe tener una letra minúscula";
    if (!RegExp(r'\d').hasMatch(value)) return "Debe tener un número";
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value))
      return "Debe tener un símbolo (!@#\$...)";
    if (contrasenasDebiles.any((p) => value.toLowerCase().contains(p)))
      return "Contraseña demasiado fácil";
    if (_nombreController.text.isNotEmpty &&
        value.toLowerCase().contains(_nombreController.text.toLowerCase()))
      return "No usar tu nombre como contraseña";
    if (_emailController.text.isNotEmpty &&
        value.toLowerCase().contains(_emailController.text.toLowerCase()))
      return "No usar tu email como contraseña";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != _passwordController.text)
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
          Navigator.pushReplacementNamed(context, '/dashboard_pasajero');
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Registro Pasajero', style: TextStyle(fontSize: 20)),
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
              // -------- Campos de registro exactamente igual que tu código --------
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
                  errorText: _emailErrorText,
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
                onChanged: _onEmailChanged,
              ),
              if (_checkingEmail)
                const Padding(
                  padding: EdgeInsets.only(left: 10, top: 3, bottom: 3),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 7),
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
                      "Debe tener entre 8 y 32 caracteres, mayúscula, minúscula, número y símbolo.",
                  helperStyle: TextStyle(color: emeraldGreen, fontSize: 13.5),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                obscureText: true,
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 7),
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
              // ----------- Checkbox con enlace a política legal -----------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                    activeColor: Colors.blue,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'Acepto los ',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PoliticaLegalScreen(),
                            ),
                          ),
                          child: const Text(
                            'términos y condiciones y política de privacidad',
                            style: TextStyle(
                              color: Color(0xFF50C878),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
