import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EstadoSuscripcionConductorScreen extends StatefulWidget {
  const EstadoSuscripcionConductorScreen({Key? key}) : super(key: key);

  @override
  State<EstadoSuscripcionConductorScreen> createState() =>
      _EstadoSuscripcionConductorScreenState();
}

class _EstadoSuscripcionConductorScreenState
    extends State<EstadoSuscripcionConductorScreen> {
  Map<String, dynamic>? _suscripcion;
  String? _mensajeError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    setState(() {
      _loading = true;
      _mensajeError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final url = Uri.parse(
        'https://graceful-balance-production-ef1d.up.railway.app/subscriptions/conductor/status',
      );
      final resp = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _suscripcion = body;
        });
      } else {
        setState(() {
          _mensajeError =
              "No se pudo consultar el estado (código: ${resp.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError = "Error de conexión: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildDetalle() {
    if (_suscripcion == null) return const SizedBox();
    // Colores para estado
    Color colorEstado;
    String estadoTexto;
    switch (_suscripcion!['estado']) {
      case "active":
        colorEstado = Colors.greenAccent;
        estadoTexto = "Activa";
        break;
      case "expired":
        colorEstado = Colors.redAccent;
        estadoTexto = "Vencida";
        break;
      case "pending":
        colorEstado = Colors.orangeAccent;
        estadoTexto = "Pendiente de pago";
        break;
      default:
        colorEstado = Colors.grey;
        estadoTexto = _suscripcion!['estado'] ?? "-";
    }
    return Card(
      color: Colors.black87,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Estado de suscripción:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              estadoTexto,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorEstado,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "¿Suscripción activa?: ${_suscripcion!['esta_activo'] == true ? "Sí" : "No"}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Tipo de plan: ${_suscripcion!['plan_type'] ?? "-"}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Precio mensual: \$${_suscripcion!['precio_mensual'] ?? "-"} CLP",
              style: const TextStyle(color: Colors.white),
            ),
            if (_suscripcion!['fecha_inicio'] != null)
              Text(
                "Fecha de inicio: ${_suscripcion!['fecha_inicio'].toString().substring(0, 10)}",
                style: const TextStyle(color: Colors.white),
              ),
            if (_suscripcion!['fecha_vencimiento'] != null)
              Text(
                "Fecha de vencimiento: ${_suscripcion!['fecha_vencimiento'].toString().substring(0, 10)}",
                style: const TextStyle(color: Colors.white),
              ),
            Text(
              "Días restantes: ${_suscripcion!['dias_restantes'] ?? "-"}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 110,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.only(left: 2, right: 12),
            textStyle: const TextStyle(fontSize: 14),
          ),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          label: const Text("ATRÁS", style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Text(
              "ZUVIROapps",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1476FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        title: null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mensajeError != null
          ? Center(
              child: Text(
                _mensajeError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : _suscripcion == null ||
                !_suscripcion!.containsKey("tiene_suscripcion") ||
                _suscripcion!['tiene_suscripcion'] == false
          ? const Center(
              child: Text(
                "Usted no posee una suscripción registrada.",
                style: TextStyle(fontSize: 17, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            )
          : _buildDetalle(),
      floatingActionButton: FloatingActionButton(
        onPressed: _cargarEstado,
        backgroundColor: const Color(0xFF1476FF),
        tooltip: "Refrescar estado",
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
