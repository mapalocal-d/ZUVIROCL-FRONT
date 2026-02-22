import 'package:flutter/material.dart';
import 'dart:convert';
import 'api_client.dart';
import 'api_config.dart';
import 'app_logger.dart';

class EstadoSuscripcionPasajeroScreen extends StatefulWidget {
  const EstadoSuscripcionPasajeroScreen({Key? key}) : super(key: key);

  @override
  State<EstadoSuscripcionPasajeroScreen> createState() =>
      _EstadoSuscripcionPasajeroScreenState();
}

class _EstadoSuscripcionPasajeroScreenState
    extends State<EstadoSuscripcionPasajeroScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _suscripcion;
  String? _mensajeError;
  bool _loading = true;
  bool _renovando = false;

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
      final resp = await _api.get(ApiConfig.suscripcionEstado);
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

  // ========== RENOVAR SUSCRIPCIÓN (#3) ==========

  Future<void> _renovarSuscripcion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Renovar suscripción',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se generará un nuevo enlace de pago para renovar tu suscripción.\n\n'
          'Plan: ${_suscripcion?['plan_type'] ?? 'mensual'}\n'
          'Precio: \$${_suscripcion?['precio_mensual'] ?? '-'} CLP',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1476FF),
            ),
            child: const Text('Renovar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _renovando = true);

    try {
      final resp = await _api.post(ApiConfig.suscripcionRenovar);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final urlPago = data['init_point'] ?? data['url_pago'];

        if (urlPago != null) {
          _mostrarMensaje('✅ Enlace de pago generado. Redirigiendo...');
          AppLogger.i('Renovación iniciada. URL: $urlPago');
        } else {
          _mostrarMensaje('✅ Renovación procesada exitosamente.');
        }

        await _cargarEstado();
      } else {
        final body = jsonDecode(resp.body);
        final detail = body['detail'] ?? 'No se pudo renovar la suscripción.';
        _mostrarMensaje('❌ $detail');
        AppLogger.w('Error renovando: ${resp.statusCode} - $detail');
      }
    } on SinConexionException {
      _mostrarMensaje('❌ Sin conexión a internet.');
    } catch (e) {
      AppLogger.e('Error renovando suscripción', e);
      _mostrarMensaje('❌ Error al renovar suscripción.');
    } finally {
      setState(() => _renovando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _puedeRenovar {
    if (_suscripcion == null) return false;
    final estado = _suscripcion!['estado'];
    final diasRestantes = _suscripcion!['dias_restantes'] ?? 0;
    return estado == 'expired' || (estado == 'active' && diasRestantes <= 7);
  }

  Widget _buildDetalle() {
    if (_suscripcion == null) return const SizedBox();
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: Colors.black87,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
          ),
          if (_puedeRenovar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _renovando ? null : _renovarSuscripcion,
                  icon: _renovando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.autorenew, color: Colors.white),
                  label: Text(
                    _renovando ? 'Renovando...' : 'Renovar suscripción',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _suscripcion!['estado'] == 'expired'
                        ? Colors.red[700]
                        : Colors.orange[700],
                    disabledBackgroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          if (_suscripcion!['estado'] == 'active' &&
              (_suscripcion!['dias_restantes'] ?? 0) <= 7 &&
              (_suscripcion!['dias_restantes'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu suscripción vence en ${_suscripcion!['dias_restantes']} días. ¡Renuévala ahora!',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
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
