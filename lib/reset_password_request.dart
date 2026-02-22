import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reset_password_confirm.dart';
import 'api_config.dart';

// Alineado al backend: Validadores.DOMINIOS_PROHIBIDOS
final Set<String> dominiosProhibidos = {
  'tempmail.com',
  '10minutemail.com',
  'guerrillamail.com',
  'throwawaymail.com',
  'mailinator.com',
  'yopmail.com',
  'sharklasers.com',
  'getairmail.com',
  'dispostable.com',
};

class ResetPasswordRequestScreen extends StatefulWidget {
  final String rol;
  const ResetPasswordRequestScreen({super.key, required this.rol});

  @override
  State<ResetPasswordRequestScreen> createState() =>
      _ResetPasswordRequestScreenState();
}

class _ResetPasswordRequestScreenState
    extends State<ResetPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  String get _rolLabel => widget.rol == "conductor" ? "Conductor" : "Pasajero";

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Backend: Validadores.email
  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu email";
    final email = value.trim().toLowerCase();

    if (email.contains(' ')) return "El email no puede contener espacios";
    if (email.length > 254) return "Email demasiado largo";
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email))
      return "Formato de email inválido";

    final parts = email.split('@');
    if (parts.length != 2) return "Formato de email inválido";
    final local = parts[0];
    final dominio = parts[1];

    if (local.length > 64) return "Parte local del email demasiado larga";
    if (local.startsWith('.') || local.endsWith('.') || email.contains('..'))
      return "Puntos mal ubicados en el email";
    if (local.startsWith('-') || local.endsWith('-'))
      return "Guiones no permitidos al inicio/final";
    if (!RegExp(r'^[a-z0-9._%+\-]+$').hasMatch(local))
      return "Caracteres no permitidos en el email";

    if (dominiosProhibidos.contains(dominio))
      return "El dominio $dominio no está permitido";
    if (dominio.endsWith('.com.com') ||
        dominio.endsWith('.cl.cl') ||
        dominio.endsWith('.es.es') ||
        dominio.endsWith('.net.net'))
      return "Dominio duplicado detectado";

    return null;
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final url = Uri.parse(ApiConfig.recuperarSolicitar);
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": _emailController.text.trim().toLowerCase(),
          "rol": widget.rol,
        }),
      );
      if (resp.statusCode == 200) {
        setState(() {
          _success = "Código enviado, revisa tu correo";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Código enviado, revisa tu correo")),
        );

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordConfirmScreen(rol: widget.rol),
            ),
          );
        }
      } else {
        final respBody = jsonDecode(resp.body);
        setState(() {
          _error = respBody["detail"] is String
              ? respBody["detail"]
              : "Error desconocido";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recuperar contraseña ($_rolLabel)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Ingresa el correo con el que te registraste y te enviaremos un código de verificación.',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email registrado',
                  helperText: 'Ejemplo: usuario@correo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: _validarEmail,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _success!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestCode,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enviar código"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
