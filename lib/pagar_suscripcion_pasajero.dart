import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dashboard_pasajero.dart';
import 'api_config.dart';

class PagoSuscripcionScreen extends StatefulWidget {
  const PagoSuscripcionScreen({Key? key}) : super(key: key);

  @override
  State<PagoSuscripcionScreen> createState() => _PagoSuscripcionScreenState();
}

class _PagoSuscripcionScreenState extends State<PagoSuscripcionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mesesController = TextEditingController(
    text: '1',
  );
  final int precioMensual = 1500;
  bool _loading = false;
  String? _mpInitPoint;
  String? _mensajeError;
  String? _mensajeExito;
  int _meses = 1;

  @override
  void initState() {
    super.initState();
    _mesesController.addListener(_updateMesesPagados);
  }

  void _updateMesesPagados() {
    final val = int.tryParse(_mesesController.text.trim());
    setState(() {
      _meses = (val != null && val >= 1 && val <= 12) ? val : 1;
    });
  }

  Future<void> _crearSuscripcion() async {
    setState(() {
      _loading = true;
      _mensajeError = null;
      _mpInitPoint = null;
      _mensajeExito = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final url = Uri.parse(ApiConfig.suscripcionCrear);
      int meses = _meses;
      final resp = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"meses_a_pagar": meses}),
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body["mp_init_point"] != null) {
        setState(() {
          _mpInitPoint = body["mp_init_point"];
          _mensajeExito = body["mensaje"] ?? 'Orden creada correctamente.';
        });
      } else {
        setState(() {
          _mensajeError = body["detail"] ?? "No se pudo crear la suscripción.";
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError = "Error inesperado: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _mesesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = _meses * precioMensual;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 95,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.only(left: 5, right: 8),
            textStyle: const TextStyle(fontSize: 14),
          ),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          label: const Text("ATRÁS", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPasajero()),
              (route) => false,
            );
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              "ZUVIROapps",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1476FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
        title: null,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "¿Cuántos meses desea pagar?",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mesesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Meses (1 a 12)",
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final n = int.tryParse(value ?? '');
                      if (n == null) return "Ingrese un número";
                      if (n < 1 || n > 12) return "Solo de 1 a 12 meses";
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Total a pagar: $_meses x \$${precioMensual.toString()} = \$${total.toString()} CLP',
                    style: const TextStyle(
                      color: Color(0xFF1476FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _crearSuscripcion();
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Generar link de pago'),
                  ),
                  if (_mensajeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Text(
                        _mensajeError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_mensajeExito != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Text(
                        _mensajeExito!,
                        style: const TextStyle(
                          color: Color(0xFF2ecc71),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_mpInitPoint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Ir a MercadoPago"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => launchUrl(Uri.parse(_mpInitPoint!)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
