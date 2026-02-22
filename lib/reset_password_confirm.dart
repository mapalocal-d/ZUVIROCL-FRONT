import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

// Alineado al backend: Validadores.contrasena
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

class ResetPasswordConfirmScreen extends StatefulWidget {
  final String rol;
  const ResetPasswordConfirmScreen({super.key, required this.rol});

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _passController = TextEditingController();
  final _pass2Controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _showPass = false;
  bool _showPass2 = false;

  String get _rolLabel => widget.rol == "conductor" ? "Conductor" : "Pasajero";

  @override
  void dispose() {
    _codigoController.dispose();
    _passController.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  // Backend: Validadores.contrasena (NIST SP 800-63B)
  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 128) return "Máximo 128 caracteres";
    if (value != value.trim())
      return "No debe tener espacios al inicio o final";

    int cumple = 0;
    if (RegExp(r'[A-Z]').hasMatch(value)) cumple++;
    if (RegExp(r'[a-z]').hasMatch(value)) cumple++;
    if (RegExp(r'[0-9]').hasMatch(value)) cumple++;
    if (RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) cumple++;

    if (cumple < 3)
      return "Debe contener al menos 3 de: mayúsculas, minúsculas, números y símbolos";

    if (contrasenasComunes.contains(value.toLowerCase()))
      return "Contraseña demasiado común. Elige una más única.";

    for (final seq in secuenciasTeclado) {
      if (value.toLowerCase().contains(seq))
        return "Contiene secuencias de teclado predecibles";
    }

    return null;
  }

  // Backend: codigo pattern=r"^[0-9]{6}$"
  String? _validarCodigo(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa el código";
    final limpio = value.trim();
    if (limpio.length != 6) return "Debe ser un código de 6 dígitos";
    if (!RegExp(r'^[0-9]{6}$').hasMatch(limpio))
      return "Solo dígitos numéricos";
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final url = Uri.parse(ApiConfig.recuperarConfirmar);
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "codigo": _codigoController.text.trim(),
          "contrasena_nueva": _passController.text,
          "confirmar_contrasena": _pass2Controller.text,
          "rol": widget.rol,
        }),
      );
      if (resp.statusCode == 200) {
        setState(() {
          _success = "Contraseña actualizada exitosamente";
          _error = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Contraseña actualizada, inicia sesión con tu nueva clave.",
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() {
          final respDecoded = jsonDecode(resp.body);
          _error = respDecoded["detail"] is String
              ? respDecoded["detail"]
              : "Error desconocido";
          _success = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error de conexión";
        _success = null;
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
      appBar: AppBar(title: Text('Cambiar contraseña ($_rolLabel)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación (6 dígitos)',
                  helperText: 'Revisa tu correo electrónico',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: _validarCodigo,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText:
                      '8-128 chars. Al menos 3 de: mayúsculas, minúsculas, números y símbolos.',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPass = !_showPass);
                    },
                  ),
                ),
                obscureText: !_showPass,
                validator: _validarPassword,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pass2Controller,
                decoration: InputDecoration(
                  labelText: 'Confirma nueva contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPass2 = !_showPass2);
                    },
                  ),
                ),
                obscureText: !_showPass2,
                validator: (v) {
                  if (v == null || v != _passController.text)
                    return "Las contraseñas no coinciden";
                  return null;
                },
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
                  onPressed: _loading ? null : _changePassword,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Cambiar contraseña"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
