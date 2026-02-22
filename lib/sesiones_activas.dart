import 'package:flutter/material.dart';
import 'dart:convert';
import 'api_client.dart';
import 'api_config.dart';
import 'app_logger.dart';

class SesionesActivasScreen extends StatefulWidget {
  const SesionesActivasScreen({super.key});

  @override
  State<SesionesActivasScreen> createState() => _SesionesActivasScreenState();
}

class _SesionesActivasScreenState extends State<SesionesActivasScreen> {
  final _api = ApiClient();
  List<dynamic> _sesiones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSesiones();
  }

  Future<void> _cargarSesiones() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await _api.get(ApiConfig.sessions);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _sesiones = data['sesiones'] ?? data ?? [];
        });
        AppLogger.i('Sesiones cargadas: ${_sesiones.length}');
      } else {
        setState(() {
          _error = 'Error al cargar sesiones (${resp.statusCode})';
        });
      }
    } on SinConexionException {
      setState(() {
        _error = 'Sin conexión a internet.';
      });
    } catch (e) {
      AppLogger.e('Error cargando sesiones', e);
      setState(() {
        _error = 'Error de conexión.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '-';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha.length > 16 ? fecha.substring(0, 16) : fecha;
    }
  }

  IconData _iconoDispositivo(String? tipo) {
    final t = (tipo ?? '').toLowerCase();
    if (t.contains('android') || t.contains('mobile'))
      return Icons.phone_android;
    if (t.contains('ios') || t.contains('iphone')) return Icons.phone_iphone;
    if (t.contains('web') || t.contains('browser')) return Icons.language;
    if (t.contains('desktop') || t.contains('windows')) return Icons.computer;
    return Icons.devices;
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _cargarSesiones,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _sesiones.isEmpty
          ? const Center(
              child: Text(
                'No hay sesiones activas.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Sesiones activas (${_sesiones.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Dispositivos donde has iniciado sesión',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sesiones.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final sesion = _sesiones[index];
                      final dispositivo =
                          sesion['dispositivo'] ??
                          sesion['user_agent'] ??
                          'Dispositivo desconocido';
                      final ip = sesion['ip'] ?? '-';
                      final fecha = _formatearFecha(
                        sesion['creado_en'] ??
                            sesion['fecha_inicio'] ??
                            sesion['created_at'],
                      );
                      final esActual =
                          sesion['es_sesion_actual'] == true ||
                          sesion['current'] == true;

                      return Card(
                        color: esActual
                            ? Colors.blue[900]!.withOpacity(0.4)
                            : Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            _iconoDispositivo(dispositivo.toString()),
                            color: esActual ? Colors.blue[300] : Colors.white54,
                            size: 32,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dispositivo.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (esActual)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Actual',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'IP: $ip',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Inicio: $fecha',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cargarSesiones,
        backgroundColor: const Color(0xFF1476FF),
        tooltip: "Refrescar sesiones",
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
