import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordRequestPassengerScreen extends StatefulWidget {
  const ResetPasswordRequestPassengerScreen({super.key});

  @override
  State<ResetPasswordRequestPassengerScreen> createState() =>
      _ResetPasswordRequestPassengerScreenState();
}

class _ResetPasswordRequestPassengerScreenState
    extends State<ResetPasswordRequestPassengerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final url = Uri.parse(
      'https://graceful-balance-production-ef1d.up.railway.app/auth/reset-password/request/passenger',
    );
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );
      if (resp.statusCode == 200) {
        setState(() {
          _success = "Código enviado, revisa tu correo";
        });
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
      appBar: AppBar(title: const Text('Recuperar contraseña (Pasajero)')),
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
