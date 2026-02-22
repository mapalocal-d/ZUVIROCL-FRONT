import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reset_password_confirm.dart';
import 'api_config.dart';

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
          "correo": _emailController.text.trim(),
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
        setState(() {
          _error = jsonDecode(resp.body)["detail"] ?? "Error desconocido";
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
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email registrado',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Ingresa tu email" : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_success != null)
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ElevatedButton(
                onPressed: _loading ? null : _requestCode,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text("Enviar código"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
