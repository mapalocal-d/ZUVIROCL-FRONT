import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistorialPagoPasajeroScreen extends StatefulWidget {
  const HistorialPagoPasajeroScreen({Key? key}) : super(key: key);

  @override
  State<HistorialPagoPasajeroScreen> createState() =>
      _HistorialPagoPasajeroScreenState();
}

class _HistorialPagoPasajeroScreenState
    extends State<HistorialPagoPasajeroScreen> {
  List<dynamic> _pagos = [];
  String? _mensajeError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loading = true;
      _mensajeError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final url = Uri.parse(
        'https://graceful-balance-production-ef1d.up.railway.app/subscriptions/passenger/history',
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
          _pagos = body['pagos'] ?? [];
        });
      } else {
        setState(() {
          _mensajeError =
              "No se pudo consultar el historial (código: ${resp.statusCode})";
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

  Widget _buildPagoCard(Map pago) {
    String estado = pago['estado']?.toString().toUpperCase() ?? '-';
    Color colorEstado = estado == "APPROVED"
        ? Colors.greenAccent
        : (estado == "PENDING" ? Colors.orangeAccent : Colors.redAccent);
    String metodo = pago['metodo_pago'] ?? '-';
    String fecha = pago['fecha_pago']?.toString().substring(0, 10) ?? '-';
    return Card(
      color: Colors.black87,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Estado: $estado",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorEstado,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Fecha de pago: $fecha",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Monto: \$${pago['monto']} CLP",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Meses pagados: ${pago['meses_pagados']}",
              style: const TextStyle(color: Colors.white),
            ),
            if (metodo.isNotEmpty)
              Text(
                "Método de pago: $metodo",
                style: const TextStyle(color: Colors.white),
              ),
            if (pago['mp_payment_id'] != null)
              Text(
                "ID transacción: ${pago['mp_payment_id']}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            if (pago['mp_status_detail'] != null)
              Text(
                "MercadoPago: ${pago['mp_status_detail']}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
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
        leadingWidth: 95,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.only(left: 5, right: 8),
            textStyle: const TextStyle(fontSize: 14),
          ),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          label: const Text("ATRÁS", style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mensajeError != null
          ? Center(
              child: Text(
                _mensajeError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : _pagos.isEmpty
          ? const Center(
              child: Text(
                "No hay pagos registrados.",
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            )
          : ListView(
              children: [
                const SizedBox(height: 12),
                ..._pagos.map<Widget>((p) => _buildPagoCard(p as Map)).toList(),
                const SizedBox(height: 18),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cargarHistorial,
        backgroundColor: const Color(0xFF1476FF),
        tooltip: "Refrescar historial",
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
