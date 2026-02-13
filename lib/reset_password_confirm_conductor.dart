import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordConfirmConductorScreen extends StatefulWidget {
  const ResetPasswordConfirmConductorScreen({super.key});

  @override
  State<ResetPasswordConfirmConductorScreen> createState() =>
      _ResetPasswordConfirmConductorScreenState();
}

class _ResetPasswordConfirmConductorScreenState
    extends State<ResetPasswordConfirmConductorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _passController = TextEditingController();
  final _pass2Controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passController.text != _pass2Controller.text) {
      setState(() {
        _error = "Las contraseñas no coinciden";
        _success = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final url = Uri.parse(
      'https://graceful-balance-production-ef1d.up.railway.app/auth/reset-password/confirm/conductor',
    );

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "codigo": _codigoController.text.trim(),
          "nueva_password": _passController.text,
          "confirm_password": _pass2Controller.text,
        }),
      );
      if (resp.statusCode == 200) {
        setState(() {
          _success = "Contraseña actualizada exitosamente.";
        });

        // SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contraseña actualizada. Inicia sesión."),
          ),
        );

        // Espera breve para que usuario vea mensaje
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          // O usa pushReplacementNamed si tienes rutas
          // Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          final decoded = jsonDecode(resp.body);
          _error = decoded["detail"] is String
              ? decoded["detail"]
              : "Error desconocido (${resp.statusCode})";
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
      appBar: AppBar(title: const Text('Cambiar contraseña (Conductor)')),
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
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.length != 6 ? "Código de 6 dígitos" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                ),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 8) ? "Mínimo 8 caracteres" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pass2Controller,
                decoration: const InputDecoration(
                  labelText: 'Confirma nueva contraseña',
                ),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 8) ? "Mínimo 8 caracteres" : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_success != null)
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text("Cambiar contraseña"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
