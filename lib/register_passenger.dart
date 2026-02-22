import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage.dart';
import 'app_logger.dart';
import 'politica_legal.dart';
import 'api_config.dart';

const emeraldGreen = Color(0xFF50C878);
final List<String> dominiosProhibidos = [
  'mailinator',
  'yopmail',
  'tempmail',
  'guerrillamail',
];
final List<String> palabrasProhibidas = [
  'admin',
  'administrador',
  'root',
  'soporte',
  'moderador',
  'appcl',
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

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<bool> emailExisteEnBackend(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.checkEmail}?email=$email&rol=pasajero'),
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body["disponible"] == false;
    }
    if (response.statusCode == 422) {
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

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    final nombre = value.trim();
    if (nombre.length < 2) return "Debe tener al menos 2 letras";
    if (nombre.length > 50) return "Máximo 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(nombre))
      return "Solo letras y espacios";
    if (palabrasProhibidas.contains(nombre.toLowerCase()))
      return "Nombre reservado por el sistema";
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
    return null;
  }

  bool _validateFormatoEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final email = value.trim().toLowerCase();
    if (email.contains(' ')) return false;
    if (!email.contains('@')) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final parteLocal = parts[0];
    final dominio = parts[1];
    if (dominio.endsWith('.com.com') ||
        dominio.endsWith('.cl.cl') ||
        dominio.endsWith('.es.es'))
      return false;
    if (email.contains('..')) return false;
    if (parteLocal.startsWith('.') || parteLocal.endsWith('.')) return false;
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) return false;
    if (dominiosProhibidos.any((d) => email.contains(d))) return false;
    if (RegExp(r'[^\x00-\x7F]').hasMatch(email)) return false;
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
      return "La contraseña debe contener al menos una letra mayúscula.";
    if (!RegExp(r'\d').hasMatch(value))
      return "La contraseña debe contener al menos un número.";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != _passwordController.text)
      return "Las contraseñas no coinciden";
    return null;
  }

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

    final url = Uri.parse(ApiConfig.registerPasajero);
    final body = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "correo": _emailController.text.trim(),
      "contrasena": _passwordController.text,
      "confirmar_contrasena": _confirmPasswordController.text,
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
        final refreshToken = respBody['refresh_token'];
        if (accessToken != null) {
          final secure = SecureStorage();
          await secure.setAccessToken(accessToken);
          if (refreshToken != null) {
            await secure.setRefreshToken(refreshToken);
          }
          await secure.setRol('pasajero');

          final usuario = respBody['usuario'];
          if (usuario != null) {
            await secure.guardarDatosUsuario(usuario);
          }
        }
        AppLogger.i('Registro pasajero exitoso.');
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
        AppLogger.w('Registro pasajero falló: ${respBody['detail']}');
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
    } catch (e, s) {
      AppLogger.e('Error en registro pasajero', e, s);
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
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
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
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  labelStyle: TextStyle(color: Colors.blue, fontSize: 15),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
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
                  helperStyle: const TextStyle(
                    color: emeraldGreen,
                    fontSize: 13.5,
                  ),
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
                      "Debe tener entre 8 y 32 caracteres, al menos un número y una mayúscula.",
                  helperStyle: const TextStyle(
                    color: emeraldGreen,
                    fontSize: 13.5,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                obscureText: !_showPassword,
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
                  helperStyle: const TextStyle(
                    color: emeraldGreen,
                    fontSize: 13.5,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.blue, fontSize: 15),
                obscureText: !_showConfirmPassword,
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 11),
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
